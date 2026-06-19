class RevenueDataPoint {
  final String label;
  final double revenue;

  const RevenueDataPoint({
    required this.label,
    required this.revenue,
  });

  factory RevenueDataPoint.fromJson(Map<String, dynamic> json) {
    return RevenueDataPoint(
      label: json['label'] as String? ?? '',
      revenue: (json['revenue'] as num? ?? 0).toDouble(),
    );
  }
}

class RevenueStatsModel {
  final double totalRevenue;
  final String period;
  final List<RevenueDataPoint> data;

  const RevenueStatsModel({
    required this.totalRevenue,
    required this.period,
    required this.data,
  });

  factory RevenueStatsModel.fromJson(Map<String, dynamic> json) {
    final dataList = (json['data'] as List? ?? [])
        .map((e) => RevenueDataPoint.fromJson(e as Map<String, dynamic>))
        .toList();

    return RevenueStatsModel(
      totalRevenue: (json['totalRevenue'] as num? ?? 0).toDouble(),
      period: json['period'] as String? ?? '7d',
      data: dataList,
    );
  }
}
