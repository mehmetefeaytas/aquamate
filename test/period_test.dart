import 'package:aquamate/models/models.dart';
import 'package:aquamate/services/period_stats_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'helpers.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr_TR');
  });

  final DateTime now = DateTime(2026, 11, 4, 12, 30); // Çarşamba

  group('Dönem aralıkları', () {
    test('bugün gece yarısından sonraki gece yarısına kadar', () {
      final PeriodRange range = PeriodType.today.rangeFor(now);
      expect(range.start, DateTime(2026, 11, 4));
      expect(range.end, DateTime(2026, 11, 5));
      expect(range.dayCount, 1);
    });

    test('hafta pazartesi başlar', () {
      final PeriodRange range = PeriodType.week.rangeFor(now);
      expect(range.start, DateTime(2026, 11, 2));
      expect(range.end, DateTime(2026, 11, 9));
      expect(range.dayCount, 7);
    });

    test('ay ilk günden sonraki ayın ilk gününe kadar', () {
      final PeriodRange range = PeriodType.month.rangeFor(now);
      expect(range.start, DateTime(2026, 11));
      expect(range.end, DateTime(2026, 12));
      expect(range.dayCount, 30);
    });

    test('yıl 1 Ocak - 1 Ocak', () {
      final PeriodRange range = PeriodType.year.rangeFor(now);
      expect(range.start, DateTime(2026));
      expect(range.end, DateTime(2027));
      expect(range.dayCount, 365);
    });

    test('önceki dönem aynı uzunluktadır', () {
      final PeriodRange week = PeriodType.week.previousRangeFor(now);
      expect(week.start, DateTime(2026, 10, 26));
      expect(week.end, DateTime(2026, 11, 2));

      final PeriodRange month = PeriodType.month.previousRangeFor(now);
      expect(month.start, DateTime(2026, 10));
      expect(month.end, DateTime(2026, 11));
    });

    test('şubat artık yıl hesabı', () {
      final PeriodRange range = PeriodType.month.rangeFor(
        DateTime(2028, 2, 10),
      );
      expect(range.end, DateTime(2028, 3));
      expect(range.dayCount, 29);
    });

    test('dönem etiketleri Türkçedir', () {
      expect(
        PeriodType.month.rangeFor(now).label(PeriodType.month),
        'Kasım 2026',
      );
      expect(PeriodType.year.rangeFor(now).label(PeriodType.year), '2026');
      expect(
        PeriodType.today.rangeFor(now).label(PeriodType.today),
        '4 Kasım 2026',
      );
    });
  });

  group('Dönem istatistikleri', () {
    PeriodStats build({
      List<WaterLog>? logs,
      List<WaterLog>? previous,
      List<WaterLog>? today,
      int goalMl = 2000,
    }) {
      final PeriodType period = PeriodType.week;
      return PeriodStatsService.build(
        period: period,
        range: period.rangeFor(now),
        previousRange: period.previousRangeFor(now),
        logs: logs ?? <WaterLog>[],
        previousLogs: previous ?? <WaterLog>[],
        todayLogs: today ?? <WaterLog>[],
        goalMl: goalMl,
        now: now,
      );
    }

    test('toplamlar ve günlük ortalama doğru hesaplanır', () {
      final PeriodStats stats = build(
        logs: <WaterLog>[
          buildLog(drink: 'Su', ml: 500, at: DateTime(2026, 11, 2, 9)),
          buildLog(drink: 'Su', ml: 500, at: DateTime(2026, 11, 2, 15)),
          buildLog(drink: 'Kahve', ml: 200, at: DateTime(2026, 11, 3, 10)),
        ],
      );

      expect(stats.totalRaw, 1200);
      expect(stats.totalEffective, 500 + 500 + 160);
      expect(stats.logCount, 3);
      expect(stats.activeDays, 2);
      expect(stats.dailyAverage, ((500 + 500 + 160) / 2).round());
      expect(stats.topDrink, 'Su');
    });

    test('hedef tutturma oranı gün bazında hesaplanır', () {
      final PeriodStats stats = build(
        logs: <WaterLog>[
          buildLog(drink: 'Su', ml: 2000, at: DateTime(2026, 11, 2, 9)),
          buildLog(drink: 'Su', ml: 500, at: DateTime(2026, 11, 3, 9)),
        ],
      );

      expect(stats.activeDays, 2);
      expect(stats.goalDays, 1);
      expect(stats.goalRate, 50);
    });

    test('haftalık grafikte 7 kova vardır', () {
      final PeriodStats stats = build(
        logs: <WaterLog>[
          buildLog(drink: 'Su', ml: 500, at: DateTime(2026, 11, 2, 9)),
        ],
      );
      expect(stats.buckets, hasLength(7));
      expect(stats.buckets.first.effective, 500);
      expect(stats.buckets[1].effective, 0);
    });

    test('aylık grafikte ayın gün sayısı kadar kova olur', () {
      final PeriodStats stats = PeriodStatsService.build(
        period: PeriodType.month,
        range: PeriodType.month.rangeFor(now),
        previousRange: PeriodType.month.previousRangeFor(now),
        logs: <WaterLog>[],
        previousLogs: <WaterLog>[],
        todayLogs: <WaterLog>[],
        goalMl: 2000,
        now: now,
      );
      expect(stats.buckets, hasLength(30));
    });

    test('yıllık grafikte 12 ay kovası olur', () {
      final PeriodStats stats = PeriodStatsService.build(
        period: PeriodType.year,
        range: PeriodType.year.rangeFor(now),
        previousRange: PeriodType.year.previousRangeFor(now),
        logs: <WaterLog>[
          buildLog(drink: 'Su', ml: 1000, at: DateTime(2026, 3, 15, 9)),
          buildLog(drink: 'Su', ml: 1000, at: DateTime(2026, 3, 16, 9)),
        ],
        previousLogs: <WaterLog>[],
        todayLogs: <WaterLog>[],
        goalMl: 2000,
        now: now,
      );
      expect(stats.buckets, hasLength(12));
      expect(stats.buckets[2].effective, 2000);
      expect(stats.buckets[0].effective, 0);
    });

    test('kafein toplamı ve kaynak dağılımı hesaplanır', () {
      final PeriodStats stats = build(
        logs: <WaterLog>[
          buildLog(drink: 'Kahve', ml: 200, at: DateTime(2026, 11, 2, 9)),
          buildLog(drink: 'Çay', ml: 200, at: DateTime(2026, 11, 2, 15)),
          buildLog(drink: 'Su', ml: 500, at: DateTime(2026, 11, 2, 18)),
        ],
        today: <WaterLog>[
          buildLog(drink: 'Kahve', ml: 200, at: DateTime(2026, 11, 4, 9)),
        ],
      );

      expect(stats.totalCaffeine, 80 + 30);
      expect(stats.caffeineByDrink['Kahve'], 80);
      expect(stats.caffeineByDrink.containsKey('Su'), isFalse);
      expect(stats.todayCaffeine, 80);
      expect(stats.maxDailyCaffeine, 110);
    });

    test('önceki dönem karşılaştırması yüzde döner', () {
      final PeriodStats stats = build(
        logs: <WaterLog>[
          buildLog(drink: 'Su', ml: 1000, at: DateTime(2026, 11, 2, 9)),
        ],
        previous: <WaterLog>[
          buildLog(drink: 'Su', ml: 500, at: DateTime(2026, 10, 27, 9)),
        ],
      );

      expect(stats.previousTotalEffective, 500);
      expect(stats.hydrationChangePercent, 100);
    });

    test('eko özeti dönem loglarından üretilir', () {
      final PeriodStats stats = build(
        logs: <WaterLog>[
          buildLog(
            drink: 'Su',
            ml: 500,
            containerId: 'pet_bottle',
            at: DateTime(2026, 11, 2, 9),
          ),
          buildLog(
            drink: 'Su',
            ml: 500,
            containerId: 'reusable_bottle',
            at: DateTime(2026, 11, 2, 15),
          ),
        ],
      );

      expect(stats.eco.trackedMl, 1000);
      expect(stats.eco.reusableMl, 500);
      expect(stats.eco.reusablePercent, 50);
      expect(stats.eco.wasteGrams, 14);
    });

    test('boş dönemde bölme hatası oluşmaz', () {
      final PeriodStats stats = build();
      expect(stats.dailyAverage, 0);
      expect(stats.goalRate, 0);
      expect(stats.hydrationChangePercent, isNull);
      expect(stats.topDrink, isNull);
    });
  });
}
