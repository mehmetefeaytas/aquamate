import 'package:aquamate/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  group('Kap kataloğu', () {
    test('her kap için atık ve CO2e ml ile ölçeklenir', () {
      final ContainerType pet = containerOf('pet_bottle')!;
      expect(pet.wasteFor(500), 14);
      expect(pet.co2For(500), 82);
      expect(pet.wasteFor(1000), 28);
      expect(pet.isReusable, isFalse);
      expect(pet.recyclable, isTrue);
      expect(pet.ecoScore, 45);
    });

    test('matara sıfır atık üretir ve en yüksek puana sahiptir', () {
      final ContainerType reusable = containerOf('reusable_bottle')!;
      expect(reusable.wasteFor(750), 0);
      expect(reusable.isReusable, isTrue);
      expect(reusable.ecoScore, 100);
    });

    test('karton bardak geri dönüştürülemez olarak işaretlidir', () {
      final ContainerType paper = containerOf('paper_cup')!;
      expect(paper.recyclable, isFalse);
      expect(paper.isNonRecyclable, isTrue);
    });

    test('bilinmeyen kap kimliği null döner', () {
      expect(containerOf('yok_boyle_kap'), isNull);
      expect(containerOf(null), isNull);
    });
  });

  group('Eko hesaplayıcı', () {
    test('tek kullanımlık kayıtlarda atık ve CO2e birikir', () {
      final EcoSummary summary = EcoCalculator.summarize(<WaterLog>[
        buildLog(drink: 'Su', ml: 500, containerId: 'pet_bottle'),
        buildLog(drink: 'Kahve', ml: 500, containerId: 'paper_cup'),
      ]);

      expect(summary.wasteGrams, closeTo(14 + 12, 0.01));
      expect(summary.co2Grams, closeTo(82 + 55, 0.01));
      expect(summary.singleUseLogs, 2);
      expect(summary.reusableMl, 0);
      expect(summary.singleUseMl, 1000);
      expect(summary.grade, 'D');
    });

    test('matara kullanımı skoru yükseltir ve atık üretmez', () {
      final EcoSummary summary = EcoCalculator.summarize(<WaterLog>[
        buildLog(drink: 'Su', ml: 500, containerId: 'reusable_bottle'),
      ]);

      expect(summary.wasteGrams, 0);
      expect(summary.score, 100);
      expect(summary.grade, 'A');
      expect(summary.reusablePercent, 100);
      expect(summary.usages.single.container.isReusable, isTrue);
    });

    test('kap seçilmemiş kayıtlar eko hesabına katılmaz', () {
      final EcoSummary summary = EcoCalculator.summarize(<WaterLog>[
        buildLog(drink: 'Su', ml: 500),
      ]);

      expect(summary.totalMl, 500);
      expect(summary.trackedMl, 0);
      expect(summary.isEmpty, isTrue);
      expect(summary.score, 0);
      expect(summary.grade, '-');
    });

    test('geri dönüşüm işareti CO2e değerini düşürür', () {
      final EcoSummary summary = EcoCalculator.summarize(<WaterLog>[
        buildLog(
          drink: 'Su',
          ml: 500,
          containerId: 'pet_bottle',
          recycled: true,
        ),
      ]);

      expect(summary.recycledLogs, 1);
      expect(summary.unmarkedLogs, 0);
      expect(summary.recyclingCreditGrams, closeTo(82 * 0.4, 0.01));
      expect(summary.co2Grams, closeTo(82 * 0.6, 0.01));
      // Atık miktarı fiziksel olarak yine üretilir.
      expect(summary.wasteGrams, 14);
    });

    test('geri dönüştürülemeyen ambalaj işaretsiz sayılmaz', () {
      final EcoSummary summary = EcoCalculator.summarize(<WaterLog>[
        buildLog(drink: 'Kahve', ml: 500, containerId: 'paper_cup'),
      ]);

      expect(summary.unmarkedLogs, 0);
      expect(summary.trashedLogs, 1);
    });

    test('matara senaryosu tasarrufu hesaplanır', () {
      final EcoSummary summary = EcoCalculator.summarize(<WaterLog>[
        buildLog(drink: 'Su', ml: 500, containerId: 'pet_bottle'),
      ]);

      expect(summary.bestCaseWasteSavedGrams, closeTo(14, 0.01));
      expect(summary.bestCaseCo2SavedGrams, closeTo(82 - 5, 0.01));
    });

    test('önceki döneme göre atık değişimi yüzdeler', () {
      // Taban anlamlı olacak kadar büyük olmalı (>= 1000 ml).
      final EcoSummary current = EcoCalculator.summarize(<WaterLog>[
        buildLog(drink: 'Su', ml: 500, containerId: 'pet_bottle'),
      ]);
      final EcoSummary previous = EcoCalculator.summarize(<WaterLog>[
        buildLog(drink: 'Su', ml: 500, containerId: 'pet_bottle'),
        buildLog(drink: 'Su', ml: 500, containerId: 'pet_bottle'),
      ]);

      expect(EcoSummary.wasteChangePercent(current, previous), -50);
      expect(EcoSummary.wasteChangePercent(previous, previous), 0);
      expect(EcoSummary.wasteChangePercent(current, EcoSummary.empty), isNull);
    });

    test('çok küçük tabanda yüzde karşılaştırması yapılmaz', () {
      final EcoSummary current = EcoCalculator.summarize(<WaterLog>[
        buildLog(drink: 'Su', ml: 500, containerId: 'pet_bottle'),
      ]);
      final EcoSummary tiny = EcoCalculator.summarize(<WaterLog>[
        buildLog(drink: 'Su', ml: 200, containerId: 'pet_bottle'),
      ]);

      expect(tiny.trackedMl, lessThan(1000));
      expect(EcoSummary.wasteChangePercent(current, tiny), isNull);
    });

    test('boş liste boş özet döner', () {
      expect(EcoCalculator.summarize(<WaterLog>[]).isEmpty, isTrue);
    });
  });

  group('Eko anlatısı', () {
    test('rapor atık miktarını ve tasarrufu içerir', () {
      final EcoSummary summary = EcoCalculator.summarize(<WaterLog>[
        buildLog(drink: 'Su', ml: 500, containerId: 'pet_bottle'),
      ]);
      final String report = EcoNarrative.build(summary, 'Kasım 2026');

      expect(report, contains('Kasım 2026'));
      expect(report, contains('14 g'));
      expect(report, contains('mataranla'));
    });

    test('boş dönemde yönlendirici metin döner', () {
      final String report = EcoNarrative.build(EcoSummary.empty, 'Bu hafta');
      expect(report, contains('henüz ambalaj verisi yok'));
    });

    test('ipucu işaretsiz ambalajı hatırlatır', () {
      final EcoSummary summary = EcoCalculator.summarize(<WaterLog>[
        buildLog(drink: 'Su', ml: 500, containerId: 'pet_bottle'),
      ]);
      expect(EcoNarrative.tip(summary), contains('geri dönüşüme'));
    });
  });
}
