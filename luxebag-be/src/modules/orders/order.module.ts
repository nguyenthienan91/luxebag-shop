import { Module } from '@nestjs/common'
import { MongooseModule } from '@nestjs/mongoose'
import { OrderService } from './order.service'
import { OrderController } from './order.controller'
import { Order, OrderSchema } from './entities/order.entity'
import { CartModule } from '../cart/cart.module'
import { InventoryModule } from '../inventory/inventory.module'
import { ProductModule } from '../products/product.module'
import { PaginationUtilModule } from '../../../common/utils/pagination-util/pagination-util.module'

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Order.name, schema: OrderSchema }]),
    CartModule,
    InventoryModule,
    ProductModule,
    PaginationUtilModule,
  ],
  controllers: [OrderController],
  providers: [OrderService],
})
export class OrderModule {}
