import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common'
import { InjectModel } from '@nestjs/mongoose'
import { InjectConnection } from '@nestjs/mongoose'
import type { Connection, Model } from 'mongoose'
import { Types } from 'mongoose'
import { Order, OrderDocument, OrderStatus, PaymentMethod, PaymentStatus } from './entities/order.entity'
import { Cart, CartDocument } from '../cart/entities/cart.entity'
import { Inventory, InventoryDocument } from '../inventory/entities/inventory.entity'
import { Product, ProductDocument } from '../products/entities/product.entity'
import { CheckoutDto } from './dto/checkout.dto'
import { UpdateOrderStatusDto } from './dto/update-order-status.dto'
import { PaginationUtilService } from '../../../common/utils/pagination-util/pagination-util.service'
import { RevenueStatsDto } from './dto/revenue-stats.dto'
import { NotificationsService } from '../notifications/notifications.service'

@Injectable()
export class OrderService {
  constructor(
    @InjectModel(Order.name) private orderModel: Model<OrderDocument>,
    @InjectModel(Cart.name) private cartModel: Model<CartDocument>,
    @InjectModel(Inventory.name) private inventoryModel: Model<InventoryDocument>,
    @InjectModel(Product.name) private productModel: Model<ProductDocument>,
    @InjectConnection() private readonly connection: Connection,
    private readonly paginationUtil: PaginationUtilService,
    private readonly notificationsService: NotificationsService,
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

    const list = await this.orderModel
      .find(filter)
      .sort({ createdAt: -1 })
      .skip(pagination.skip)
      .limit(itemPerPage)
      .exec()

    return pagination.format(list)
  }

  // [USER] GET /orders — lấy đơn hàng của user
  async findByUser(userId: string, status?: OrderStatus): Promise<OrderDocument[]> {
    const filter: Record<string, any> = { userId: new Types.ObjectId(userId) }
    if (status) {
      filter.status = status
    }
    return this.orderModel.find(filter).sort({ createdAt: -1 }).exec()
  }

  async findById(id: string, userId: string, isAdmin = false): Promise<OrderDocument> {
    const filter = isAdmin ? { _id: id } : { _id: id, userId: new Types.ObjectId(userId) }
    const order = await this.orderModel.findOne(filter).exec()
    if (!order) throw new NotFoundException(`Order ${id} not found`)
    return order
  }

  async findRawById(id: string): Promise<OrderDocument | null> {
    if (!Types.ObjectId.isValid(id)) return null
    return this.orderModel.findById(id).exec()
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
            paymentStatus: PaymentStatus.UNPAID,
            status: OrderStatus.PENDING,
          },
        ],
        { session },
      )

      // 4. Xóa sạch giỏ hàng
      await this.cartModel.findOneAndUpdate({ userId: userObjectId }, { items: [] }, { session }).exec()

      await session.commitTransaction()

      // Trigger checkout notification
      try {
        await this.notificationsService.createNotification(
          userId,
          'Đặt đơn hàng thành công! 🛒',
          `Đơn hàng #${order._id} của bạn đã được đặt thành công và đang chờ xử lý.`,
          'order',
          'Order',
          order._id.toString(),
        )
      } catch (err) {
        console.error('Failed to create checkout notification:', err)
      }

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
    if (dto.status === OrderStatus.CANCELLED && order.status !== OrderStatus.CANCELLED) {
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
    if (dto.status) order.status = dto.status
    if (dto.paymentStatus) order.paymentStatus = dto.paymentStatus
    await order.save()

    // Trigger status update notification
    try {
      let title = ''
      let body = ''

      if (dto.status === OrderStatus.SHIPPED) {
        title = 'Đơn hàng đang giao 🚚'
        body = `Đơn hàng #${order._id} của bạn đang trên đường giao.`
      } else if (dto.status === OrderStatus.COMPLETED) {
        title = 'Đơn hàng hoàn thành ✅'
        body = `Đơn hàng #${order._id} đã được giao thành công. Cảm ơn bạn đã mua sắm!`
      } else if (dto.status === OrderStatus.CANCELLED) {
        title = 'Đơn hàng đã hủy ❌'
        body = `Đơn hàng #${order._id} của bạn đã bị hủy.`
      } else if (dto.status === OrderStatus.PROCESSING) {
        title = 'Đơn hàng đang xử lý ⚙️'
        body = `Đơn hàng #${order._id} của bạn đang được xử lý.`
      }

      if (title && body) {
        await this.notificationsService.createNotification(
          order.userId,
          title,
          body,
          'order',
          'Order',
          order._id.toString(),
        )
      }
    } catch (err) {
      console.error('Failed to create status update notification:', err)
    }

    return order
  }

  // [ADMIN] GET /orders/revenue-stats — Revenue statistics with flexible period
  async getRevenueStats(period: string = '7d'): Promise<RevenueStatsDto> {
    const validPeriods = ['7d', '30d', '6m', '12m', 'year']
    if (!validPeriods.includes(period)) {
      throw new BadRequestException(`Invalid period "${period}". Must be one of: ${validPeriods.join(', ')}`)
    }

    const now = new Date()
    let startDate: Date
    let dateFormat: string

    switch (period) {
      case '7d': {
        // Monday of current week in Asia/Ho_Chi_Minh (UTC+7)
        const localNow = new Date(now.getTime() + 7 * 60 * 60 * 1000)
        const dayOfWeek = localNow.getUTCDay() // 0=Sun, 1=Mon, ...
        const diffToMonday = dayOfWeek === 0 ? 6 : dayOfWeek - 1
        startDate = new Date(localNow)
        startDate.setUTCDate(startDate.getUTCDate() - diffToMonday)
        startDate.setUTCHours(0, 0, 0, 0)
        // Convert back from local to UTC
        startDate = new Date(startDate.getTime() - 7 * 60 * 60 * 1000)
        dateFormat = '%Y-%m-%d'
        break
      }
      case '30d': {
        startDate = new Date(now)
        startDate.setDate(startDate.getDate() - 29)
        startDate.setHours(0, 0, 0, 0)
        dateFormat = '%Y-%m-%d'
        break
      }
      case '6m': {
        startDate = new Date(now)
        startDate.setMonth(startDate.getMonth() - 5)
        startDate.setDate(1)
        startDate.setHours(0, 0, 0, 0)
        dateFormat = '%Y-%m'
        break
      }
      case '12m': {
        startDate = new Date(now)
        startDate.setMonth(startDate.getMonth() - 11)
        startDate.setDate(1)
        startDate.setHours(0, 0, 0, 0)
        dateFormat = '%Y-%m'
        break
      }
      case 'year': {
        // January 1st of current year (Asia/Ho_Chi_Minh)
        const localYear = new Date(now.getTime() + 7 * 60 * 60 * 1000).getUTCFullYear()
        startDate = new Date(Date.UTC(localYear, 0, 1) - 7 * 60 * 60 * 1000)
        dateFormat = '%Y-%m'
        break
      }
      default:
        startDate = new Date(now)
        dateFormat = '%Y-%m-%d'
    }

    const stats = await this.orderModel.aggregate([
      { $match: { status: OrderStatus.COMPLETED } },
      {
        $facet: {
          totalRevenue: [{ $group: { _id: null, total: { $sum: '$totalAmount' } } }],
          data: [
            { $match: { createdAt: { $gte: startDate } } },
            {
              $group: {
                _id: {
                  $dateToString: {
                    format: dateFormat,
                    date: '$createdAt',
                    timezone: 'Asia/Ho_Chi_Minh',
                  },
                },
                revenue: { $sum: '$totalAmount' },
              },
            },
            { $sort: { _id: 1 } },
            { $project: { _id: 0, label: '$_id', revenue: 1 } },
          ],
        },
      },
    ])

    const result = stats[0]
    const totalRevenue = result?.totalRevenue?.[0]?.total ?? 0
    const data = result?.data ?? []

    return {
      totalRevenue,
      period,
      data,
    }
  }

  // [SYSTEM] Cập nhật nguyên tử status và paymentStatus cho VNPay
  async updateOrderStatusAndPayment(orderId: string, status: OrderStatus, paymentStatus: PaymentStatus) {
    return this.orderModel.updateOne({ _id: new Types.ObjectId(orderId) }, { $set: { status, paymentStatus } }).exec()
  }
}
