import { Injectable } from '@nestjs/common'
import { SizeCategory } from '../products/entities/product.entity'

@Injectable()
export class ShippingService {
  private readonly RATE_USD_VND = 26267.54

  private readonly SOUTHERN_PROVINCES = [
    'Bình Phước', 'Bình Dương', 'Đồng Nai', 'Tây Ninh', 'Bà Rịa - Vũng Tàu',
    'Long An', 'Đồng Tháp', 'Tiền Giang', 'An Giang', 'Bến Tre', 'Vĩnh Long',
    'Trà Vinh', 'Hậu Giang', 'Kiên Giang', 'Sóc Trăng', 'Bạc Liêu', 'Cà Mau', 'Cần Thơ'
  ]

  private getSizeWeight(sizeCategory: string): number {
    switch (sizeCategory) {
      case SizeCategory.MINI:
        return 0.4
      case SizeCategory.SMALL:
        return 0.6
      case SizeCategory.MEDIUM:
        return 1.0
      case SizeCategory.LARGE:
        return 1.5
      default:
        return 0.5 // Default fallback
    }
  }

  calculateShippingFee(province: string, items: { quantity: number; sizeCategory: string }[]): number {
    if (!items || items.length === 0) return 0

    // 1. Tính tổng trọng lượng (kg)
    let totalWeight = 0
    for (const item of items) {
      totalWeight += this.getSizeWeight(item.sizeCategory) * item.quantity
    }

    if (totalWeight <= 0) return 0

    // 2. Phân loại khu vực giao hàng
    let feeVnd = 0
    const normalizedProvince = province.trim()

    // 2.1 Nội tỉnh (Hồ Chí Minh)
    if (normalizedProvince === 'Hồ Chí Minh') {
      if (totalWeight <= 3) {
        feeVnd = 30000
      } else {
        const extraWeight = totalWeight - 3
        const extraSteps = Math.ceil(extraWeight / 0.5)
        feeVnd = 30000 + extraSteps * 2500
      }
    } 
    // 2.2 Đặc biệt (Hà Nội, Đà Nẵng)
    else if (['Hà Nội', 'Đà Nẵng'].includes(normalizedProvince)) {
      if (totalWeight <= 0.5) {
        feeVnd = 40000
      } else {
        const extraWeight = totalWeight - 0.5
        const extraSteps = Math.ceil(extraWeight / 0.5)
        feeVnd = 40000 + extraSteps * 5000
      }
    } 
    // 2.3 Nội miền (Miền Nam)
    else if (this.SOUTHERN_PROVINCES.includes(normalizedProvince)) {
      if (totalWeight <= 0.5) {
        feeVnd = 35000
      } else {
        const extraWeight = totalWeight - 0.5
        const extraSteps = Math.ceil(extraWeight / 0.5)
        feeVnd = 35000 + extraSteps * 2500
      }
    } 
    // 2.4 Liên miền (Các tỉnh khác)
    else {
      if (totalWeight <= 0.5) {
        feeVnd = 40000
      } else {
        const extraWeight = totalWeight - 0.5
        const extraSteps = Math.ceil(extraWeight / 0.5)
        feeVnd = 40000 + extraSteps * 5000
      }
    }

    // 3. Quy đổi ra USD và làm tròn 2 chữ số thập phân
    const feeUsd = feeVnd / this.RATE_USD_VND
    return Math.round(feeUsd * 100) / 100
  }
}
