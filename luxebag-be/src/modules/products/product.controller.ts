import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  Query,
  UploadedFiles,
  UseInterceptors,
} from '@nestjs/common'
import { ApiQuery, ApiConsumes, ApiBody } from '@nestjs/swagger'
import { FilesInterceptor } from '@nestjs/platform-express'
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
  @ApiQuery({ name: 'minPrice', required: false, type: Number })
  @ApiQuery({ name: 'maxPrice', required: false, type: Number })
  async findAll(
    @Query('page') page?: string,
    @Query('itemPerPage') itemPerPage?: string,
    @Query('categoryId') categoryId?: string,
    @Query('search') search?: string,
    @Query('minPrice') minPrice?: string,
    @Query('maxPrice') maxPrice?: string,
  ) {
    return okResponse(
      await this.productService.findAll({
        page: page ? parseInt(page) : undefined,
        itemPerPage: itemPerPage ? parseInt(itemPerPage) : undefined,
        categoryId,
        search,
        minPrice: minPrice ? parseFloat(minPrice) : undefined,
        maxPrice: maxPrice ? parseFloat(maxPrice) : undefined,
      }),
    )
  }

  // GET /products/:id
  @Get(':id')
  @SkipAuth()
  async findOne(@Param('id') id: string) {
    return okResponse(await this.productService.findById(id))
  }

  // POST /products — chỉ DELIVERY và ADMIN mới được tạo
  @Post()
  @Roles(UserRole.DELIVERY, UserRole.ADMIN)
  async create(@Body() createProductDto: CreateProductDto) {
    return okResponse(await this.productService.create(createProductDto))
  }

  // PATCH /products/:id
  @Patch(':id')
  @Roles(UserRole.DELIVERY, UserRole.ADMIN)
  async update(@Param('id') id: string, @Body() updateProductDto: UpdateProductDto) {
    return okResponse(await this.productService.update(id, updateProductDto))
  }

  // DELETE /products/:id — soft delete
  @Delete(':id')
  @Roles(UserRole.DELIVERY, UserRole.ADMIN)
  async remove(@Param('id') id: string) {
    return okResponse(await this.productService.softDelete(id))
  }

  // POST /products/:productId/upload-images — upload ảnh sản phẩm (thay thế toàn bộ)
  @Post(':productId/upload-images')
  @Roles(UserRole.DELIVERY, UserRole.ADMIN)
  @UseInterceptors(FilesInterceptor('images', 10))
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        images: { type: 'array', items: { type: 'string', format: 'binary' } },
      },
    },
  })
  async uploadImages(@Param('productId') productId: string, @UploadedFiles() files: Express.Multer.File[]) {
    return okResponse(await this.productService.uploadImages(productId, files))
  }
}
