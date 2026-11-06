import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/period_stats_service.dart';
import '../theme/app_theme.dart';

/// Dönem grafiği: günlük veya aylık barlar + isteğe bağlı hedef çizgisi.
class PeriodBarChart extends StatelessWidget {
  const PeriodBarChart({
    super.key,
    required this.buckets,
    required this.valueOf,
    this.goalValue,
    this.goalLabel = 'Hedef',
    this.unit = 'ml',
    this.colors = const <Color>[AppColors.primary, AppColors.accent],
    this.height = 220,
  });

  final List<ChartBucket> buckets;
  final int Function(ChartBucket bucket) valueOf;
  final int? goalValue;
  final String goalLabel;
  final String unit;
  final List<Color> colors;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (buckets.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text(
            'Bu dönem için veri yok',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.subtitle,
            ),
          ),
        ),
      );
    }

    final List<double> values = buckets
        .map((ChartBucket b) => valueOf(b).toDouble())
        .toList();
    final double maxBar = values.isEmpty ? 0 : values.reduce(math.max);
    final double chartMax = math.max(
      math.max(maxBar * 1.2, (goalValue ?? 0) * 1.25),
      unit == 'ml' ? 800 : 40,
    );

    final int labelStep = buckets.length <= 8 ? 1 : (buckets.length / 8).ceil();

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          maxY: chartMax,
          minY: 0,
          alignment: BarChartAlignment.spaceAround,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem:
                  (
                    BarChartGroupData group,
                    int groupIndex,
                    BarChartRodData rod,
                    int rodIndex,
                  ) {
                    final ChartBucket bucket = buckets[group.x];
                    return BarTooltipItem(
                      '${bucket.label}\n${rod.toY.round()} $unit',
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                interval: chartMax / 3,
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value <= 0) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      value >= 1000
                          ? '${(value / 1000).toStringAsFixed(1)}k'
                          : '${value.round()}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.subtitle,
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final int index = value.toInt();
                  if (index < 0 || index >= buckets.length) {
                    return const SizedBox.shrink();
                  }
                  if (buckets.length > 8 && index % labelStep != 0) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      buckets[index].label,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.subtitle,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: chartMax / 3,
            getDrawingHorizontalLine: (double value) =>
                const FlLine(color: Color(0xFFE9F0F8), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          extraLinesData: ExtraLinesData(
            horizontalLines: <HorizontalLine>[
              if (goalValue != null && goalValue! > 0)
                HorizontalLine(
                  y: goalValue!.toDouble(),
                  color: AppColors.orange,
                  strokeWidth: 1.6,
                  dashArray: <int>[7, 7],
                  label: HorizontalLineLabel(
                    show: true,
                    labelResolver: (HorizontalLine line) => goalLabel,
                    style: const TextStyle(
                      color: AppColors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                    alignment: Alignment.topRight,
                  ),
                ),
            ],
          ),
          barGroups: List<BarChartGroupData>.generate(buckets.length, (int i) {
            return BarChartGroupData(
              x: i,
              barRods: <BarChartRodData>[
                BarChartRodData(
                  toY: values[i],
                  width: buckets.length > 15 ? 8 : 18,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(7),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: colors,
                  ),
                ),
              ],
            );
          }),
        ),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}
