import { Injectable, NotFoundException } from '@nestjs/common'
import { InjectModel } from '@nestjs/mongoose'
import type { Model } from 'mongoose'
import { Types } from 'mongoose'
import { Cart, CartDocument } from './entities/cart.entity'

@Injectable()
export class CartService {
  constructor(@InjectModel(Cart.name) private cartModel: Model<CartDocument>) {}

  async getCart(userId: string): Promise<CartDocument> {
    const userObjectId = new Types.ObjectId(userId)
    let cart = await this.cartModel.findOne({ userId: userObjectId }).populate('items.productId').exec()
    if (!cart) {
      cart = await this.cartModel.create({ userId: userObjectId, items: [] })
    }
    return cart
  }

  async addItem(userId: string, productId: string, quantity: number): Promise<CartDocument> {
    const userObjectId = new Types.ObjectId(userId)
    let cart = await this.cartModel.findOne({ userId: userObjectId }).exec()
    if (!cart) {
      cart = await this.cartModel.create({ userId: userObjectId, items: [] })
    }

    const existingItem = cart.items.find((item) => item.productId.toString() === productId)
    if (existingItem) {
      existingItem.quantity += quantity
    } else {
      cart.items.push({ productId: new Types.ObjectId(productId) as any, quantity })
    }

    await cart.save()
    return cart.populate('items.productId')
  }

  async updateItem(userId: string, productId: string, quantity: number): Promise<CartDocument> {
    const userObjectId = new Types.ObjectId(userId)
    const cart = await this.cartModel.findOne({ userId: userObjectId }).exec()
    if (!cart) throw new NotFoundException('Cart not found')

    const item = cart.items.find((i) => i.productId.toString() === productId)
    if (!item) throw new NotFoundException(`Product ${productId} not found in cart`)

    item.quantity = quantity
    await cart.save()
    return cart.populate('items.productId')
  }

  async removeItem(userId: string, productId: string): Promise<CartDocument> {
    const userObjectId = new Types.ObjectId(userId)
    const cart = await this.cartModel.findOne({ userId: userObjectId }).exec()
    if (!cart) throw new NotFoundException('Cart not found')

    cart.items = cart.items.filter((i) => i.productId.toString() !== productId)
    await cart.save()
    return cart.populate('items.productId')
  }

  async clearCart(userId: string): Promise<CartDocument> {
    const userObjectId = new Types.ObjectId(userId)
    const cart = await this.cartModel.findOne({ userId: userObjectId }).exec()
    if (!cart) throw new NotFoundException('Cart not found')

    cart.items = []
    await cart.save()
    return cart.populate('items.productId')
  }
}
