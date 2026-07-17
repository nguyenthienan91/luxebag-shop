import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  UploadedFile,
  UseInterceptors,
  Query,
} from '@nestjs/common'
import { FileInterceptor } from '@nestjs/platform-express'
import { ApiConsumes, ApiBody } from '@nestjs/swagger'
import { UsersService } from './users.service'
import { CreateUserDto } from './dto/create-user.dto'
import { UpdateUserDto } from './dto/update-user.dto'
import { UserRole } from './entities/user.entity'
import { Roles } from '../../../common/decorators/roles.decorator'
import { User } from '../../../common/decorators/user.decorator'
import type { UserInfo } from '../../../common/decorators/user.decorator'
import { okResponse } from '../../../common/interceptors/format-response/format-response.util'

@Controller('users')
@Roles(UserRole.ADMIN)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  // PATCH /users/profile/avatar — cập nhật ảnh đại diện
  @Patch('profile/avatar')
  @Roles()
  @UseInterceptors(FileInterceptor('image'))
  @ApiConsumes('multipart/form-data')
  @ApiBody({ schema: { type: 'object', properties: { image: { type: 'string', format: 'binary' } } } })
  async uploadAvatar(@User() user: UserInfo, @UploadedFile() file: Express.Multer.File) {
    return okResponse(await this.usersService.uploadAvatar(user.userID, file))
  }

  @Patch('me')
  @Roles()
  updateMe(@User() user: UserInfo, @Body() updateUserDto: UpdateUserDto) {
    return this.usersService.update(user.userID, updateUserDto)
  }

  @Get('me')
  @Roles()
  getMe(@User() user: UserInfo) {
    return this.usersService.findById(user.userID)
  }

  @Post()
  create(@Body() createUserDto: CreateUserDto) {
    return this.usersService.create(createUserDto)
  }

  @Get()
  async findAll(
    @Query('search') search?: string,
    @Query('role') role?: string,
    @Query('isActive') isActive?: string,
  ) {
    return okResponse(await this.usersService.findAll(search, role, isActive))
  }

  @Get(':id')
  @Roles(UserRole.ADMIN, UserRole.STAFF)
  findOne(@Param('id') id: string) {
    return this.usersService.findById(id)
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() updateUserDto: UpdateUserDto) {
    return this.usersService.update(id, updateUserDto)
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.usersService.remove(id)
  }
}
