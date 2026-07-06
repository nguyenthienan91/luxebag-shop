import { Module, forwardRef } from '@nestjs/common'
import { MongooseModule } from '@nestjs/mongoose'
import { MulterModule } from '@nestjs/platform-express'
import { memoryStorage } from 'multer'
import { ProductService } from './product.service'
import { ProductController } from './product.controller'
import { Product, ProductSchema } from './entities/product.entity'
import { PaginationUtilModule } from '../../../common/utils/pagination-util/pagination-util.module'
import { InventoryModule } from '../inventory/inventory.module'
import { CloudinaryModule } from '../../../common/services/cloudinary/cloudinary.module'

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Product.name, schema: ProductSchema }]),
    PaginationUtilModule,
    forwardRef(() => InventoryModule),
    CloudinaryModule,
    MulterModule.register({ storage: memoryStorage() }),
  ],
  controllers: [ProductController],
  providers: [ProductService],
  exports: [ProductService, MongooseModule],
})
export class ProductModule {}
