import 'dart:math' as math;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'data/database_helper.dart';
import 'models/models.dart';
import 'screens/guide_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/stats_screen.dart';
import 'services/drink_repository.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Türkçe tarih/saat biçimleri (intl).
  try {
    await initializeDateFormatting('tr_TR');
  } catch (_) {
    // Yerel veriler yüklenemezse varsayılan biçimlerle devam edilir.
  }

  // Yerel bildirim sistemi başlangıç ayarları.
  try {
    await NotificationService.initialize();
  } catch (_) {
    // Desteklenmeyen platformlarda sessizce geçilir.
  }

  // Kullanıcı tanımlı içecekleri belleğe al.
  await DrinkRepository.instance.ensureLoaded();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(const AquaMateApp());
}

class AquaMateApp extends StatelessWidget {
  const AquaMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AquaMate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('tr'),
      supportedLocales: const <Locale>[Locale('tr')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const _StartupGate(),
    );
  }
}

/// İlk açılışta onboarding'i, sonrasında ana kabuğu gösterir.
class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  bool _loading = true;
  bool _onboardingDone = true;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    bool done = true;
    try {
      final UserSettings settings = await DatabaseHelper.instance.getSettings();
      done = settings.onboardingDone;
      // Eko hatırlatması açıksa uygulama açılışında yeniden planlanır
      // (iOS planlanmış bildirimleri uygulama silinince temizler).
      if (settings.ecoReminderEnabled) {
        await NotificationService.scheduleEcoReminder(enabled: true);
      }
    } catch (_) {
      // Veritabanı açılamazsa doğrudan ana ekrana geçilir.
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _onboardingDone = done;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (!_onboardingDone) {
      return OnboardingScreen(
        onDone: () => setState(() => _onboardingDone = true),
      );
    }

    return const AquaMateShell();
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.screen);

  final String label;
  final IconData icon;
  final Widget screen;
}

/// 4 sekmeli kabuk: animasyonlu sayfa geçişleri + ekranı kaplayan buzlu tab bar.
class AquaMateShell extends StatefulWidget {
  const AquaMateShell({super.key});

  @override
  State<AquaMateShell> createState() => _AquaMateShellState();
}

class _AquaMateShellState extends State<AquaMateShell> {
  static const List<_NavItem> _items = <_NavItem>[
    _NavItem('Ana Sayfa', Icons.home_rounded, HomeScreen()),
    _NavItem('İstatistik', Icons.insights_rounded, StatsScreen()),
    _NavItem('Rehber', Icons.menu_book_rounded, GuideScreen()),
    _NavItem('Ayarlar', Icons.settings_rounded, SettingsScreen()),
  ];

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: KeyedSubtree(
            key: ValueKey<int>(_index),
            child: _items[_index].screen,
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(bottomInset),
    );
  }

  Widget _buildBottomBar(double bottomInset) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.90),
            border: const Border(
              top: BorderSide(color: Color(0x18000000), width: 0.6),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: EdgeInsets.only(top: 8, bottom: math.max(8.0, bottomInset)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              for (int i = 0; i < _items.length; i++)
                _buildNavItem(i, _items[i]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, _NavItem item) {
    final bool isSelected = _index == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_index == index) {
            return;
          }
          HapticFeedback.selectionClick();
          setState(() => _index = index);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                item.icon,
                size: 25,
                color: isSelected ? AppColors.primary : const Color(0xFF8E9BAE),
              ),
              const SizedBox(height: 3),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primary
                      : const Color(0xFF8E9BAE),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
