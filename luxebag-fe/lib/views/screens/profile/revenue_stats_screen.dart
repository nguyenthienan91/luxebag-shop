import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../utils/app_colors.dart';
import '../../../viewmodels/order_viewmodel.dart';
import '../../../models/revenue_stats_model.dart';

class RevenueStatsScreen extends StatefulWidget {
  const RevenueStatsScreen({super.key});

  @override
  State<RevenueStatsScreen> createState() => _RevenueStatsScreenState();
}

class _RevenueStatsScreenState extends State<RevenueStatsScreen> {
  String _selectedPeriod = '7d';

  static const List<Map<String, String>> _periodOptions = [
    {'value': '7d', 'label': '7D'},
    {'value': '30d', 'label': '30D'},
    {'value': '6m', 'label': '6M'},
    {'value': '12m', 'label': '12M'},
    {'value': 'year', 'label': 'Year'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderViewModel>().fetchRevenueStats(period: _selectedPeriod);
    });
  }

  void _onPeriodChanged(String period) {
    if (period == _selectedPeriod) return;
    setState(() => _selectedPeriod = period);
    context.read<OrderViewModel>().fetchRevenueStats(period: period);
  }

  String _formatCurrency(double amount) {
    final stringVal = amount.toInt().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < stringVal.length; i++) {
      if (i > 0 && (stringVal.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(stringVal[i]);
    }
    return '\$ ${buffer.toString()}';
  }

  String _formatCompact(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1).replaceAll('.0', '')}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1).replaceAll('.0', '')}k';
    }
    return value.toStringAsFixed(0);
  }

  /// Determines whether the current period uses day-level labels
  bool get _isDayPeriod => _selectedPeriod == '7d' || _selectedPeriod == '30d';

  /// Format a label for display on the X-axis
  String _formatLabel(String rawLabel) {
    if (_isDayPeriod) {
      // rawLabel is YYYY-MM-DD
      final parts = rawLabel.split('-');
      if (parts.length == 3) {
        final monthInt = int.parse(parts[1]);
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return '${parts[2]} ${months[monthInt - 1]}'; // e.g. 17 Jun
      }
    } else {
      // rawLabel is YYYY-MM
      final parts = rawLabel.split('-');
      if (parts.length == 2) {
        final monthInt = int.parse(parts[1]);
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return months[monthInt - 1]; // e.g. Jun
      }
    }
    return rawLabel;
  }

  /// Format a label for tooltip (more verbose)
  String _formatTooltipLabel(String rawLabel) {
    if (_isDayPeriod) {
      final parts = rawLabel.split('-');
      if (parts.length == 3) {
        final monthInt = int.parse(parts[1]);
        const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
        return '${int.parse(parts[2])} ${months[monthInt - 1]} ${parts[0]}';
      }
    } else {
      final parts = rawLabel.split('-');
      if (parts.length == 2) {
        final monthInt = int.parse(parts[1]);
        const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
        return '${months[monthInt - 1]} ${parts[0]}';
      }
    }
    return rawLabel;
  }

  Map<String, double> _calculateMaxYAndInterval(double maxRevenue) {
    if (maxRevenue <= 0) {
      return {'maxY': 1000.0, 'interval': 250.0};
    }
    
    double rawMaxY = maxRevenue * 1.2;
    
    // Find the magnitude
    double magnitude = 1.0;
    if (rawMaxY >= 1000000) {
      magnitude = 1000000.0;
    } else if (rawMaxY >= 1000) {
      magnitude = 1000.0;
    } else if (rawMaxY >= 100) {
      magnitude = 100.0;
    } else if (rawMaxY >= 10) {
      magnitude = 10.0;
    }
    
    double normalized = rawMaxY / magnitude;
    
    double roundedNormalized;
    double interval;
    
    if (normalized <= 2.0) {
      roundedNormalized = 2.0;
      interval = 0.5;
    } else if (normalized <= 4.0) {
      roundedNormalized = 4.0;
      interval = 1.0;
    } else if (normalized <= 6.0) {
      roundedNormalized = 6.0;
      interval = 1.5;
    } else if (normalized <= 8.0) {
      roundedNormalized = 8.0;
      interval = 2.0;
    } else if (normalized <= 10.0) {
      roundedNormalized = 10.0;
      interval = 2.5;
    } else {
      roundedNormalized = ((normalized / 5).ceil() * 5).toDouble();
      interval = roundedNormalized / 4;
    }
    
    return {
      'maxY': roundedNormalized * magnitude,
      'interval': interval * magnitude,
    };
  }

  /// Description text based on period
  String _getPeriodDescription() {
    switch (_selectedPeriod) {
      case '7d':
        return 'This week (Mon – Sun)';
      case '30d':
        return 'Last 30 days';
      case '6m':
        return 'Last 6 months';
      case '12m':
        return 'Last 12 months';
      case 'year':
        return 'This year';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderVM = context.watch<OrderViewModel>();
    final stats = orderVM.revenueStats;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Business Statistics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.divider),
        ),
      ),
      body: orderVM.isLoadingStats && stats == null
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : orderVM.errorMessage != null && stats == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 60, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text(
                          orderVM.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () =>
                              context.read<OrderViewModel>().fetchRevenueStats(period: _selectedPeriod),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Retry',
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      ],
                    ),
                  ),
                )
              : stats == null
                  ? const Center(
                      child: Text('Failed to load statistics.'),
                    )
                  : RefreshIndicator(
                      onRefresh: () =>
                          context.read<OrderViewModel>().fetchRevenueStats(period: _selectedPeriod),
                      color: AppColors.primary,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        children: [
                          // ── Total Revenue Card (Premium Design) ──
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF2C2C2C),
                                  Color(0xFF151515),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD4AF37)
                                            .withOpacity(0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.monetization_on_outlined,
                                        color: Color(0xFFD4AF37),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'TOTAL REVENUE',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFD4AF37),
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  _formatCurrency(stats.totalRevenue),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'From all completed orders',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // ── Chart Title ──
                          const Text(
                            'Revenue Chart',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // ── Period Chip Selector ──
                          _buildPeriodChips(),
                          const SizedBox(height: 8),

                          // ── Period Description ──
                          Text(
                            _getPeriodDescription(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ── Bar Chart Widget ──
                          Container(
                            height: 340,
                            padding: const EdgeInsets.only(
                              top: 20,
                              bottom: 12,
                              right: 20,
                              left: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: AppColors.inputBorder, width: 1),
                            ),
                            child: orderVM.isLoadingStats
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          AppColors.primary),
                                    ),
                                  )
                                : _buildChart(stats.data),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildPeriodChips() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.inputBorder, width: 1.5),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: _periodOptions.map((option) {
          final isActive = _selectedPeriod == option['value'];
          return Expanded(
            child: GestureDetector(
              onTap: () => _onPeriodChanged(option['value']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  option['label']!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChart(List<RevenueDataPoint> data) {
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_rounded,
                size: 48, color: AppColors.textSecondary.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text(
              'No revenue data for ${_getPeriodDescription().toLowerCase()}.',
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final maxRevenue = data.map((e) => e.revenue).fold<double>(0.0, (m, e) => e > m ? e : m);
    final chartConfig = _calculateMaxYAndInterval(maxRevenue);
    final double maxY = chartConfig['maxY']!;
    final double interval = chartConfig['interval']!;

    // Calculate bar width based on data count
    double barWidth;
    if (data.length <= 7) {
      barWidth = 24;
    } else if (data.length <= 12) {
      barWidth = 20;
    } else {
      barWidth = 10;
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          handleBuiltInTouches: data.length > 12,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => data.length <= 12
                ? Colors.transparent
                : const Color(0xFF2C2C2C),
            tooltipPadding: data.length <= 12
                ? const EdgeInsets.symmetric(horizontal: 4, vertical: 2)
                : const EdgeInsets.all(8),
            tooltipMargin: data.length <= 12 ? 4 : 8,
            fitInsideVertically: true,
            fitInsideHorizontally: true,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final label = data[group.x.toInt()].label;
              final formattedLabel = _formatTooltipLabel(label);
              
              if (data.length <= 12) {
                return BarTooltipItem(
                  '\$${_formatCompact(rod.toY)}',
                  const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                  ),
                );
              } else {
                return BarTooltipItem(
                  '$formattedLabel\n',
                  const TextStyle(
                    color: Color(0xFFD4AF37),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: _formatCurrency(rod.toY),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) return const SizedBox();

                // Only show every Nth label to avoid overcrowding
                final showLabel = data.length <= 12 ||
                    index == 0 ||
                    index == data.length - 1 ||
                    index % (data.length / 6).ceil() == 0;

                if (!showLabel) return const SizedBox();

                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _formatLabel(data[index].label),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              interval: interval,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    _formatCompact(value),
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.divider.withOpacity(0.4),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(
          show: false,
        ),
        barGroups: List.generate(
          data.length,
          (index) => BarChartGroupData(
            x: index,
            showingTooltipIndicators: data.length <= 12 ? [0] : [],
            barRods: [
              BarChartRodData(
                toY: data[index].revenue,
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFD4AF37),
                    Color(0xFFB5942D),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: barWidth,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
