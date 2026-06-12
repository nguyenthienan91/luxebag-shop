import { z } from 'zod'
import { createZodDto } from 'nestjs-zod'
import { OrderStatus } from '../entities/order.entity'

export const UpdateOrderStatusSchema = z.object({
  status: z.nativeEnum(OrderStatus, { error: `status must be one of: ${Object.values(OrderStatus).join(', ')}` }),
})

export class UpdateOrderStatusDto extends createZodDto(UpdateOrderStatusSchema) {}
