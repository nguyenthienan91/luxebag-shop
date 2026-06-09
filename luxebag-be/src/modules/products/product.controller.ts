import { Controller, Get, Post, Body, Patch, Param, Delete, Query } from '@nestjs/common'
import { ApiQuery } from '@nestjs/swagger'
import { ProductService } from './product.service'
import { CreateProductDto } from './dto/create-product.dto'
import { UpdateProductDto } from './dto/update-product.dto'
import { UserRole } from '../users/entities/user.entity'
import { Roles } from '../../../common/decorators/roles.decorator'
import { SkipAuth } from '../auth/auth.decorator'
import { okResponse } from '../../../common/interceptors/format-response/format-response.util'

@Controller('products')
export class ProductController {
  constructor(private readonly productService: ProductService) {}

  // GET /products?page=1&itemPerPage=10&categoryId=...&search=...
  @Get()
  @SkipAuth()
  @ApiQuery({ name: 'page', required: false, type: Number, example: 1 })
  @ApiQuery({ name: 'itemPerPage', required: false, type: Number, example: 10 })
  @ApiQuery({ name: 'categoryId', required: false, type: String })
  @ApiQuery({ name: 'search', required: false, type: String })
  async findAll(
    @Query('page') page?: string,
    @Query('itemPerPage') itemPerPage?: string,
    @Query('categoryId') categoryId?: string,
    @Query('search') search?: string,
  ) {
    return okResponse(
      await this.productService.findAll({
        page: page ? parseInt(page) : undefined,
        itemPerPage: itemPerPage ? parseInt(itemPerPage) : undefined,
        categoryId,
        search,
      }),
    )
  }

  // GET /products/:id
  @Get(':id')
  @SkipAuth()
  async findOne(@Param('id') id: string) {
    return okResponse(await this.productService.findById(id))
  }

  // POST /products — chỉ SELLER và ADMIN mới được tạo
  @Post()
  @Roles(UserRole.SELLER, UserRole.ADMIN)
  async create(@Body() createProductDto: CreateProductDto) {
    return okResponse(await this.productService.create(createProductDto))
  }

  // PATCH /products/:id
  @Patch(':id')
  @Roles(UserRole.SELLER, UserRole.ADMIN)
  async update(@Param('id') id: string, @Body() updateProductDto: UpdateProductDto) {
    return okResponse(await this.productService.update(id, updateProductDto))
  }

  // DELETE /products/:id — soft delete
  @Delete(':id')
  @Roles(UserRole.SELLER, UserRole.ADMIN)
  async remove(@Param('id') id: string) {
    return okResponse(await this.productService.softDelete(id))
  }
}
