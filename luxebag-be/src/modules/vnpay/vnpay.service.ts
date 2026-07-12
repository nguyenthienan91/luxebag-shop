import { Injectable } from '@nestjs/common'
import * as crypto from 'crypto'
import moment from 'moment'
import * as qs from 'qs'

@Injectable()
export class VnpayService {
  createPaymentUrl(orderId: string, amount: number, ipAddress: string): string {
    const tmnCode = process.env.VNP_TMNCODE || ''
    const secretKey = process.env.VNP_HASH_SECRET || ''
    let vnpUrl = process.env.VNP_URL || ''
    const returnUrl = process.env.VNP_RETURN_URL || ''
    const createDate = moment(new Date()).format('YYYYMMDDHHmmss')
    const expireDate = moment(new Date()).add(15, 'minutes').format('YYYYMMDDHHmmss')
    const exchangeRate = 26267.54

    let vnp_Params: any = {}
    vnp_Params['vnp_Version'] = '2.1.0'
    vnp_Params['vnp_Command'] = 'pay'
    vnp_Params['vnp_TmnCode'] = tmnCode
    vnp_Params['vnp_Locale'] = 'vn'
    vnp_Params['vnp_CurrCode'] = 'VND'
    vnp_Params['vnp_TxnRef'] = orderId // Mã đơn hàng trong hệ thống LuxeBag của bạn
    vnp_Params['vnp_OrderInfo'] = `Thanh toan don hang #${orderId}`
    vnp_Params['vnp_OrderType'] = 'other'

    // Quy đổi từ USD sang VND và nhân tiếp 100 theo quy định VNPay
    vnp_Params['vnp_Amount'] = Math.round(amount * exchangeRate * 100)

    vnp_Params['vnp_ReturnUrl'] = returnUrl
    vnp_Params['vnp_IpAddr'] = ipAddress
    vnp_Params['vnp_CreateDate'] = createDate
    vnp_Params['vnp_ExpireDate'] = expireDate

    // Sắp xếp các tham số theo thứ tự alphabet (Bắt buộc)
    vnp_Params = this.sortObject(vnp_Params)

    // Tính toán tạo mã băm bảo mật chữ ký
    const signData = qs.stringify(vnp_Params, { encode: false })
    const hmac = crypto.createHmac('sha512', secretKey)
    const signed = hmac.update(Buffer.from(signData, 'utf-8')).digest('hex')

    vnp_Params['vnp_SecureHash'] = signed
    vnpUrl += '?' + qs.stringify(vnp_Params, { encode: false })

    return vnpUrl
  }

  verifyReturnUrl(query: any): boolean {
    let vnp_Params = { ...query }
    const secureHash = vnp_Params['vnp_SecureHash']

    delete vnp_Params['vnp_SecureHash']
    delete vnp_Params['vnp_SecureHashType']

    vnp_Params = this.sortObject(vnp_Params)

    const secretKey = process.env.VNP_HASH_SECRET || ''
    const signData = qs.stringify(vnp_Params, { encode: false })
    const hmac = crypto.createHmac('sha512', secretKey)
    const signed = hmac.update(Buffer.from(signData, 'utf-8')).digest('hex')

    return secureHash === signed
  }

  public sortObject(obj: any) {
    const sorted: Record<string, string> = {}
    const str: string[] = []
    let key
    for (key in obj) {
      if (obj.hasOwnProperty(key)) {
        str.push(encodeURIComponent(key))
      }
    }
    str.sort()
    for (key = 0; key < str.length; key++) {
      sorted[str[key]] = encodeURIComponent(obj[str[key]]).replace(/%20/g, '+')
    }
    return sorted
  }
}
