import { z } from 'zod'
import { ProductGender, SizeCategory, StockStatus } from '../entities/product.entity'

const objectIdRegex = /^[a-f\d]{24}$/i

const priceRefinement = (data: { currentPrice?: number; retailPrice?: number }) => {
  if (data.currentPrice !== undefined && data.retailPrice !== undefined) {
    return data.currentPrice <= data.retailPrice
  }
  return true
}

const priceRefinementOptions = {
  message: 'Current price cannot be greater than retail price',
  path: ['currentPrice'],
}

// --- BASE SHAPE (dùng cho cả CREATE và UPDATE) ---
const ProductBaseSchema = z.object({
  // THÔNG TIN CƠ BẢN
  title: z.string({ error: 'Title is required' }).trim().min(1, 'Title cannot be empty'),
  modelNumber: z.string({ error: 'Model number is required' }).trim().min(1, 'Model number cannot be empty'),
  upcCode: z.string().trim().optional(),
  sku: z.string({ error: 'SKU is required' }).min(1, 'SKU cannot be empty'),
  description: z.string({ error: 'Description is required' }).min(1, 'Description cannot be empty'),
  images: z.array(z.string().url('Each image must be a valid URL')).optional(), // TODO: required after Cloudinary integration

  // GIÁ CẢ & KHUYẾN MÃI
  retailPrice: z
    .number({ error: 'Retail price is required and must be a number' })
    .positive('Retail price must be greater than 0'),
  currentPrice: z
    .number({ error: 'Current price is required and must be a number' })
    .positive('Current price must be greater than 0'),
  saleEventName: z.string().nullable().optional(),

  // THUỘC TÍNH CHI TIẾT SẢN PHẨM
  brand: z.string().min(1, 'Brand cannot be empty').default('Montblanc'),
  gender: z.nativeEnum(ProductGender).default(ProductGender.UNISEX),
  material: z.string({ error: 'Material is required' }).min(1, 'Material cannot be empty'),
  sizeInfo: z.string().optional(),
  sizeCategory: z.nativeEnum(SizeCategory).default(SizeCategory.MEDIUM),

  // QUẢN LÝ PHÂN LOẠI & ĐƠN VỊ
  department: z.string({ error: 'Department is required' }).min(1, 'Department cannot be empty'),
  categoryId: z
    .string({ error: 'Category ID is required' })
    .regex(objectIdRegex, 'Category ID must be a valid MongoDB ObjectId'),

  // TRẠNG THÁI & LOGISTIC
  stockStatus: z.nativeEnum(StockStatus).default(StockStatus.IN_STOCK),
  condition: z.string().default('New'),
  shippingOptions: z
    .object({
      freeShipping: z.boolean().default(true),
      nextDayShipping: z.boolean().default(false),
    })
    .default({ freeShipping: true, nextDayShipping: false }),
})

// --- CREATE ---
export const CreateProductSchema = ProductBaseSchema.refine(priceRefinement, priceRefinementOptions)

export type CreateProductDto = z.infer<typeof CreateProductSchema>

// --- UPDATE (tất cả field đều optional) ---
export const UpdateProductSchema = ProductBaseSchema.partial().refine(priceRefinement, priceRefinementOptions)

export type UpdateProductDto = z.infer<typeof UpdateProductSchema>
