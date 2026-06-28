import { Module } from '@nestjs/common'
import { MongooseModule } from '@nestjs/mongoose'
import { NotificationsController } from './notifications.controller'
import { NotificationsService } from './notifications.service'
import { Notification, NotificationSchema } from './notification.schema'
import { PaginationUtilModule } from '../../../common/utils/pagination-util/pagination-util.module'

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Notification.name, schema: NotificationSchema }]),
    PaginationUtilModule,
  ],
  controllers: [NotificationsController],
  providers: [NotificationsService],
  exports: [NotificationsService],
})
export class NotificationsModule {}
