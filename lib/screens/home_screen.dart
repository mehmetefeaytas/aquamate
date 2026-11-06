import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_info.dart';
import '../data/database_helper.dart';
import '../models/models.dart';
import '../services/drink_repository.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/container_picker_sheet.dart';
import '../widgets/eco_widgets.dart';
import '../widgets/wave_painter.dart';
import 'drink_library_screen.dart';

/// Ekran 1: Ana Sayfa - günlük giriş, motivasyon ve hızlı su ekleme.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserSettings _settings = UserSettings.defaults();
  List<WaterLog> _todayLogs = <WaterLog>[];
  int _streak = 0;
  DrinkType _selectedType = kDrinkTypes.first;
  bool _loading = true;
  bool _ecoBannerDismissed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await DrinkRepository.instance.ensureLoaded();
    final UserSettings settings = await DatabaseHelper.instance.getSettings();
    final List<WaterLog> logs = await DatabaseHelper.instance.logsForDay(
      DateTime.now(),
    );
    final int streak = await DatabaseHelper.instance.streakDays();
    if (!mounted) {
      return;
    }
    setState(() {
      _settings = settings;
      _todayLogs = logs;
      _streak = streak;
      _loading = false;
      // Seçili içecek silinmiş bir özel içecekse suya dön.
      if (!DrinkRepository.instance.all.any(
        (DrinkType t) => t.label == _selectedType.label,
      )) {
        _selectedType = kDrinkTypes.first;
      }
    });
  }

  int get _consumedMl => _todayLogs.fold<int>(
    0,
    (int sum, WaterLog log) => sum + log.effectiveAmount,
  );

  int get _goalMl => _settings.dailyGoal <= 0 ? 2500 : _settings.dailyGoal;

  double get _progress => (_consumedMl / _goalMl).clamp(0.0, 1.0);

  int get _caffeineMg =>
      _todayLogs.fold<int>(0, (int sum, WaterLog log) => sum + log.caffeineMg);

  EcoSummary get _ecoToday => EcoCalculator.summarize(_todayLogs);

  String get _dateText =>
      DateFormat('d MMMM y, EEEE', 'tr_TR').format(DateTime.now());

  String _motivationMessage(double value) {
    if (value >= 1) {
      return 'Tebrikler! Günlük hidrasyon hedefini başarıyla tamamladın!';
    }
    if (value > 0.60) {
      return 'Hedefe çok yaklaştın, son birkaç bardak kaldı!';
    }
    if (value > 0.25) {
      return 'Harika gidiyorsun! Beyin ve kas fonksiyonların şu an çok mutlu.';
    }
    return 'Güne enerjik başlamak için ilk bardak suyunu iç!';
  }

  Map<String, int> get _typeTotals {
    final Map<String, int> totals = <String, int>{};
    for (final WaterLog log in _todayLogs) {
      totals[log.drinkType] =
          (totals[log.drinkType] ?? 0) + log.effectiveAmount;
    }
    return totals;
  }

  /// Ekleme akışı: gerekirse kap sorar, sonra kaydeder.
  Future<void> _requestAdd(int rawMl, {DrinkType? type}) async {
    final DrinkType drink = type ?? _selectedType;

    String? containerId;
    if (_settings.askContainer) {
      final ContainerChoice? choice = await showContainerPicker(
        context,
        drinkLabel: drink.label,
        ml: rawMl,
        selectedId: _settings.lastContainerId ?? drink.defaultContainerId,
        askAgain: _settings.askContainer,
      );
      if (!mounted || choice == null) {
        return;
      }
      containerId = choice.container?.id;
      if (choice.remember) {
        final UserSettings updated = _settings.copyWith(
          askContainer: false,
          lastContainerId: containerId ?? _settings.lastContainerId,
        );
        await DatabaseHelper.instance.saveSettings(updated);
        if (!mounted) {
          return;
        }
        _settings = updated;
      } else if (containerId != null &&
          containerId != _settings.lastContainerId) {
        final UserSettings updated = _settings.copyWith(
          lastContainerId: containerId,
        );
        await DatabaseHelper.instance.saveSettings(updated);
        if (!mounted) {
          return;
        }
        _settings = updated;
      }
    } else {
      containerId = _settings.lastContainerId;
    }

    await _save(rawMl, drink, containerId);
  }

  Future<void> _save(int rawMl, DrinkType drink, String? containerId) async {
    final WaterLog log = WaterLog(
      drinkType: drink.label,
      rawAmount: rawMl,
      effectiveAmount: drink.effectiveOf(rawMl),
      caffeineMg: drink.caffeineOf(rawMl),
      containerId: containerId,
      createdAt: DateTime.now(),
    );
    await SoundService.playDrop();
    await DatabaseHelper.instance.insertLog(log);
    await _load();
    if (!mounted) {
      return;
    }
    final int netMl = log.effectiveAmount;
    final ContainerType? container = containerOf(containerId);
    String suffix = '';
    if (container != null) {
      suffix = container.isReusable
          ? ' · ${container.shortLabel} ♻'
          : ' · ${container.shortLabel}';
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '+${formatMl(rawMl)} ml ${drink.label} eklendi'
            '${netMl != rawMl ? ' (Net: $netMl ml)' : ''}$suffix',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<void> _openCustomAmountSheet() async {
    double value = 250;
    String? containerId = _settings.lastContainerId;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            final int amount = value.round();
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                8,
                24,
                28 + MediaQuery.paddingOf(context).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Özel Miktar Seç',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '50 ml - 1000 ml arasında seçim yapabilirsin.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Text(
                        '$amount ml',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Slider(
                    value: value,
                    min: 50,
                    max: 1000,
                    divisions: 19,
                    label: '$amount ml',
                    onChanged: (double next) =>
                        setSheetState(() => value = next),
                  ),
                  Row(
                    children: <Widget>[
                      Icon(
                        _selectedType.icon,
                        color: _selectedType.color,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_selectedType.label} (${_selectedType.factorLabel}) '
                          '-> Net: ${_selectedType.effectiveOf(amount)} ml',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text('Kap', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: kContainerTypes.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (BuildContext context, int index) {
                        final ContainerType container = kContainerTypes[index];
                        final bool selected = container.id == containerId;
                        return GestureDetector(
                          onTap: () =>
                              setSheetState(() => containerId = container.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? container.color.withValues(alpha: 0.16)
                                  : const Color(0xFFF4F8FC),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color: selected
                                    ? container.color
                                    : const Color(0xFFE7EEF7),
                                width: selected ? 1.6 : 1.1,
                              ),
                            ),
                            child: Row(
                              children: <Widget>[
                                Icon(
                                  container.icon,
                                  size: 15,
                                  color: container.color,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  container.shortLabel,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: selected
                                        ? AppColors.heading
                                        : AppColors.subtitle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextButton(
                        onPressed: () async {
                          Navigator.of(sheetContext).pop();
                          await _save(amount, _selectedType, containerId);
                        },
                        child: const Text(
                          'Kaydet ve Ekle',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (!mounted) {
      return;
    }
    await _load();
  }

  Future<void> _openLibrary() async {
    final DrinkType? picked = await Navigator.of(context).push<DrinkType>(
      MaterialPageRoute<DrinkType>(
        builder: (BuildContext context) => const DrinkLibraryScreen(),
      ),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _selectedType = picked);
    await DrinkRepository.instance.reload();
    if (mounted) {
      setState(
        () => _selectedType = DrinkRepository.instance.byLabel(picked.label),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final double bottomInset = MediaQuery.paddingOf(context).bottom;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 100 + bottomInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildHeader(),
          const SizedBox(height: 18),
          _buildMotivationCard(),
          const SizedBox(height: 26),
          _buildSphereSection(),
          const SizedBox(height: 18),
          _buildInsightRow(),
          const SizedBox(height: 18),
          if (_ecoToday.unmarkedLogs > 0 && !_ecoBannerDismissed) ...<Widget>[
            _buildRecyclingBanner(),
            const SizedBox(height: 18),
          ],
          Text(
            'İçecek Türü Seç',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _buildDrinkSelector(),
          const SizedBox(height: 24),
          Text('Hızlı Ekle', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _buildQuickAddRow(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                AppInfo.greeting(_settings.displayName),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(_dateText, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            gradient: AppColors.warmGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.orange.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.local_fire_department_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                '$_streak Günlük Seri',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMotivationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.30),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _motivationMessage(_consumedMl / _goalMl),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.28),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Hedef: ${formatMl(_goalMl)} ml',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '%${(_progress * 100).round()} tamamlandı',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSphereSection() {
    final int remaining = _goalMl - _consumedMl;
    return Column(
      children: <Widget>[
        Text(
          'Bugünkü Hidrasyon',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 18),
        Center(
          child: WaveSphere(
            typeTotals: _typeTotals,
            consumedMl: _consumedMl,
            goalMl: _goalMl,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColors.cardShadow,
            border: Border.all(color: const Color(0xFFE4EDF7), width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                remaining <= 0
                    ? Icons.check_circle_rounded
                    : Icons.water_drop_rounded,
                size: 16,
                color: remaining <= 0 ? AppColors.green : AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                remaining > 0
                    ? 'Hedefe ${formatMl(remaining)} ml kaldı  •  Hedef: ${formatMl(_goalMl)} ml'
                    : 'Hedef tamamlandı, harikasın!  •  ${formatMl(_goalMl)} ml',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.heading,
                ),
              ),
            ],
          ),
        ),
        if (_typeTotals.isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: <Widget>[
              for (final DrinkType type in DrinkRepository.instance.all)
                if ((_typeTotals[type.label] ?? 0) > 0)
                  _LegendChip(
                    color: type.color,
                    label: type.shortLabel,
                    percent: ((_typeTotals[type.label] ?? 0) / _goalMl * 100)
                        .round(),
                  ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildInsightRow() {
    final CaffeineStatus status = CaffeineCalculator.status(
      consumedMg: _caffeineMg,
      limitMg: _settings.caffeineLimitMg,
    );
    final Color caffeineColor = switch (status) {
      CaffeineStatus.low => AppColors.green,
      CaffeineStatus.moderate => AppColors.primary,
      CaffeineStatus.high => AppColors.orange,
      CaffeineStatus.exceeded => const Color(0xFFE11D48),
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: _MiniInsightCard(
              icon: Icons.coffee_rounded,
              color: caffeineColor,
              title: 'Kafein',
              value: '$_caffeineMg',
              unit: '/ ${_settings.caffeineLimitMg} mg',
              progress: (_caffeineMg / _settings.caffeineLimitMg).clamp(
                0.0,
                1.0,
              ),
              caption: status.label,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MiniInsightCard(
              icon: Icons.eco_rounded,
              color: _ecoToday.score >= 60 ? AppColors.green : AppColors.orange,
              title: 'Sürdürülebilirlik',
              value: '${_ecoToday.score}',
              unit: '/100',
              progress: _ecoToday.score / 100,
              caption: _ecoToday.isEmpty
                  ? 'Kap seçilmedi'
                  : '${formatGrams(_ecoToday.wasteGrams)} atık',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecyclingBanner() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFA7F3D0), width: 1.2),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.recycling_rounded, color: AppColors.green, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Geri dönüşümü unutma',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.heading,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Bugün ${_ecoToday.unmarkedLogs} tek kullanımlık ambalaj '
                  'işaretsiz. İstatistik > Eko bölümünden işaretleyebilirsin.',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.subtitle,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _ecoBannerDismissed = true),
            icon: const Icon(Icons.close_rounded, size: 18),
            color: AppColors.subtitle,
          ),
        ],
      ),
    );
  }

  Widget _buildDrinkSelector() {
    final List<DrinkType> types = DrinkRepository.instance.all;
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: types.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (BuildContext context, int index) {
          if (index == types.length) {
            return GestureDetector(
              onTap: _openLibrary,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    width: 1.4,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.apps_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 7),
                    Text(
                      'Tümü',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final DrinkType type = types[index];
          final bool selected = type.label == _selectedType.label;
          return GestureDetector(
            onTap: () => setState(() => _selectedType = type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: selected ? AppColors.primaryGradient : null,
                color: selected ? null : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? Colors.transparent
                      : const Color(0xFFE3ECF7),
                  width: 1.4,
                ),
                boxShadow: selected
                    ? AppColors.cardShadow
                    : const <BoxShadow>[],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    type.icon,
                    size: 18,
                    color: selected ? Colors.white : type.color,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    '${type.label} (${type.factorLabel})',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : AppColors.subtitle,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickAddRow() {
    final List<_QuickAmount> amounts = <_QuickAmount>[
      const _QuickAmount(
        ml: 200,
        label: 'Su Bardağı',
        icon: Icons.local_cafe_rounded,
      ),
      const _QuickAmount(
        ml: 330,
        label: 'Şişe',
        icon: Icons.local_drink_rounded,
      ),
      const _QuickAmount(
        ml: 500,
        label: 'Matara',
        icon: Icons.sports_bar_rounded,
      ),
    ];

    return Row(
      children: <Widget>[
        for (final _QuickAmount amount in amounts) ...<Widget>[
          Expanded(
            child: _QuickAddCard(
              icon: amount.icon,
              amountText: '${amount.ml}',
              label: amount.label,
              onTap: () => _requestAdd(amount.ml),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: _QuickAddCard(
            icon: Icons.tune_rounded,
            amountText: 'Özel',
            label: 'Miktar',
            highlighted: true,
            onTap: _openCustomAmountSheet,
          ),
        ),
      ],
    );
  }
}

class _QuickAmount {
  const _QuickAmount({
    required this.ml,
    required this.label,
    required this.icon,
  });

  final int ml;
  final String label;
  final IconData icon;
}

/// Ana sayfadaki kafein / sürdürülebilirlik mini kartı.
class _MiniInsightCard extends StatelessWidget {
  const _MiniInsightCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.unit,
    required this.progress,
    required this.caption,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String unit;
  final double progress;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.subtitle,
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
                  TextSpan(
                    text: ' $unit',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: const Color(0xFFEDF4FB),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.subtitle,
            ),
          ),
        ],
      ),
    );
  }
}

/// Küre altındaki içecek türü legend çipi.
class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.color,
    required this.label,
    required this.percent,
  });

  final Color color;
  final String label;
  final int percent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          '$label %$percent',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.subtitle,
          ),
        ),
      ],
    );
  }
}

class _QuickAddCard extends StatelessWidget {
  const _QuickAddCard({
    required this.icon,
    required this.amountText,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String amountText;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          height: 104,
          decoration: BoxDecoration(
            gradient: highlighted ? AppColors.primaryGradient : null,
            color: highlighted ? null : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                size: 24,
                color: highlighted ? Colors.white : AppColors.primary,
              ),
              const SizedBox(height: 8),
              Text(
                amountText,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: highlighted ? Colors.white : AppColors.heading,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: highlighted
                      ? Colors.white.withValues(alpha: 0.9)
                      : AppColors.subtitle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
