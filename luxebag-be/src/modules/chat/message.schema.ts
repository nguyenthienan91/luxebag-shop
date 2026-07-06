import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { HydratedDocument, Types } from 'mongoose'

export type MessageDocument = HydratedDocument<Message>

@Schema({ timestamps: true })
export class Message {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  senderId!: Types.ObjectId

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  receiverId!: Types.ObjectId

  @Prop({ required: true })
  messageText!: string

  @Prop({ required: true, index: true })
  roomId!: string

  @Prop({ default: false })
  isRead!: boolean

  @Prop({ type: Types.ObjectId, ref: 'Order', required: false, default: null, index: true })
  orderId?: Types.ObjectId

  @Prop({ type: String, required: false, default: null })
  orderCodeSnapshot?: string

  createdAt!: Date
  updatedAt!: Date
}

export const MessageSchema = SchemaFactory.createForClass(Message)

// Compound index for sorted roomId pagination
MessageSchema.index({ roomId: 1, createdAt: -1 })
