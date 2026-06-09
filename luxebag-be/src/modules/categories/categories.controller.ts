import { Controller, Get, Post, Body, Patch, Param, Delete } from '@nestjs/common'
import { CategoriesService } from './categories.service'
import { CreateCategoryDto } from './dto/create-category.dto'
import { UpdateCategoryDto } from './dto/update-category.dto'
import { UserRole } from '../users/entities/user.entity'
import { Roles } from '../../../common/decorators/roles.decorator'
import { SkipAuth } from '../auth/auth.decorator'
import { okResponse } from '../../../common/interceptors/format-response/format-response.util'

@Controller('categories')
export class CategoriesController {
  constructor(private readonly categoriesService: CategoriesService) {}

  // GET /categories — public, hiển thị danh sách cho trang chủ
  @Get()
  @SkipAuth()
  async findAll() {
    return okResponse(await this.categoriesService.findAll())
  }

  // GET /categories/:id — public
  @Get(':id')
  @SkipAuth()
  async findOne(@Param('id') id: string) {
    return okResponse(await this.categoriesService.findById(id))
  }

  // POST /categories — chỉ ADMIN
  @Post()
  @Roles(UserRole.ADMIN)
  async create(@Body() createCategoryDto: CreateCategoryDto) {
    return okResponse(await this.categoriesService.create(createCategoryDto))
  }

  // PATCH /categories/:id — chỉ ADMIN
  @Patch(':id')
  @Roles(UserRole.ADMIN)
  async update(@Param('id') id: string, @Body() updateCategoryDto: UpdateCategoryDto) {
    return okResponse(await this.categoriesService.update(id, updateCategoryDto))
  }

  // DELETE /categories/:id — soft delete, chỉ ADMIN
  @Delete(':id')
  @Roles(UserRole.ADMIN)
  async remove(@Param('id') id: string) {
    return okResponse(await this.categoriesService.softDelete(id))
  }
}
