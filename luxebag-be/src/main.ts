import { NestFactory } from '@nestjs/core'
import { Logger } from '@nestjs/common'
import { AppModule } from './app.module'
import { LoggerModule } from '../logger/logger.module'
import { initApp } from './init'

async function bootstrap() {
  const app = await NestFactory.create(AppModule, {
    logger: LoggerModule.createLogger(),
  })

  const {
    PORT = 3000,
    HOST = 'localhost',
    APP_PREFIX = '/api',
    APP_NAME = 'nestjs_app',
    NODE_ENV = 'development',
  } = process.env

  initApp(app)

  await app.listen(PORT, HOST)
  const protocol = NODE_ENV === 'production' ? 'https' : 'http'
  Logger.log(`Service is running at ${protocol}://${HOST}:${PORT}${APP_PREFIX}`, APP_NAME)
}
bootstrap()
