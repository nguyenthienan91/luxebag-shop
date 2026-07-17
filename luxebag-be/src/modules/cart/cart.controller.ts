import { Controller, Get, Post, Put, Delete, Body, Param } from '@nestjs/common'
import { CartService } from './cart.service'
import { AddToCartDto, UpdateCartDto } from './dto/cart.dto'
import { User, type UserInfo } from '../../../common/decorators/user.decorator'
import { okResponse } from '../../../common/interceptors/format-response/format-response.util'

@Controller('cart')
export class CartController {
  constructor(private readonly cartService: CartService) {}

  // GET /cart
  @Get()
  async getCart(@User() user: UserInfo) {
    return okResponse(await this.cartService.getCart(user.userID))
  }

  // POST /cart/add
  @Post('add')
  async addItem(@Body() dto: AddToCartDto, @User() user: UserInfo) {
    return okResponse(await this.cartService.addItem(user.userID, dto.productId, dto.quantity))
  }

  // PUT /cart/update
  @Put('update')
  async updateItem(@Body() dto: UpdateCartDto, @User() user: UserInfo) {
    return okResponse(await this.cartService.updateItem(user.userID, dto.productId, dto.quantity))
  }

  // DELETE /cart/remove/:productId
  @Delete('remove/:productId')
  async removeItem(@Param('productId') productId: string, @User() user: UserInfo) {
    return okResponse(await this.cartService.removeItem(user.userID, productId))
  }

  // DELETE /cart/clear
  @Delete('clear')
  async clearCart(@User() user: UserInfo) {
    return okResponse(await this.cartService.clearCart(user.userID))
  }
}
