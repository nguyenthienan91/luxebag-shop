import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { HydratedDocument } from 'mongoose'

export type CategoryDocument = HydratedDocument<Category>

@Schema({ timestamps: true })
export class Category {
  id!: string

  @Prop({ required: true, trim: true, unique: true })
  name!: string

  @Prop({ type: String, trim: true, default: null })
  description!: string | null

  @Prop({ default: false })
  _destroy!: boolean
}

export const CategorySchema = SchemaFactory.createForClass(Category)
