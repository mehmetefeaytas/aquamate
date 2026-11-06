import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../models/models.dart';
import '../services/period_stats_service.dart';
import '../theme/app_theme.dart';
import '../widgets/eco_widgets.dart';
import 'stats/caffeine_tab.dart';
import 'stats/eco_tab.dart';
import 'stats/hydration_tab.dart';

/// Ekran 2: İstatistikler - hidrasyon, kafein ve sürdürülebilirlik.
class StatsScreen extends StatefulWidget {
  const StatsScreen({
    super.key,
    this.initialTab = 0,
    this.initialPeriod = PeriodType.week,
  });

  /// Açılıştaki alt sekme (0: Hidrasyon, 1: Kafein, 2: Eko).
  final int initialTab;

  /// Açılıştaki dönem.
  final PeriodType initialPeriod;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  static const List<_TabSpec> _tabs = <_TabSpec>[
    _TabSpec(
      label: 'Hidrasyon',
      icon: Icons.water_drop_rounded,
      color: AppColors.primary,
    ),
    _TabSpec(
      label: 'Kafein',
      icon: Icons.coffee_rounded,
      color: Color(0xFF8B5E34),
    ),
    _TabSpec(label: 'Eko', icon: Icons.eco_rounded, color: AppColors.green),
  ];

  late PeriodType _period = widget.initialPeriod;
  late int _tab = widget.initialTab;
  UserSettings _settings = UserSettings.defaults();
  PeriodStats? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final UserSettings settings = await DatabaseHelper.instance.getSettings();
    final PeriodStats stats = await PeriodStatsService.load(
      period: _period,
      goalMl: settings.dailyGoal,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _settings = settings;
      _stats = stats;
      _loading = false;
    });
  }

  Future<void> _reloadQuietly() async {
    final UserSettings settings = await DatabaseHelper.instance.getSettings();
    final PeriodStats stats = await PeriodStatsService.load(
      period: _period,
      goalMl: settings.dailyGoal,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _settings = settings;
      _stats = stats;
    });
  }

  Future<void> _changePeriod(PeriodType period) async {
    if (period == _period) {
      return;
    }
    setState(() {
      _period = period;
      _loading = true;
    });
    await _load();
  }

  Future<void> _deleteLog(WaterLog log) async {
    if (log.id != null) {
      await DatabaseHelper.instance.deleteLog(log.id!);
    }
    await _reloadQuietly();
  }

  Future<void> _toggleRecycled(WaterLog log) async {
    if (log.id == null) {
      return;
    }
    await DatabaseHelper.instance.setRecycled(log.id!, !log.recycled);
    await _reloadQuietly();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text(
            log.recycled
                ? 'Geri dönüşüm işareti kaldırıldı'
                : 'Geri dönüşüme atıldı olarak işaretlendi ♻',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 100 + bottomInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'İstatistikler',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            _stats == null
                ? 'Hidrasyon, kafein ve sürdürülebilirlik'
                : '${_stats!.range.label(_period)} · '
                      '${_stats!.activeDays} aktif gün',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          PeriodSelector(selected: _period, onChanged: _changePeriod),
          const SizedBox(height: 14),
          _buildTabBar(),
          const SizedBox(height: 18),
          if (_loading || _stats == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: KeyedSubtree(
                key: ValueKey<String>('${_period.name}-$_tab'),
                child: _buildContent(_stats!),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(PeriodStats stats) {
    switch (_tab) {
      case 1:
        return CaffeineTab(stats: stats, settings: _settings);
      case 2:
        return EcoTab(stats: stats);
      case 0:
      default:
        return HydrationTab(
          stats: stats,
          onDeleteLog: _deleteLog,
          onToggleRecycled: _toggleRecycled,
        );
    }
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F1FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          for (int i = 0; i < _tabs.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _tab = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _tab == i ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _tab == i
                        ? <BoxShadow>[
                            BoxShadow(
                              color: _tabs[i].color.withValues(alpha: 0.18),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : const <BoxShadow>[],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        _tabs[i].icon,
                        size: 16,
                        color: _tab == i ? _tabs[i].color : AppColors.subtitle,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _tabs[i].label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _tab == i
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: _tab == i
                              ? _tabs[i].color
                              : AppColors.subtitle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}
