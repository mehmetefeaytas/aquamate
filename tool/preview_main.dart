// Yalnızca geliştirme amaçlı önizleme koşucusu.
//
// Gerçek ekranları örnek veriyle açar; simülatörde görsel doğrulama ve ekran
// görüntüsü üretmek için kullanılır. Ürün derlemesine dahil edilmez.
//
//   flutter run -t tool/preview_main.dart \
//     --dart-define=PREVIEW=stats_eco --dart-define=PERIOD=month
//
// PREVIEW değerleri: onboarding, home, picker, stats_hydration, stats_caffeine,
// stats_eco, library, editor, settings, about, guide
import 'package:aquamate/data/database_helper.dart';
import 'package:aquamate/models/models.dart';
import 'package:aquamate/screens/about_screen.dart';
import 'package:aquamate/screens/drink_editor_screen.dart';
import 'package:aquamate/screens/drink_library_screen.dart';
import 'package:aquamate/screens/guide_screen.dart';
import 'package:aquamate/screens/home_screen.dart';
import 'package:aquamate/screens/onboarding_screen.dart';
import 'package:aquamate/screens/settings_screen.dart';
import 'package:aquamate/screens/stats/eco_tab.dart';
import 'package:aquamate/screens/stats_screen.dart';
import 'package:aquamate/services/drink_repository.dart';
import 'package:aquamate/services/period_stats_service.dart';
import 'package:aquamate/theme/app_theme.dart';
import 'package:aquamate/widgets/container_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

const String _screen = String.fromEnvironment('PREVIEW', defaultValue: 'home');
const String _periodName = String.fromEnvironment(
  'PERIOD',
  defaultValue: 'month',
);
const bool _seed = bool.fromEnvironment('SEED', defaultValue: true);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR');
  await DrinkRepository.instance.ensureLoaded();

  final UserSettings settings = await DatabaseHelper.instance.getSettings();
  await DatabaseHelper.instance.saveSettings(
    settings.copyWith(
      onboardingDone: true,
      dailyGoal: 2500,
      userName: 'Efe',
    ),
  );

  if (_seed) {
    final List<WaterLog> today = await DatabaseHelper.instance.logsForDay(
      DateTime.now(),
    );
    if (today.isEmpty) {
      await DatabaseHelper.instance.addSampleData();
    }
  }

  runApp(const _PreviewApp());
}

class _PreviewApp extends StatelessWidget {
  const _PreviewApp();

  PeriodType get _period => switch (_periodName) {
    'today' => PeriodType.today,
    'week' => PeriodType.week,
    'year' => PeriodType.year,
    _ => PeriodType.month,
  };

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('tr'),
      supportedLocales: const <Locale>[Locale('tr')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: _buildScreen(),
    );
  }

  Widget _buildScreen() {
    switch (_screen) {
      case 'onboarding':
        return OnboardingScreen(onDone: () {});
      case 'picker':
        return const _PickerPreview();
      case 'stats_hydration':
        return _shell(
          StatsScreen(initialTab: 0, initialPeriod: _period),
          title: 'İstatistik · Hidrasyon',
        );
      case 'stats_caffeine':
        return _shell(
          StatsScreen(initialTab: 1, initialPeriod: _period),
          title: 'İstatistik · Kafein',
        );
      case 'stats_eco':
        return _shell(
          StatsScreen(initialTab: 2, initialPeriod: _period),
          title: 'İstatistik · Eko',
        );
      case 'eco_report':
        return _EcoReportPreview(period: _period);
      case 'library':
        return const DrinkLibraryScreen();
      case 'editor':
        return const DrinkEditorScreen();
      case 'settings':
        return _shell(const SettingsScreen(), title: 'Ayarlar');
      case 'about':
        return const AboutScreen();
      case 'guide':
        return _shell(const GuideScreen(), title: 'Rehber');
      case 'home':
      default:
        return _shell(const HomeScreen(), title: 'Ana Sayfa');
    }
  }

  Widget _shell(Widget child, {required String title}) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: child),
    );
  }
}

class _PickerPreview extends StatefulWidget {
  const _PickerPreview();
  @override
  State<_PickerPreview> createState() => _PickerPreviewState();
}

class _PickerPreviewState extends State<_PickerPreview> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) {
        return;
      }
      await showContainerPicker(
        context,
        drinkLabel: 'Kahve',
        ml: 200,
        selectedId: 'paper_cup',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(
          'Kap seçim sayfası önizlemesi',
          style: TextStyle(fontSize: 13, color: AppColors.subtitle),
        ),
      ),
    );
  }
}

/// Eko sekmesinin alt bölümünü (rapor + tasarruf kartı) göstermek için
/// kaydırılmış önizleme.
class _EcoReportPreview extends StatefulWidget {
  const _EcoReportPreview({required this.period});

  final PeriodType period;

  @override
  State<_EcoReportPreview> createState() => _EcoReportPreviewState();
}

class _EcoReportPreviewState extends State<_EcoReportPreview> {
  final ScrollController _controller = ScrollController(
    initialScrollOffset: 980,
  );
  PeriodStats? _stats;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats = await PeriodStatsService.load(
      period: widget.period,
      goalMl: 2500,
    );
    if (!mounted) {
      return;
    }
    setState(() => _stats = stats);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PeriodStats? stats = _stats;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: stats == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: EcoTab(stats: stats),
              ),
      ),
    );
  }
}
