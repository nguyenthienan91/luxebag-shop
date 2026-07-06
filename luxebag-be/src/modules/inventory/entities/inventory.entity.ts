import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { HydratedDocument, Types } from 'mongoose'

export type InventoryDocument = HydratedDocument<Inventory>

@Schema({ _id: false })
export class InventoryLog {
  @Prop({ required: true })
  change!: number // dương = nhập kho, âm = xuất kho

  @Prop({ required: true })
  reason!: string // 'ORDER', 'RESTOCK', etc.

  @Prop({ type: Date, default: () => new Date() })
  createdAt!: Date
}

export const InventoryLogSchema = SchemaFactory.createForClass(InventoryLog)

@Schema({ timestamps: true })
export class Inventory {
  @Prop({ type: Types.ObjectId, ref: 'Product', required: true, unique: true })
  productId!: Types.ObjectId

  @Prop({ required: true, min: 0, default: 0 })
  stock!: number

  @Prop({ type: [InventoryLogSchema], default: [] })
  logs!: InventoryLog[]
}

export const InventorySchema = SchemaFactory.createForClass(Inventory)
