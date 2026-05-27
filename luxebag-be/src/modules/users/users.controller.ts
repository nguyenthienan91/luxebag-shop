import { Controller, Get, Post, Body, Patch, Param, Delete, UseGuards, Req } from '@nestjs/common'
import { UsersService } from './users.service'
import { CreateUserDto } from './dto/create-user.dto'
import { UpdateUserDto } from './dto/update-user.dto'
import { UserRole } from './entities/user.entity'
import { Roles } from '../../../common/decorators/roles.decorator'
import { User } from '../../../common/decorators/user.decorator'
import type { UserInfo } from '../../../common/decorators/user.decorator'

@Controller('users')
@Roles(UserRole.ADMIN)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

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
  findAll() {
    return this.usersService.findAll()
  }

  @Get(':id')
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
