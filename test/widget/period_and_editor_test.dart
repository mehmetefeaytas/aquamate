import 'package:aquamate/models/models.dart';
import 'package:aquamate/screens/drink_editor_screen.dart';
import 'package:aquamate/theme/app_theme.dart';
import 'package:aquamate/widgets/eco_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('tr'),
    supportedLocales: const <Locale>[Locale('tr')],
    localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(body: child),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr_TR');
  });

  group('Dönem seçici', () {
    testWidgets('dört dönemi gösterir ve seçimi bildirir', (tester) async {
      PeriodType? selected;

      await tester.pumpWidget(
        _wrap(
          PeriodSelector(
            selected: PeriodType.week,
            onChanged: (PeriodType value) => selected = value,
          ),
        ),
      );

      expect(find.text('Bugün'), findsOneWidget);
      expect(find.text('Hafta'), findsOneWidget);
      expect(find.text('Ay'), findsOneWidget);
      expect(find.text('Yıl'), findsOneWidget);

      await tester.tap(find.text('Ay'));
      await tester.pumpAndSettle();

      expect(selected, PeriodType.month);
    });

    testWidgets('küçük ekranda taşma yapmaz', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _wrap(PeriodSelector(selected: PeriodType.today, onChanged: (_) {})),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('Özel içecek düzenleyici', () {
    testWidgets('boş ad ile kaydetmeye çalışınca hata gösterir', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_wrap(const DrinkEditorScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Yeni İçecek'), findsOneWidget);
      expect(find.text('İçeceği Ekle'), findsOneWidget);

      await tester.tap(find.text('İçeceği Ekle'));
      await tester.pumpAndSettle();

      expect(find.text('İçecek adı boş olamaz.'), findsOneWidget);
    });

    testWidgets('hidrasyon ve kafein önizlemesi güncellenir', (tester) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_wrap(const DrinkEditorScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Hidrasyon %100 · 0 mg/100 ml kafein'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Ev Limonatası');
      await tester.pump();

      expect(find.text('Ev Limonatası'), findsWidgets);
      expect(find.text('Kafeinsiz içecek.'), findsOneWidget);
    });
  });

  group('Büyük metin ölçeği', () {
    testWidgets('dönem seçici 1.6x ölçekte taşmaz', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: _wrap(
            PeriodSelector(selected: PeriodType.week, onChanged: (_) {}),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('Model tutarlılığı', () {
    test('her içecek bir kap önerisi tanımlar', () {
      for (final DrinkType type in kDrinkTypes) {
        expect(type.defaultContainerId, isNotNull, reason: type.label);
        expect(
          containerOf(type.defaultContainerId),
          isNotNull,
          reason: type.label,
        );
      }
    });

    test('tüm kap kimlikleri benzersizdir', () {
      final Set<String> ids = kContainerTypes
          .map((ContainerType t) => t.id)
          .toSet();
      expect(ids.length, kContainerTypes.length);
    });
  });
}
