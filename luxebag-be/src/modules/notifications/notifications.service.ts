import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common'
import { InjectModel } from '@nestjs/mongoose'
import { Model, Types } from 'mongoose'
import { Notification, NotificationDocument } from './notification.schema'
import { PaginationUtilService } from '../../../common/utils/pagination-util/pagination-util.service'

@Injectable()
export class NotificationsService {
  constructor(
    @InjectModel(Notification.name) private readonly notificationModel: Model<NotificationDocument>,
    private readonly paginationUtil: PaginationUtilService,
  ) {}

  async createNotification(
    userId: string | Types.ObjectId,
    title: string,
    body: string,
    type: 'order' | 'promotion' | 'system',
    referenceType?: string | null,
    referenceId?: string | null,
  ): Promise<NotificationDocument> {
    return this.notificationModel.create({
      userId: new Types.ObjectId(userId),
      title,
      body,
      type,
      referenceType,
      referenceId,
    })
  }

  async findByUser(userId: string, page: number = 1, limit: number = 20) {
    const userObjectId = new Types.ObjectId(userId)
    const filter = { userId: userObjectId }

    const totalItems = await this.notificationModel.countDocuments(filter)
    const pagination = this.paginationUtil.paging({ page, itemPerPage: limit, totalItems })

    const list = await this.notificationModel
      .find(filter)
      .sort({ createdAt: -1 })
      .skip(pagination.skip)
      .limit(limit)
      .exec()

    return pagination.format(list)
  }

  async markAsRead(id: string, userId: string): Promise<NotificationDocument> {
    if (!Types.ObjectId.isValid(id)) {
      throw new NotFoundException(`Notification not found`)
    }

    const notification = await this.notificationModel.findById(id).exec()
    if (!notification) {
      throw new NotFoundException(`Notification not found`)
    }

    // Verify ownership
    if (notification.userId.toString() !== userId) {
      throw new ForbiddenException('You do not have permission to modify this notification')
    }

    notification.isRead = true
    await notification.save()
    return notification
  }

  async markAllAsRead(userId: string): Promise<number> {
    const userObjectId = new Types.ObjectId(userId)
    const result = await this.notificationModel.updateMany(
      { userId: userObjectId, isRead: false },
      { $set: { isRead: true } },
    ).exec()
    return result.modifiedCount
  }
}
