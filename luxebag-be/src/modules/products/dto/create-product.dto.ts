import { createZodDto } from 'nestjs-zod'
import { CreateProductSchema } from '../schemas/product.zod'

export class CreateProductDto extends createZodDto(CreateProductSchema) {}
