import { Controller, Get, Patch, Post, Param, Body } from '@nestjs/common'
import { InventoryService } from './inventory.service'
import { UserRole } from '../users/entities/user.entity'
import { Roles } from '../../../common/decorators/roles.decorator'
import { okResponse } from '../../../common/interceptors/format-response/format-response.util'
import { z } from 'zod'
import { createZodDto } from 'nestjs-zod'

const inventoryActionSchema = z.enum(['IMPORT', 'DEDUCT'])

class SetStockDto extends createZodDto(
  z.object({
    stock: z.number({ error: 'stock must be a number' }).int().min(0, 'stock cannot be negative'),
  }),
) {}

class AdjustInventoryDto extends createZodDto(
  z.object({
    action: inventoryActionSchema,
    quantity: z.number({ error: 'quantity must be a number' }).int().min(1, 'quantity must be greater than 0'),
  }),
) {}

@Controller('inventory')
@Roles(UserRole.ADMIN)
export class InventoryController {
  constructor(private readonly inventoryService: InventoryService) {}

  // GET /inventory/:productId — xem tồn kho của 1 sản phẩm
  @Get(':productId')
  async findOne(@Param('productId') productId: string) {
    return okResponse(await this.inventoryService.findByProduct(productId))
  }

  // PATCH /inventory/:productId/stock — set số lượng tồn kho
  @Patch(':productId/stock')
  async setStock(@Param('productId') productId: string, @Body() dto: SetStockDto) {
    return okResponse(await this.inventoryService.setStock(productId, dto.stock))
  }

  // PATCH /inventory/:productId — import hoặc trừ tồn kho
  @Patch(':productId')
  async adjustStock(@Param('productId') productId: string, @Body() dto: AdjustInventoryDto) {
    return okResponse(await this.inventoryService.adjustStock(productId, dto.action, dto.quantity))
  }

  // POST /inventory/bulk-init — init inventory cho toàn bộ product chưa có record
  @Post('bulk-init')
  async bulkInit() {
    return okResponse(await this.inventoryService.bulkInit())
  }
}
