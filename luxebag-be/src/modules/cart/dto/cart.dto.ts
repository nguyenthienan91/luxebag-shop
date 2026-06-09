import { z } from 'zod'
import { createZodDto } from 'nestjs-zod'

const objectIdRegex = /^[a-f\d]{24}$/i

export const AddToCartSchema = z.object({
  productId: z.string().regex(objectIdRegex, 'productId must be a valid MongoDB ObjectId'),
  quantity: z
    .number({ error: 'quantity is required and must be a number' })
    .int()
    .min(1, 'quantity must be at least 1'),
})

export const UpdateCartSchema = z.object({
  productId: z.string().regex(objectIdRegex, 'productId must be a valid MongoDB ObjectId'),
  quantity: z
    .number({ error: 'quantity is required and must be a number' })
    .int()
    .min(1, 'quantity must be at least 1'),
})

export class AddToCartDto extends createZodDto(AddToCartSchema) {}
export class UpdateCartDto extends createZodDto(UpdateCartSchema) {}
