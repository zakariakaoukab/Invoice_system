import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../providers/dashboard_provider.dart';
import '../../ai_assistant/presentation/ai_chat_dialog.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlySales = ref.watch(monthlySalesProvider);
    final orderCount = ref.watch(monthlyOrderCountProvider);
    final avgValue = ref.watch(avgOrderValueProvider);
    final chartAsync = ref.watch(monthlySalesChartProvider);
    final topProductsAsync = ref.watch(topProductsProvider);
    final monthlyOrdersAsync = ref.watch(monthlyOrdersProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AiChatDialog(),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.smart_toy_rounded, color: AppColors.onPrimary),
        label: const Text(
          'AI Assistant',
          style: TextStyle(color: AppColors.onPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.contentPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(
              title: AppStrings.dashboardTitle,
              subtitle: 'نظرة عامة على أداء المبيعات',
            ),
            const SizedBox(height: 28),

            // KPI Cards
            monthlyOrdersAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => Text('${AppStrings.error}: $e',
                  style: const TextStyle(color: AppColors.error)),
              data: (_) => _buildKpiCards(monthlySales, orderCount, avgValue),
            ),

            const SizedBox(height: 28),

            // Charts row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sales chart
                Expanded(
                  flex: 3,
                  child: _SalesChartCard(chartAsync: chartAsync),
                ),
                const SizedBox(width: 16),
                // Top products
                Expanded(
                  flex: 2,
                  child: _TopProductsCard(topProductsAsync: topProductsAsync),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCards(
      double monthlySales, int orderCount, double avgValue) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: AppStrings.monthlySales,
            value: CurrencyFormatter.format(monthlySales),
            icon: Icons.attach_money_rounded,
            iconColor: AppColors.success,
            bgColor: AppColors.success.withOpacity(0.1),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            title: AppStrings.monthlyOrders,
            value: orderCount.toString(),
            icon: Icons.receipt_long_rounded,
            iconColor: AppColors.info,
            bgColor: AppColors.info.withOpacity(0.1),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            title: AppStrings.avgOrderValue,
            value: CurrencyFormatter.format(avgValue),
            icon: Icons.trending_up_rounded,
            iconColor: AppColors.primary,
            bgColor: AppColors.primaryContainer,
          ),
        ),
      ],
    );
  }
}

// ── Sales Chart Card ──────────────────────────────────────────────────────────

class _SalesChartCard extends StatelessWidget {
  final AsyncValue<Map<String, double>> chartAsync;
  const _SalesChartCard({required this.chartAsync});

  @override
  Widget build(BuildContext context) {
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
            AppStrings.salesChart,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: chartAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => Text(AppStrings.error,
                  style: const TextStyle(color: AppColors.error)),
              data: (data) => data.isEmpty
                  ? const EmptyStateWidget(message: AppStrings.noData)
                  : _buildBarChart(data),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(Map<String, double> data) {
    final sortedKeys = data.keys.toList()..sort();
    final maxY = data.values.isEmpty
        ? 100.0
        : data.values.reduce((a, b) => a > b ? a : b) * 1.2;

    final bars = sortedKeys.asMap().entries.map((e) {
      final amount = data[e.value] ?? 0;
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: amount,
            gradient: const LinearGradient(
              colors: [AppColors.primaryLight, AppColors.primaryDark],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: 24,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        maxY: maxY,
        barGroups: bars,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AppColors.divider, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= sortedKeys.length) {
                  return const SizedBox.shrink();
                }
                final key = sortedKeys[idx];
                final parts = key.split('-');
                final month = int.tryParse(parts[1]) ?? 1;
                final date = DateTime(int.tryParse(parts[0]) ?? 2024, month);
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormatter.formatMonthAbbr(date),
                    style: const TextStyle(
                      color: AppColors.onSurfaceMuted,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 56,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  CurrencyFormatter.format(value),
                  style: const TextStyle(
                    color: AppColors.onSurfaceMuted,
                    fontSize: 11,
                  ),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.surfaceElevated,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                CurrencyFormatter.format(rod.toY),
                const TextStyle(
                  color: AppColors.primary,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Top Products Card ─────────────────────────────────────────────────────────

class _TopProductsCard extends StatelessWidget {
  final AsyncValue<List<MapEntry<String, int>>> topProductsAsync;
  const _TopProductsCard({required this.topProductsAsync});

  @override
  Widget build(BuildContext context) {
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
            AppStrings.topProducts,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          topProductsAsync.when(
            loading: () => const LoadingWidget(),
            error: (e, _) => Text(AppStrings.error,
                style: const TextStyle(color: AppColors.error)),
            data: (products) => products.isEmpty
                ? const EmptyStateWidget(message: AppStrings.noData)
                : Column(
                    children: products.asMap().entries.map((e) {
                      final rank = e.key + 1;
                      final name = e.value.key;
                      final qty = e.value.value;
                      return _TopProductRow(
                          rank: rank, name: name, quantity: qty);
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TopProductRow extends StatelessWidget {
  final int rank;
  final String name;
  final int quantity;

  const _TopProductRow(
      {required this.rank, required this.name, required this.quantity});

  @override
  Widget build(BuildContext context) {
    final colors = [
      AppColors.primary,
      AppColors.primaryLight,
      AppColors.info,
      AppColors.success,
      AppColors.onSurfaceMuted,
    ];
    final color = colors[(rank - 1).clamp(0, colors.length - 1)];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: AppColors.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '$quantity ${AppStrings.stockUnits}',
            style: const TextStyle(
              color: AppColors.onSurfaceMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
