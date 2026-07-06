import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common'
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

  private getProductObjectId(productId: string): Types.ObjectId {
    if (!Types.ObjectId.isValid(productId)) {
      throw new BadRequestException(`Invalid productId: ${productId}`)
    }

    return new Types.ObjectId(productId)
  }

  // Lấy tồn kho của 1 sản phẩm
  async findByProduct(productId: string): Promise<InventoryDocument> {
    const inventory = await this.inventoryModel.findOne({ productId: this.getProductObjectId(productId) }).exec()
    if (!inventory) throw new NotFoundException(`Inventory for product ${productId} not found`)
    return inventory
  }

  // Tạo inventory khi product mới được tạo (stock = 0)
  async initForProduct(productId: string): Promise<InventoryDocument> {
    return this.inventoryModel.create({ productId: this.getProductObjectId(productId), stock: 0 })
  }

  // PATCH /inventory/:productId/stock — ADMIN set số lượng tồn kho
  async setStock(productId: string, stock: number): Promise<InventoryDocument> {
    const productObjectId = this.getProductObjectId(productId)
    const product = await this.productModel.findById(productObjectId).exec()
    if (!product) throw new NotFoundException(`Product ${productId} not found`)

    const inventory = await this.inventoryModel
      .findOneAndUpdate(
        { productId: productObjectId },
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

  // PATCH /inventory/:productId — ADMIN import hoặc trừ tồn kho
  async adjustStock(productId: string, action: 'IMPORT' | 'DEDUCT', quantity: number): Promise<InventoryDocument> {
    const productObjectId = this.getProductObjectId(productId)
    const product = await this.productModel.findById(productObjectId).exec()
    if (!product) throw new NotFoundException(`Product ${productId} not found`)

    const inventory = await this.inventoryModel.findOne({ productId: productObjectId }).exec()
    const currentStock = inventory?.stock ?? 0

    if (quantity <= 0) {
      throw new BadRequestException('quantity must be greater than 0')
    }

    const stockChange = action === 'IMPORT' ? quantity : -quantity
    const nextStock = currentStock + stockChange
    if (nextStock < 0) {
      throw new BadRequestException(
        `Insufficient stock for product ${productId} (current: ${currentStock}, change: ${stockChange})`,
      )
    }

    if (action === 'DEDUCT' && !inventory) {
      throw new NotFoundException(`Inventory for product ${productId} not found`)
    }

    const updatedInventory = await this.inventoryModel
      .findOneAndUpdate(
        { productId: productObjectId },
        {
          $inc: { stock: stockChange },
          $push: {
            logs: {
              change: stockChange,
              reason: action,
              createdAt: new Date(),
            },
          },
        },
        { returnDocument: 'after', upsert: action === 'IMPORT' },
      )
      .exec()

    if (!updatedInventory) throw new NotFoundException(`Inventory for product ${productId} not found`)

    const newStatus = nextStock === 0 ? StockStatus.OUT_OF_STOCK : StockStatus.IN_STOCK
    await this.productModel.findByIdAndUpdate(productId, { stockStatus: newStatus }).exec()

    return updatedInventory
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
