export class RevenueDataPoint {
  label!: string    // "2026-06-17" (daily) or "2026-06" (monthly)
  revenue!: number
}

export class RevenueStatsDto {
  totalRevenue!: number
  period!: string                    // "7d" | "30d" | "6m" | "12m" | "year"
  data!: RevenueDataPoint[]          // unified time-series
}
