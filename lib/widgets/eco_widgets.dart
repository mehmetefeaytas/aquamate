import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

/// Dönem seçici: Bugün / Hafta / Ay / Yıl.
class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final PeriodType selected;
  final ValueChanged<PeriodType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F1FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          for (final PeriodType period in PeriodType.values)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(period),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: period == selected
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: period == selected
                        ? <BoxShadow>[
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.18),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : const <BoxShadow>[],
                  ),
                  child: Text(
                    period.label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: period == selected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: period == selected
                          ? AppColors.primary
                          : AppColors.subtitle,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 0-100 arası eko skorunu halka olarak gösterir.
class EcoScoreRing extends StatelessWidget {
  const EcoScoreRing({
    super.key,
    required this.score,
    required this.grade,
    this.size = 132,
    this.caption = 'Eko skoru',
  });

  final int score;
  final String grade;
  final double size;
  final String caption;

  Color get _color {
    if (score >= 80) {
      return AppColors.green;
    }
    if (score >= 60) {
      return const Color(0xFF22C55E).withValues(alpha: 0.85);
    }
    if (score >= 40) {
      return AppColors.orange;
    }
    return const Color(0xFFE11D48);
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: (score / 100).clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double value, _) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              CustomPaint(
                size: Size(size, size),
                painter: _RingPainter(progress: value, color: _color),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    '$score',
                    style: TextStyle(
                      fontSize: size * 0.26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.heading,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    '/100 · $grade',
                    style: TextStyle(
                      fontSize: size * 0.10,
                      fontWeight: FontWeight.w700,
                      color: _color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    caption,
                    style: TextStyle(
                      fontSize: size * 0.082,
                      fontWeight: FontWeight.w600,
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

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2 - 9;
    final double stroke = 12;

    final Paint background = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFE6EEF8);
    canvas.drawCircle(center, radius, background);

    if (progress <= 0) {
      return;
    }

    final Paint foreground = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + math.pi * 2,
        colors: <Color>[color.withValues(alpha: 0.65), color],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      foreground,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// Değer + birim + alt açıklama gösteren küçük metrik kutusu.
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    this.unit = '',
    this.subtitle,
    this.highlight = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String unit;
  final String? subtitle;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight ? color.withValues(alpha: 0.08) : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlight
              ? color.withValues(alpha: 0.35)
              : const Color(0xFFEAF1F9),
          width: 1.2,
        ),
        boxShadow: highlight ? const <BoxShadow>[] : AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.subtitle,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                text: value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.heading,
                  letterSpacing: -0.5,
                ),
                children: <InlineSpan>[
                  if (unit.isNotEmpty)
                    TextSpan(
                      text: ' $unit',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: 3),
            Text(
              subtitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.subtitle,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Önceki döneme göre değişim çipi. [lowerIsBetter] eko/atık için `true`.
class TrendChip extends StatelessWidget {
  const TrendChip({
    super.key,
    required this.percent,
    this.lowerIsBetter = false,
    this.emptyLabel = 'Karşılaştırma yok',
  });

  final int? percent;
  final bool lowerIsBetter;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final int? value = percent;
    if (value == null) {
      return Text(
        emptyLabel,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.subtitle,
        ),
      );
    }

    final bool up = value >= 0;
    final bool good = lowerIsBetter ? !up : up;
    final Color color = value == 0
        ? AppColors.subtitle
        : (good ? AppColors.green : const Color(0xFFE11D48));
    final IconData icon = value == 0
        ? Icons.remove_rounded
        : (up ? Icons.trending_up_rounded : Icons.trending_down_rounded);

    // Aşırı büyük yüzdeler (küçük taban dönemler) okunaksız olmasın.
    final String label = value.abs() > 999 ? '%999+' : '%${value.abs()}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kap dağılımı donut grafiği + efsane.
class ContainerDonut extends StatelessWidget {
  const ContainerDonut({super.key, required this.usages});

  final List<ContainerUsage> usages;

  @override
  Widget build(BuildContext context) {
    if (usages.isEmpty) {
      return const SizedBox(
        height: 160,
        child: Center(
          child: Text(
            'Bu dönemde ambalaj verisi yok.\nİçecek eklerken kabını seç.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.subtitle,
              height: 1.5,
            ),
          ),
        ),
      );
    }

    final int total = usages.fold<int>(
      0,
      (int s, ContainerUsage u) => s + u.ml,
    );

    return Column(
      children: <Widget>[
        SizedBox(
          height: 170,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 44,
              sections: <PieChartSectionData>[
                for (final ContainerUsage usage in usages)
                  PieChartSectionData(
                    value: usage.ml.toDouble(),
                    color: usage.container.color,
                    radius: 22,
                    showTitle: false,
                    borderSide: const BorderSide(color: Colors.white, width: 2),
                  ),
              ],
            ),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: <Widget>[
            for (final ContainerUsage usage in usages)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: usage.container.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${usage.container.shortLabel} '
                    '%${(usage.ml / total * 100).round()}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.subtitle,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

/// Gram / kg biçimlendirme.
String formatGrams(double grams) {
  if (grams >= 1000) {
    return '${NumberFormat('0.00', 'tr_TR').format(grams / 1000)} kg';
  }
  return '${NumberFormat('#,##0', 'tr_TR').format(grams.round())} g';
}

/// Ağırlıklı sayı biçimlendirme (ml -> L).
String formatLiters(int ml) {
  if (ml >= 1000) {
    return '${NumberFormat('0.0', 'tr_TR').format(ml / 1000)} L';
  }
  return '$ml ml';
}
