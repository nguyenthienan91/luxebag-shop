import { Injectable, NotFoundException } from '@nestjs/common'
import { InjectModel } from '@nestjs/mongoose'
import type { Model } from 'mongoose'
import { Cart, CartDocument } from './entities/cart.entity'

@Injectable()
export class CartService {
  constructor(@InjectModel(Cart.name) private cartModel: Model<CartDocument>) {}

  // Lấy giỏ hàng của user (populate product), tạo mới nếu chưa có
  async getCart(userId: string): Promise<CartDocument> {
    let cart = await this.cartModel.findOne({ userId }).populate('items.productId').exec()
    if (!cart) {
      cart = await this.cartModel.create({ userId, items: [] })
    }
    return cart
  }

  // POST /cart/add — cộng dồn nếu đã có, thêm mới nếu chưa có
  async addItem(userId: string, productId: string, quantity: number): Promise<CartDocument> {
    let cart = await this.cartModel.findOne({ userId }).exec()
    if (!cart) {
      cart = await this.cartModel.create({ userId, items: [] })
    }

    const existingItem = cart.items.find((item) => item.productId.toString() === productId)
    if (existingItem) {
      existingItem.quantity += quantity
    } else {
      cart.items.push({ productId: productId as any, quantity })
    }

    await cart.save()
    return cart.populate('items.productId')
  }

  // PUT /cart/update — ghi đè quantity
  async updateItem(userId: string, productId: string, quantity: number): Promise<CartDocument> {
    const cart = await this.cartModel.findOne({ userId }).exec()
    if (!cart) throw new NotFoundException('Cart not found')

    const item = cart.items.find((i) => i.productId.toString() === productId)
    if (!item) throw new NotFoundException(`Product ${productId} not found in cart`)

    item.quantity = quantity
    await cart.save()
    return cart.populate('items.productId')
  }

  // DELETE /cart/remove/:productId
  async removeItem(userId: string, productId: string): Promise<CartDocument> {
    const cart = await this.cartModel.findOne({ userId }).exec()
    if (!cart) throw new NotFoundException('Cart not found')

    cart.items = cart.items.filter((i) => i.productId.toString() !== productId)
    await cart.save()
    return cart.populate('items.productId')
  }

  // Xóa toàn bộ items sau khi checkout
  async clearCart(userId: string): Promise<void> {
    await this.cartModel.findOneAndUpdate({ userId }, { items: [] }).exec()
  }
}
