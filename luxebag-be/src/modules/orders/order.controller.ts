import { Controller, Get, Post, Patch, Body, Param, Query } from '@nestjs/common'
import { ApiQuery } from '@nestjs/swagger'
import { OrderService } from './order.service'
import { CheckoutDto } from './dto/checkout.dto'
import { UpdateOrderStatusDto } from './dto/update-order-status.dto'
import { OrderStatus, PaymentMethod } from './entities/order.entity'
import { User, type UserInfo } from '../../../common/decorators/user.decorator'
import { Roles } from '../../../common/decorators/roles.decorator'
import { UserRole } from '../users/entities/user.entity'
import { okResponse } from '../../../common/interceptors/format-response/format-response.util'

@Controller('orders')
export class OrderController {
  constructor(private readonly orderService: OrderService) {}

  // GET /orders/admin — [ADMIN] lấy toàn bộ đơn hàng, có phân trang + lọc
  @Get('admin')
  @Roles(UserRole.ADMIN)
  @ApiQuery({ name: 'page', required: false, type: Number, example: 1 })
  @ApiQuery({ name: 'itemPerPage', required: false, type: Number, example: 10 })
  @ApiQuery({ name: 'status', required: false, enum: OrderStatus })
  @ApiQuery({ name: 'paymentMethod', required: false, enum: PaymentMethod })
  @ApiQuery({ name: 'userId', required: false, type: String })
  async findAll(
    @Query('page') page?: string,
    @Query('itemPerPage') itemPerPage?: string,
    @Query('status') status?: OrderStatus,
    @Query('paymentMethod') paymentMethod?: PaymentMethod,
    @Query('userId') userId?: string,
  ) {
    return okResponse(
      await this.orderService.findAll(
        page ? parseInt(page) : undefined,
        itemPerPage ? parseInt(itemPerPage) : undefined,
        status,
        paymentMethod,
        userId,
      ),
    )
  }

  // GET /orders/revenue-stats — [ADMIN] Revenue statistics with flexible period
  @Get('revenue-stats')
  @Roles(UserRole.ADMIN)
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
  async checkout(@Body() dto: CheckoutDto, @User() user: UserInfo) {
    return okResponse(await this.orderService.checkout(user.userID, dto))
  }

  // PATCH /orders/:orderId/status — [ADMIN] cập nhật trạng thái đơn hàng
  @Patch(':orderId/status')
  @Roles(UserRole.ADMIN)
  async updateStatus(@Param('orderId') orderId: string, @Body() dto: UpdateOrderStatusDto) {
    return okResponse(await this.orderService.updateStatus(orderId, dto))
  }
}
