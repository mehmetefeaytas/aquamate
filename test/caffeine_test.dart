import 'package:aquamate/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Kafein hesaplama', () {
    test('içecek kafein değerleri ml ile ölçeklenir', () {
      expect(drinkTypeOf('Kahve').caffeineOf(200), 80);
      expect(drinkTypeOf('Espresso').caffeineOf(30), 64);
      expect(drinkTypeOf('Türk Kahvesi').caffeineOf(100), 100);
      expect(drinkTypeOf('Çay').caffeineOf(200), 30);
      expect(drinkTypeOf('Kola').caffeineOf(330), 33);
    });

    test('kafeinsiz içecekler sıfır döner', () {
      for (final String label in <String>[
        'Su',
        'Maden Suyu',
        'Ayran',
        'Süt',
        'Limonata',
        'Bitki Çayı',
      ]) {
        expect(drinkTypeOf(label).caffeineOf(500), 0, reason: label);
        expect(drinkTypeOf(label).hasCaffeine, isFalse, reason: label);
      }
    });

    test('enerji içeceği yüksek kafein içerir', () {
      expect(drinkTypeOf('Enerji İçeceği').caffeineOf(250), 80);
      expect(drinkTypeOf('Enerji İçeceği').hasCaffeine, isTrue);
    });
  });

  group('Kafein durumu', () {
    test('limitin altında düşük / dengeli', () {
      expect(
        CaffeineCalculator.status(consumedMg: 50, limitMg: 400),
        CaffeineStatus.low,
      );
      expect(
        CaffeineCalculator.status(consumedMg: 200, limitMg: 400),
        CaffeineStatus.moderate,
      );
    });

    test('%75 ve üzeri yüksek, %100 ve üzeri limit aşımı', () {
      expect(
        CaffeineCalculator.status(consumedMg: 300, limitMg: 400),
        CaffeineStatus.high,
      );
      expect(
        CaffeineCalculator.status(consumedMg: 400, limitMg: 400),
        CaffeineStatus.exceeded,
      );
      expect(
        CaffeineCalculator.status(consumedMg: 520, limitMg: 400),
        CaffeineStatus.exceeded,
      );
    });

    test('sıfır veya negatif limit varsayılana düşer', () {
      expect(
        CaffeineCalculator.status(consumedMg: 100, limitMg: 0),
        CaffeineStatus.low,
      );
    });

    test('durum etiketleri Türkçedir', () {
      expect(CaffeineStatus.exceeded.label, 'Limit aşıldı');
      expect(CaffeineStatus.high.label, 'Yüksek');
    });
  });

  group('Son kafein saati', () {
    test('uyku saatinden 8 saat öncesini önerir', () {
      expect(CaffeineCalculator.cutoffLabel(23 * 60), '15:00');
      expect(CaffeineCalculator.cutoffLabel(22 * 60), '14:00');
      expect(CaffeineCalculator.cutoffLabel(24 * 60), '16:00');
    });

    test('gece yarısını geçen hesap 24 saat döngüsüne sarar', () {
      expect(CaffeineCalculator.cutoffLabel(4 * 60), '20:00');
      expect(CaffeineCalculator.cutoffLabel(0), '16:00');
    });
  });

  group('Kafeinli gün toplamı', () {
    test('günlük log toplamı limit ile karşılaştırılır', () {
      final int total =
          <DrinkType>[
            drinkTypeOf('Kahve'),
            drinkTypeOf('Espresso'),
            drinkTypeOf('Çay'),
          ].fold<int>(0, (int sum, DrinkType type) {
            final int ml = type.label == 'Espresso' ? 30 : 200;
            return sum + type.caffeineOf(ml);
          });

      expect(total, 80 + 64 + 30);
      expect(
        CaffeineCalculator.status(consumedMg: total, limitMg: 200),
        CaffeineStatus.high,
      );
    });
  });
}
