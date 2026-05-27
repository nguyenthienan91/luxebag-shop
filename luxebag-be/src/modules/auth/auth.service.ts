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
import { SignInDto, SignUpDto } from './dto/sign.dto'
import { ChangePasswordDto, ForgotPasswordDto, ResetPasswordDto } from './dto/password.dto'
import { WithUser } from '../../../common/decorators/user.decorator'

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

    const passwordHashed = await this.stringUtilService.hash(password)
    const userCreated = await this.usersService.createUser({
      email,
      password: passwordHashed,
      ...otherInfo,
    })
    // await this.walletsService.createWallet(userCreated._id)
    const { password: _pw, ...userResponse } = userCreated.toObject({
      virtuals: true,
    })
    return userResponse
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

    const userID = user.id
    const userEmail = user.email
    const role = user.role
    return await this.createToken({ userID, userEmail, role })
  }

  async refreshToken(refreshToken: string) {
    const { iat: _iat, exp: _exp, ...user } = await this.verifyToken(refreshToken)
    return this.createToken(user)
  }

  sendSMS() {
    return {}
  }

  async forgotPassword(forgotPasswordDto: ForgotPasswordDto) {
    const { email, phoneNumber, redirectTo } = forgotPasswordDto
    const user = await this.usersService.getUser({
      $or: [{ email }, { phoneNumber }],
    })

    if (!user) throw new UnauthorizedException('Not found user')

    const userEmail = user.email
    if (userEmail) {
      // 1. Tạo Token và thời gian hết hạn (15 phút)
      const token = randomUUID()
      const expires = new Date(Date.now() + 15 * 60 * 1000)

      // 2. Lưu vào database (Sử dụng các trường đã thêm vào Schema trước đó)
      await this.usersService.update(user.id, {
        resetPasswordToken: token,
        resetPasswordExpiresAt: expires.toISOString(),
      })

      // 3. Gửi mail qua Resend
      try {
        await this.mailService.sendResetPasswordEmail(user.email, token, redirectTo)
        return { message: 'Vui lòng kiểm tra email của bạn' }
      } catch (error) {
        throw new InternalServerErrorException('Lỗi khi gửi email')
      }
    } else {
      this.sendSMS()
      return { message: 'Vui lòng kiểm tra điện thoại của bạn' }
    }
  }

  async resetPassword(token: string, dto: ResetPasswordDto) {
    const { newPassword } = dto

    const user = await this.usersService.getUser({ resetPasswordToken: token })
    if (!user) throw new BadRequestException('Invalid or expired token')

    const isExpired = !user.resetPasswordExpiresAt || new Date(user.resetPasswordExpiresAt) < new Date()
    if (isExpired) throw new BadRequestException('Token has expired')

    const passwordHashed = await this.stringUtilService.hash(newPassword)
    await this.usersService.update(user.id, {
      password: passwordHashed,
      resetPasswordToken: null,
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

    const passwordHashed = await this.stringUtilService.hash(newPassword)
    await this.usersService.updateById(user.userID, { password: passwordHashed })
    return { message: 'Password have changed successfully.' }
  }
}
