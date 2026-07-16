import { Controller, Post, Body, Get, Res, UseGuards, Query } from '@nestjs/common'
import { AuthService } from './auth.service'
import { SignInDto, SignInResponseDto, SignUpDto, GoogleLoginDto } from './dto/sign.dto'
import { SkipAuth } from './auth.decorator'
import type { Response } from 'express'
import ms from 'ms'
import { ZodResponse } from 'nestjs-zod'
import { TokenKeys } from './consts/jwt.const'
import { ChangePasswordDto, ForgotPasswordDto, ResetPasswordDto, VerifyOtpDto } from './dto/password.dto'
import { AuthGuard } from './auth.guard'
import { COOKIE_CONFIG_DEFAULT, CookiesToken } from '../../../common/decorators/cookie/cookie.const'
import { Cookies } from '../../../common/decorators/cookie/cookie.decorator'
import { User } from '../../../common/decorators/user.decorator'
import type { UserInfo } from '../../../common/decorators/user.decorator'

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('sign-up')
  @SkipAuth()
  signUp(@Body() signUpDto: SignUpDto) {
    return this.authService.signUp(signUpDto)
  }

  @Post('sign-in')
  @SkipAuth()
  @ZodResponse({ type: SignInResponseDto })
  async signIn(@Body() signInDto: SignInDto, @Res({ passthrough: true }) res: Response) {
    const data = await this.authService.signIn(signInDto)

    res.cookie(TokenKeys.ACCESS_TOKEN_KEY, data.accessToken, {
      ...COOKIE_CONFIG_DEFAULT,
      maxAge: ms(CookiesToken.ACCESS_TOKEN_EXPIRE_IN),
    })
    res.cookie(TokenKeys.REFRESH_TOKEN_KEY, data.refreshToken, {
      ...COOKIE_CONFIG_DEFAULT,
      maxAge: ms(CookiesToken.REFRESH_TOKEN_EXPIRE_IN),
    })
    return data
  }

  @Post('google-login')
  @SkipAuth()
  @ZodResponse({ type: SignInResponseDto })
  async googleLogin(@Body() googleLoginDto: GoogleLoginDto, @Res({ passthrough: true }) res: Response) {
    const data = await this.authService.googleLogin(googleLoginDto.idToken)

    res.cookie(TokenKeys.ACCESS_TOKEN_KEY, data.accessToken, {
      ...COOKIE_CONFIG_DEFAULT,
      maxAge: ms(CookiesToken.ACCESS_TOKEN_EXPIRE_IN),
    })
    res.cookie(TokenKeys.REFRESH_TOKEN_KEY, data.refreshToken, {
      ...COOKIE_CONFIG_DEFAULT,
      maxAge: ms(CookiesToken.REFRESH_TOKEN_EXPIRE_IN),
    })
    return data
  }

  @Get('logout')
  @SkipAuth()
  logout(@Res({ passthrough: true }) res: Response) {
    res.clearCookie(TokenKeys.ACCESS_TOKEN_KEY, {
      ...COOKIE_CONFIG_DEFAULT,
      maxAge: ms(CookiesToken.ACCESS_TOKEN_EXPIRE_IN),
    })
    res.clearCookie(TokenKeys.REFRESH_TOKEN_KEY, {
      ...COOKIE_CONFIG_DEFAULT,
      maxAge: ms(CookiesToken.REFRESH_TOKEN_EXPIRE_IN),
    })
    return { message: 'Logout success!' }
  }

  @Get('refresh-token')
  @SkipAuth()
  async refreshToken(@Cookies('refreshToken') refreshToken: string, @Res({ passthrough: true }) res: Response) {
    const data = await this.authService.refreshToken(refreshToken)

    res.cookie(TokenKeys.ACCESS_TOKEN_KEY, data.accessToken, {
      ...COOKIE_CONFIG_DEFAULT,
      maxAge: ms(CookiesToken.ACCESS_TOKEN_EXPIRE_IN),
    })
    res.cookie(TokenKeys.REFRESH_TOKEN_KEY, data.refreshToken, {
      ...COOKIE_CONFIG_DEFAULT,
      maxAge: ms(CookiesToken.REFRESH_TOKEN_EXPIRE_IN),
    })
    return data
  }

  @Post('forgot-password')
  @SkipAuth()
  async forgotPassword(@Body() forgotPasswordDto: ForgotPasswordDto) {
    return await this.authService.forgotPassword(forgotPasswordDto)
  }

  @Post('verify-otp')
  @SkipAuth()
  async verifyOtp(@Body() verifyOtpDto: VerifyOtpDto) {
    return await this.authService.verifyOtp(verifyOtpDto)
  }

  @Post('reset-password')
  @SkipAuth()
  async resetPassword(@Body() resetPasswordDto: ResetPasswordDto) {
    return await this.authService.resetPassword(resetPasswordDto)
  }

  @Post('change-password')
  @UseGuards(AuthGuard)
  async changePassword(@Body() changePasswordDto: ChangePasswordDto, @User() user: UserInfo) {
    return await this.authService.changePassword({ ...changePasswordDto, user })
  }
}
