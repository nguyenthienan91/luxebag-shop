import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { HydratedDocument, Types } from 'mongoose'

export enum OrderStatus {
  PENDING = 'pending',
  PROCESSING = 'processing',
  SHIPPED = 'shipped',
  COMPLETED = 'completed',
  CANCELLED = 'cancelled',
}

export enum PaymentMethod {
  COD = 'COD',
  CARD = 'CARD',
}

export type OrderDocument = HydratedDocument<Order>

// --- PRODUCT SNAPSHOT: Đóng băng thông tin sản phẩm tại thời điểm mua ---
@Schema({ _id: false })
export class OrderItem {
  @Prop({ type: Types.ObjectId, ref: 'Product', required: true })
  productId!: Types.ObjectId

  @Prop({ required: true })
  title!: string

  @Prop({ required: true })
  sku!: string

  @Prop({ type: String, default: null })
  image!: string | null

  @Prop({ required: true })
  priceAtPurchase!: number

  @Prop({ required: true, min: 1 })
  quantity!: number
}

export const OrderItemSchema = SchemaFactory.createForClass(OrderItem)

@Schema({ timestamps: true })
export class Order {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  userId!: Types.ObjectId

  @Prop({ type: [OrderItemSchema], required: true })
  items!: OrderItem[]

  @Prop({ required: true })
  totalAmount!: number

  @Prop({ required: true, trim: true })
  shippingAddress!: string

  @Prop({ type: String, enum: PaymentMethod, required: true })
  paymentMethod!: PaymentMethod

  @Prop({ type: String, enum: OrderStatus, default: OrderStatus.PENDING })
  status!: OrderStatus
}

export const OrderSchema = SchemaFactory.createForClass(Order)
