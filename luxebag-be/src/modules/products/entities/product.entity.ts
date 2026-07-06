import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { HydratedDocument, Types } from 'mongoose'

export enum ProductGender {
  MEN = 'Men',
  WOMEN = 'Women',
  UNISEX = 'Unisex',
}

export enum SizeCategory {
  MINI = 'Mini',
  SMALL = 'Small',
  MEDIUM = 'Medium',
  LARGE = 'Large',
}

export enum StockStatus {
  IN_STOCK = 'IN STOCK',
  OUT_OF_STOCK = 'OUT OF STOCK',
}

export type ProductDocument = HydratedDocument<Product>

@Schema({
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true },
})
export class Product {
  id!: string

  // --- THÔNG TIN CƠ BẢN ---
  @Prop({ required: true, trim: true })
  title!: string

  @Prop({ required: true, trim: true })
  modelNumber!: string

  @Prop({ trim: true })
  upcCode!: string

  @Prop({ required: true, unique: true })
  sku!: string

  @Prop({ required: true })
  description!: string

  @Prop([{ type: String, required: true }])
  images!: string[]

  // --- GIÁ CẢ & KHUYẾN MÃI ---
  @Prop({ required: true })
  retailPrice!: number

  @Prop({ required: true })
  currentPrice!: number

  @Prop({ type: String, default: null })
  saleEventName!: string | null

  // --- THUỘC TÍNH CHI TIẾT SẢN PHẨM ---
  @Prop({ required: true, default: 'Montblanc' })
  brand!: string

  @Prop({ type: String, enum: ProductGender, default: ProductGender.UNISEX })
  gender!: ProductGender

  @Prop({ required: true })
  material!: string

  @Prop({ type: String })
  sizeInfo!: string

  @Prop({ type: String, enum: SizeCategory, default: SizeCategory.MEDIUM })
  sizeCategory!: SizeCategory

  // --- QUẢN LÝ PHÂN LOẠI & ĐƠN VỊ ---
  @Prop({ required: true })
  department!: string

  @Prop({ type: Types.ObjectId, ref: 'Category', required: true })
  categoryId!: Types.ObjectId

  // --- TRẠNG THÁI & LOGISTIC ---
  @Prop({ type: String, enum: StockStatus, default: StockStatus.IN_STOCK })
  stockStatus!: StockStatus

  @Prop({ type: String, default: 'New' })
  condition!: string

  @Prop({ default: false })
  _destroy!: boolean

  @Prop({
    type: {
      freeShipping: { type: Boolean, default: true },
      nextDayShipping: { type: Boolean, default: false },
    },
    default: {},
  })
  shippingOptions!: {
    freeShipping: boolean
    nextDayShipping: boolean
  }
}

export const ProductSchema = SchemaFactory.createForClass(Product)

// --- VIRTUAL PROPERTY: Tự động tính % giảm giá gửi về client ---
ProductSchema.virtual('discountPercentage').get(function () {
  if (this.retailPrice && this.currentPrice && this.retailPrice > this.currentPrice) {
    const discount = ((this.retailPrice - this.currentPrice) / this.retailPrice) * 100
    return Math.round(discount)
  }
  return 0
})
