import { Injectable, NotFoundException } from '@nestjs/common'
import { InjectModel } from '@nestjs/mongoose'
import type { Model } from 'mongoose'
import { Types } from 'mongoose'
import { Inventory, InventoryDocument } from './entities/inventory.entity'
import { Product, ProductDocument, StockStatus } from '../products/entities/product.entity'

@Injectable()
export class InventoryService {
  constructor(
    @InjectModel(Inventory.name) private inventoryModel: Model<InventoryDocument>,
    @InjectModel(Product.name) private productModel: Model<ProductDocument>,
  ) {}

  // Lấy tồn kho của 1 sản phẩm
  async findByProduct(productId: string): Promise<InventoryDocument> {
    const inventory = await this.inventoryModel.findOne({ productId: new Types.ObjectId(productId) }).exec()
    if (!inventory) throw new NotFoundException(`Inventory for product ${productId} not found`)
    return inventory
  }

  // Tạo inventory khi product mới được tạo (stock = 0)
  async initForProduct(productId: string): Promise<InventoryDocument> {
    return this.inventoryModel.create({ productId: new Types.ObjectId(productId), stock: 0 })
  }

  // PATCH /inventory/:productId/stock — ADMIN set số lượng tồn kho
  async setStock(productId: string, stock: number): Promise<InventoryDocument> {
    const inventory = await this.inventoryModel
      .findOneAndUpdate(
        { productId: new Types.ObjectId(productId) },
        {
          $set: { stock },
          $push: { logs: { change: stock, reason: 'MANUAL_SET', createdAt: new Date() } },
        },
        { returnDocument: 'after', upsert: true },
      )
      .exec()
    if (!inventory) throw new NotFoundException(`Inventory for product ${productId} not found`)

    // Tự động đồng bộ stockStatus trên product
    const newStatus = stock === 0 ? StockStatus.OUT_OF_STOCK : StockStatus.IN_STOCK
    await this.productModel.findByIdAndUpdate(productId, { stockStatus: newStatus }).exec()

    return inventory
  }

  // POST /inventory/bulk-init — ADMIN init inventory cho tất cả products chưa có record
  async bulkInit(): Promise<{ initialized: number }> {
    const allProducts = await this.productModel.find({ _destroy: false }).select('_id').exec()
    const existingIds = (await this.inventoryModel.find().select('productId').exec()).map((i) => i.productId.toString())

    const missing = allProducts.filter((p) => !existingIds.includes(p._id.toString()))

    if (missing.length > 0) {
      await this.inventoryModel.insertMany(missing.map((p) => ({ productId: p._id, stock: 0 })))
    }

    return { initialized: missing.length }
  }
}
