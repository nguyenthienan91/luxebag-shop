import { z } from 'zod'

const CategoryBaseSchema = z.object({
  name: z.string({ error: 'Name is required' }).trim().min(1, 'Name cannot be empty'),
  description: z.string().trim().nullable().optional(),
})

export const CreateCategorySchema = CategoryBaseSchema

export type CreateCategoryDto = z.infer<typeof CreateCategorySchema>

export const UpdateCategorySchema = CategoryBaseSchema.partial()

export type UpdateCategoryDto = z.infer<typeof UpdateCategorySchema>
