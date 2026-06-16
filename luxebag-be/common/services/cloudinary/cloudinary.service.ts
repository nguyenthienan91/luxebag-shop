import { Injectable } from '@nestjs/common'
import { ConfigService } from '@nestjs/config'
import { v2 as cloudinary, UploadApiResponse, UploadApiErrorResponse } from 'cloudinary'
import 'multer'

@Injectable()
export class CloudinaryService {
  constructor(private readonly configService: ConfigService) {
    cloudinary.config({
      cloud_name: this.configService.get<string>('CLOUDINARY_CLOUD_NAME'),
      api_key: this.configService.get<string>('CLOUDINARY_API_KEY'),
      api_secret: this.configService.get<string>('CLOUDINARY_API_SECRET'),
    })
  }

  /** Upload 1 file lên Cloudinary vào folder chỉ định */
  async uploadToFolder(file: Express.Multer.File, folder: string): Promise<UploadApiResponse> {
    return new Promise((resolve, reject) => {
      const uploadStream = cloudinary.uploader.upload_stream(
        { folder, allowed_formats: ['jpg', 'png', 'jpeg', 'webp'] },
        (error, result) => {
          if (error) return reject(new Error(error.message || 'Cloudinary upload failed'))
          if (!result) return reject(new Error('Upload returned no result'))
          resolve(result)
        },
      )
      uploadStream.end(file.buffer)
    })
  }

  /** Xóa ảnh trên Cloudinary theo public_id */
  async deleteImage(publicId: string): Promise<void> {
    await cloudinary.uploader.destroy(publicId)
  }

  /** Trích xuất public_id từ Cloudinary URL */
  extractPublicId(url: string): string | null {
    try {
      // URL dạng: https://res.cloudinary.com/<cloud>/image/upload/v123456/<folder>/<filename>.ext
      const match = url.match(/\/upload\/(?:v\d+\/)?(.+)\.[a-z]+$/i)
      return match ? match[1] : null
    } catch {
      return null
    }
  }

  /** Legacy method — giữ lại tương thích ngược */
  async uploadImage(file: Express.Multer.File): Promise<UploadApiResponse | UploadApiErrorResponse> {
    return this.uploadToFolder(file, 'handbag-shop')
  }
}
