import { Injectable, NotFoundException } from '@nestjs/common'
import { InjectModel } from '@nestjs/mongoose'
import type { Model } from 'mongoose'
import { Product, ProductDocument } from './entities/product.entity'
import { CreateProductDto } from './dto/create-product.dto'
import { UpdateProductDto } from './dto/update-product.dto'
import { PaginationUtilService } from '../../../common/utils/pagination-util/pagination-util.service'
import { InventoryService } from '../inventory/inventory.service'
import { CloudinaryService } from '../../../common/services/cloudinary/cloudinary.service'

export interface FindAllProductsParams {
  page?: number
  itemPerPage?: number
  categoryId?: string
  search?: string
  minPrice?: number
  maxPrice?: number
}

@Injectable()
export class ProductService {
  constructor(
    @InjectModel(Product.name) private productModel: Model<ProductDocument>,
    private readonly paginationUtil: PaginationUtilService,
    private readonly inventoryService: InventoryService,
    private readonly cloudinaryService: CloudinaryService,
  ) {}

  async findAll(params: FindAllProductsParams) {
    const { page = 1, itemPerPage = 10, categoryId, search, minPrice, maxPrice } = params

    const filter: Record<string, any> = { _destroy: false }

    if (categoryId) {
      filter.categoryId = categoryId
    }

    if (search) {
      filter.title = { $regex: search, $options: 'i' }
    }

    if (minPrice !== undefined || maxPrice !== undefined) {
      filter.currentPrice = {}
      if (minPrice !== undefined) filter.currentPrice.$gte = minPrice
      if (maxPrice !== undefined) filter.currentPrice.$lte = maxPrice
    }

    const totalItems = await this.productModel.countDocuments(filter)
    const pagination = this.paginationUtil.paging({ page, itemPerPage, totalItems })

    const list = await this.productModel
      .find(filter)
      .populate('categoryId')
      .sort({ createdAt: -1 })
      .skip(pagination.skip)
      .limit(itemPerPage)
      .exec()

    return pagination.format(list)
  }

  async findById(id: string) {
    const product = await this.productModel.findOne({ _id: id, _destroy: false }).populate('categoryId').exec()
    if (!product) throw new NotFoundException(`Product ${id} not found`)

    const inventory = await this.inventoryService.findByProduct(id).catch(() => null)
    const stock = inventory?.stock ?? 0

    return { ...product.toObject(), stock }
  }

  async create(dto: CreateProductDto): Promise<ProductDocument> {
    const product = await this.productModel.create(dto)
    // Tự động tạo inventory với stock = 0 cho product mới
    await this.inventoryService.initForProduct(product._id.toString())
    return product
  }

  async update(id: string, dto: UpdateProductDto): Promise<ProductDocument> {
    const product = await this.productModel
      .findOneAndUpdate({ _id: id, _destroy: false }, dto, { returnDocument: 'after' })
      .exec()
    if (!product) throw new NotFoundException(`Product ${id} not found`)
    return product
  }

  async softDelete(id: string): Promise<ProductDocument> {
    const product = await this.productModel
      .findOneAndUpdate({ _id: id, _destroy: false }, { _destroy: true }, { returnDocument: 'after' })
      .exec()
    if (!product) throw new NotFoundException(`Product ${id} not found`)
    return product
  }

  async uploadImages(productId: string, files: Express.Multer.File[]): Promise<ProductDocument> {
    const product = await this.productModel.findOne({ _id: productId, _destroy: false }).exec()
    if (!product) throw new NotFoundException(`Product ${productId} not found`)

    // Xóa ảnh cũ trên Cloudinary (nếu có)
    if (product.images?.length) {
      await Promise.all(
        product.images.map((url) => {
          const publicId = this.cloudinaryService.extractPublicId(url)
          return publicId ? this.cloudinaryService.deleteImage(publicId) : Promise.resolve()
        }),
      )
    }

    // Upload song song tất cả ảnh mới vào luxebag/products
    const uploadResults = await Promise.all(
      files.map((file) => this.cloudinaryService.uploadToFolder(file, 'luxebag/products')),
    )
    const newImageUrls = uploadResults.map((r) => r.secure_url)

    // Cập nhật mảng images trong DB
    return this.productModel
      .findByIdAndUpdate(productId, { images: newImageUrls }, { returnDocument: 'after' })
      .exec() as Promise<ProductDocument>
  }
}
