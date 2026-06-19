import { Module } from '@nestjs/common'
import { MongooseModule } from '@nestjs/mongoose'
import { ChatGateway } from './chat.gateway'
import { ChatService } from './chat.service'
import { ChatController } from './chat.controller'
import { Message, MessageSchema } from './message.schema'
import { UsersModule } from '../users/users.module'
import { AuthModule } from '../auth/auth.module'
import { OrderModule } from '../orders/order.module'

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Message.name, schema: MessageSchema }]),
    UsersModule,
    AuthModule,
    OrderModule,
  ],
  controllers: [ChatController],
  providers: [ChatService, ChatGateway],
  exports: [ChatService],
})
export class ChatModule {}
