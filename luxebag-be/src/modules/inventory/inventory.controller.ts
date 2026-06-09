import { Controller, Get, Patch, Post, Param, Body } from '@nestjs/common'
import { InventoryService } from './inventory.service'
import { UserRole } from '../users/entities/user.entity'
import { Roles } from '../../../common/decorators/roles.decorator'
import { okResponse } from '../../../common/interceptors/format-response/format-response.util'
import { z } from 'zod'
import { createZodDto } from 'nestjs-zod'

class SetStockDto extends createZodDto(
  z.object({
    stock: z.number({ error: 'stock must be a number' }).int().min(0, 'stock cannot be negative'),
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

  // POST /inventory/bulk-init — init inventory cho toàn bộ product chưa có record
  @Post('bulk-init')
  async bulkInit() {
    return okResponse(await this.inventoryService.bulkInit())
  }
}
