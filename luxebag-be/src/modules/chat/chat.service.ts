import { Injectable } from '@nestjs/common'
import { InjectModel } from '@nestjs/mongoose'
import { Model, Types } from 'mongoose'
import { Message, MessageDocument } from './message.schema'
import { UsersService } from '../users/users.service'

@Injectable()
export class ChatService {
  constructor(
    @InjectModel(Message.name) private messageModel: Model<MessageDocument>,
    private readonly usersService: UsersService,
  ) {}

  async getConversations(adminId: string): Promise<any[]> {
    const adminObjectId = new Types.ObjectId(adminId)

    // Aggregate to find unique chat rooms involving this admin, sorted by latest message
    const conversations = await this.messageModel.aggregate([
      {
        $match: {
          $or: [
            { senderId: adminId },
            { receiverId: adminId },
            { senderId: adminObjectId },
            { receiverId: adminObjectId }
          ]
        }
      },
      {
        $sort: { createdAt: -1 }
      },
      {
        $group: {
          _id: '$roomId',
          lastMessage: { $first: '$$ROOT' }
        }
      },
      {
        $sort: { 'lastMessage.createdAt': -1 }
      }
    ]).exec()

    const result: any[] = []

    for (const conv of conversations) {
      const lastMsg = conv.lastMessage
      const otherUserId = lastMsg.senderId.toString() === adminId
        ? lastMsg.receiverId
        : lastMsg.senderId

      const otherUser = await this.usersService.findById(otherUserId.toString())
      if (!otherUser) continue

      // Calculate unread count for the admin in this room
      const unreadCount = await this.messageModel.countDocuments({
        roomId: conv._id,
        isRead: false,
        $or: [
          { receiverId: adminId },
          { receiverId: adminObjectId }
        ]
      })

      result.push({
        roomId: conv._id,
        otherUser: {
          id: otherUser.id,
          displayName: otherUser.displayName,
          avatar: otherUser.avatar,
          email: otherUser.email,
        },
        lastMessageText: lastMsg.messageText,
        lastMessageTime: lastMsg.createdAt,
        unreadCount,
      })
    }

    return result
  }

  generateRoomId(userId1: string, userId2: string): string {
    return [userId1.toString(), userId2.toString()].sort().join('_')
  }

  async saveMessage(
    senderId: string,
    receiverId: string,
    messageText: string,
    orderId?: string,
    isRead = false,
    orderCodeSnapshot?: string
  ): Promise<MessageDocument> {
    const roomId = this.generateRoomId(senderId, receiverId)
    return this.messageModel.create({
      senderId,
      receiverId,
      messageText,
      roomId,
      isRead,
      orderId: orderId ? new Types.ObjectId(orderId) : undefined,
      orderCodeSnapshot: orderCodeSnapshot || undefined,
    })
  }

  async markRoomAsRead(roomId: string, readerId: string): Promise<number> {
    const readerObjectId = new Types.ObjectId(readerId)
    const result = await this.messageModel.updateMany(
      {
        roomId,
        isRead: false,
        $or: [
          { receiverId: readerId },
          { receiverId: readerObjectId }
        ]
      },
      { $set: { isRead: true } }
    ).exec()
    console.log(`[ChatService] markRoomAsRead: room=${roomId}, reader=${readerId}, modified=${result.modifiedCount}`)
    return result.modifiedCount
  }

  async markAsReadByUsers(currentUserId: string, otherUserId: string): Promise<number> {
    const roomId = this.generateRoomId(currentUserId, otherUserId)
    return this.markRoomAsRead(roomId, currentUserId)
  }

  async getMessages(userId1: string, userId2: string, page: number, limit: number): Promise<MessageDocument[]> {
    const roomId = this.generateRoomId(userId1, userId2)
    const skip = (page - 1) * limit
    const list = await this.messageModel
      .find({ roomId })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .exec()
    
    return list.reverse()
  }
}
