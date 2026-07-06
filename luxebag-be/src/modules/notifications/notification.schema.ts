import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { HydratedDocument, Types } from 'mongoose'

export type NotificationDocument = HydratedDocument<Notification>

@Schema({ timestamps: true })
export class Notification {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true, index: true })
  userId!: Types.ObjectId

  @Prop({ required: true })
  title!: string

  @Prop({ required: true })
  body!: string

  @Prop({ default: false })
  isRead!: boolean

  @Prop({ required: true, enum: ['order', 'promotion', 'system'] })
  type!: string

  @Prop({ type: String, required: false, default: null })
  referenceType?: string | null

  @Prop({ type: String, required: false, default: null })
  referenceId?: string | null

  createdAt!: Date
  updatedAt!: Date
}

export const NotificationSchema = SchemaFactory.createForClass(Notification)

// Compound index on { userId: 1, createdAt: -1 }
NotificationSchema.index({ userId: 1, createdAt: -1 })
