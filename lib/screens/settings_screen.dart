import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/app_info.dart';
import '../data/database_helper.dart';
import '../models/models.dart';
import '../services/drink_repository.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'about_screen.dart';
import 'drink_library_screen.dart';

/// Ekran 4: Hedef, kafein, sürdürülebilirlik ve hatırlatıcı ayarları.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserSettings _settings = UserSettings.defaults();
  double _weight = 70;
  double _activity = 30;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await DrinkRepository.instance.ensureLoaded();
    final UserSettings settings = await DatabaseHelper.instance.getSettings();
    if (!mounted) {
      return;
    }
    setState(() {
      _settings = settings;
      _weight = settings.weight.toDouble();
      _activity = settings.activityMinutes.toDouble();
      _loading = false;
    });
  }

  int get _suggestedGoal => GoalCalculator.calculate(
    weight: _weight.round(),
    activityMinutes: _activity.round(),
  );

  void _snack(String message, {IconData icon = Icons.check_circle_rounded}) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          content: Row(
            children: <Widget>[
              Icon(icon, color: AppColors.accent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  Future<void> _saveGoal() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    final UserSettings updated = _settings.copyWith(
      weight: _weight.round(),
      activityMinutes: _activity.round(),
      dailyGoal: _suggestedGoal,
    );
    await DatabaseHelper.instance.saveSettings(updated);
    if (updated.notificationsEnabled) {
      await NotificationService.scheduleRecurring(
        intervalHours: updated.reminderInterval,
        dailyGoalMl: updated.dailyGoal,
      );
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _settings = updated;
      _busy = false;
    });
    _snack('Günlük hedef güncellendi: ${formatMl(updated.dailyGoal)} ml');
  }

  Future<void> _toggleNotifications(bool enabled) async {
    bool granted = enabled;
    if (enabled) {
      granted = await NotificationService.requestPermission();
    }

    final UserSettings updated = _settings.copyWith(
      notificationsEnabled: granted,
    );
    await DatabaseHelper.instance.saveSettings(updated);

    if (granted) {
      await NotificationService.scheduleRecurring(
        intervalHours: updated.reminderInterval,
        dailyGoalMl: updated.dailyGoal,
      );
    } else {
      await NotificationService.cancelScheduled();
    }

    if (!mounted) {
      return;
    }
    setState(() => _settings = updated);
    _snack(
      granted
          ? 'Hatırlatıcı açıldı: her ${updated.reminderInterval} saatte bir'
          : 'Hatırlatıcı kapatıldı',
      icon: granted
          ? Icons.notifications_active_rounded
          : Icons.notifications_off_rounded,
    );
  }

  Future<void> _changeInterval(int hours) async {
    final UserSettings updated = _settings.copyWith(reminderInterval: hours);
    await DatabaseHelper.instance.saveSettings(updated);
    if (updated.notificationsEnabled) {
      await NotificationService.scheduleRecurring(
        intervalHours: hours,
        dailyGoalMl: updated.dailyGoal,
      );
    }
    if (!mounted) {
      return;
    }
    setState(() => _settings = updated);
    _snack('Hatırlatma sıklığı: $hours saat', icon: Icons.schedule_rounded);
  }

  Future<void> _saveCaffeine({int? limitMg, int? bedtimeMinutes}) async {
    final UserSettings updated = _settings.copyWith(
      caffeineLimitMg: limitMg,
      bedtimeMinutes: bedtimeMinutes,
    );
    await DatabaseHelper.instance.saveSettings(updated);
    if (!mounted) {
      return;
    }
    setState(() => _settings = updated);
  }

  Future<void> _pickBedtime() async {
    final TimeOfDay initial = TimeOfDay(
      hour: _settings.bedtimeMinutes ~/ 60,
      minute: _settings.bedtimeMinutes % 60,
    );
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: 'Uyku saatin',
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked == null) {
      return;
    }
    await _saveCaffeine(bedtimeMinutes: picked.hour * 60 + picked.minute);
    _snack(
      'Uyku saati ${_settings.bedtimeLabel} olarak kaydedildi',
      icon: Icons.bedtime_rounded,
    );
  }

  Future<void> _toggleEcoReminder(bool enabled) async {
    final UserSettings updated = _settings.copyWith(
      ecoReminderEnabled: enabled,
    );
    await DatabaseHelper.instance.saveSettings(updated);
    await NotificationService.scheduleEcoReminder(enabled: enabled);
    await NotificationService.scheduleWeeklyEcoSummary(enabled: enabled);
    if (!mounted) {
      return;
    }
    setState(() => _settings = updated);
    _snack(
      enabled
          ? 'Akşam 21:00 geri dönüşüm hatırlatması açıldı'
          : 'Sürdürülebilirlik hatırlatmaları kapatıldı',
      icon: Icons.eco_rounded,
    );
  }

  Future<void> _toggleAskContainer(bool enabled) async {
    final UserSettings updated = _settings.copyWith(askContainer: enabled);
    await DatabaseHelper.instance.saveSettings(updated);
    if (!mounted) {
      return;
    }
    setState(() => _settings = updated);
    _snack(
      enabled
          ? 'Her içecekte kap sorulacak'
          : 'Son seçtiğin kap otomatik kullanılacak',
      icon: Icons.local_drink_rounded,
    );
  }

  Future<void> _setDefaultContainer(String? id) async {
    final UserSettings updated = _settings.copyWith(lastContainerId: id);
    await DatabaseHelper.instance.saveSettings(updated);
    if (!mounted) {
      return;
    }
    setState(() => _settings = updated);
  }

  Future<void> _openLibrary() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            const DrinkLibraryScreen(pickMode: false),
      ),
    );
    await _load();
  }

  Future<void> _openAbout() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const AboutScreen(),
      ),
    );
  }

  Future<void> _sendTestNotification() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    final bool granted = await NotificationService.requestPermission();
    await NotificationService.showNow(
      title: 'AquaMate su hatırlatması',
      body:
          'Günlük hedefiniz ${formatMl(_settings.dailyGoal)} ml. Şimdi bir bardak su içme zamanı!',
    );
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    _snack(
      granted
          ? 'Test bildirimi gönderildi (önizleme ekranda)'
          : 'Bildirim izni verilmedi, yine de önizleme gösterildi',
      icon: Icons.notifications_active_rounded,
    );
  }

  Future<void> _openDataTools() async {
    final String? action = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Geliştirici Veri Araçları'),
          content: const Text(
            'Yalnızca geliştirme ve sunum derlemelerinde görünür. Grafik ve '
            'listeleri test etmek için örnek veri ekleyebilir veya tüm '
            'kayıtları temizleyebilirsin.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop('reset'),
              child: const Text(
                'Temizle',
                style: TextStyle(
                  color: Color(0xFFE11D48),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop('add'),
              child: const Text('Örnek Veri Ekle'),
            ),
          ],
        );
      },
    );

    if (!mounted || action == null) {
      return;
    }

    setState(() => _busy = true);
    if (action == 'add') {
      await DatabaseHelper.instance.addSampleData();
    } else {
      await DatabaseHelper.instance.clearAllLogs();
    }
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    _snack(
      action == 'add'
          ? 'Örnek veriler veritabanına eklendi'
          : 'Tüm kayıtlar temizlendi',
      icon: Icons.storage_rounded,
    );
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
          Text('Ayarlar', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Hedefini, kafein limitini ve tercihlerini kişiselleştir',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          _buildProfileCard(),
          const SizedBox(height: 16),
          _buildGoalCalculator(),
          const SizedBox(height: 16),
          _buildCaffeineCard(),
          const SizedBox(height: 16),
          _buildSustainabilityCard(),
          const SizedBox(height: 16),
          _buildReminderCard(),
          const SizedBox(height: 16),
          _buildDrinkLibraryCard(),
          const SizedBox(height: 16),
          _buildAboutCard(),
          if (kDebugMode) ...<Widget>[
            const SizedBox(height: 16),
            _buildDebugCard(),
          ],
          const SizedBox(height: 20),
          Center(
            child: Text(
              '${AppInfo.name} ${AppInfo.versionLabel} · Yerel SQLite veritabanı',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  /// Görünen adı düzenleme penceresi.
  Future<void> _editName() async {
    final TextEditingController controller = TextEditingController(
      text: _settings.displayName ?? '',
    );
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Adın'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 24,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Adın',
              counterText: '',
            ),
            onSubmitted: (String value) =>
                Navigator.of(dialogContext).pop(value),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (result == null) {
      return;
    }

    final UserSettings updated = _settings.copyWith(
      userName: result.trim().isEmpty ? '' : result.trim(),
    );
    await DatabaseHelper.instance.saveSettings(updated);
    if (!mounted) {
      return;
    }
    setState(() => _settings = updated);
    _snack(
      updated.displayName == null
          ? 'Ad kaldırıldı, selamlama sade kalacak'
          : 'Merhaba, ${updated.displayName}!',
      icon: Icons.person_rounded,
    );
  }

  Widget _buildProfileCard() {
    final String? name = _settings.displayName;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _editName,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  name == null ? '?' : name.characters.first.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      name ?? 'Adını ekle',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.heading,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name == null
                          ? 'Ana sayfada seni adınla karşılayalım'
                          : 'Ana sayfada "Merhaba, $name" olarak görünür',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.subtitle,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.edit_outlined,
                size: 18,
                color: AppColors.subtitle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalCalculator() {
    return _SettingsCard(
      icon: Icons.monitor_weight_rounded,
      color: AppColors.primary,
      title: 'Akıllı Hedef Hesaplayıcı',
      subtitle: 'Kilo ve egzersize göre günlük hedefini otomatik hesapla',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SliderRow(
            label: 'Kilonuz',
            valueLabel: '${_weight.round()} kg',
            icon: Icons.monitor_weight_rounded,
            value: _weight,
            min: 40,
            max: 150,
            divisions: 110,
            onChanged: (double v) => setState(() => _weight = v),
          ),
          const SizedBox(height: 6),
          _SliderRow(
            label: 'Günlük Egzersiz',
            valueLabel: '${_activity.round()} dk',
            icon: Icons.directions_run_rounded,
            value: _activity,
            min: 0,
            max: 120,
            divisions: 24,
            onChanged: (double v) => setState(() => _activity = v),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F7FE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Kilo × 35 ml + (Egzersiz Dakikası / 30) × 350 ml',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Önerilen günlük hedef',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.subtitle,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${formatMl(_suggestedGoal)} ml',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Kayıtlı: ${formatMl(_settings.dailyGoal)} ml',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.subtitle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _GradientButton(
            label: 'Hedefi Kaydet ve Uygula',
            busy: _busy,
            onPressed: _saveGoal,
          ),
        ],
      ),
    );
  }

  Widget _buildCaffeineCard() {
    final String cutoff = CaffeineCalculator.cutoffLabel(
      _settings.bedtimeMinutes,
    );
    return _SettingsCard(
      icon: Icons.coffee_rounded,
      color: const Color(0xFF8B5E34),
      title: 'Kafein Takibi',
      subtitle: 'Günlük üst sınır ve uyku saatine göre öneri',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Günlük kafein limiti',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.heading,
                  ),
                ),
              ),
              Text(
                '${_settings.caffeineLimitMg} mg',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF8B5E34),
                ),
              ),
            ],
          ),
          Slider(
            value: _settings.caffeineLimitMg.toDouble().clamp(100, 600),
            min: 100,
            max: 600,
            divisions: 10,
            label: '${_settings.caffeineLimitMg} mg',
            onChanged: (double value) => setState(
              () => _settings = _settings.copyWith(
                caffeineLimitMg: (value / 50).round() * 50,
              ),
            ),
            onChangeEnd: (double value) =>
                _saveCaffeine(limitMg: (value / 50).round() * 50),
          ),
          const SizedBox(height: 4),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Sağlıklı yetişkinler için yaygın öneri 400 mg/gün.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _pickBedtime,
              child: Ink(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFD),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE7EEF7)),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.bedtime_rounded,
                      size: 18,
                      color: Color(0xFF8B5E34),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Uyku saati',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.subtitle,
                            ),
                          ),
                          Text(
                            _settings.bedtimeLabel,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.heading,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        const Text(
                          'Son kafein önerisi',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.subtitle,
                          ),
                        ),
                        Text(
                          cutoff,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF8B5E34),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.subtitle,
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

  Widget _buildSustainabilityCard() {
    final ContainerType selected =
        containerOf(_settings.lastContainerId) ?? kContainerTypes.first;

    return _SettingsCard(
      icon: Icons.eco_rounded,
      color: AppColors.green,
      title: 'Sürdürülebilirlik',
      subtitle: 'Ambalaj takibi ve geri dönüşüm hatırlatmaları',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SwitchListTile.adaptive(
            value: _settings.askContainer,
            onChanged: _busy ? null : _toggleAskContainer,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Her içecekte kabı sor',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.heading,
              ),
            ),
            subtitle: const Text(
              'Kapalıysa son seçtiğin kap otomatik kullanılır.',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: AppColors.subtitle,
              ),
            ),
          ),
          SwitchListTile.adaptive(
            value: _settings.ecoReminderEnabled,
            onChanged: _busy ? null : _toggleEcoReminder,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Geri dönüşüm hatırlatması',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.heading,
              ),
            ),
            subtitle: const Text(
              'Akşam 21:00 ve pazar günü haftalık eko özeti.',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: AppColors.subtitle,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Varsayılan kap',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.heading,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: selected.id,
            isExpanded: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF7FAFD),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            items: <DropdownMenuItem<String>>[
              for (final ContainerType container in kContainerTypes)
                DropdownMenuItem<String>(
                  value: container.id,
                  child: Row(
                    children: <Widget>[
                      Icon(container.icon, size: 17, color: container.color),
                      const SizedBox(width: 8),
                      Text(container.label),
                    ],
                  ),
                ),
            ],
            onChanged: (String? value) => _setDefaultContainer(value),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard() {
    const List<int> intervals = <int>[1, 2, 3];

    return _SettingsCard(
      icon: Icons.notifications_active_rounded,
      color: AppColors.orange,
      title: 'Su Tüketimi Hatırlatıcısı',
      subtitle: 'Düzenli aralıklarla cihazına hatırlatma gönderir',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SwitchListTile.adaptive(
            value: _settings.notificationsEnabled,
            onChanged: _busy ? null : _toggleNotifications,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Bildirimleri Aç / Kapat',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: AppColors.heading,
              ),
            ),
            subtitle: Text(
              _settings.notificationsEnabled
                  ? 'Hatırlatıcılar aktif'
                  : 'Şu an kapalı',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppColors.subtitle,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Hatırlatma Sıklığı',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.heading,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: intervals.map<Widget>((int hours) {
              final bool selected = _settings.reminderInterval == hours;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _changeInterval(hours),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: EdgeInsets.only(
                      right: hours == intervals.last ? 0 : 10,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: selected ? AppColors.primaryGradient : null,
                      color: selected ? null : const Color(0xFFF1F7FE),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '$hours Saat',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : AppColors.subtitle,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              const Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: AppColors.subtitle,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'İzin verildiğinde her ${_settings.reminderInterval} saatte '
                  'bir hedefine göre bildirim gönderilir.',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.subtitle,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrinkLibraryCard() {
    final int customCount = DrinkRepository.instance.custom.length;
    return _SettingsCard(
      icon: Icons.local_drink_rounded,
      color: const Color(0xFF56CCF2),
      title: 'İçecek Kütüphanesi',
      subtitle:
          '${kDrinkTypes.length + customCount} içecek · '
          '$customCount özel tanım',
      child: Column(
        children: <Widget>[
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F7FE),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  width: 1.4,
                ),
              ),
              child: TextButton.icon(
                onPressed: _openLibrary,
                icon: const Icon(
                  Icons.apps_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                label: const Text(
                  'Kataloğu Aç / Özel İçecek Ekle',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return _SettingsCard(
      icon: Icons.info_rounded,
      color: AppColors.subtitle,
      title: 'Hakkında ve Yasal',
      subtitle: 'Gizlilik, kullanım koşulları, lisanslar',
      child: Column(
        children: <Widget>[
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFD),
                borderRadius: BorderRadius.circular(18),
              ),
              child: TextButton.icon(
                onPressed: _openAbout,
                icon: const Icon(
                  Icons.privacy_tip_outlined,
                  color: AppColors.subtitle,
                  size: 20,
                ),
                label: const Text(
                  'Gizlilik ve Hakkında Sayfası',
                  style: TextStyle(
                    color: AppColors.heading,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugCard() {
    return _SettingsCard(
      icon: Icons.science_rounded,
      color: const Color(0xFF8B5CF6),
      title: 'Geliştirici Araçları',
      subtitle: 'Yalnızca debug derlemelerinde görünür',
      child: Column(
        children: <Widget>[
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.warmGradient,
                borderRadius: BorderRadius.circular(18),
              ),
              child: TextButton.icon(
                onPressed: _busy ? null : _sendTestNotification,
                icon: const Icon(
                  Icons.notifications_active_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                label: const Text(
                  'Anlık Test Bildirimi Gönder',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F7FE),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  width: 1.4,
                ),
              ),
              child: TextButton.icon(
                onPressed: _busy ? null : _openDataTools,
                icon: const Icon(
                  Icons.storage_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                label: const Text(
                  'Örnek Veri Ekle / Temizle',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(18),
        ),
        child: TextButton(
          onPressed: busy ? null : onPressed,
          child: busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.cardShadow,
      ),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.valueLabel,
    required this.icon,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final IconData icon;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, size: 17, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.heading,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                valueLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: valueLabel,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
