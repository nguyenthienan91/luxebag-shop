import { Controller, Get, Put, Param, Query } from '@nestjs/common'
import { NotificationsService } from './notifications.service'
import { User, type UserInfo } from '../../../common/decorators/user.decorator'
import { okResponse } from '../../../common/interceptors/format-response/format-response.util'

@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Get()
  async findAll(
    @User() user: UserInfo,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    const pageNum = page ? parseInt(page, 10) : 1
    const limitNum = limit ? parseInt(limit, 10) : 20
    const result = await this.notificationsService.findByUser(user.userID, pageNum, limitNum)
    return okResponse(result)
  }

  @Put('read-all')
  async markAllAsRead(@User() user: UserInfo) {
    const modifiedCount = await this.notificationsService.markAllAsRead(user.userID)
    return okResponse({ modifiedCount })
  }

  @Put(':id/read')
  async markAsRead(
    @Param('id') id: string,
    @User() user: UserInfo,
  ) {
    const notification = await this.notificationsService.markAsRead(id, user.userID)
    return okResponse(notification)
  }
}
