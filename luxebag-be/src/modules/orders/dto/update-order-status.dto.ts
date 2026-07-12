import { z } from 'zod'
import { createZodDto } from 'nestjs-zod'
import { OrderStatus, PaymentStatus } from '../entities/order.entity'

export const UpdateOrderStatusSchema = z.object({
  status: z
    .nativeEnum(OrderStatus, { error: `status must be one of: ${Object.values(OrderStatus).join(', ')}` })
    .optional(),
  paymentStatus: z
    .nativeEnum(PaymentStatus, { error: `paymentStatus must be one of: ${Object.values(PaymentStatus).join(', ')}` })
    .optional(),
})

export class UpdateOrderStatusDto extends createZodDto(UpdateOrderStatusSchema) {}
