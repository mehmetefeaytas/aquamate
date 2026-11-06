import 'dart:math' as math;

import 'package:intl/intl.dart';

import 'models.dart';

/// Bir kabın dönem içindeki kullanım özeti.
class ContainerUsage {
  const ContainerUsage({
    required this.container,
    required this.ml,
    required this.logCount,
    required this.wasteGrams,
    required this.co2Grams,
    required this.recycledCount,
  });

  final ContainerType container;
  final int ml;
  final int logCount;
  final double wasteGrams;
  final double co2Grams;

  /// Geri dönüşüme atıldığı işaretlenen kayıt sayısı.
  final int recycledCount;

  int get percentOfVolume => ml;

  double get wasteKg => wasteGrams / 1000;
}

/// Dönem bazlı sürdürülebilirlik özeti.
class EcoSummary {
  const EcoSummary({
    required this.totalMl,
    required this.trackedMl,
    required this.wasteGrams,
    required this.co2Grams,
    required this.recyclingCreditGrams,
    required this.score,
    required this.reusableMl,
    required this.singleUseMl,
    required this.singleUseLogs,
    required this.recycledLogs,
    required this.trashedLogs,
    required this.unmarkedLogs,
    required this.usages,
    required this.bestCaseWasteSavedGrams,
    required this.bestCaseCo2SavedGrams,
  });

  /// Ambalajı bilinmeyen kayıtlar hariç, kabı işaretlenmiş toplam hacim.
  final int trackedMl;

  /// Dönemdeki tüm kayıtların brüt hacmi.
  final int totalMl;

  final double wasteGrams;
  final double co2Grams;

  /// Geri dönüşüm sayesinde önlenen CO2e (g).
  final double recyclingCreditGrams;

  /// 0-100 arası ağırlıklı sürdürülebilirlik puanı.
  final int score;

  final int reusableMl;
  final int singleUseMl;

  final int singleUseLogs;
  final int recycledLogs;
  final int trashedLogs;
  final int unmarkedLogs;

  final List<ContainerUsage> usages;

  /// Tüm tek kullanımlık hacim matarayla içilseydi önlenen atık/CO2e.
  final double bestCaseWasteSavedGrams;
  final double bestCaseCo2SavedGrams;

  static const EcoSummary empty = EcoSummary(
    totalMl: 0,
    trackedMl: 0,
    wasteGrams: 0,
    co2Grams: 0,
    recyclingCreditGrams: 0,
    score: 0,
    reusableMl: 0,
    singleUseMl: 0,
    singleUseLogs: 0,
    recycledLogs: 0,
    trashedLogs: 0,
    unmarkedLogs: 0,
    usages: <ContainerUsage>[],
    bestCaseWasteSavedGrams: 0,
    bestCaseCo2SavedGrams: 0,
  );

  bool get isEmpty => trackedMl == 0;

  /// %0-100: tekrar kullanılabilir kaplarda içilen hacim payı.
  int get reusablePercent =>
      trackedMl == 0 ? 0 : (reusableMl / trackedMl * 100).round();

  /// A / B / C / D harf notu.
  String get grade {
    if (isEmpty) {
      return '-';
    }
    if (score >= 80) {
      return 'A';
    }
    if (score >= 60) {
      return 'B';
    }
    if (score >= 40) {
      return 'C';
    }
    return 'D';
  }

  double get wasteKg => wasteGrams / 1000;

  double get co2Kg => co2Grams / 1000;

  /// Önceki döneme göre atık değişimi (%); negatif = iyileşme.
  ///
  /// Önceki dönemin tabanı çok küçükse yüzde anlamsız olur (0,5 g -> 40 g
  /// "%7900" gibi). Bu durumda karşılaştırma gösterilmez.
  static int? wasteChangePercent(EcoSummary current, EcoSummary previous) {
    if (previous.wasteGrams < 5 || previous.trackedMl < 1000) {
      return null;
    }
    return ((current.wasteGrams - previous.wasteGrams) /
            previous.wasteGrams *
            100)
        .round();
  }
}

/// [WaterLog] listesinden eko özeti üretir.
class EcoCalculator {
  const EcoCalculator._();

  /// Geri dönüştürülen ambalajın CO2e avantajı (yaklaşık %40 tasarruf).
  static const double recyclingSavingRatio = 0.4;

  static EcoSummary summarize(List<WaterLog> logs) {
    if (logs.isEmpty) {
      return EcoSummary.empty;
    }

    final Map<String, _UsageAccumulator> acc = <String, _UsageAccumulator>{};

    int totalMl = 0;
    int trackedMl = 0;
    int reusableMl = 0;
    int singleUseMl = 0;
    int singleUseLogs = 0;
    int recycledLogs = 0;
    int trashedLogs = 0;
    int unmarkedLogs = 0;
    double waste = 0;
    double co2 = 0;
    double recyclingCredit = 0;
    double scoreWeighted = 0;
    double bestCaseWaste = 0;
    double bestCaseCo2 = 0;

    for (final WaterLog log in logs) {
      totalMl += log.rawAmount;
      final ContainerType? container = containerOf(log.containerId);
      if (container == null) {
        continue;
      }

      trackedMl += log.rawAmount;
      final double logWaste = container.wasteFor(log.rawAmount);
      final double logCo2 = container.co2For(log.rawAmount);
      waste += logWaste;
      co2 += logCo2;
      scoreWeighted += container.ecoScore * log.rawAmount;

      if (container.isReusable) {
        reusableMl += log.rawAmount;
      } else {
        singleUseMl += log.rawAmount;
        singleUseLogs++;
        // Tüm tek kullanımlık hacim matara olsaydı ne olurdu?
        bestCaseWaste += logWaste;
        bestCaseCo2 += logCo2 - kBestCaseContainer.co2For(log.rawAmount);

        if (container.recyclable) {
          if (log.recycled) {
            recycledLogs++;
            recyclingCredit += logCo2 * recyclingSavingRatio;
          } else {
            trashedLogs++;
            unmarkedLogs++;
          }
        } else {
          trashedLogs++;
        }
      }

      final _UsageAccumulator usage = acc.putIfAbsent(
        container.id,
        () => _UsageAccumulator(container),
      );
      usage.ml += log.rawAmount;
      usage.logCount++;
      usage.waste += logWaste;
      usage.co2 += logCo2;
      if (log.recycled) {
        usage.recycledCount++;
      }
    }

    final double netCo2 = math.max(0, co2 - recyclingCredit);
    final int score = trackedMl == 0 ? 0 : (scoreWeighted / trackedMl).round();

    final List<ContainerUsage> usages =
        acc.values.map((_UsageAccumulator a) => a.toUsage()).toList()
          ..sort((a, b) => b.ml.compareTo(a.ml));

    return EcoSummary(
      totalMl: totalMl,
      trackedMl: trackedMl,
      wasteGrams: waste,
      co2Grams: netCo2,
      recyclingCreditGrams: recyclingCredit,
      score: score,
      reusableMl: reusableMl,
      singleUseMl: singleUseMl,
      singleUseLogs: singleUseLogs,
      recycledLogs: recycledLogs,
      trashedLogs: trashedLogs,
      unmarkedLogs: unmarkedLogs,
      usages: usages,
      bestCaseWasteSavedGrams: math.max(0, bestCaseWaste),
      bestCaseCo2SavedGrams: math.max(0, bestCaseCo2),
    );
  }
}

class _UsageAccumulator {
  _UsageAccumulator(this.container);

  final ContainerType container;
  int ml = 0;
  int logCount = 0;
  double waste = 0;
  double co2 = 0;
  int recycledCount = 0;

  ContainerUsage toUsage() => ContainerUsage(
    container: container,
    ml: ml,
    logCount: logCount,
    wasteGrams: waste,
    co2Grams: co2,
    recycledCount: recycledCount,
  );
}

/// Eko raporunu insan diline çeviren yardımcı.
class EcoNarrative {
  EcoNarrative._();

  static final NumberFormat _gramFormat = NumberFormat('#,##0', 'tr_TR');

  static String _g(double value) {
    if (value >= 1000) {
      return '${NumberFormat('0.0', 'tr_TR').format(value / 1000)} kg';
    }
    return '${_gramFormat.format(value.round())} g';
  }

  /// "Bu ay 284 g atık ürettin — ..." biçiminde dönem raporu.
  static String build(EcoSummary summary, String periodLabel) {
    if (summary.isEmpty) {
      return '$periodLabel için henüz ambalaj verisi yok. '
          'İçecek eklerken kabını seçerek atık ve karbon ayak izini takip '
          'etmeye başlayabilirsin.';
    }

    final StringBuffer buffer = StringBuffer();
    buffer.write(
      '$periodLabel ${_g(summary.wasteGrams)} ambalaj atığı '
      'ürettin',
    );

    if (summary.usages.isEmpty) {
      buffer.write('.');
      return buffer.toString();
    }

    final List<String> parts = <String>[];
    for (final ContainerUsage usage in summary.usages.take(3)) {
      if (usage.container.isReusable) {
        continue;
      }
      parts.add(
        '${usage.logCount} ${usage.container.shortLabel.toLowerCase()}',
      );
    }
    if (parts.isNotEmpty) {
      buffer.write(' — ${parts.join(', ')}');
    }
    buffer.write('.');

    if (summary.singleUseLogs > 0) {
      buffer.write(
        ' Tek kullanımlık ${summary.singleUseLogs} kaydın '
        '${summary.recycledLogs} tanesini geri dönüşüme attın.',
      );
      if (summary.unmarkedLogs > 0) {
        buffer.write(' ${summary.unmarkedLogs} tanesi hâlâ işaretsiz.');
      }
    }

    if (summary.bestCaseWasteSavedGrams > 0.5) {
      buffer.write(
        ' Tüm bu içecekleri mataranla içseydin '
        '${_g(summary.bestCaseWasteSavedGrams)} atık ve '
        '${_g(summary.bestCaseCo2SavedGrams)} CO₂e tasarruf edebilirdin.',
      );
    } else {
      buffer.write(
        ' Neredeyse tamamını tekrar kullanılabilir kaplarla '
        'içmişsin, harika gidiyorsun!',
      );
    }

    return buffer.toString();
  }

  /// Tek cümlelik ipucu (ana sayfa kartı için).
  static String tip(EcoSummary summary) {
    if (summary.isEmpty) {
      return 'Kabını seç, atık ve CO₂ etkini birlikte görelim.';
    }
    if (summary.unmarkedLogs > 0) {
      return '${summary.unmarkedLogs} ambalajı geri dönüşüme atmayı unutma.';
    }
    if (summary.reusablePercent >= 80) {
      return 'Matara kahramanı! %${summary.reusablePercent} tekrar kullanılabilir.';
    }
    if (summary.singleUseLogs > 0) {
      return 'Bir sonraki içeceğinde matarayı dene: '
          '${_g(summary.bestCaseWasteSavedGrams)} atık tasarrufu seni bekliyor.';
    }
    return 'Bugünkü eko skorun ${summary.score}/100.';
  }
}
