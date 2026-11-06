import 'package:aquamate/models/models.dart';
import 'package:aquamate/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  group('Hidrasyon katsayıları (biyoyararlanım motoru)', () {
    test('Kahve %80 katsayısı ile net hesaplar', () {
      final DrinkType kahve = drinkTypeOf('Kahve');
      expect(kahve.hydrationFactor, 0.80);
      expect(kahve.effectiveOf(200), 160);
    });

    test('Çay, Su ve Maden Suyu katsayıları korunur', () {
      expect(drinkTypeOf('Çay').effectiveOf(200), 170);
      expect(drinkTypeOf('Su').effectiveOf(250), 250);
      expect(drinkTypeOf('Maden Suyu').effectiveOf(330), 330);
    });

    test('Katalog en az 20 içecek türü içerir', () {
      expect(kDrinkTypes.length, greaterThanOrEqualTo(20));
      expect(
        kDrinkTypes.map((DrinkType t) => t.label).toSet().length,
        kDrinkTypes.length,
      );
    });

    test('Tüm kategoriler katalogda temsil edilir', () {
      final Set<DrinkCategory> categories = kDrinkTypes
          .map((DrinkType t) => t.category)
          .toSet();
      for (final DrinkCategory category in DrinkCategory.values) {
        if (category == DrinkCategory.other) {
          continue;
        }
        expect(categories, contains(category));
      }
    });
  });

  group('Akıllı hedef hesaplayıcı', () {
    test('Kilo * 35 ml + (Egzersiz / 30) * 350 ml formülünü uygular', () {
      expect(
        GoalCalculator.calculate(weight: 70, activityMinutes: 30),
        70 * 35 + 350,
      );
      expect(GoalCalculator.calculate(weight: 80, activityMinutes: 0), 80 * 35);
      expect(
        GoalCalculator.calculate(weight: 60, activityMinutes: 60),
        60 * 35 + 700,
      );
    });

    test('Varsayılan ayarlar beklendiği gibidir', () {
      final UserSettings defaults = UserSettings.defaults();
      expect(defaults.weight, 70);
      expect(defaults.activityMinutes, 30);
      expect(defaults.dailyGoal, 2500);
      expect(defaults.reminderInterval, 2);
      expect(defaults.notificationsEnabled, isFalse);
      expect(defaults.caffeineLimitMg, 400);
      expect(defaults.bedtimeMinutes, 23 * 60);
      expect(defaults.ecoReminderEnabled, isTrue);
      expect(defaults.askContainer, isTrue);
      expect(defaults.onboardingDone, isFalse);
    });

    test('UserSettings map dönüşümü kayıpsızdır', () {
      const UserSettings settings = UserSettings(
        weight: 82,
        activityMinutes: 45,
        dailyGoal: 3100,
        reminderInterval: 1,
        notificationsEnabled: true,
        caffeineLimitMg: 250,
        bedtimeMinutes: 22 * 60 + 30,
        ecoReminderEnabled: false,
        askContainer: false,
        lastContainerId: 'pet_bottle',
        onboardingDone: true,
      );
      final UserSettings restored = UserSettings.fromMap(settings.toMap());
      expect(restored.weight, 82);
      expect(restored.activityMinutes, 45);
      expect(restored.dailyGoal, 3100);
      expect(restored.caffeineLimitMg, 250);
      expect(restored.bedtimeMinutes, 22 * 60 + 30);
      expect(restored.ecoReminderEnabled, isFalse);
      expect(restored.askContainer, isFalse);
      expect(restored.lastContainerId, 'pet_bottle');
      expect(restored.onboardingDone, isTrue);
    });

    test('Görünen ad boşsa null, doluysa kırpılır', () {
      expect(UserSettings.defaults().displayName, isNull);
      expect(
        UserSettings.defaults().copyWith(userName: '   ').displayName,
        isNull,
      );
      expect(
        UserSettings.defaults().copyWith(userName: '  Efe  ').displayName,
        'Efe',
      );
    });

    test('userName map dönüşümünde korunur', () {
      final UserSettings named = UserSettings.defaults().copyWith(
        userName: 'Mehmet Efe',
      );
      final UserSettings restored = UserSettings.fromMap(named.toMap());
      expect(restored.userName, 'Mehmet Efe');
    });

    test('Uyku saati etiketi 24 saat biçimindedir', () {
      expect(UserSettings.defaults().bedtimeLabel, '23:00');
      expect(
        UserSettings.defaults()
            .copyWith(bedtimeMinutes: 7 * 60 + 5)
            .bedtimeLabel,
        '07:05',
      );
    });
  });

  group('WaterLog modeli', () {
    test('map dönüşümü ve özet metni doğrudur', () {
      final WaterLog log = WaterLog(
        drinkType: 'Kahve',
        rawAmount: 200,
        effectiveAmount: 160,
        caffeineMg: 80,
        containerId: 'paper_cup',
        recycled: true,
        createdAt: DateTime(2026, 10, 15, 9, 30),
      );
      final WaterLog restored = WaterLog.fromMap(log.toMap());

      expect(restored.drinkType, 'Kahve');
      expect(restored.rawAmount, 200);
      expect(restored.effectiveAmount, 160);
      expect(restored.caffeineMg, 80);
      expect(restored.containerId, 'paper_cup');
      expect(restored.recycled, isTrue);
      expect(restored.createdAt, log.createdAt);
      expect(restored.summaryLine, '+200 ml Kahve -> Net: 160 ml');
      expect(restored.type.label, 'Kahve');
    });

    test('Eski (v1) kayıtlar eksik kolonlarla okunabilir', () {
      final WaterLog log = WaterLog.fromMap(<String, Object?>{
        'id': 3,
        'drink_type': 'Su',
        'raw_amount': 250,
        'effective_amount': 250,
        'created_at': DateTime(2026, 1, 1).toIso8601String(),
      });
      expect(log.caffeineMg, 0);
      expect(log.containerId, isNull);
      expect(log.recycled, isFalse);
    });

    test('Bilinmeyen içecek etiketi çökmeden nötr tipe düşer', () {
      final DrinkType unknown = drinkTypeOf('Silinmiş İçecek');
      expect(unknown.label, 'Silinmiş İçecek');
      expect(unknown.effectiveOf(200), greaterThan(0));
    });
  });

  group('Sunum biçimlendirme', () {
    test('formatMl binlik ayracı kullanır', () {
      expect(formatMl(2500), '2.500');
      expect(formatMl(1600), '1.600');
      expect(formatMl(900), '900');
      expect(formatMl(12500), '12.500');
    });
  });

  group('Test yardımcıları', () {
    test('log kurucusu doğru değerleri üretir', () {
      final WaterLog log = buildLog(
        drink: 'Su',
        ml: 330,
        containerId: 'pet_bottle',
      );
      expect(log.effectiveAmount, 330);
      expect(log.caffeineMg, 0);
      expect(log.containerId, 'pet_bottle');
    });
  });
}
