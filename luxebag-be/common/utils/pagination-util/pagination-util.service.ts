import { Injectable } from '@nestjs/common'
import { Pagination, PagingDefault } from './pagination-util.interface'

@Injectable()
export class PaginationUtilService extends Pagination {
  paging({ page = PagingDefault.PAGE, itemPerPage = PagingDefault.ITEM_PER_PAGE, totalItems = 0 }) {
    const skip = (page - 1) * itemPerPage
    const totalPages = Math.ceil(totalItems / itemPerPage)
    
    return {
      skip,
      totalPages,
      totalItems,
      format: <T>(list: T) => ({
        list,
        totalPages,
        totalItems,
      }),
    }
  }
}
