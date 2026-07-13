import { Controller, Get, Query, Res } from '@nestjs/common'
import { VnpayService } from '../vnpay/vnpay.service'
import { OrderService } from './order.service'
import type { Response } from 'express'
import { OrderStatus, PaymentStatus } from './entities/order.entity'
import { SkipAuth } from '../auth/auth.decorator'

@Controller('payments/vnpay')
export class PaymentController {
  constructor(
    private readonly vnpayService: VnpayService,
    private readonly orderService: OrderService,
  ) {}

  @SkipAuth()
  @Get('return')
  async vnpayReturn(@Query() query: any, @Res() res: Response) {
    const isValid = this.vnpayService.verifyReturnUrl(query)
    const feUrl = process.env.FE_URL || 'http://localhost:3000'

    if (isValid) {
      if (query.vnp_ResponseCode === '00') {
        // Update order status in return URL for localhost testing
        // (VNPay IPN cannot reach localhost)
        // vnp_TxnRef có dạng orderId_timestamp, tách lấy orderId thực
        const orderId = (query.vnp_TxnRef as string).split('_')[0]
        const order = await this.orderService.findRawById(orderId)
        if (order && order.status === OrderStatus.PENDING) {
          await this.orderService.updateOrderStatusAndPayment(orderId, OrderStatus.PROCESSING, PaymentStatus.PAID)
        }
        return res.redirect(`${feUrl}/payment-success?orderId=${orderId}`)
      } else {
        // Xóa link thanh toán khi giao dịch thất bại / bị hủy
        const orderId = (query.vnp_TxnRef as string).split('_')[0]
        await this.orderService.clearPaymentUrl(orderId)
        return res.redirect(`${feUrl}/payment-failed?orderId=${orderId}`)
      }
    } else {
      return res.status(400).json({ message: 'Invalid signature' })
    }
  }

  @SkipAuth()
  @Get('ipn')
  async vnpayIpn(@Query() query: any, @Res() res: Response) {
    const isValid = this.vnpayService.verifyReturnUrl(query)

    if (isValid) {
      // vnp_TxnRef có dạng orderId_timestamp, tách lấy orderId thực
      const orderId = (query.vnp_TxnRef as string).split('_')[0]
      if (query.vnp_ResponseCode === '00') {
        const order = await this.orderService.findRawById(orderId)
        // Cập nhật trạng thái thành PROCESSING và PAID (Atomic)
        if (order && order.status === OrderStatus.PENDING) {
          await this.orderService.updateOrderStatusAndPayment(orderId, OrderStatus.PROCESSING, PaymentStatus.PAID)
        }
      } else {
        // Xóa link thanh toán khi giao dịch thất bại / bị hủy
        const failOrderId = (query.vnp_TxnRef as string).split('_')[0]
        await this.orderService.clearPaymentUrl(failOrderId)
      }
      return res.status(200).json({ RspCode: '00', Message: 'Confirm Success' })
    } else {
      return res.status(200).json({ RspCode: '97', Message: 'Checksum failed' })
    }
  }
}
