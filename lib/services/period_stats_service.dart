import 'package:intl/intl.dart';

import '../data/database_helper.dart';
import '../models/models.dart';

/// Grafikteki tek bir kova (gün veya ay).
class ChartBucket {
  const ChartBucket({
    required this.label,
    required this.start,
    required this.raw,
    required this.effective,
    required this.caffeine,
  });

  final String label;
  final DateTime start;
  final int raw;
  final int effective;
  final int caffeine;
}

/// Bir dönemin tüm istatistikleri: hidrasyon, kafein ve sürdürülebilirlik.
class PeriodStats {
  const PeriodStats({
    required this.period,
    required this.range,
    required this.previousRange,
    required this.logs,
    required this.previousLogs,
    required this.totalRaw,
    required this.totalEffective,
    required this.totalCaffeine,
    required this.previousTotalEffective,
    required this.previousTotalCaffeine,
    required this.previousActiveDays,
    required this.rawByDrink,
    required this.caffeineByDrink,
    required this.dailyCaffeine,
    required this.activeDays,
    required this.goalDays,
    required this.maxDailyCaffeine,
    required this.buckets,
    required this.eco,
    required this.previousEco,
    required this.todayLogs,
    required this.todayCaffeine,
    required this.goalMl,
  });

  final PeriodType period;
  final PeriodRange range;
  final PeriodRange previousRange;

  final List<WaterLog> logs;
  final List<WaterLog> previousLogs;

  final int totalRaw;
  final int totalEffective;
  final int totalCaffeine;
  final int previousTotalEffective;
  final int previousTotalCaffeine;

  /// Önceki dönemde kayıt girilen gün sayısı (karşılaştırma güvenilirliği).
  final int previousActiveDays;

  /// İçecek etiketi -> brüt ml.
  final Map<String, int> rawByDrink;

  /// İçecek etiketi -> kafein mg.
  final Map<String, int> caffeineByDrink;

  /// Gün anahtarı (yyyy-MM-dd) -> toplam kafein mg.
  final Map<String, int> dailyCaffeine;

  /// Kayıt girilen gün sayısı (bugünkü kısmi gün dahil).
  final int activeDays;

  /// Günlük hedefin tutturulduğu gün sayısı.
  final int goalDays;

  final int maxDailyCaffeine;
  final List<ChartBucket> buckets;

  final EcoSummary eco;
  final EcoSummary previousEco;

  /// Kafein halkası her zaman bugünü gösterir.
  final List<WaterLog> todayLogs;
  final int todayCaffeine;

  final int goalMl;

  int get logCount => logs.length;

  int get dayDivisor => activeDays <= 0 ? 1 : activeDays;

  int get dailyAverage => (totalEffective / dayDivisor).round();

  int get previousDailyAverage {
    final int days = previousLogs.isEmpty ? 1 : _distinctDays(previousLogs);
    return (previousTotalEffective / days).round();
  }

  /// Hedef tutturma oranı (%).
  int get goalRate {
    if (activeDays <= 0) {
      return 0;
    }
    return (goalDays / activeDays * 100).round();
  }

  /// Önceki döneme göre net hidrasyon değişimi (%).
  int? get hydrationChangePercent {
    // Çok küçük tabanlarda yüzde yanıltıcı olur.
    if (previousTotalEffective < 500) {
      return null;
    }
    return ((totalEffective - previousTotalEffective) /
            previousTotalEffective *
            100)
        .round();
  }

  int? get caffeineChangePercent {
    if (previousTotalCaffeine < 20) {
      return null;
    }
    return ((totalCaffeine - previousTotalCaffeine) /
            previousTotalCaffeine *
            100)
        .round();
  }

  /// En çok tüketilen içecek.
  String? get topDrink {
    if (rawByDrink.isEmpty) {
      return null;
    }
    final List<MapEntry<String, int>> entries = rawByDrink.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.first.key;
  }

  static int _distinctDays(List<WaterLog> logs) {
    final Set<String> days = <String>{};
    for (final WaterLog log in logs) {
      days.add(DateFormat('yyyy-MM-dd').format(log.createdAt));
    }
    return days.length;
  }
}

/// Dönem istatistiklerini veritabanından tek sorguyla üretir.
class PeriodStatsService {
  const PeriodStatsService._();

  static Future<PeriodStats> load({
    required PeriodType period,
    required int goalMl,
    DateTime? nowOverride,
  }) async {
    final DateTime now = nowOverride ?? DateTime.now();
    final PeriodRange range = period.rangeFor(now);
    final PeriodRange previous = period.previousRangeFor(now);

    final List<WaterLog> logs = await DatabaseHelper.instance.logsBetween(
      range.start,
      range.end,
    );
    final List<WaterLog> previousLogs = await DatabaseHelper.instance
        .logsBetween(previous.start, previous.end);
    final List<WaterLog> todayLogs = await DatabaseHelper.instance.logsForDay(
      now,
    );

    return build(
      period: period,
      range: range,
      previousRange: previous,
      logs: logs,
      previousLogs: previousLogs,
      todayLogs: todayLogs,
      goalMl: goalMl,
      now: now,
    );
  }

  /// Saf (pure) hesaplama - testlerde doğrudan kullanılabilir.
  static PeriodStats build({
    required PeriodType period,
    required PeriodRange range,
    required PeriodRange previousRange,
    required List<WaterLog> logs,
    required List<WaterLog> previousLogs,
    required List<WaterLog> todayLogs,
    required int goalMl,
    required DateTime now,
  }) {
    int totalRaw = 0;
    int totalEffective = 0;
    int totalCaffeine = 0;
    int previousTotalEffective = 0;
    int previousTotalCaffeine = 0;
    final Map<String, int> rawByDrink = <String, int>{};
    final Map<String, int> caffeineByDrink = <String, int>{};
    final Map<String, int> effectiveByDay = <String, int>{};
    final Map<String, int> caffeineByDay = <String, int>{};

    for (final WaterLog log in logs) {
      totalRaw += log.rawAmount;
      totalEffective += log.effectiveAmount;
      totalCaffeine += log.caffeineMg;
      rawByDrink.update(
        log.drinkType,
        (int value) => value + log.rawAmount,
        ifAbsent: () => log.rawAmount,
      );
      if (log.caffeineMg > 0) {
        caffeineByDrink.update(
          log.drinkType,
          (int value) => value + log.caffeineMg,
          ifAbsent: () => log.caffeineMg,
        );
      }
      final String dayKey = DateFormat('yyyy-MM-dd').format(log.createdAt);
      effectiveByDay.update(
        dayKey,
        (int value) => value + log.effectiveAmount,
        ifAbsent: () => log.effectiveAmount,
      );
      caffeineByDay.update(
        dayKey,
        (int value) => value + log.caffeineMg,
        ifAbsent: () => log.caffeineMg,
      );
    }

    final Set<String> previousDays = <String>{};
    for (final WaterLog log in previousLogs) {
      previousTotalEffective += log.effectiveAmount;
      previousTotalCaffeine += log.caffeineMg;
      previousDays.add(DateFormat('yyyy-MM-dd').format(log.createdAt));
    }

    int goalDays = 0;
    for (final int value in effectiveByDay.values) {
      if (value >= goalMl) {
        goalDays++;
      }
    }

    int maxDailyCaffeine = 0;
    for (final int value in caffeineByDay.values) {
      if (value > maxDailyCaffeine) {
        maxDailyCaffeine = value;
      }
    }

    final int todayCaffeine = todayLogs.fold<int>(
      0,
      (int sum, WaterLog log) => sum + log.caffeineMg,
    );

    return PeriodStats(
      period: period,
      range: range,
      previousRange: previousRange,
      logs: logs,
      previousLogs: previousLogs,
      totalRaw: totalRaw,
      totalEffective: totalEffective,
      totalCaffeine: totalCaffeine,
      previousTotalEffective: previousTotalEffective,
      previousTotalCaffeine: previousTotalCaffeine,
      previousActiveDays: previousDays.length,
      rawByDrink: rawByDrink,
      caffeineByDrink: caffeineByDrink,
      dailyCaffeine: caffeineByDay,
      activeDays: effectiveByDay.length,
      goalDays: goalDays,
      maxDailyCaffeine: maxDailyCaffeine,
      buckets: _buildBuckets(
        period: period,
        range: range,
        effectiveByDay: effectiveByDay,
        caffeineByDay: caffeineByDay,
        rawByDrinkPerBucket: logs,
      ),
      eco: EcoCalculator.summarize(logs),
      previousEco: EcoCalculator.summarize(previousLogs),
      todayLogs: todayLogs,
      todayCaffeine: todayCaffeine,
      goalMl: goalMl,
    );
  }

  static List<ChartBucket> _buildBuckets({
    required PeriodType period,
    required PeriodRange range,
    required Map<String, int> effectiveByDay,
    required Map<String, int> caffeineByDay,
    required List<WaterLog> rawByDrinkPerBucket,
  }) {
    final Map<String, int> rawByDay = <String, int>{};
    for (final WaterLog log in rawByDrinkPerBucket) {
      final String key = DateFormat('yyyy-MM-dd').format(log.createdAt);
      rawByDay.update(
        key,
        (int v) => v + log.rawAmount,
        ifAbsent: () => log.rawAmount,
      );
    }

    switch (period) {
      case PeriodType.today:
        final String key = DateFormat('yyyy-MM-dd').format(range.start);
        return <ChartBucket>[
          ChartBucket(
            label: 'Bugün',
            start: range.start,
            raw: rawByDay[key] ?? 0,
            effective: effectiveByDay[key] ?? 0,
            caffeine: caffeineByDay[key] ?? 0,
          ),
        ];

      case PeriodType.week:
      case PeriodType.month:
        final int days = period == PeriodType.week
            ? 7
            : DateUtilsX.daysInMonth(range.start.year, range.start.month);
        return List<ChartBucket>.generate(days, (int i) {
          final DateTime day = DateTime(
            range.start.year,
            range.start.month,
            range.start.day + i,
          );
          final String key = DateFormat('yyyy-MM-dd').format(day);
          final String label = period == PeriodType.week
              ? DateFormat.E('tr_TR').format(day)
              : day.day.toString();
          return ChartBucket(
            label: label,
            start: day,
            raw: rawByDay[key] ?? 0,
            effective: effectiveByDay[key] ?? 0,
            caffeine: caffeineByDay[key] ?? 0,
          );
        });

      case PeriodType.year:
        return List<ChartBucket>.generate(12, (int i) {
          final DateTime month = DateTime(range.start.year, i + 1);
          int raw = 0;
          int effective = 0;
          int caffeine = 0;
          final int days = DateUtilsX.daysInMonth(month.year, month.month);
          for (int d = 1; d <= days; d++) {
            final String key = DateFormat(
              'yyyy-MM-dd',
            ).format(DateTime(month.year, month.month, d));
            raw += rawByDay[key] ?? 0;
            effective += effectiveByDay[key] ?? 0;
            caffeine += caffeineByDay[key] ?? 0;
          }
          return ChartBucket(
            label: DateFormat.MMM('tr_TR').format(month),
            start: month,
            raw: raw,
            effective: effective,
            caffeine: caffeine,
          );
        });
    }
  }
}
