import z from 'zod'
import { createZodDto } from 'nestjs-zod'
import { UserSchema } from '../../users/schemas/user.zod'

const forgotPasswordSchema = z.object({
  email: UserSchema.shape.email,
})

export class ForgotPasswordDto extends createZodDto(forgotPasswordSchema) {}

const changePasswordSchema = z.object({
  oldPassword: UserSchema.shape.password,
  newPassword: UserSchema.shape.password,
})

export class ChangePasswordDto extends createZodDto(changePasswordSchema) {}

const verifyOtpSchema = z.object({
  email: UserSchema.shape.email,
  otp: z.string().length(6, { message: 'OTP must be exactly 6 digits' }),
})

export class VerifyOtpDto extends createZodDto(verifyOtpSchema) {}

const resetPasswordSchema = z.object({
  email: UserSchema.shape.email,
  otp: z.string().length(6, { message: 'OTP must be exactly 6 digits' }),
  newPassword: UserSchema.shape.password,
})

export class ResetPasswordDto extends createZodDto(resetPasswordSchema) {}
