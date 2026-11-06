import 'drink_catalog.dart';

export 'container_type.dart';
export 'drink_catalog.dart';
export 'eco.dart';
export 'period.dart';

/// `water_logs` tablosunun Dart modeli.
class WaterLog {
  const WaterLog({
    this.id,
    required this.drinkType,
    required this.rawAmount,
    required this.effectiveAmount,
    required this.createdAt,
    this.caffeineMg = 0,
    this.containerId,
    this.recycled = false,
  });

  final int? id;
  final String drinkType;
  final int rawAmount;
  final int effectiveAmount;
  final DateTime createdAt;

  /// Bu kaydın kafein katkısı (mg).
  final int caffeineMg;

  /// İçeceğin içildiği kap kimliği; `null` ise bilinmiyor (eski kayıtlar).
  final String? containerId;

  /// Tek kullanımlık ambalaj geri dönüşüme atıldı mı?
  final bool recycled;

  factory WaterLog.fromMap(Map<String, Object?> map) => WaterLog(
    id: map['id'] as int?,
    drinkType: map['drink_type'] as String,
    rawAmount: (map['raw_amount'] as num).toInt(),
    effectiveAmount: (map['effective_amount'] as num).toInt(),
    caffeineMg: (map['caffeine_mg'] as num?)?.toInt() ?? 0,
    containerId: map['container_type'] as String?,
    recycled: ((map['recycled'] as num?)?.toInt() ?? 0) == 1,
    createdAt: DateTime.parse(map['created_at'] as String),
  );

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'drink_type': drinkType,
    'raw_amount': rawAmount,
    'effective_amount': effectiveAmount,
    'caffeine_mg': caffeineMg,
    'container_type': containerId,
    'recycled': recycled ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
  };

  WaterLog copyWith({
    int? id,
    String? drinkType,
    int? rawAmount,
    int? effectiveAmount,
    DateTime? createdAt,
    int? caffeineMg,
    String? containerId,
    bool? recycled,
  }) {
    return WaterLog(
      id: id ?? this.id,
      drinkType: drinkType ?? this.drinkType,
      rawAmount: rawAmount ?? this.rawAmount,
      effectiveAmount: effectiveAmount ?? this.effectiveAmount,
      createdAt: createdAt ?? this.createdAt,
      caffeineMg: caffeineMg ?? this.caffeineMg,
      containerId: containerId ?? this.containerId,
      recycled: recycled ?? this.recycled,
    );
  }

  DrinkType get type => drinkTypeOf(drinkType);

  /// Örn: "+200 ml Kahve -> Net: 160 ml"
  String get summaryLine =>
      '+$rawAmount ml $drinkType -> Net: $effectiveAmount ml';
}

/// Akıllı hedef hesaplayıcı:
/// `Kilo * 35 ml + (Egzersiz Dakikası / 30) * 350 ml`
class GoalCalculator {
  const GoalCalculator._();

  static int calculate({required int weight, required int activityMinutes}) {
    final int fromWeight = weight * 35;
    final int fromActivity = ((activityMinutes / 30) * 350).round();
    return (fromWeight + fromActivity).round();
  }
}

/// Kafein tüketim yardımcıları.
class CaffeineCalculator {
  const CaffeineCalculator._();

  /// Yetişkinler için genel üst sınır (EFSA / FDA): 400 mg/gün.
  static const int defaultLimitMg = 400;

  /// Yatmadan kaç saat önce kafein alımı kesilmeli.
  static const int cutoffHoursBeforeBed = 8;

  /// Günlük limitle karşılaştırılmış durum.
  static CaffeineStatus status({
    required int consumedMg,
    required int limitMg,
  }) {
    final int limit = limitMg <= 0 ? defaultLimitMg : limitMg;
    final double ratio = consumedMg / limit;
    if (ratio >= 1) {
      return CaffeineStatus.exceeded;
    }
    if (ratio >= 0.75) {
      return CaffeineStatus.high;
    }
    if (ratio >= 0.4) {
      return CaffeineStatus.moderate;
    }
    return CaffeineStatus.low;
  }

  /// Önerilen son kafein saatini döndürür (uyku saati - 8 saat).
  static String cutoffLabel(int bedtimeMinutes) {
    final int total = (bedtimeMinutes - cutoffHoursBeforeBed * 60) % (24 * 60);
    final int normalized = total < 0 ? total + 24 * 60 : total;
    final int hour = normalized ~/ 60;
    final int minute = normalized % 60;
    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }
}

enum CaffeineStatus {
  low,
  moderate,
  high,
  exceeded;

  String get label {
    switch (this) {
      case CaffeineStatus.low:
        return 'Düşük';
      case CaffeineStatus.moderate:
        return 'Dengeli';
      case CaffeineStatus.high:
        return 'Yüksek';
      case CaffeineStatus.exceeded:
        return 'Limit aşıldı';
    }
  }
}

/// `user_settings` tablosunun Dart modeli.
class UserSettings {
  const UserSettings({
    this.id = 1,
    required this.weight,
    required this.activityMinutes,
    required this.dailyGoal,
    required this.reminderInterval,
    required this.notificationsEnabled,
    this.caffeineLimitMg = CaffeineCalculator.defaultLimitMg,
    this.bedtimeMinutes = 23 * 60,
    this.ecoReminderEnabled = true,
    this.askContainer = true,
    this.lastContainerId = 'reusable_bottle',
    this.onboardingDone = false,
    this.userName,
  });

  factory UserSettings.defaults() => const UserSettings(
    id: 1,
    weight: 70,
    activityMinutes: 30,
    dailyGoal: 2500,
    reminderInterval: 2,
    notificationsEnabled: false,
  );

  final int id;
  final int weight;
  final int activityMinutes;
  final int dailyGoal;
  final int reminderInterval;
  final bool notificationsEnabled;

  /// Günlük kafein üst sınırı (mg).
  final int caffeineLimitMg;

  /// Uyku saati (gün içindeki dakika: 23:00 -> 1380).
  final int bedtimeMinutes;

  /// Akşam geri dönüşüm hatırlatması açık mı?
  final bool ecoReminderEnabled;

  /// Her eklemede kap sorulsun mu?
  final bool askContainer;

  /// Son seçilen kap (akıllı varsayılan).
  final String? lastContainerId;

  /// İlk açılış tanıtımı tamamlandı mı?
  final bool onboardingDone;

  /// Kullanıcının tercih ettiği görünen ad (selamlamada kullanılır).
  final String? userName;

  /// Selamlama için kullanılacak ad; boşsa `null`.
  String? get displayName {
    final String trimmed = (userName ?? '').trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  int get suggestedGoal => GoalCalculator.calculate(
    weight: weight,
    activityMinutes: activityMinutes,
  );

  /// "23:00" biçiminde uyku saati.
  String get bedtimeLabel {
    final int hour = bedtimeMinutes ~/ 60;
    final int minute = bedtimeMinutes % 60;
    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }

  UserSettings copyWith({
    int? weight,
    int? activityMinutes,
    int? dailyGoal,
    int? reminderInterval,
    bool? notificationsEnabled,
    int? caffeineLimitMg,
    int? bedtimeMinutes,
    bool? ecoReminderEnabled,
    bool? askContainer,
    String? lastContainerId,
    bool? onboardingDone,
    String? userName,
  }) => UserSettings(
    id: id,
    weight: weight ?? this.weight,
    activityMinutes: activityMinutes ?? this.activityMinutes,
    dailyGoal: dailyGoal ?? this.dailyGoal,
    reminderInterval: reminderInterval ?? this.reminderInterval,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    caffeineLimitMg: caffeineLimitMg ?? this.caffeineLimitMg,
    bedtimeMinutes: bedtimeMinutes ?? this.bedtimeMinutes,
    ecoReminderEnabled: ecoReminderEnabled ?? this.ecoReminderEnabled,
    askContainer: askContainer ?? this.askContainer,
    lastContainerId: lastContainerId ?? this.lastContainerId,
    onboardingDone: onboardingDone ?? this.onboardingDone,
    userName: userName ?? this.userName,
  );

  factory UserSettings.fromMap(Map<String, Object?> map) => UserSettings(
    id: (map['id'] as num?)?.toInt() ?? 1,
    weight: (map['weight'] as num?)?.toInt() ?? 70,
    activityMinutes: (map['activity_minutes'] as num?)?.toInt() ?? 30,
    dailyGoal: (map['daily_goal'] as num?)?.toInt() ?? 2500,
    reminderInterval: (map['reminder_interval'] as num?)?.toInt() ?? 2,
    notificationsEnabled:
        ((map['notifications_enabled'] as num?)?.toInt() ?? 0) == 1,
    caffeineLimitMg:
        (map['caffeine_limit_mg'] as num?)?.toInt() ??
        CaffeineCalculator.defaultLimitMg,
    bedtimeMinutes: (map['bedtime_minutes'] as num?)?.toInt() ?? 23 * 60,
    ecoReminderEnabled:
        ((map['eco_reminder_enabled'] as num?)?.toInt() ?? 1) == 1,
    askContainer: ((map['ask_container'] as num?)?.toInt() ?? 1) == 1,
    lastContainerId: map['last_container'] as String? ?? 'reusable_bottle',
    onboardingDone: ((map['onboarding_done'] as num?)?.toInt() ?? 0) == 1,
    userName: _nameOrNull(map['user_name'] as String?),
  );

  static String? _nameOrNull(String? raw) {
    final String trimmed = (raw ?? '').trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'weight': weight,
    'activity_minutes': activityMinutes,
    'daily_goal': dailyGoal,
    'reminder_interval': reminderInterval,
    'notifications_enabled': notificationsEnabled ? 1 : 0,
    'caffeine_limit_mg': caffeineLimitMg,
    'bedtime_minutes': bedtimeMinutes,
    'eco_reminder_enabled': ecoReminderEnabled ? 1 : 0,
    'ask_container': askContainer ? 1 : 0,
    'last_container': lastContainerId,
    'onboarding_done': onboardingDone ? 1 : 0,
    'user_name': displayName,
  };
}
