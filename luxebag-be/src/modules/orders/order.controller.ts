import { Controller, Get, Post, Patch, Body, Param, Query, Ip } from '@nestjs/common'
import { ApiQuery } from '@nestjs/swagger'
import { OrderService } from './order.service'
import { CheckoutDto } from './dto/checkout.dto'
import { UpdateOrderStatusDto } from './dto/update-order-status.dto'
import { OrderStatus, PaymentMethod } from './entities/order.entity'
import { User, type UserInfo } from '../../../common/decorators/user.decorator'
import { Roles } from '../../../common/decorators/roles.decorator'
import { UserRole } from '../users/entities/user.entity'
import { okResponse } from '../../../common/interceptors/format-response/format-response.util'
import { VnpayService } from '../vnpay/vnpay.service'

@Controller('orders')
export class OrderController {
  constructor(
    private readonly orderService: OrderService,
    private readonly vnpayService: VnpayService,
  ) {}

  // GET /orders/admin — [ADMIN] lấy toàn bộ đơn hàng, có phân trang + lọc
  @Get('admin')
  @Roles(UserRole.STAFF, UserRole.ADMIN)
  @ApiQuery({ name: 'page', required: false, type: Number, example: 1 })
  @ApiQuery({ name: 'itemPerPage', required: false, type: Number, example: 10 })
  @ApiQuery({ name: 'status', required: false, enum: OrderStatus })
  @ApiQuery({ name: 'paymentMethod', required: false, enum: PaymentMethod })
  @ApiQuery({ name: 'userId', required: false, type: String })
  @ApiQuery({ name: 'search', required: false, type: String })
  @ApiQuery({ name: 'startDate', required: false, type: String })
  @ApiQuery({ name: 'endDate', required: false, type: String })
  async findAll(
    @Query('page') page?: string,
    @Query('itemPerPage') itemPerPage?: string,
    @Query('status') status?: OrderStatus,
    @Query('paymentMethod') paymentMethod?: PaymentMethod,
    @Query('userId') userId?: string,
    @Query('search') search?: string,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    return okResponse(
      await this.orderService.findAll(
        page ? parseInt(page) : undefined,
        itemPerPage ? parseInt(itemPerPage) : undefined,
        status,
        paymentMethod,
        userId,
        search,
        startDate,
        endDate,
      ),
    )
  }

  // GET /orders/revenue-stats — [ADMIN] Revenue statistics with flexible period
  @Get('revenue-stats')
  @Roles(UserRole.STAFF, UserRole.ADMIN)
  @ApiQuery({ name: 'period', required: false, type: String, enum: ['7d', '30d', '6m', '12m', 'year'], example: '7d' })
  async getRevenueStats(@Query('period') period?: string) {
    return okResponse(await this.orderService.getRevenueStats(period || '7d'))
  }

  // GET /orders — lấy lịch sử đơn hàng của user
  @Get()
  @ApiQuery({ name: 'status', required: false, enum: OrderStatus })
  async findMyOrders(@User() user: UserInfo, @Query('status') status?: OrderStatus) {
    return okResponse(await this.orderService.findByUser(user.userID, status))
  }

  // GET /orders/:id
  @Get(':id')
  async findOne(@Param('id') id: string, @User() user: UserInfo) {
    const isAdmin = user.role === UserRole.ADMIN
    return okResponse(await this.orderService.findById(id, user.userID, isAdmin))
  }

  // POST /orders/checkout
  @Post('checkout')
  async checkout(@Body() dto: CheckoutDto, @User() user: UserInfo, @Ip() ip: string) {
    const order = await this.orderService.checkout(user.userID, dto)

    if (dto.paymentMethod === PaymentMethod.VNPAY) {
      const paymentUrl = this.vnpayService.createPaymentUrl(order._id.toString(), order.totalAmount, ip || '127.0.0.1')
      order.paymentUrl = paymentUrl
      order.paymentUrlCreatedAt = new Date()
      await order.save()
    }

    return okResponse(order)
  }

  // PATCH /orders/:orderId/status — [ADMIN] cập nhật trạng thái đơn hàng
  @Patch(':orderId/status')
  @Roles(UserRole.STAFF, UserRole.ADMIN)
  async updateStatus(@Param('orderId') orderId: string, @Body() dto: UpdateOrderStatusDto) {
    return okResponse(await this.orderService.updateStatus(orderId, dto))
  }

  // PATCH /orders/:id/cancel — [CUSTOMER] Khách hàng tự hủy đơn
  @Patch(':id/cancel')
  async cancelOrder(@Param('id') id: string, @User() user: UserInfo) {
    return okResponse(await this.orderService.cancelOrder(id, user.userID))
  }

  // POST /orders/:id/recreate-payment-url — [CUSTOMER] Khởi tạo lại link thanh toán VNPay
  @Post(':id/recreate-payment-url')
  async recreatePaymentUrl(
    @Param('id') id: string,
    @User() user: UserInfo,
    @Ip() ip: string,
  ) {
    return okResponse(await this.orderService.recreatePaymentUrl(id, user.userID, ip || '127.0.0.1'))
  }
}
