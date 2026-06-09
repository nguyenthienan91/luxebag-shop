import { createZodDto } from 'nestjs-zod'
import { CreateCategorySchema } from '../schemas/category.zod'

export class CreateCategoryDto extends createZodDto(CreateCategorySchema) {}
