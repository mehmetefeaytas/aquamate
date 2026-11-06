import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/period_stats_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/eco_widgets.dart';
import '../../widgets/period_bar_chart.dart';
import '../../widgets/section_card.dart';

/// İstatistik > Kafein sekmesi.
class CaffeineTab extends StatelessWidget {
  const CaffeineTab({super.key, required this.stats, required this.settings});

  final PeriodStats stats;
  final UserSettings settings;

  int get _limit => settings.caffeineLimitMg <= 0
      ? CaffeineCalculator.defaultLimitMg
      : settings.caffeineLimitMg;

  Color get _statusColor {
    switch (CaffeineCalculator.status(
      consumedMg: stats.todayCaffeine,
      limitMg: _limit,
    )) {
      case CaffeineStatus.low:
        return AppColors.green;
      case CaffeineStatus.moderate:
        return AppColors.primary;
      case CaffeineStatus.high:
        return AppColors.orange;
      case CaffeineStatus.exceeded:
        return const Color(0xFFE11D48);
    }
  }

  int get _overLimitDays =>
      stats.dailyCaffeine.values.where((int mg) => mg > _limit).length;

  int get _periodDailyAverage {
    if (stats.dailyCaffeine.isEmpty) {
      return 0;
    }
    final int total = stats.dailyCaffeine.values.fold<int>(
      0,
      (int sum, int mg) => sum + mg,
    );
    return (total / stats.dailyCaffeine.length).round();
  }

  Map<String, int> get _todaySources {
    final Map<String, int> sources = <String, int>{};
    for (final WaterLog log in stats.todayLogs) {
      if (log.caffeineMg <= 0) {
        continue;
      }
      sources.update(
        log.drinkType,
        (int value) => value + log.caffeineMg,
        ifAbsent: () => log.caffeineMg,
      );
    }
    return sources;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildTodayCard(context),
        const SizedBox(height: 14),
        _buildSourcesCard(context),
        const SizedBox(height: 14),
        _buildPeriodCard(context),
        if (stats.period != PeriodType.today) ...<Widget>[
          const SizedBox(height: 14),
          SectionCard(
            title: stats.period == PeriodType.year
                ? 'Aylık Kafein Trendi'
                : 'Günlük Kafein Trendi',
            subtitle: 'Toplam kafein (mg) · kesikli çizgi günlük limit',
            child: PeriodBarChart(
              buckets: stats.buckets,
              valueOf: (ChartBucket b) => b.caffeine,
              goalValue: _limit,
              goalLabel: 'Limit',
              unit: 'mg',
              colors: const <Color>[Color(0xFF8B5E34), Color(0xFFF5B942)],
            ),
          ),
        ],
        const SizedBox(height: 14),
        _buildNote(context),
      ],
    );
  }

  Widget _buildTodayCard(BuildContext context) {
    final int consumed = stats.todayCaffeine;
    final int remaining = math.max(0, _limit - consumed);
    final double ratio = (consumed / _limit).clamp(0.0, 1.2);
    final CaffeineStatus status = CaffeineCalculator.status(
      consumedMg: consumed,
      limitMg: _limit,
    );
    final String cutoff = CaffeineCalculator.cutoffLabel(
      settings.bedtimeMinutes,
    );

    return SectionCard(
      title: 'Bugünkü Kafein',
      subtitle: 'Günlük önerilen üst sınır: $_limit mg',
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              _CaffeineGauge(
                value: ratio.clamp(0.0, 1.0),
                color: _statusColor,
                consumed: consumed,
                limit: _limit,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        status.label,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: _statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      consumed > _limit
                          ? '${consumed - _limit} mg limitin üzerindesin'
                          : 'Kalan: ${formatMl(remaining)} mg',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.heading,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Uyku saatine (${settings.bedtimeLabel}) göre son kafein '
                      'önerisi: $cutoff',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.subtitle,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (consumed > _limit) ...<Widget>[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: <Widget>[
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: Color(0xFFE11D48),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bugün limitin üzerine çıktın. Sonraki içeceklerde '
                      'kafeinsiz alternatifleri dene.',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF9F1239),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSourcesCard(BuildContext context) {
    final Map<String, int> sources = _todaySources;
    if (sources.isEmpty) {
      return SectionCard(
        title: 'Bugünkü Kaynaklar',
        subtitle: 'Kafein nereden geliyor?',
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Text(
            'Bugün kafein içeren bir içecek kaydetmedin. Harika!',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.subtitle,
            ),
          ),
        ),
      );
    }

    final List<MapEntry<String, int>> entries = sources.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final int total = entries.fold<int>(
      0,
      (int sum, MapEntry<String, int> e) => sum + e.value,
    );

    return SectionCard(
      title: 'Bugünkü Kaynaklar',
      subtitle: 'Kafein içeren içeceklerin dağılımı',
      child: Column(
        children: <Widget>[
          for (final MapEntry<String, int> entry in entries)
            DistributionRow(
              color: drinkTypeOf(entry.key).color,
              icon: drinkTypeOf(entry.key).icon,
              label: entry.key,
              valueLabel: '${entry.value} mg',
              fraction: entry.value / total,
            ),
        ],
      ),
    );
  }

  Widget _buildPeriodCard(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: MetricTile(
                icon: Icons.local_cafe_rounded,
                color: const Color(0xFF8B5E34),
                title: 'Dönem Toplamı',
                value: formatMl(stats.totalCaffeine),
                unit: 'mg',
                subtitle: stats.range.label(stats.period),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricTile(
                icon: Icons.show_chart_rounded,
                color: AppColors.orange,
                title: 'Günlük Ortalama',
                value: '$_periodDailyAverage',
                unit: 'mg',
                subtitle: 'İçilen gün başına',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricTile(
                icon: Icons.warning_amber_rounded,
                color: _overLimitDays > 0
                    ? const Color(0xFFE11D48)
                    : AppColors.green,
                title: 'Limit Aşımı',
                value: '$_overLimitDays',
                unit: 'gün',
                subtitle: 'En yüksek gün: ${stats.maxDailyCaffeine} mg',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.cardShadow,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  stats.range.previousLabel(stats.period),
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.subtitle,
                  ),
                ),
              ),
              TrendChip(
                percent: stats.previousActiveDays >= 3
                    ? stats.caffeineChangePercent
                    : null,
                lowerIsBetter: true,
                emptyLabel: 'Karşılaştırma için yeterli veri yok',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNote(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7EEF7)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.info_outline_rounded, size: 17, color: AppColors.subtitle),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Kafein değerleri ortalama referanslardır; demleme süresi ve '
              'porsiyona göre değişir. 400 mg/gün üst sınırı sağlıklı '
              'yetişkinler içindir, hamilelik veya kalp rahatsızlığında '
              'doktoruna danış. Bu uygulama tıbbi tavsiye vermez.',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.subtitle,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CaffeineGauge extends StatelessWidget {
  const _CaffeineGauge({
    required this.value,
    required this.color,
    required this.consumed,
    required this.limit,
  });

  final double value;
  final Color color;
  final int consumed;
  final int limit;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double progress, _) {
        return SizedBox(
          width: 118,
          height: 118,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              CustomPaint(
                size: const Size(118, 118),
                painter: _GaugePainter(progress: progress, color: color),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    '$consumed',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.heading,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    '/ $limit mg',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.subtitle,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2 - 8;
    final double stroke = 11;

    final Paint background = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFEFF2F6);
    canvas.drawCircle(center, radius, background);

    if (progress <= 0) {
      return;
    }

    final Paint foreground = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0.0, 1.0),
      false,
      foreground,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
