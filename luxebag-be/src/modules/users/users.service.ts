import { Injectable, NotFoundException } from '@nestjs/common'
import { InjectModel } from '@nestjs/mongoose'
import type { Model, UpdateQuery } from 'mongoose'
import { User, UserDocument } from './entities/user.entity'
import { CreateUserDto } from './dto/create-user.dto'
import { UpdateUserDto } from './dto/update-user.dto'
import { CloudinaryService } from '../../../common/services/cloudinary/cloudinary.service'
import { StringUtilService } from '../../../common/utils/string-util/string-util.service'

@Injectable()
export class UsersService {
  constructor(
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    private readonly cloudinaryService: CloudinaryService,
    private readonly stringUtilService: StringUtilService,
  ) {}

  async getUser(filter: Partial<User> & Record<string, any>): Promise<UserDocument | null> {
    return this.userModel.findOne(filter).exec()
  }

  async createUser(data: Partial<User>): Promise<UserDocument> {
    if (data.password) {
      data.password = await this.stringUtilService.hash(data.password)
    }
    return this.userModel.create(data)
  }

  async findAll(search?: string, role?: string, isActive?: string): Promise<UserDocument[]> {
    const filter: any = {}
    if (role) {
      filter.role = role
    }
    if (isActive !== undefined && isActive !== '') {
      filter.isActive = isActive === 'true'
    }
    if (search) {
      filter.$or = [
        { displayName: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } },
        { phoneNumber: { $regex: search, $options: 'i' } },
      ]
    }
    return this.userModel.find(filter).select('-password').exec()
  }

  async findById(id: string): Promise<UserDocument | null> {
    return this.userModel.findById(id).select('-password').exec()
  }

  async updateById(id: string, data: UpdateQuery<UserDocument>): Promise<UserDocument | null> {
    if (data.password) {
      data.password = await this.stringUtilService.hash(data.password)
    }
    return this.userModel.findByIdAndUpdate(id, data, { returnDocument: 'after' }).select('-password').exec()
  }

  async deleteById(id: string): Promise<UserDocument | null> {
    return this.userModel.findByIdAndDelete(id).exec()
  }

  // Alias methods used by UsersController DTOs
  create(createUserDto: CreateUserDto) {
    return this.createUser(createUserDto as unknown as Partial<User>)
  }

  update(id: string, updateUserDto: UpdateUserDto) {
    return this.updateById(id, updateUserDto)
  }

  remove(id: string) {
    return this.deleteById(id)
  }

  async uploadAvatar(userId: string, file: Express.Multer.File): Promise<UserDocument> {
    const user = await this.userModel.findById(userId).exec()
    if (!user) throw new NotFoundException(`User ${userId} not found`)

    // Xóa ảnh cũ trên Cloudinary nếu có
    if (user.avatar) {
      const publicId = this.cloudinaryService.extractPublicId(user.avatar)
      if (publicId) await this.cloudinaryService.deleteImage(publicId)
    }

    // Upload ảnh mới vào thư mục luxebag/avatars
    const result = await this.cloudinaryService.uploadToFolder(file, 'luxebag/avatars')

    // Cập nhật avatar URL trong DB và trả về user (không có password)
    return this.userModel
      .findByIdAndUpdate(userId, { avatar: result.secure_url }, { returnDocument: 'after' })
      .select('-password')
      .exec() as Promise<UserDocument>
  }
}
