import { Controller, Get, Post, Delete, Body, Param } from '@nestjs/common'
import { WishlistService } from './wishlist.service'
import { User, type UserInfo } from '../../../common/decorators/user.decorator'
import { z } from 'zod'
import { createZodDto } from 'nestjs-zod'
import { okResponse } from '../../../common/interceptors/format-response/format-response.util'

const objectIdRegex = /^[a-f\d]{24}$/i

class AddToWishlistDto extends createZodDto(
  z.object({
    productId: z.string().regex(objectIdRegex, 'productId must be a valid MongoDB ObjectId'),
  }),
) {}

@Controller('wishlist')
export class WishlistController {
  constructor(private readonly wishlistService: WishlistService) {}

  // GET /wishlist — lấy danh sách yêu thích của user hiện tại
  @Get()
  async findAll(@User() user: UserInfo) {
    return okResponse(await this.wishlistService.findByUser(user.userID))
  }

  // POST /wishlist — thêm sản phẩm vào danh sách yêu thích
  @Post()
  async add(@Body() dto: AddToWishlistDto, @User() user: UserInfo) {
    return okResponse(await this.wishlistService.add(user.userID, dto.productId))
  }

  // DELETE /wishlist/:productId — xóa sản phẩm khỏi danh sách yêu thích
  @Delete(':productId')
  async remove(@Param('productId') productId: string, @User() user: UserInfo) {
    return okResponse(await this.wishlistService.remove(user.userID, productId))
  }
}
