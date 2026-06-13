import { ConflictException, Injectable, NotFoundException } from '@nestjs/common'
import { InjectModel } from '@nestjs/mongoose'
import { Model, Types } from 'mongoose'
import { Wishlist, WishlistDocument } from './entities/wishlist.entity'

@Injectable()
export class WishlistService {
  constructor(@InjectModel(Wishlist.name) private wishlistModel: Model<WishlistDocument>) {}

  // Lấy toàn bộ wishlist của user, populate thông tin product
  async findByUser(userId: string): Promise<WishlistDocument[]> {
    return this.wishlistModel
      .find({ userId: new Types.ObjectId(userId) })
      .populate('productId')
      .exec()
  }

  // Thêm sản phẩm vào wishlist, kiểm tra trùng lặp
  async add(userId: string, productId: string): Promise<WishlistDocument> {
    const userObjId = new Types.ObjectId(userId)
    const productObjId = new Types.ObjectId(productId)

    const existing = await this.wishlistModel.findOne({ userId: userObjId, productId: productObjId }).exec()
    if (existing) throw new ConflictException('Product already in wishlist')
    return this.wishlistModel.create({ userId: userObjId, productId: productObjId })
  }

  // Xóa sản phẩm khỏi wishlist
  async remove(userId: string, productId: string): Promise<WishlistDocument> {
    const item = await this.wishlistModel
      .findOneAndDelete({
        userId: new Types.ObjectId(userId),
        productId: new Types.ObjectId(productId),
      })
      .exec()
    if (!item) throw new NotFoundException('Wishlist item not found')
    return item
  }
}
