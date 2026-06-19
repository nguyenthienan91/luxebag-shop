import { Module } from '@nestjs/common'
import { APP_GUARD } from '@nestjs/core'
import { AppController } from './app.controller'
import { AppService } from './app.service'
import { ConfigModule, ConfigService } from '@nestjs/config'
import { MongooseModule } from '@nestjs/mongoose'
import { AuthModule } from './modules/auth/auth.module'
import { UsersModule } from './modules/users/users.module'
import { ProductModule } from './modules/products/product.module'
import { WishlistModule } from './modules/wishlist/wishlist.module'
import { CategoriesModule } from './modules/categories/categories.module'
import { CartModule } from './modules/cart/cart.module'
import { OrderModule } from './modules/orders/order.module'
import { InventoryModule } from './modules/inventory/inventory.module'
import { ChatModule } from './modules/chat/chat.module'
import { AuthGuard } from './modules/auth/auth.guard'
import { RolesGuard } from '../common/security/roles/roles.guard'

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    MongooseModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      // eslint-disable-next-line @typescript-eslint/require-await
      useFactory: async (configService: ConfigService) => ({
        uri: configService.get<string>('MONGODB_URI'),
      }),
    }),
    AuthModule,
    UsersModule,
    ProductModule,
    WishlistModule,
    CategoriesModule,
    CartModule,
    OrderModule,
    InventoryModule,
    ChatModule,
  ],
  controllers: [AppController],
  providers: [AppService, { provide: APP_GUARD, useClass: AuthGuard }, { provide: APP_GUARD, useClass: RolesGuard }],
})
export class AppModule {}
