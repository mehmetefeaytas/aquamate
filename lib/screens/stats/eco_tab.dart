import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/period_stats_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/eco_widgets.dart';
import '../../widgets/section_card.dart';

/// İstatistik > Eko (sürdürülebilirlik) sekmesi.
class EcoTab extends StatelessWidget {
  const EcoTab({super.key, required this.stats});

  final PeriodStats stats;

  EcoSummary get _eco => stats.eco;

  @override
  Widget build(BuildContext context) {
    final EcoSummary eco = _eco;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildScoreCard(context),
        const SizedBox(height: 14),
        _buildMetrics(context),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Kap Dağılımı',
          subtitle: 'Hacme göre hangi kapta ne kadar içtin',
          child: ContainerDonut(usages: eco.usages),
        ),
        const SizedBox(height: 14),
        _buildRecyclingCard(context),
        const SizedBox(height: 14),
        _buildReportCard(context),
        if (eco.bestCaseWasteSavedGrams > 0.5) ...<Widget>[
          const SizedBox(height: 14),
          _buildSavingsCard(context),
        ],
        const SizedBox(height: 14),
        _buildNote(context),
      ],
    );
  }

  Widget _buildScoreCard(BuildContext context) {
    final EcoSummary eco = _eco;
    final int? change = stats.previousActiveDays >= 3
        ? EcoSummary.wasteChangePercent(eco, stats.previousEco)
        : null;

    return SectionCard(
      title: 'Sürdürülebilirlik Skoru',
      subtitle: 'Hacme göre ağırlıklı kap puanı (0-100)',
      child: Row(
        children: <Widget>[
          EcoScoreRing(score: eco.score, grade: eco.grade, size: 124),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Text(
                      'Tekrar kullanılabilir',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.subtitle,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '%${eco.reusablePercent}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.heading,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: eco.reusablePercent / 100,
                    minHeight: 7,
                    backgroundColor: const Color(0xFFEFF5FB),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.green,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  stats.range.previousLabel(stats.period),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.subtitle,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    TrendChip(
                      percent: change,
                      lowerIsBetter: true,
                      emptyLabel: 'Yeterli veri yok',
                    ),
                    if (change != null) ...<Widget>[
                      const SizedBox(width: 6),
                      const Flexible(
                        child: Text(
                          'atık',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.subtitle,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetrics(BuildContext context) {
    final EcoSummary eco = _eco;
    return Row(
      children: <Widget>[
        Expanded(
          child: MetricTile(
            icon: Icons.delete_outline_rounded,
            color: AppColors.orange,
            title: 'Ambalaj Atığı',
            value: formatGrams(eco.wasteGrams),
            subtitle: '${eco.singleUseLogs} tek kullanımlık',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: MetricTile(
            icon: Icons.cloud_outlined,
            color: const Color(0xFF0EA5E9),
            title: 'Karbon Ayak İzi',
            value: formatGrams(eco.co2Grams),
            unit: 'CO₂e',
            subtitle: eco.recyclingCreditGrams > 0
                ? 'Geri dönüşümle ${formatGrams(eco.recyclingCreditGrams)} azaldı'
                : 'Ambalaj kaynaklı',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: MetricTile(
            icon: Icons.recycling_rounded,
            color: AppColors.green,
            title: 'Geri Dönüşüm',
            value: '${eco.recycledLogs}',
            unit: 'kayıt',
            subtitle: eco.unmarkedLogs > 0
                ? '${eco.unmarkedLogs} işaretsiz'
                : 'Hepsi işaretli',
          ),
        ),
      ],
    );
  }

  Widget _buildRecyclingCard(BuildContext context) {
    final EcoSummary eco = _eco;
    if (eco.singleUseLogs == 0) {
      return SectionCard(
        title: 'Geri Dönüşüm Durumu',
        subtitle: 'Tek kullanımlık ambalaj kullanmadın',
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: <Widget>[
              Icon(Icons.verified_rounded, color: AppColors.green, size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tüm içecekleri tekrar kullanılabilir kaplarla içmişsin.',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.subtitle,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final List<_RecycleRowData> rows = <_RecycleRowData>[
      _RecycleRowData(
        icon: Icons.recycling_rounded,
        color: AppColors.green,
        label: 'Geri dönüşüme atıldı',
        count: eco.recycledLogs,
        total: eco.singleUseLogs,
      ),
      if (eco.unmarkedLogs > 0)
        _RecycleRowData(
          icon: Icons.help_outline_rounded,
          color: AppColors.orange,
          label: 'İşaretlenmedi',
          count: eco.unmarkedLogs,
          total: eco.singleUseLogs,
        ),
      _RecycleRowData(
        icon: Icons.delete_forever_rounded,
        color: const Color(0xFFE11D48),
        label: 'Geri dönüştürülemez',
        count: eco.trashedLogs - eco.unmarkedLogs,
        total: eco.singleUseLogs,
      ),
    ];

    return SectionCard(
      title: 'Geri Dönüşüm Durumu',
      subtitle: '${eco.singleUseLogs} tek kullanımlık ambalaj kaydı',
      child: Column(
        children: <Widget>[
          for (final _RecycleRowData row in rows)
            if (row.count > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: <Widget>[
                    Icon(row.icon, size: 17, color: row.color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        row.label,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.heading,
                        ),
                      ),
                    ),
                    Text(
                      '${row.count}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: row.color,
                      ),
                    ),
                  ],
                ),
              ),
          if (eco.unmarkedLogs > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.recycling_rounded,
                    size: 17,
                    color: AppColors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${eco.unmarkedLogs} ambalajı geri dönüşüme atmayı '
                      'unutma. Hidrasyon sekmesindeki kayıtlardan ♻ ile '
                      'işaretleyebilirsin.',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF9A3412),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReportCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF065F46), Color(0xFF10B981)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.green.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${stats.range.label(stats.period)} raporu',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            EcoNarrative.build(_eco, stats.range.label(stats.period)),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsCard(BuildContext context) {
    final EcoSummary eco = _eco;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.cardShadow,
        border: Border.all(color: const Color(0xFFD1FAE5), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Şunu tercih etseydin',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.heading,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Tek kullanımlık kaplardaki ${formatMl(eco.singleUseMl)} içeceği '
            'mataranla içseydin:',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.subtitle,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _SavingValue(
                  value: formatGrams(eco.bestCaseWasteSavedGrams),
                  label: 'daha az atık',
                  icon: Icons.delete_outline_rounded,
                ),
              ),
              Container(width: 1, height: 44, color: const Color(0xFFE7EEF7)),
              Expanded(
                child: _SavingValue(
                  value: formatGrams(eco.bestCaseCo2SavedGrams),
                  label: 'daha az CO₂e',
                  icon: Icons.cloud_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
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
              'Atık ve CO₂e değerleri 500 ml referans hacme göre yaklaşık '
              'yaşam döngüsü tahminleridir. Amaç kesin muhasebe değil, '
              'seçimlerinin etkisini görünür kılmaktır.',
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

class _RecycleRowData {
  const _RecycleRowData({
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
    required this.total,
  });

  final IconData icon;
  final Color color;
  final String label;
  final int count;
  final int total;
}

class _SavingValue extends StatelessWidget {
  const _SavingValue({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Icon(icon, size: 18, color: AppColors.green),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.heading,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: AppColors.subtitle,
          ),
        ),
      ],
    );
  }
}
