import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common'
import { InjectModel } from '@nestjs/mongoose'
import { InjectConnection } from '@nestjs/mongoose'
import type { Connection, Model } from 'mongoose'
import { Types } from 'mongoose'
import { Order, OrderDocument } from './entities/order.entity'
import { Cart, CartDocument } from '../cart/entities/cart.entity'
import { Inventory, InventoryDocument } from '../inventory/entities/inventory.entity'
import { Product, ProductDocument } from '../products/entities/product.entity'
import { CheckoutDto } from './dto/checkout.dto'

@Injectable()
export class OrderService {
  constructor(
    @InjectModel(Order.name) private orderModel: Model<OrderDocument>,
    @InjectModel(Cart.name) private cartModel: Model<CartDocument>,
    @InjectModel(Inventory.name) private inventoryModel: Model<InventoryDocument>,
    @InjectModel(Product.name) private productModel: Model<ProductDocument>,
    @InjectConnection() private readonly connection: Connection,
  ) {}

  // Lấy danh sách đơn hàng của user
  async findByUser(userId: string): Promise<OrderDocument[]> {
    return this.orderModel.find({ userId }).sort({ createdAt: -1 }).exec()
  }

  // Lấy chi tiết 1 đơn hàng
  async findById(id: string, userId: string): Promise<OrderDocument> {
    const order = await this.orderModel.findOne({ _id: id, userId }).exec()
    if (!order) throw new NotFoundException(`Order ${id} not found`)
    return order
  }

  // POST /orders/checkout — Đặt hàng với Mongoose Transaction
  async checkout(userId: string, dto: CheckoutDto): Promise<OrderDocument> {
    const session = await this.connection.startSession()
    session.startTransaction()

    try {
      // 1. Lấy giỏ hàng hiện tại, populate product
      const cart = await this.cartModel
        .findOne({ userId })
        .populate<{ items: { productId: ProductDocument; quantity: number }[] }>('items.productId')
        .session(session)
        .exec()

      if (!cart || cart.items.length === 0) {
        throw new BadRequestException('Cart is empty')
      }

      let totalAmount = 0
      const orderItems: {
        productId: Types.ObjectId
        title: string
        sku: string
        image: string | null
        priceAtPurchase: number
        quantity: number
      }[] = []

      // 2. Vòng lặp kiểm tra kho và build snapshot
      for (const item of cart.items) {
        const product = item.productId
        if (!product || !product._id) {
          throw new BadRequestException('One or more products in cart no longer exist')
        }

        const inventory = await this.inventoryModel.findOne({ productId: product._id }).session(session).exec()

        // Kiểm tra tồn kho
        if (!inventory || inventory.stock < item.quantity) {
          throw new BadRequestException(
            `Product "${product.title}" is out of stock (available: ${inventory?.stock ?? 0}, requested: ${item.quantity})`,
          )
        }

        // Trừ kho nguyên tử + ghi log
        await this.inventoryModel
          .findOneAndUpdate(
            { productId: product._id },
            {
              $inc: { stock: -item.quantity },
              $push: {
                logs: {
                  change: -item.quantity,
                  reason: 'ORDER',
                  createdAt: new Date(),
                },
              },
            },
            { session },
          )
          .exec()

        // Giá lấy từ DB, không lấy từ client
        const priceAtPurchase = product.currentPrice
        const itemTotal = priceAtPurchase * item.quantity
        totalAmount += itemTotal

        // Build product snapshot
        orderItems.push({
          productId: product._id,
          title: product.title,
          sku: product.sku,
          image: product.images?.[0] ?? null,
          priceAtPurchase,
          quantity: item.quantity,
        })
      }

      // 3. Tạo đơn hàng
      const [order] = await this.orderModel.create(
        [
          {
            userId,
            items: orderItems,
            totalAmount,
            shippingAddress: dto.shippingAddress,
            paymentMethod: dto.paymentMethod,
          },
        ],
        { session },
      )

      // 4. Xóa sạch giỏ hàng
      await this.cartModel.findOneAndUpdate({ userId }, { items: [] }, { session }).exec()

      await session.commitTransaction()
      return order
    } catch (error) {
      await session.abortTransaction()
      throw error
    } finally {
      await session.endSession()
    }
  }
}
