import { Module } from '@nestjs/common'
import { MongooseModule } from '@nestjs/mongoose'
import { OrderService } from './order.service'
import { OrderController } from './order.controller'
import { Order, OrderSchema } from './entities/order.entity'
import { CartModule } from '../cart/cart.module'
import { InventoryModule } from '../inventory/inventory.module'
import { ProductModule } from '../products/product.module'

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Order.name, schema: OrderSchema }]),
    CartModule,
    InventoryModule,
    ProductModule,
  ],
  controllers: [OrderController],
  providers: [OrderService],
})
export class OrderModule {}
