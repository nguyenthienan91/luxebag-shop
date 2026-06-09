import { Module } from '@nestjs/common'
import { MongooseModule } from '@nestjs/mongoose'
import { CartService } from './cart.service'
import { CartController } from './cart.controller'
import { Cart, CartSchema } from './entities/cart.entity'

@Module({
  imports: [MongooseModule.forFeature([{ name: Cart.name, schema: CartSchema }])],
  controllers: [CartController],
  providers: [CartService],
  exports: [CartService, MongooseModule],
})
export class CartModule {}
