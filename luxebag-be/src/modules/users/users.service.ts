import { Injectable } from '@nestjs/common'
import { InjectModel } from '@nestjs/mongoose'
import type { Model, UpdateQuery } from 'mongoose'
import { User, UserDocument } from './entities/user.entity'
import { CreateUserDto } from './dto/create-user.dto'
import { UpdateUserDto } from './dto/update-user.dto'

@Injectable()
export class UsersService {
  constructor(@InjectModel(User.name) private userModel: Model<UserDocument>) {}

  async getUser(filter: Partial<User> & Record<string, any>): Promise<UserDocument | null> {
    return this.userModel.findOne(filter).exec()
  }

  async createUser(data: Partial<User>): Promise<UserDocument> {
    return this.userModel.create(data)
  }

  async findAll(): Promise<UserDocument[]> {
    return this.userModel.find().select('-password').exec()
  }

  async findById(id: string): Promise<UserDocument | null> {
    return this.userModel.findById(id).select('-password').exec()
  }

  async updateById(id: string, data: UpdateQuery<UserDocument>): Promise<UserDocument | null> {
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
}
