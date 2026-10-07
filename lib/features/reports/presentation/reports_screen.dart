import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../providers/reports_provider.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.contentPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, ref),
            const SizedBox(height: 28),
            _buildKpiCards(ref),
            const SizedBox(height: 28),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildSalesTrendChart(ref),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _buildProductBreakdownChart(ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final dateRange = ref.watch(reportDateRangeProvider);

    return PageHeader(
      title: AppStrings.reportsTitle,
      subtitle: AppStrings.reportsSubtitle,
      action: _buildDateRangeSelector(context, ref, dateRange),
    );
  }

  Widget _buildDateRangeSelector(BuildContext context, WidgetRef ref, ReportDateRangeState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ReportDateRange>(
          value: state.type,
          icon: const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
          style: const TextStyle(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w600,
            fontFamily: 'Cairo',
          ),
          onChanged: (ReportDateRange? newValue) async {
            if (newValue == null) return;
            
            if (newValue == ReportDateRange.custom) {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: AppColors.primary,
                        onPrimary: AppColors.onPrimary,
                        surface: AppColors.surface,
                        onSurface: AppColors.onSurface,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                ref.read(reportDateRangeProvider.notifier).setCustomRange(picked.start, picked.end);
              }
            } else {
              ref.read(reportDateRangeProvider.notifier).setType(newValue);
            }
          },
          items: const [
            DropdownMenuItem(
              value: ReportDateRange.last7Days,
              child: Text(AppStrings.last7Days),
            ),
            DropdownMenuItem(
              value: ReportDateRange.last30Days,
              child: Text(AppStrings.last30Days),
            ),
            DropdownMenuItem(
              value: ReportDateRange.thisMonth,
              child: Text(AppStrings.thisMonth),
            ),
            DropdownMenuItem(
              value: ReportDateRange.allTime,
              child: Text(AppStrings.allTime),
            ),
            DropdownMenuItem(
              value: ReportDateRange.custom,
              child: Text(AppStrings.customDateRange),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCards(WidgetRef ref) {
    final revenue = ref.watch(reportTotalRevenueProvider);
    final ordersCount = ref.watch(reportTotalOrdersProvider);
    final avgOrder = ref.watch(reportAvgOrderValueProvider);

    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: AppStrings.totalRevenue,
            value: CurrencyFormatter.format(revenue),
            icon: Icons.account_balance_wallet_rounded,
            iconColor: AppColors.success,
            bgColor: AppColors.success.withOpacity(0.1),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            title: AppStrings.totalOrdersCount,
            value: ordersCount.toString(),
            icon: Icons.shopping_bag_rounded,
            iconColor: AppColors.info,
            bgColor: AppColors.info.withOpacity(0.1),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            title: AppStrings.averageOrder,
            value: CurrencyFormatter.format(avgOrder),
            icon: Icons.calculate_rounded,
            iconColor: AppColors.primary,
            bgColor: AppColors.primaryContainer,
          ),
        ),
      ],
    );
  }

  Widget _buildSalesTrendChart(WidgetRef ref) {
    final salesTrend = ref.watch(reportSalesTrendProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            AppStrings.salesTrend,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: salesTrend.isEmpty
                ? const EmptyStateWidget(message: AppStrings.noData)
                : _LineChartWidget(salesTrend: salesTrend),
          ),
        ],
      ),
    );
  }

  Widget _buildProductBreakdownChart(WidgetRef ref) {
    final productBreakdown = ref.watch(reportProductBreakdownProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            AppStrings.salesByProduct,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: productBreakdown.isEmpty
                ? const EmptyStateWidget(message: AppStrings.noData)
                : _PieChartWidget(productBreakdown: productBreakdown),
          ),
        ],
      ),
    );
  }
}

// ── Line Chart ──────────────────────────────────────────────────────────────

class _LineChartWidget extends StatelessWidget {
  final Map<DateTime, double> salesTrend;

  const _LineChartWidget({required this.salesTrend});

  @override
  Widget build(BuildContext context) {
    final sortedKeys = salesTrend.keys.toList()..sort();
    
    // Create spots
    final spots = <FlSpot>[];
    double maxY = 0;

    for (int i = 0; i < sortedKeys.length; i++) {
      final val = salesTrend[sortedKeys[i]]!;
      spots.add(FlSpot(i.toDouble(), val));
      if (val > maxY) maxY = val;
    }

    maxY = maxY == 0 ? 100 : maxY * 1.2;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.divider, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= sortedKeys.length) return const SizedBox.shrink();
                
                // Show fewer labels if there are many points
                if (sortedKeys.length > 10 && idx % (sortedKeys.length ~/ 5) != 0) {
                  return const SizedBox.shrink();
                }

                final date = sortedKeys[idx];
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    '${date.day}/${date.month}',
                    style: const TextStyle(color: AppColors.onSurfaceMuted, fontSize: 11),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  CurrencyFormatter.format(value),
                  style: const TextStyle(color: AppColors.onSurfaceMuted, fontSize: 11),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (sortedKeys.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.3),
                  AppColors.primary.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.surfaceElevated,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final date = sortedKeys[spot.x.toInt()];
                return LineTooltipItem(
                  '${DateFormatter.formatDate(date)}\n',
                  const TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12, fontFamily: 'Cairo'),
                  children: [
                    TextSpan(
                      text: CurrencyFormatter.format(spot.y),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

// ── Pie Chart ───────────────────────────────────────────────────────────────

class _PieChartWidget extends StatefulWidget {
  final Map<String, double> productBreakdown;

  const _PieChartWidget({required this.productBreakdown});

  @override
  State<_PieChartWidget> createState() => _PieChartWidgetState();
}

class _PieChartWidgetState extends State<_PieChartWidget> {
  int touchedIndex = -1;

  final List<Color> _colors = [
    AppColors.primary,
    AppColors.info,
    AppColors.success,
    AppColors.warning,
    AppColors.error,
    AppColors.primaryLight,
  ];

  @override
  Widget build(BuildContext context) {
    // Take top 5, group rest as "Other"
    final entries = widget.productBreakdown.entries.toList();
    final topEntries = entries.take(5).toList();
    final otherTotal = entries.skip(5).fold(0.0, (sum, e) => sum + e.value);
    
    if (otherTotal > 0) {
      topEntries.add(MapEntry('أخرى', otherTotal));
    }

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedIndex = -1;
                      return;
                    }
                    touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: showingSections(topEntries),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Legend
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: topEntries.asMap().entries.map((e) {
              final isTouched = e.key == touchedIndex;
              final color = _colors[e.key % _colors.length];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e.value.key,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isTouched ? FontWeight.bold : FontWeight.normal,
                          color: isTouched ? AppColors.onSurface : AppColors.onSurfaceMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> showingSections(List<MapEntry<String, double>> entries) {
    final total = entries.fold(0.0, (sum, e) => sum + e.value);

    return entries.asMap().entries.map((e) {
      final i = e.key;
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 14.0 : 12.0; // Show percentages always
      final radius = isTouched ? 60.0 : 50.0;
      final color = _colors[i % _colors.length];

      final percentage = total == 0 ? 0.0 : (e.value.value / total) * 100;
      final title = '${percentage.toStringAsFixed(1)}%';

      return PieChartSectionData(
        color: color,
        value: e.value.value,
        title: title,
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }
}
