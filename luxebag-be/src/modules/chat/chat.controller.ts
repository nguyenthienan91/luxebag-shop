import { Controller, Get, Post, Param, Query } from '@nestjs/common'
import { ChatService } from './chat.service'
import { User } from '../../../common/decorators/user.decorator'
import type { UserInfo } from '../../../common/decorators/user.decorator'
import { Roles } from '../../../common/decorators/roles.decorator'
import { okResponse } from '../../../common/interceptors/format-response/format-response.util'
import { UsersService } from '../users/users.service'
import { UserRole } from '../users/entities/user.entity'

@Controller('messages')
export class ChatController {
  constructor(
    private readonly chatService: ChatService,
    private readonly usersService: UsersService,
  ) {}

  @Get('shop')
  @Roles()
  async getShopInfo() {
    const users = await this.usersService.findAll()
    const admins = users.filter((u) => u.role === UserRole.ADMIN && u.isActive)

    return okResponse(
      admins.map((admin) => ({
        id: admin.id,
        displayName: admin.displayName,
        avatar: admin.avatar,
        email: admin.email,
        role: admin.role,
      })),
    )
  }

  @Get('conversations')
  @Roles(UserRole.ADMIN)
  async getConversations(@User() user: UserInfo) {
    return okResponse(await this.chatService.getConversations(user.userID))
  }

  @Post('read/:otherUserId')
  @Roles()
  async markAsRead(
    @User() user: UserInfo,
    @Param('otherUserId') otherUserId: string,
  ) {
    const modified = await this.chatService.markAsReadByUsers(user.userID, otherUserId)
    return okResponse({ modified })
  }

  @Get(':shopId')
  @Roles()
  async getMessages(
    @User() user: UserInfo,
    @Param('shopId') shopId: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    const pageNum = page ? parseInt(page, 10) : 1
    const limitNum = limit ? parseInt(limit, 10) : 20
    const messages = await this.chatService.getMessages(user.userID, shopId, pageNum, limitNum)
    return okResponse(messages)
  }
}

