import { Injectable, NotFoundException } from '@nestjs/common'
import { InjectModel } from '@nestjs/mongoose'
import type { Model } from 'mongoose'
import { Category, CategoryDocument } from './entities/category.entity'
import { CreateCategoryDto } from './dto/create-category.dto'
import { UpdateCategoryDto } from './dto/update-category.dto'

@Injectable()
export class CategoriesService {
  constructor(@InjectModel(Category.name) private categoryModel: Model<CategoryDocument>) {}

  async findAll(): Promise<CategoryDocument[]> {
    return this.categoryModel.find({ _destroy: false }).exec()
  }

  async findById(id: string): Promise<CategoryDocument> {
    const category = await this.categoryModel.findOne({ _id: id, _destroy: false }).exec()
    if (!category) throw new NotFoundException(`Category ${id} not found`)
    return category
  }

  async create(dto: CreateCategoryDto): Promise<CategoryDocument> {
    return this.categoryModel.create(dto)
  }

  async update(id: string, dto: UpdateCategoryDto): Promise<CategoryDocument> {
    const category = await this.categoryModel
      .findOneAndUpdate({ _id: id, _destroy: false }, dto, { returnDocument: 'after' })
      .exec()
    if (!category) throw new NotFoundException(`Category ${id} not found`)
    return category
  }

  async softDelete(id: string): Promise<CategoryDocument> {
    const category = await this.categoryModel
      .findOneAndUpdate({ _id: id, _destroy: false }, { _destroy: true }, { returnDocument: 'after' })
      .exec()
    if (!category) throw new NotFoundException(`Category ${id} not found`)
    return category
  }
}
