import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Yerel bildirim sistemi: anlık bildirimler + zamanlanmış su içme hatırlatmaları.
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static int _nextId = 0;

  static const String channelId = 'aquamate_reminders';
  static const String channelName = 'AquaMate Hatırlatmaları';
  static const String channelDescription =
      'Günlük su hedefi için zamanlanmış hatırlatmalar.';

  static const String ecoChannelId = 'aquamate_eco';
  static const String ecoChannelName = 'AquaMate Sürdürülebilirlik';
  static const String ecoChannelDescription =
      'Geri dönüşüm ve haftalık sürdürülebilirlik özeti hatırlatmaları.';

  static const int _ecoReminderId = 91000;
  static const int _weeklyEcoSummaryId = 91001;

  /// Eklentiyi bir kez hazırlar ve cihaz saat dilimini ayarlar.
  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    tz_data.initializeTimeZones();
    await _setLocalTimeZone();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings darwinSettings =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      ),
    );
    _initialized = true;
  }

  static Future<void> _setLocalTimeZone() async {
    try {
      final TimezoneInfo info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Platform bilgi veremezse Türkiye saat dilimi ile devam et.
      try {
        tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
      } catch (_) {
        // tz verisi yüklenemediğinde UTC kullanılır (bildirimler yine çalışır).
      }
    }
  }

  static NotificationDetails get _details => const NotificationDetails(
    android: AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(''),
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  static NotificationDetails get _ecoDetails => const NotificationDetails(
    android: AndroidNotificationDetails(
      ecoChannelId,
      ecoChannelName,
      channelDescription: ecoChannelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: false,
      enableVibration: false,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(''),
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    ),
  );

  static int _id() {
    _nextId++;
    return _nextId;
  }

  /// Kullanıcıya bildirim izni sorar, izin durumunu döner.
  static Future<bool> requestPermission() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImpl = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidImpl != null) {
        await androidImpl.requestNotificationsPermission();
        return await androidImpl.areNotificationsEnabled() ?? true;
      }

      final IOSFlutterLocalNotificationsPlugin? iosImpl = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (iosImpl != null) {
        final bool? granted = await iosImpl.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (_) {
      // İzin isteği desteklenmeyen platformlarda sessizce geçilir.
    }
    return true;
  }

  /// Sunum sırasında hemen gösterilecek test bildirimi.
  static Future<void> showNow({
    required String title,
    required String body,
    bool ecoStyle = false,
  }) async {
    await initialize();
    await _plugin.show(
      id: _id(),
      title: title,
      body: body,
      notificationDetails: ecoStyle ? _ecoDetails : _details,
    );
  }

  /// Akşam 21:00 geri dönüşüm hatırlatması (günlük tekrar).
  static Future<void> scheduleEcoReminder({required bool enabled}) async {
    await initialize();
    await cancelEcoReminder();
    if (!enabled) {
      return;
    }

    try {
      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime target = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        21,
      );
      if (target.isBefore(now)) {
        target = target.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        id: _ecoReminderId,
        title: 'Geri dönüşümü unutma',
        body:
            'Bugün tek kullanımlık bir ambalaj kullandın. Şişeni ya da bardağını geri dönüşüme atmayı unutma.',
        scheduledDate: target,
        notificationDetails: _ecoDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      // Desteklenmeyen platformlarda yok sayılır.
    }
  }

  /// Pazar 20:00 haftalık eko özeti.
  static Future<void> scheduleWeeklyEcoSummary({required bool enabled}) async {
    await initialize();
    try {
      await _plugin.cancel(id: _weeklyEcoSummaryId);
    } catch (_) {
      // Yoksayılır.
    }
    if (!enabled) {
      return;
    }

    try {
      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      int daysUntilSunday = (DateTime.sunday - now.weekday) % 7;
      if (daysUntilSunday < 0) {
        daysUntilSunday += 7;
      }
      tz.TZDateTime target = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day + daysUntilSunday,
        20,
      );
      if (!target.isAfter(now)) {
        target = target.add(const Duration(days: 7));
      }

      await _plugin.zonedSchedule(
        id: _weeklyEcoSummaryId,
        title: 'Haftalık sürdürülebilirlik özetin hazır',
        body:
            'Bu haftanın atık ve karbon ayak izini görmek için Eko sekmesine göz at.',
        scheduledDate: target,
        notificationDetails: _ecoDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (_) {
      // Desteklenmeyen platformlarda yok sayılır.
    }
  }

  /// Zamanlanmış su hatırlatmalarını iptal eder (eko hatırlatmaları korunur).
  static Future<void> cancelScheduled() async {
    for (int k = 1; k <= 24; k++) {
      try {
        await _plugin.cancel(id: 90000 + k);
      } catch (_) {
        // Desteklenmeyen platformlarda yok sayılır.
      }
    }
  }

  static Future<void> cancelEcoReminder() async {
    try {
      await _plugin.cancel(id: _ecoReminderId);
    } catch (_) {
      // Yoksayılır.
    }
  }

  /// Günlük hedefe göre her `intervalHours` saatte bir tekrarlayan hatırlatma.
  static Future<void> scheduleRecurring({
    required int intervalHours,
    required int dailyGoalMl,
  }) async {
    await initialize();
    await cancelScheduled();

    final int hours = intervalHours < 1 ? 1 : intervalHours;
    final int perDay = 24 ~/ hours;
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    for (int k = 1; k <= perDay; k++) {
      final tz.TZDateTime target = now.add(Duration(hours: k * hours));
      final tz.TZDateTime exact = tz.TZDateTime(
        tz.local,
        target.year,
        target.month,
        target.day,
        target.hour,
        target.minute,
      );
      if (exact.isBefore(now.add(const Duration(minutes: 2)))) {
        continue;
      }

      await _plugin.zonedSchedule(
        id: 90000 + k,
        title: 'Su molası verdiniz mi?',
        body:
            'Günlük hedefiniz $dailyGoalMl ml. Şimdi bir bardak su içmenin tam zamanı.',
        scheduledDate: exact,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }
}
