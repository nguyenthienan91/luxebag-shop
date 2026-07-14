import { Module, forwardRef } from '@nestjs/common'
import { MongooseModule } from '@nestjs/mongoose'
import { MulterModule } from '@nestjs/platform-express'
import { memoryStorage } from 'multer'
import { UsersService } from './users.service'
import { UsersController } from './users.controller'
import { User, UserSchema } from './entities/user.entity'
import { AuthModule } from '../auth/auth.module'
import { CloudinaryModule } from '../../../common/services/cloudinary/cloudinary.module'

import { StringUtilService } from '../../../common/utils/string-util/string-util.service'

@Module({
  imports: [
    MongooseModule.forFeature([{ name: User.name, schema: UserSchema }]),
    forwardRef(() => AuthModule),
    CloudinaryModule,
    MulterModule.register({ storage: memoryStorage() }),
  ],
  controllers: [UsersController],
  providers: [UsersService, StringUtilService],
  exports: [UsersService, MongooseModule],
})
export class UsersModule {}
