import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common'
import { InjectModel } from '@nestjs/mongoose'
import { InjectConnection } from '@nestjs/mongoose'
import type { Connection, Model } from 'mongoose'
import { Types } from 'mongoose'
import { Order, OrderDocument, OrderStatus, PaymentMethod } from './entities/order.entity'
import { Cart, CartDocument } from '../cart/entities/cart.entity'
import { Inventory, InventoryDocument } from '../inventory/entities/inventory.entity'
import { Product, ProductDocument } from '../products/entities/product.entity'
import { CheckoutDto } from './dto/checkout.dto'
import { UpdateOrderStatusDto } from './dto/update-order-status.dto'
import { PaginationUtilService } from '../../../common/utils/pagination-util/pagination-util.service'

@Injectable()
export class OrderService {
  constructor(
    @InjectModel(Order.name) private orderModel: Model<OrderDocument>,
    @InjectModel(Cart.name) private cartModel: Model<CartDocument>,
    @InjectModel(Inventory.name) private inventoryModel: Model<InventoryDocument>,
    @InjectModel(Product.name) private productModel: Model<ProductDocument>,
    @InjectConnection() private readonly connection: Connection,
    private readonly paginationUtil: PaginationUtilService,
  ) {}

  // [ADMIN] GET /orders/admin — lấy tất cả đơn hàng, có phân trang + lọc
  async findAll(
    page: number = 1,
    itemPerPage: number = 10,
    status?: OrderStatus,
    paymentMethod?: PaymentMethod,
    userId?: string,
  ) {
    const filter: Record<string, any> = {}
    if (status) filter.status = status
    if (paymentMethod) filter.paymentMethod = paymentMethod
    if (userId) filter.userId = new Types.ObjectId(userId)

    const totalItems = await this.orderModel.countDocuments(filter)
    const pagination = this.paginationUtil.paging({ page, itemPerPage, totalItems })

    const list = await this.orderModel.find(filter).sort({ createdAt: -1 }).skip(pagination.skip).limit(itemPerPage).exec()

    return pagination.format(list)
  }

  // [USER] GET /orders — lấy đơn hàng của user
  async findByUser(userId: string): Promise<OrderDocument[]> {
    return this.orderModel
      .find({ userId: new Types.ObjectId(userId) })
      .sort({ createdAt: -1 })
      .exec()
  }

  async findById(id: string, userId: string): Promise<OrderDocument> {
    const order = await this.orderModel.findOne({ _id: id, userId: new Types.ObjectId(userId) }).exec()
    if (!order) throw new NotFoundException(`Order ${id} not found`)
    return order
  }

  async checkout(userId: string, dto: CheckoutDto): Promise<OrderDocument> {
    const session = await this.connection.startSession()
    session.startTransaction()
    const userObjectId = new Types.ObjectId(userId)

    try {
      // 1. Lấy giỏ hàng hiện tại, populate product
      const cart = await this.cartModel
        .findOne({ userId: userObjectId })
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
            userId: userObjectId,
            items: orderItems,
            totalAmount,
            shippingAddress: dto.shippingAddress,
            paymentMethod: dto.paymentMethod,
          },
        ],
        { session },
      )

      // 4. Xóa sạch giỏ hàng
      await this.cartModel.findOneAndUpdate({ userId: userObjectId }, { items: [] }, { session }).exec()

      await session.commitTransaction()
      return order
    } catch (error) {
      await session.abortTransaction()
      throw error
    } finally {
      await session.endSession()
    }
  }

  // [ADMIN] PATCH /orders/:orderId/status — cập nhật trạng thái đơn hàng
  async updateStatus(orderId: string, dto: UpdateOrderStatusDto): Promise<OrderDocument> {
    const order = await this.orderModel.findById(orderId).exec()
    if (!order) throw new NotFoundException(`Order ${orderId} not found`)

    // 1. Đóng băng đơn hàng đã hoàn thành hoặc đã hủy
    const frozenStatuses = [OrderStatus.COMPLETED, OrderStatus.CANCELLED]
    if (frozenStatuses.includes(order.status)) {
      throw new BadRequestException(`Cannot update order with status "${order.status}"`)
    }

    // 2. Hoàn kho khi hủy đơn
    if (dto.status === OrderStatus.CANCELLED) {
      for (const item of order.items) {
        await this.inventoryModel
          .findOneAndUpdate(
            { productId: item.productId },
            {
              $inc: { stock: item.quantity },
              $push: {
                logs: {
                  change: item.quantity,
                  reason: 'CANCEL_ORDER_RESTORE',
                  note: `Hoàn kho do hủy đơn hàng #${orderId}`,
                  createdAt: new Date(),
                },
              },
            },
          )
          .exec()
      }
    }

    // 3. Cập nhật status và lưu
    order.status = dto.status
    await order.save()
    return order
  }
}
