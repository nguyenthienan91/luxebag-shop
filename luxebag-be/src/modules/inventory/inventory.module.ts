import { Module, forwardRef } from '@nestjs/common'
import { MongooseModule } from '@nestjs/mongoose'
import { InventoryService } from './inventory.service'
import { InventoryController } from './inventory.controller'
import { Inventory, InventorySchema } from './entities/inventory.entity'
import { ProductModule } from '../products/product.module'

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Inventory.name, schema: InventorySchema }]),
    forwardRef(() => ProductModule),
  ],
  controllers: [InventoryController],
  providers: [InventoryService],
  exports: [InventoryService, MongooseModule],
})
export class InventoryModule {}
