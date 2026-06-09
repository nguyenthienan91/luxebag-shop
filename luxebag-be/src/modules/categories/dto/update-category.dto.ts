import { createZodDto } from 'nestjs-zod'
import { UpdateCategorySchema } from '../schemas/category.zod'

export class UpdateCategoryDto extends createZodDto(UpdateCategorySchema) {}
