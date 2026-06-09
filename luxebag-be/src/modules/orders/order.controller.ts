import { Controller, Get, Post, Body, Param } from '@nestjs/common'
import { OrderService } from './order.service'
import { CheckoutDto } from './dto/checkout.dto'
import { User, type UserInfo } from '../../../common/decorators/user.decorator'
import { okResponse } from '../../../common/interceptors/format-response/format-response.util'

@Controller('orders')
export class OrderController {
  constructor(private readonly orderService: OrderService) {}

  // GET /orders — lấy lịch sử đơn hàng của user
  @Get()
  async findAll(@User() user: UserInfo) {
    return okResponse(await this.orderService.findByUser(user.userID))
  }

  // GET /orders/:id
  @Get(':id')
  async findOne(@Param('id') id: string, @User() user: UserInfo) {
    return okResponse(await this.orderService.findById(id, user.userID))
  }

  // POST /orders/checkout
  @Post('checkout')
  async checkout(@Body() dto: CheckoutDto, @User() user: UserInfo) {
    return okResponse(await this.orderService.checkout(user.userID, dto))
  }
}
