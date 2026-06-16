import { Module, forwardRef } from '@nestjs/common'
import { AuthService } from './auth.service'
import { AuthController } from './auth.controller'
import { UsersModule } from '../users/users.module'
import { JwtModule } from '@nestjs/jwt'
import { ConfigService } from '@nestjs/config'
import { JWTEnvs } from './consts/jwt.const'
import { AuthGuard } from './auth.guard'
import { StringUtilService } from '../../../common/utils/string-util/string-util.service'
import { MailService } from '../../../common/utils/mail-util/mail.service'

@Module({
  imports: [
    forwardRef(() => UsersModule),
    JwtModule.registerAsync({
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        global: true,
        secret: configService.get<string>(JWTEnvs.JWT_SECRET),
      }),
    }),
  ],
  controllers: [AuthController],
  providers: [AuthService, AuthGuard, StringUtilService, MailService],
  exports: [AuthService, AuthGuard],
})
export class AuthModule {}
