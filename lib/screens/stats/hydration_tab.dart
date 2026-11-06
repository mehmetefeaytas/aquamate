import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/models.dart';
import '../../services/period_stats_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/eco_widgets.dart';
import '../../widgets/period_bar_chart.dart';
import '../../widgets/section_card.dart';

/// İstatistik > Hidrasyon sekmesi.
class HydrationTab extends StatelessWidget {
  const HydrationTab({
    super.key,
    required this.stats,
    required this.onDeleteLog,
    required this.onToggleRecycled,
  });

  final PeriodStats stats;
  final ValueChanged<WaterLog> onDeleteLog;
  final ValueChanged<WaterLog> onToggleRecycled;

  double get _hydrationScore =>
      stats.totalRaw == 0 ? 0 : (stats.totalEffective / stats.totalRaw) * 100;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSummary(context),
        const SizedBox(height: 14),
        if (stats.period != PeriodType.today) ...<Widget>[
          SectionCard(
            title: stats.period == PeriodType.year
                ? 'Aylık Su Tüketimi'
                : 'Günlük Su Tüketimi',
            subtitle:
                'Net hidrasyon (ml) · kesikli çizgi günlük hedef (${formatMl(stats.goalMl)} ml)',
            child: PeriodBarChart(
              buckets: stats.buckets,
              valueOf: (ChartBucket b) => b.effective,
              goalValue: stats.goalMl,
            ),
          ),
          const SizedBox(height: 14),
        ],
        _buildDrinkDistribution(context),
        const SizedBox(height: 14),
        _buildGoalCard(context),
        const SizedBox(height: 20),
        Text(
          'Bugünkü Kayıtlar',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Kaydı sola kaydırarak silebilir, ♻ simgesine dokunarak geri '
          'dönüşüme attığını işaretleyebilirsin.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        _buildLogList(context),
      ],
    );
  }

  Widget _buildSummary(BuildContext context) {
    final NumberFormat liter = NumberFormat('0.0', 'tr_TR');
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: MetricTile(
                icon: Icons.timeline_rounded,
                color: AppColors.primary,
                title: stats.period == PeriodType.today
                    ? 'Bugünkü Toplam'
                    : 'Günlük Ortalama',
                value: formatMl(stats.dailyAverage),
                unit: 'ml',
                subtitle: '${stats.activeDays} aktif gün',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricTile(
                icon: Icons.water_drop_rounded,
                color: AppColors.accent,
                title: 'Toplam Tüketim',
                value: liter.format(stats.totalEffective / 1000),
                unit: 'L',
                subtitle: '${stats.logCount} kayıt',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricTile(
                icon: Icons.insights_rounded,
                color: AppColors.green,
                title: 'Hidrasyon Skoru',
                value: '%${_hydrationScore.round()}',
                subtitle: 'Net / brüt oran',
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
                    ? stats.hydrationChangePercent
                    : null,
                emptyLabel: 'Karşılaştırma için yeterli veri yok',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDrinkDistribution(BuildContext context) {
    if (stats.rawByDrink.isEmpty) {
      return SectionCard(
        title: 'İçecek Dağılımı',
        subtitle: 'Brüt tüketim (ml)',
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 22),
          alignment: Alignment.center,
          child: const Text(
            'Bu dönemde kayıt yok.\nAna sayfadan içecek ekleyerek başla.',
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

    final List<MapEntry<String, int>> entries =
        stats.rawByDrink.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final int total = entries.fold<int>(
      0,
      (int sum, MapEntry<String, int> e) => sum + e.value,
    );

    return SectionCard(
      title: 'İçecek Dağılımı',
      subtitle: 'Brüt tüketim (ml) · ${entries.length} farklı içecek',
      child: Column(
        children: <Widget>[
          for (final MapEntry<String, int> entry in entries.take(8))
            DistributionRow(
              color: drinkTypeOf(entry.key).color,
              icon: drinkTypeOf(entry.key).icon,
              label: entry.key,
              valueLabel:
                  '${formatMl(entry.value)} ml '
                  '(%${(entry.value / total * 100).round()})',
              fraction: entry.value / total,
            ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context) {
    final int rate = stats.goalRate;
    return SectionCard(
      title: 'Hedef Tutturma',
      subtitle:
          'Günlük ${formatMl(stats.goalMl)} ml hedefini tutturduğun günler',
      child: Row(
        children: <Widget>[
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (rate / 100).clamp(0.0, 1.0),
                minHeight: 12,
                backgroundColor: const Color(0xFFEFF5FB),
                valueColor: AlwaysStoppedAnimation<Color>(
                  rate >= 70 ? AppColors.green : AppColors.orange,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '%$rate',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.heading,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogList(BuildContext context) {
    if (stats.todayLogs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppColors.cardShadow,
        ),
        child: const Column(
          children: <Widget>[
            Icon(Icons.water_drop_rounded, size: 36, color: AppColors.accent),
            SizedBox(height: 10),
            Text(
              'Bugün henüz kayıt yok.\nAna sayfadan su ekleyerek başlayabilirsin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.subtitle,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    final List<WaterLog> sorted = List<WaterLog>.from(stats.todayLogs)
      ..sort((WaterLog a, WaterLog b) => a.createdAt.compareTo(b.createdAt));

    return Column(
      children: sorted.map<Widget>((WaterLog log) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _LogTile(
            log: log,
            onDelete: () => onDeleteLog(log),
            onToggleRecycled: () => onToggleRecycled(log),
          ),
        );
      }).toList(),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({
    required this.log,
    required this.onDelete,
    required this.onToggleRecycled,
  });

  final WaterLog log;
  final VoidCallback onDelete;
  final VoidCallback onToggleRecycled;

  @override
  Widget build(BuildContext context) {
    final DrinkType type = log.type;
    final ContainerType? container = containerOf(log.containerId);
    final bool showRecycle =
        container != null && !container.isReusable && container.recyclable;

    return Dismissible(
      key: ValueKey<int>(log.id ?? log.hashCode),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE7EA),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFE11D48),
              size: 22,
            ),
            SizedBox(width: 8),
            Text(
              'Sil',
              style: TextStyle(
                color: Color(0xFFE11D48),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: type.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(type.icon, color: type.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          type.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat.Hm('tr_TR').format(log.createdAt),
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.subtitle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '+${log.rawAmount} ml → Net: ${log.effectiveAmount} ml'
                    '${log.caffeineMg > 0 ? ' · ${log.caffeineMg} mg kafein' : ''}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.subtitle,
                    ),
                  ),
                  if (container != null) ...<Widget>[
                    const SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        Icon(container.icon, size: 13, color: container.color),
                        const SizedBox(width: 4),
                        Text(
                          container.shortLabel,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: container.color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (showRecycle)
              IconButton(
                onPressed: onToggleRecycled,
                tooltip: log.recycled
                    ? 'Geri dönüşüm işaretini kaldır'
                    : 'Geri dönüşüme attım',
                icon: Icon(
                  log.recycled
                      ? Icons.recycling_rounded
                      : Icons.recycling_outlined,
                  size: 20,
                ),
                color: log.recycled ? AppColors.green : AppColors.subtitle,
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '+${log.effectiveAmount}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
