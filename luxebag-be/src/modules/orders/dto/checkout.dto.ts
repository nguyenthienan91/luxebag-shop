import { z } from 'zod'
import { createZodDto } from 'nestjs-zod'
import { PaymentMethod } from '../entities/order.entity'

export const CheckoutSchema = z.object({
  province: z.string({ error: 'Province is required' }).min(1, 'Province cannot be empty'),
  shippingAddress: z.string({ error: 'Shipping address is required' }).min(1, 'Shipping address cannot be empty'),
  paymentMethod: z.nativeEnum(PaymentMethod, { error: 'paymentMethod must be COD or VNPAY' }),
  selectedProductIds: z.array(z.string()).optional(),
})

export class CheckoutDto extends createZodDto(CheckoutSchema) {}
