import { createZodDto } from 'nestjs-zod'
import { z } from 'zod'

import { TokenKeys } from '../consts/jwt.const'
import { UserSchema } from '../../users/schemas/user.zod'

const SignInSchema = UserSchema.pick({ email: true, password: true })

const SignUpSchema = SignInSchema.merge(UserSchema.pick({ displayName: true }).partial())

const SignInResponseSchema = z.object({
  [TokenKeys.ACCESS_TOKEN_KEY]: z.string(),
  [TokenKeys.REFRESH_TOKEN_KEY]: z.string(),
})

class SignInDto extends createZodDto(SignInSchema) {}

class SignInResponseDto extends createZodDto(SignInResponseSchema) {}

class SignUpDto extends createZodDto(SignUpSchema) {}

const GoogleLoginSchema = z.object({
  idToken: z.string(),
})

class GoogleLoginDto extends createZodDto(GoogleLoginSchema) {}

const VerifyEmailSchema = z.object({
  email: UserSchema.shape.email,
  otp: z.string().length(6, { message: 'OTP must be exactly 6 digits' }),
})

class VerifyEmailDto extends createZodDto(VerifyEmailSchema) {}

const ResendVerificationSchema = z.object({
  email: UserSchema.shape.email,
})

class ResendVerificationDto extends createZodDto(ResendVerificationSchema) {}

export { SignInDto, SignInResponseDto, SignUpDto, GoogleLoginDto, VerifyEmailDto, ResendVerificationDto }
