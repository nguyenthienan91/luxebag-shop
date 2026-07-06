import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  MessageBody,
  ConnectedSocket,
} from '@nestjs/websockets'
import { Server, Socket } from 'socket.io'
import { ChatService } from './chat.service'
import { AuthService } from '../auth/auth.service'
import { UsersService } from '../users/users.service'
import { OrderService } from '../orders/order.service'

@WebSocketGateway({
  cors: {
    origin: '*',
  },
})
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server!: Server

  // Map userId to socketId
  private readonly userSockets = new Map<string, string>()

  constructor(
    private readonly chatService: ChatService,
    private readonly authService: AuthService,
    private readonly usersService: UsersService,
    private readonly orderService: OrderService,
  ) {}

  async handleConnection(client: Socket) {
    try {
      const authHeader = client.handshake.auth?.token || client.handshake.query?.token
      if (!authHeader) {
        console.log(`Socket connection rejected: No token provided (${client.id})`)
        client.disconnect()
        return
      }

      const token = authHeader.startsWith('Bearer ') ? authHeader.split(' ')[1] : authHeader
      const payload = await this.authService.verifyToken(token)
      const user = await this.usersService.findById(payload.userID)

      if (!user || !user.isActive) {
        console.log(`Socket connection rejected: User not found or inactive (${client.id})`)
        client.disconnect()
        return
      }

      // Attach user details to socket session
      client.data.user = {
        userID: user.id,
        userEmail: user.email,
        role: user.role,
      }

      this.userSockets.set(user.id, client.id)
      console.log(`Socket client authenticated: ${user.email} (${client.id})`)

      // Broadcast user online status
      this.server.emit('chat:user_online', { userId: user.id })
    } catch (err) {
      console.error(`Socket connection error: ${err.message} (${client.id})`)
      client.disconnect()
    }
  }

  handleDisconnect(client: Socket) {
    const user = client.data?.user
    if (user) {
      this.userSockets.delete(user.userID)
      console.log(`Socket client disconnected: ${user.userEmail} (${client.id})`)

      // Broadcast user offline status
      this.server.emit('chat:user_offline', { userId: user.userID })
    }
  }

  @SubscribeMessage('chat:join')
  async handleJoin(
    @MessageBody() data: { targetId: string },
    @ConnectedSocket() client: Socket,
  ) {
    const currentUserId = client.data?.user?.userID
    if (!currentUserId || !data?.targetId) {
      return
    }

    const roomId = this.chatService.generateRoomId(currentUserId, data.targetId)
    client.join(roomId)
    console.log(`Socket client ${client.id} (user: ${currentUserId}) joined room ${roomId}`)

    // Mark existing messages in this room as read for the current user
    await this.chatService.markRoomAsRead(roomId, currentUserId)

    // Notify the other user that messages in this room have been read
    this.server.to(roomId).emit('chat:read', { roomId, readerId: currentUserId })
  }

  @SubscribeMessage('chat:send')
  async handleSendMessage(
    @MessageBody() data: { receiverId: string; messageText: string; orderId?: string },
    @ConnectedSocket() client: Socket,
  ) {
    const senderId = client.data?.user?.userID
    if (!senderId || !data?.receiverId || !data?.messageText) {
      return
    }

    const roomId = this.chatService.generateRoomId(senderId, data.receiverId)

    // 1. Verify order ownership if orderId is provided
    let verifiedOrderId: string | undefined = undefined
    let orderCodeSnapshot: string | undefined = undefined

    if (data.orderId) {
      try {
        const order = await this.orderService.findRawById(data.orderId)
        if (order) {
          const isOwner = order.userId.toString() === senderId
          const isAdmin = client.data?.user?.role === 'admin'
          if (isOwner || isAdmin) {
            verifiedOrderId = data.orderId
            orderCodeSnapshot = data.orderId.slice(-8).toUpperCase()
          } else {
            console.warn(`Unauthorized order link attempt by user ${senderId} for order ${data.orderId}`)
          }
        }
      } catch (err) {
        console.error(`Error verifying order ownership: ${err.message}`)
      }
    }

    // 2. Check if the receiver is currently online and in the same chat room
    let isRead = false
    const receiverSocketId = this.userSockets.get(data.receiverId)
    if (receiverSocketId) {
      const receiverSocket = this.server.sockets.sockets.get(receiverSocketId)
      if (receiverSocket && receiverSocket.rooms.has(roomId)) {
        isRead = true
      }
    }

    // 3. Save message to database
    const savedMsg = await this.chatService.saveMessage(
      senderId,
      data.receiverId,
      data.messageText,
      verifiedOrderId,
      isRead,
      orderCodeSnapshot,
    )

    const payload = {
      id: savedMsg._id.toString(),
      content: savedMsg.messageText,
      senderId: savedMsg.senderId.toString(),
      receiverId: savedMsg.receiverId.toString(),
      sentAt: savedMsg.createdAt.toISOString(),
      isRead: savedMsg.isRead,
      roomId,
      orderId: savedMsg.orderId ? savedMsg.orderId.toString() : null,
      orderCodeSnapshot: savedMsg.orderCodeSnapshot,
    }

    // Broadcast the message to both participants in the roomId channel
    this.server.to(roomId).emit('chat:receive', payload)

    // 4. Mock Push Notification if receiver is offline
    const isReceiverOnline = this.userSockets.has(data.receiverId)
    if (!isReceiverOnline) {
      try {
        const sender = await this.usersService.findById(senderId)
        const senderName = sender?.displayName || sender?.email || 'User'
        console.log(`[PUSH NOTIFICATION] Target ${data.receiverId} is offline. Pushed: "${senderName}: ${data.messageText}"`)
      } catch (err) {
        console.error(`Failed to push notification log: ${err.message}`)
      }
    }
  }
}
