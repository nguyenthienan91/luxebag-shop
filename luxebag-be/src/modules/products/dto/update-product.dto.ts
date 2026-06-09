import { createZodDto } from 'nestjs-zod'
import { UpdateProductSchema } from '../schemas/product.zod'

export class UpdateProductDto extends createZodDto(UpdateProductSchema) {}
