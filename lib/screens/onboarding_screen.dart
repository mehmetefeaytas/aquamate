import 'package:flutter/material.dart';

import '../core/app_info.dart';
import '../data/database_helper.dart';
import '../models/models.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

/// İlk açılış tanıtımı: hedef, kafein ve sürdürülebilirlik adımları.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  final TextEditingController _name = TextEditingController();
  int _page = 0;

  double _weight = 70;
  double _activity = 30;
  int _caffeineLimit = CaffeineCalculator.defaultLimitMg;
  int _bedtimeMinutes = 23 * 60;
  bool _notifications = true;
  bool _saving = false;

  int get _goal => GoalCalculator.calculate(
    weight: _weight.round(),
    activityMinutes: _activity.round(),
  );

  @override
  void dispose() {
    _controller.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_page < 3) {
      await _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    await _finish();
  }

  Future<void> _finish() async {
    if (_saving) {
      return;
    }
    setState(() => _saving = true);

    bool notifications = false;
    if (_notifications) {
      try {
        notifications = await NotificationService.requestPermission();
      } catch (_) {
        notifications = false;
      }
    }

    final UserSettings settings = UserSettings.defaults().copyWith(
      weight: _weight.round(),
      activityMinutes: _activity.round(),
      dailyGoal: _goal,
      caffeineLimitMg: _caffeineLimit,
      bedtimeMinutes: _bedtimeMinutes,
      notificationsEnabled: notifications,
      ecoReminderEnabled: true,
      onboardingDone: true,
      userName: _name.text,
    );
    await DatabaseHelper.instance.saveSettings(settings);

    if (notifications) {
      try {
        await NotificationService.scheduleRecurring(
          intervalHours: settings.reminderInterval,
          dailyGoalMl: settings.dailyGoal,
        );
        await NotificationService.scheduleEcoReminder(enabled: true);
      } catch (_) {
        // Bildirim planlanamazsa akış kesilmez.
      }
    }

    if (!mounted) {
      return;
    }
    widget.onDone();
  }

  Future<void> _pickBedtime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _bedtimeMinutes ~/ 60,
        minute: _bedtimeMinutes % 60,
      ),
      helpText: 'Genelde kaçta uyuyorsun?',
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
    setState(() => _bedtimeMinutes = picked.hour * 60 + picked.minute);
  }

  String get _bedtimeLabel {
    final int h = _bedtimeMinutes ~/ 60;
    final int m = _bedtimeMinutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
              child: Row(
                children: <Widget>[
                  const Spacer(),
                  TextButton(
                    onPressed: _saving ? null : _finish,
                    child: const Text(
                      'Atla',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.subtitle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (int index) => setState(() => _page = index),
                children: <Widget>[
                  _buildWelcome(),
                  _buildGoalPage(),
                  _buildCaffeinePage(),
                  _buildEcoPage(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      for (int i = 0; i < 4; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _page ? 22 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: i == _page
                                ? AppColors.primary
                                : const Color(0xFFD8E5F4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: TextButton(
                        onPressed: _saving ? null : _next,
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _page == 3 ? 'Başla' : 'Devam',
                                style: const TextStyle(
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 104,
              height: 104,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(32),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.32),
                    blurRadius: 26,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(
                Icons.water_drop_rounded,
                color: Colors.white,
                size: 52,
              ),
            ),
          ),
          const SizedBox(height: 26),
          Text(
            _name.text.trim().isEmpty
                ? '${AppInfo.name}\'e hoş geldin'
                : 'Hoş geldin, ${_name.text.trim()}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Su, kafein ve ambalaj atığını tek yerde takip et. '
            'İlk 3 adımda seni tanıyalım, sonra her şey otomatik.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          _buildNameField(),
          const SizedBox(height: 20),
          const _FeatureTile(
            icon: Icons.water_drop_rounded,
            color: AppColors.primary,
            title: 'Akıllı hidrasyon',
            text: 'Her içeceğin net hidrasyon katsayısıyla gerçek su katkısı.',
          ),
          const _FeatureTile(
            icon: Icons.coffee_rounded,
            color: Color(0xFF8B5E34),
            title: 'Kafein kontrolü',
            text: 'Günlük limit, kaynak dağılımı ve uyku saati uyarısı.',
          ),
          const _FeatureTile(
            icon: Icons.eco_rounded,
            color: AppColors.green,
            title: 'Sürdürülebilirlik',
            text: 'Kap seç, atık ve CO₂ etkini ay sonu raporunda gör.',
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.person_outline_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Sana nasıl hitap edelim?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.heading,
                  ),
                ),
              ),
              Text(
                'Zorunlu değil',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.subtitle.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _name,
            maxLength: 24,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _next(),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.heading,
            ),
            decoration: InputDecoration(
              hintText: 'Adın',
              counterText: '',
              filled: true,
              fillColor: const Color(0xFFF4F8FC),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ana sayfada "Merhaba, adın" olarak karşılar. İstemezsen boş bırak.',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: AppColors.subtitle,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 12),
          Text(
            'Günlük hedefin',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            'Kilon ve günlük hareketin hedefini belirler. Sonradan '
            'değiştirebilirsin.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 22),
          _OnboardingSlider(
            label: 'Kilon',
            valueLabel: '${_weight.round()} kg',
            icon: Icons.monitor_weight_rounded,
            value: _weight,
            min: 40,
            max: 150,
            divisions: 110,
            onChanged: (double v) => setState(() => _weight = v),
          ),
          const SizedBox(height: 12),
          _OnboardingSlider(
            label: 'Günlük egzersiz',
            valueLabel: '${_activity.round()} dk',
            icon: Icons.directions_run_rounded,
            value: _activity,
            min: 0,
            max: 120,
            divisions: 24,
            onChanged: (double v) => setState(() => _activity = v),
          ),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.28),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Önerilen günlük hedef',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatMl(_goal)} ml',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kilo × 35 ml + (egzersiz / 30) × 350 ml',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaffeinePage() {
    final String cutoff = CaffeineCalculator.cutoffLabel(_bedtimeMinutes);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 12),
          Text(
            'Kafein ve uyku',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            'Günlük kafein üst sınırını ve uyku saatini seç; uygulama '
            'son kafein saatini hesaplasın.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.coffee_rounded,
                      size: 17,
                      color: Color(0xFF8B5E34),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Günlük kafein limiti',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.heading,
                        ),
                      ),
                    ),
                    Text(
                      '$_caffeineLimit mg',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF8B5E34),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _caffeineLimit.toDouble(),
                  min: 100,
                  max: 600,
                  divisions: 10,
                  label: '$_caffeineLimit mg',
                  onChanged: (double v) =>
                      setState(() => _caffeineLimit = (v / 50).round() * 50),
                ),
                const Text(
                  'Sağlıklı yetişkinler için yaygın öneri 400 mg/gün.',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.subtitle,
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: _pickBedtime,
              child: Ink(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.bedtime_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Uyku saati',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.heading,
                        ),
                      ),
                    ),
                    Text(
                      _bedtimeLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
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
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: AppColors.orange,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Uyku saatine göre son kafein önerisi: $cutoff',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF9A3412),
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

  Widget _buildEcoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 12),
          Text(
            'Sürdürülebilirlik',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            'Her içecekte kabını seç: matara mı, PET şişe mi, karton bardak mı? '
            'Ay sonunda atık ve karbon ayak izini raporlayalım.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          const _FeatureTile(
            icon: Icons.sports_bar_rounded,
            color: AppColors.green,
            title: 'Tek dokunuşla kap seçimi',
            text: 'Son seçimin hatırlanır, istersen hiç sormayız.',
          ),
          const _FeatureTile(
            icon: Icons.recycling_rounded,
            color: Color(0xFF0EA5E9),
            title: 'Geri dönüşüm takibi',
            text: 'Ambalajı geri dönüşüme attın mı? Akşam hatırlatırız.',
          ),
          const _FeatureTile(
            icon: Icons.insights_rounded,
            color: AppColors.orange,
            title: 'Ay sonu raporu',
            text: '"Şunu tercih etseydin" karşılaştırmasıyla tasarrufunu gör.',
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: SwitchListTile.adaptive(
              value: _notifications,
              onChanged: (bool value) => setState(() => _notifications = value),
              title: const Text(
                'Hatırlatmaları aç',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.heading,
                ),
              ),
              subtitle: const Text(
                'Su molası, geri dönüşüm ve haftalık eko özeti. İstediğin '
                'zaman kapatabilirsin.',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.subtitle,
                  height: 1.35,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Devam ederek gizlilik özetini kabul etmiş olursun: verilerin '
            'yalnızca bu cihazda saklanır, hiçbir sunucuya gönderilmez.',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: AppColors.subtitle,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.heading,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.subtitle,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingSlider extends StatelessWidget {
  const _OnboardingSlider({
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 17, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.heading,
                  ),
                ),
              ),
              Text(
                valueLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
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
      ),
    );
  }
}
