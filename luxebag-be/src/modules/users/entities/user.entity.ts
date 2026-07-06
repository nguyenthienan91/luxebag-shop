import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { HydratedDocument } from 'mongoose'

export enum UserRole {
  CUSTOMER = 'customer', // Khách hàng mua sắm
  SELLER = 'seller', // Người bán hàng (có thể là cá nhân hoặc doanh nghiệp)
  DELIVERY = 'delivery', // Nhân viên giao hàng
  ADMIN = 'admin', // Quản trị viên hệ thống
}

export type UserDocument = HydratedDocument<User>

@Schema({ timestamps: true })
export class User {
  id!: string

  @Prop({ required: true, unique: true, lowercase: true, trim: true })
  email!: string

  @Prop({ required: true })
  password!: string

  @Prop({ trim: true, default: null })
  phoneNumber!: string

  @Prop({ trim: true })
  identityNumber!: string

  @Prop({ type: String, enum: ['male', 'female', 'other'], default: null })
  gender!: string | null

  @Prop({ type: Date, default: null })
  dateOfBirth!: Date | null

  @Prop({ type: String, trim: true, default: null })
  address!: string | null

  @Prop({ trim: true })
  displayName!: string

  @Prop({ type: String, trim: true, default: null })
  avatar!: string | null

  @Prop({ type: String, enum: UserRole, default: UserRole.CUSTOMER })
  role!: UserRole

  @Prop({ default: true })
  isActive!: boolean

  @Prop({ default: false })
  isVerified!: boolean

  // --- LUỒNG FORGOT PASSWORD ---

  @Prop({ type: String, default: null })
  resetPasswordToken!: string | null // Dùng cho link reset qua Email

  @Prop({ type: String, default: null })
  resetPasswordOtp!: string | null // Dùng cho mã OTP qua SMS

  @Prop({ type: Date, default: null })
  resetPasswordExpiresAt!: Date | null // Thời hạn của Token hoặc OTP

  @Prop({ default: false })
  _destroy!: boolean
}

export const UserSchema = SchemaFactory.createForClass(User)
