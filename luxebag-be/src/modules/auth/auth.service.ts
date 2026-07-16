import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  InternalServerErrorException,
  UnauthorizedException,
} from '@nestjs/common'
import { UsersService } from '../users/users.service'
import { JwtService, TokenExpiredError } from '@nestjs/jwt'
import { JwtPayload, JWTToken, TokenKeys } from './consts/jwt.const'
import { randomUUID } from 'crypto'
import { StringUtilService } from '../../../common/utils/string-util/string-util.service'
import { MailService } from '../../../common/utils/mail-util/mail.service'
import { SignInDto, SignUpDto, VerifyEmailDto, ResendVerificationDto } from './dto/sign.dto'
import { ChangePasswordDto, ForgotPasswordDto, ResetPasswordDto, VerifyOtpDto } from './dto/password.dto'
import { WithUser } from '../../../common/decorators/user.decorator'
import { OAuth2Client } from 'google-auth-library'

@Injectable()
export class AuthService {
  constructor(
    private usersService: UsersService,
    private stringUtilService: StringUtilService,
    private jwtService: JwtService,
    private mailService: MailService,
  ) {}

  async createToken<T extends Record<string, any>>(payload: T) {
    const accessToken = await this.jwtService.signAsync(payload, {
      expiresIn: JWTToken.ACCESS_TOKEN_EXPIRE_IN,
    })
    const refreshToken = await this.jwtService.signAsync(payload, {
      expiresIn: JWTToken.REFRESH_TOKEN_EXPIRE_IN,
    })

    return {
      [TokenKeys.ACCESS_TOKEN_KEY]: accessToken,
      [TokenKeys.REFRESH_TOKEN_KEY]: refreshToken,
    }
  }

  async verifyToken(token: string): Promise<JwtPayload> {
    try {
      return await this.jwtService.verifyAsync<JwtPayload>(token)
    } catch (error) {
      throw new UnauthorizedException(error instanceof TokenExpiredError ? 'Token expired' : 'Invalid token')
    }
  }

  async signUp(signUpDto: SignUpDto) {
    const { email, password, ...otherInfo } = signUpDto
    const existing = await this.usersService.getUser({ email })
    if (existing) throw new BadRequestException('User already exist!')

    const otp = Math.floor(100000 + Math.random() * 900000).toString()
    const expires = new Date(Date.now() + 15 * 60 * 1000)

    const userCreated = await this.usersService.createUser({
      email,
      password,
      verificationOtp: otp,
      verificationOtpExpiresAt: expires,
      isVerified: false,
      ...otherInfo,
    })

    try {
      await this.mailService.sendVerificationOtpEmail(email, otp)
    } catch (error) {
      console.error('Error sending verification email during signup:', error)
    }

    const { password: _pw, ...userResponse } = userCreated.toObject({
      virtuals: true,
    })
    return {
      message: 'Đăng ký thành công! Vui lòng xác thực email của bạn.',
      user: userResponse,
    }
  }

  async signIn(signInDto: SignInDto) {
    const { email, password } = signInDto
    const user = await this.usersService.getUser({ email })
    if (!user) throw new UnauthorizedException()

    if (!user.isActive) {
      throw new ForbiddenException('Account has been banned')
    }

    const isMatch = await this.stringUtilService.compare(password, user.password)
    if (!isMatch) throw new UnauthorizedException()

    if (!user.isVerified) {
      // 1. Tạo mới OTP xác thực email và lưu vào database
      const otp = Math.floor(100000 + Math.random() * 900000).toString()
      const expires = new Date(Date.now() + 15 * 60 * 1000)

      await this.usersService.update(user.id, {
        verificationOtp: otp,
        verificationOtpExpiresAt: expires.toISOString(),
      })

      // 2. Gửi email xác thực mới
      try {
        await this.mailService.sendVerificationOtpEmail(user.email, otp)
      } catch (error) {
        console.error('Error sending verification email during sign-in:', error)
      }

      throw new ForbiddenException('Tài khoản chưa được xác thực email. Vui lòng xác thực trước khi đăng nhập.')
    }

    const userID = user.id
    const userEmail = user.email
    const role = user.role
    return await this.createToken({ userID, userEmail, role })
  }

  async verifyEmail(dto: VerifyEmailDto) {
    const { email, otp } = dto
    const user = await this.usersService.getUser({ email })

    if (!user) throw new BadRequestException('Không tìm thấy người dùng')
    if (user.isVerified) throw new BadRequestException('Tài khoản đã được xác thực')

    if (!user.verificationOtp || user.verificationOtp !== otp) {
      throw new BadRequestException('Mã OTP không chính xác')
    }

    const isExpired = !user.verificationOtpExpiresAt || new Date(user.verificationOtpExpiresAt) < new Date()
    if (isExpired) throw new BadRequestException('Mã OTP đã hết hạn')

    await this.usersService.update(user.id, {
      isVerified: true,
      verificationOtp: null,
      verificationOtpExpiresAt: null,
    })

    // Tự động đăng nhập người dùng sau khi xác thực thành công
    const userID = user.id
    const userEmail = user.email
    const role = user.role
    return await this.createToken({ userID, userEmail, role })
  }

  async resendVerificationOtp(dto: ResendVerificationDto) {
    const { email } = dto
    const user = await this.usersService.getUser({ email })

    if (!user) throw new BadRequestException('Không tìm thấy người dùng')
    if (user.isVerified) throw new BadRequestException('Tài khoản đã được xác thực')

    const otp = Math.floor(100000 + Math.random() * 900000).toString()
    const expires = new Date(Date.now() + 15 * 60 * 1000)

    await this.usersService.update(user.id, {
      verificationOtp: otp,
      verificationOtpExpiresAt: expires.toISOString(),
    })

    try {
      await this.mailService.sendVerificationOtpEmail(user.email, otp)
      return { message: 'Đã gửi lại mã OTP xác thực email' }
    } catch (error) {
      throw new InternalServerErrorException('Lỗi khi gửi email')
    }
  }

  async refreshToken(refreshToken: string) {
    const { iat: _iat, exp: _exp, ...user } = await this.verifyToken(refreshToken)
    return this.createToken(user)
  }

  sendSMS() {
    return {}
  }

  async forgotPassword(forgotPasswordDto: ForgotPasswordDto) {
    const { email } = forgotPasswordDto
    const user = await this.usersService.getUser({ email })

    if (!user) throw new UnauthorizedException('Not found user')

    const userEmail = user.email
    if (userEmail) {
      // 1. Tạo OTP (6 chữ số) và thời gian hết hạn (15 phút)
      const otp = Math.floor(100000 + Math.random() * 900000).toString()
      const expires = new Date(Date.now() + 15 * 60 * 1000)

      // 2. Lưu vào database
      await this.usersService.update(user.id, {
        resetPasswordOtp: otp,
        resetPasswordExpiresAt: expires.toISOString(),
      })

      // 3. Gửi mail OTP qua Resend
      try {
        await this.mailService.sendResetPasswordOtpEmail(user.email, otp)
        return { message: 'Vui lòng kiểm tra email của bạn để nhận mã OTP' }
      } catch (error) {
        throw new InternalServerErrorException('Lỗi khi gửi email')
      }
    } else {
      throw new UnauthorizedException('Tài khoản không có email')
    }
  }

  async verifyOtp(verifyOtpDto: VerifyOtpDto) {
    const { email, otp } = verifyOtpDto
    const user = await this.usersService.getUser({ email })

    if (!user) throw new BadRequestException('Không tìm thấy người dùng')
    if (!user.resetPasswordOtp || user.resetPasswordOtp !== otp) {
      throw new BadRequestException('Mã OTP không chính xác')
    }

    const isExpired = !user.resetPasswordExpiresAt || new Date(user.resetPasswordExpiresAt) < new Date()
    if (isExpired) throw new BadRequestException('Mã OTP đã hết hạn')

    return { message: 'Xác thực OTP thành công' }
  }

  async resetPassword(dto: ResetPasswordDto) {
    const { email, otp, newPassword } = dto

    const user = await this.usersService.getUser({ email })
    if (!user) throw new BadRequestException('Không tìm thấy người dùng')
    if (!user.resetPasswordOtp || user.resetPasswordOtp !== otp) {
      throw new BadRequestException('Mã OTP không chính xác')
    }

    const isExpired = !user.resetPasswordExpiresAt || new Date(user.resetPasswordExpiresAt) < new Date()
    if (isExpired) throw new BadRequestException('Mã OTP đã hết hạn')

    await this.usersService.update(user.id, {
      password: newPassword,
      resetPasswordOtp: null,
      resetPasswordExpiresAt: null,
    })

    return { message: 'Mật khẩu đã được đặt lại thành công' }
  }

  async changePassword(changePasswordDto: WithUser<ChangePasswordDto>) {
    const { oldPassword, user, newPassword } = changePasswordDto

    const existingUser = await this.usersService.getUser({ _id: user.userID })
    if (!existingUser) throw new UnauthorizedException('User not found')

    const isMatch = await this.stringUtilService.compare(oldPassword, existingUser.password)
    if (!isMatch) throw new BadRequestException('Old password is incorrect')

    await this.usersService.updateById(user.userID, { password: newPassword })
    return { message: 'Password have changed successfully.' }
  }

  async verifyGoogleToken(idToken: string) {
    try {
      const client = new OAuth2Client(process.env.AUTH_GOOGLE_ID)
      const ticket = await client.verifyIdToken({
        idToken,
        audience: process.env.AUTH_GOOGLE_ID,
      })
      const payload = ticket.getPayload()
      if (!payload) {
        throw new UnauthorizedException('Invalid Google token payload')
      }
      return payload
    } catch (error) {
      throw new UnauthorizedException('Google authentication failed: ' + (error instanceof Error ? error.message : String(error)))
    }
  }

  async googleLogin(idToken: string) {
    const payload = await this.verifyGoogleToken(idToken)
    const { email, name, picture } = payload

    if (!email) {
      throw new BadRequestException('Email not provided by Google')
    }

    let user = await this.usersService.getUser({ email })

    if (!user) {
      // Create user if not exists
      const randomPassword = randomUUID()

      user = await this.usersService.createUser({
        email,
        password: randomPassword,
        displayName: name || email.split('@')[0],
        avatar: picture || null,
        role: 'customer' as any, // Default to customer
        isActive: true,
        isVerified: true,
      })
    } else {
      if (!user.isActive) {
        throw new ForbiddenException('Account has been banned')
      }

      // Update avatar or display name if not set
      let needsUpdate = false
      const updateData: any = {}
      if (!user.displayName && name) {
        updateData.displayName = name
        needsUpdate = true
      }
      if (!user.avatar && picture) {
        updateData.avatar = picture
        needsUpdate = true
      }
      if (needsUpdate) {
        await this.usersService.update(user.id, updateData)
      }
    }

    const userID = user.id
    const userEmail = user.email
    const role = user.role
    return await this.createToken({ userID, userEmail, role })
  }
}
