import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/models.dart';

/// Cihaz üzerindeki `aquamate.db` SQLite veritabanını yöneten Singleton sınıf.
class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const String dbName = 'aquamate.db';
  static const int dbVersion = 3;

  Database? _database;

  Future<Database> get database async {
    _database ??= await _open();
    return _database!;
  }

  Future<Database> _open() async {
    final String path = p.join(await getDatabasesPath(), dbName);
    return openDatabase(
      path,
      version: dbVersion,
      onCreate: _onCreate,
      onUpgrade: migrate,
      onOpen: _ensureDefaultSettings,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE water_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        drink_type TEXT NOT NULL,
        raw_amount INTEGER NOT NULL,
        effective_amount INTEGER NOT NULL,
        caffeine_mg INTEGER NOT NULL DEFAULT 0,
        container_type TEXT,
        recycled INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE user_settings (
        id INTEGER PRIMARY KEY,
        weight INTEGER NOT NULL DEFAULT 70,
        activity_minutes INTEGER NOT NULL DEFAULT 30,
        daily_goal INTEGER NOT NULL DEFAULT 2500,
        reminder_interval INTEGER NOT NULL DEFAULT 2,
        notifications_enabled INTEGER NOT NULL DEFAULT 0,
        caffeine_limit_mg INTEGER NOT NULL DEFAULT 400,
        bedtime_minutes INTEGER NOT NULL DEFAULT 1380,
        eco_reminder_enabled INTEGER NOT NULL DEFAULT 1,
        ask_container INTEGER NOT NULL DEFAULT 1,
        last_container TEXT,
        onboarding_done INTEGER NOT NULL DEFAULT 0,
        user_name TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE custom_drinks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        label TEXT NOT NULL UNIQUE,
        hydration_factor REAL NOT NULL DEFAULT 1.0,
        caffeine_per_100ml REAL NOT NULL DEFAULT 0,
        icon_index INTEGER NOT NULL DEFAULT 0,
        color_value INTEGER NOT NULL DEFAULT 4280391411,
        category TEXT NOT NULL DEFAULT 'other',
        default_container TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.insert('user_settings', UserSettings.defaults().toMap());
  }

  /// v1 -> v2: kafein ve ambalaj kolonları, özel içecek tablosu, yeni ayarlar.
  /// v2 -> v3: `user_settings.user_name` (selamlamada kullanılan görünen ad).
  ///
  /// Testlerden doğrudan çağrılabilsin diye genel (public) bırakıldı.
  /// Tekrar çalıştırılabilir (idempotent): kolon varsa atlanır.
  static Future<void> migrate(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      final List<Map<String, Object?>> columns = await db.rawQuery(
        'PRAGMA table_info(water_logs)',
      );
      final Set<String> names = columns
          .map((Map<String, Object?> c) => c['name'] as String)
          .toSet();

      if (!names.contains('caffeine_mg')) {
        await db.execute(
          'ALTER TABLE water_logs ADD COLUMN caffeine_mg INTEGER NOT NULL DEFAULT 0',
        );
      }
      if (!names.contains('container_type')) {
        await db.execute(
          'ALTER TABLE water_logs ADD COLUMN container_type TEXT',
        );
      }
      if (!names.contains('recycled')) {
        await db.execute(
          'ALTER TABLE water_logs ADD COLUMN recycled INTEGER NOT NULL DEFAULT 0',
        );
      }

      await db.execute('''
        CREATE TABLE IF NOT EXISTS custom_drinks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          label TEXT NOT NULL UNIQUE,
          hydration_factor REAL NOT NULL DEFAULT 1.0,
          caffeine_per_100ml REAL NOT NULL DEFAULT 0,
          icon_index INTEGER NOT NULL DEFAULT 0,
          color_value INTEGER NOT NULL DEFAULT 4280391411,
          category TEXT NOT NULL DEFAULT 'other',
          default_container TEXT,
          created_at TEXT NOT NULL
        )
      ''');

      final List<Map<String, Object?>> settingColumns = await db.rawQuery(
        'PRAGMA table_info(user_settings)',
      );
      final Set<String> settingNames = settingColumns
          .map((Map<String, Object?> c) => c['name'] as String)
          .toSet();

      Future<void> addSetting(String name, String definition) async {
        if (!settingNames.contains(name)) {
          await db.execute(
            'ALTER TABLE user_settings ADD COLUMN $name $definition',
          );
        }
      }

      await addSetting('caffeine_limit_mg', 'INTEGER NOT NULL DEFAULT 400');
      await addSetting('bedtime_minutes', 'INTEGER NOT NULL DEFAULT 1380');
      await addSetting('eco_reminder_enabled', 'INTEGER NOT NULL DEFAULT 1');
      await addSetting('ask_container', 'INTEGER NOT NULL DEFAULT 1');
      await addSetting('last_container', 'TEXT');
      await addSetting('onboarding_done', 'INTEGER NOT NULL DEFAULT 0');
    }

    if (oldVersion < 3) {
      final List<Map<String, Object?>> settingColumns = await db.rawQuery(
        'PRAGMA table_info(user_settings)',
      );
      final Set<String> names = settingColumns
          .map((Map<String, Object?> c) => c['name'] as String)
          .toSet();
      if (!names.contains('user_name')) {
        await db.execute('ALTER TABLE user_settings ADD COLUMN user_name TEXT');
      }
    }
  }

  Future<void> _ensureDefaultSettings(Database db) async {
    final List<Map<String, Object?>> rows = await db.query(
      'user_settings',
      limit: 1,
    );
    if (rows.isEmpty) {
      await db.insert('user_settings', UserSettings.defaults().toMap());
    }
  }

  // ----------------------------------------------------------- water_logs

  Future<int> insertLog(WaterLog log) async {
    final Database db = await database;
    return db.insert('water_logs', log.toMap()..remove('id'));
  }

  Future<void> updateLog(WaterLog log) async {
    if (log.id == null) {
      return;
    }
    final Database db = await database;
    await db.update(
      'water_logs',
      log.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: <Object?>[log.id],
    );
  }

  /// Yalnızca "geri dönüşüme attım" işaretini günceller.
  Future<void> setRecycled(int id, bool recycled) async {
    final Database db = await database;
    await db.update(
      'water_logs',
      <String, Object?>{'recycled': recycled ? 1 : 0},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> deleteLog(int id) async {
    final Database db = await database;
    await db.delete('water_logs', where: 'id = ?', whereArgs: <Object?>[id]);
  }

  Future<List<WaterLog>> logsForDay(DateTime day) async {
    final DateTime start = DateTime(day.year, day.month, day.day);
    return logsBetween(start, start.add(const Duration(days: 1)));
  }

  Future<List<WaterLog>> logsBetween(DateTime start, DateTime end) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      'water_logs',
      where: 'created_at >= ? AND created_at < ?',
      whereArgs: <Object?>[start.toIso8601String(), end.toIso8601String()],
      orderBy: 'created_at DESC',
    );
    return rows.map(WaterLog.fromMap).toList();
  }

  Future<List<WaterLog>> recentLogs({required int days}) async {
    final DateTime now = DateTime.now();
    final DateTime start = DateTime(now.year, now.month, now.day - (days - 1));
    return logsBetween(start, start.add(Duration(days: days)));
  }

  /// Dönem içindeki toplam kafein (mg) - hızlı özet için.
  Future<int> caffeineBetween(DateTime start, DateTime end) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT COALESCE(SUM(caffeine_mg), 0) AS total FROM water_logs '
      'WHERE created_at >= ? AND created_at < ?',
      <Object?>[start.toIso8601String(), end.toIso8601String()],
    );
    return (rows.first['total'] as num?)?.toInt() ?? 0;
  }

  /// En çok kafein alınan günün mg değeri (dönem içinde).
  Future<int> maxDailyCaffeineBetween(DateTime start, DateTime end) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT date(created_at) AS day, SUM(caffeine_mg) AS total '
      'FROM water_logs WHERE created_at >= ? AND created_at < ? '
      'GROUP BY day ORDER BY total DESC LIMIT 1',
      <Object?>[start.toIso8601String(), end.toIso8601String()],
    );
    if (rows.isEmpty) {
      return 0;
    }
    return (rows.first['total'] as num?)?.toInt() ?? 0;
  }

  Future<int> streakDays() async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT DISTINCT date(created_at) AS day FROM water_logs ORDER BY day DESC',
    );
    final Set<String> days = rows.map((m) => m['day'] as String).toSet();
    if (days.isEmpty) {
      return 0;
    }

    final DateTime now = DateTime.now();
    DateTime cursor = DateTime(now.year, now.month, now.day);
    if (!_hasDay(days, cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!_hasDay(days, cursor)) {
        return 0;
      }
    }

    int streak = 0;
    while (_hasDay(days, cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  bool _hasDay(Set<String> days, DateTime day) {
    final String key =
        '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    return days.contains(key);
  }

  // -------------------------------------------------------- user_settings

  Future<UserSettings> getSettings() async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      'user_settings',
      where: 'id = 1',
      limit: 1,
    );
    if (rows.isEmpty) {
      final UserSettings defaults = UserSettings.defaults();
      await db.insert('user_settings', defaults.toMap());
      return defaults;
    }
    return UserSettings.fromMap(rows.first);
  }

  Future<void> saveSettings(UserSettings settings) async {
    final Database db = await database;
    await db.insert(
      'user_settings',
      settings.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // -------------------------------------------------------- custom_drinks

  Future<List<Map<String, Object?>>> customDrinkRows() async {
    final Database db = await database;
    return db.query('custom_drinks', orderBy: 'created_at ASC');
  }

  Future<int> insertCustomDrink(Map<String, Object?> row) async {
    final Database db = await database;
    return db.insert('custom_drinks', row);
  }

  Future<void> updateCustomDrink(int id, Map<String, Object?> row) async {
    final Database db = await database;
    await db.update(
      'custom_drinks',
      row,
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> deleteCustomDrink(int id) async {
    final Database db = await database;
    await db.delete('custom_drinks', where: 'id = ?', whereArgs: <Object?>[id]);
  }

  Future<bool> customDrinkLabelExists(String label, {int? exceptId}) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      'custom_drinks',
      columns: <String>['id'],
      where: exceptId == null ? 'label = ?' : 'label = ? AND id != ?',
      whereArgs: exceptId == null
          ? <Object?>[label]
          : <Object?>[label, exceptId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  // ------------------------------------------------------ demo yardımcıları

  /// Yalnızca debug/sunum için: son 7 güne gerçekçi örnek kayıt ekler.
  ///
  /// Release derlemesinde hiçbir şey yazmaz; ürün verisi her zaman boş başlar.
  Future<void> addSampleData() async {
    if (!kDebugMode) {
      return;
    }
    final Database db = await database;
    final DateTime now = DateTime.now();
    final Batch batch = db.batch();

    for (int back = 6; back >= 0; back--) {
      final DateTime day = DateTime(now.year, now.month, now.day - back);
      for (final Map<String, Object?> row in _demoRowsForDay(
        day,
        upToNow: back == 0,
      )) {
        batch.insert('water_logs', row);
      }
    }
    await batch.commit(noResult: true);
  }

  /// Tüm kayıtları siler (veri sıfırlama).
  Future<void> clearAllLogs() async {
    final Database db = await database;
    await db.delete('water_logs');
  }

  /// Gün başına gerçekçi, deterministik (rastgele ama tekrarlanabilir) kayıtlar.
  /// Yalnızca debug/sunum araçlarında kullanılır.
  List<Map<String, Object?>> _demoRowsForDay(
    DateTime day, {
    bool upToNow = false,
  }) {
    final int dayKey = day.year * 10000 + day.month * 100 + day.day;
    final Random random = Random(dayKey);
    final DateTime now = DateTime.now();

    const List<List<Object?>> pool = <List<Object?>>[
      <Object?>[7, 45, 'Su', 250, 'reusable_bottle', 0],
      <Object?>[9, 10, 'Çay', 200, 'glass_cup', 0],
      <Object?>[10, 40, 'Maden Suyu', 250, 'glass_bottle', 1],
      <Object?>[12, 30, 'Su', 330, 'pet_bottle', 0],
      <Object?>[14, 0, 'Kahve', 200, 'paper_cup', 0],
      <Object?>[15, 45, 'Çay', 200, 'glass_cup', 0],
      <Object?>[17, 30, 'Su', 500, 'reusable_bottle', 0],
      <Object?>[19, 15, 'Maden Suyu', 330, 'glass_bottle', 1],
      <Object?>[21, 0, 'Su', 330, 'pet_bottle', 1],
    ];

    final List<List<Object?>> shuffled = List<List<Object?>>.from(pool)
      ..shuffle(random);
    final int count = 5 + random.nextInt(2);
    final List<List<Object?>> picked = shuffled.take(count).toList()
      ..sort((a, b) {
        final int ma = (a[0] as int) * 60 + (a[1] as int);
        final int mb = (b[0] as int) * 60 + (b[1] as int);
        return ma.compareTo(mb);
      });

    final List<Map<String, Object?>> rows = <Map<String, Object?>>[];
    for (final List<Object?> item in picked) {
      final DateTime createdAt = DateTime(
        day.year,
        day.month,
        day.day,
        item[0] as int,
        item[1] as int,
      );
      if (upToNow && createdAt.isAfter(now)) {
        continue;
      }
      final String label = item[2] as String;
      final int raw = item[3] as int;
      final DrinkType type = drinkTypeOf(label);
      rows.add(<String, Object?>{
        'drink_type': label,
        'raw_amount': raw,
        'effective_amount': type.effectiveOf(raw),
        'caffeine_mg': type.caffeineOf(raw),
        'container_type': item[4] as String,
        'recycled': item[5] as int,
        'created_at': createdAt.toIso8601String(),
      });
    }
    return rows;
  }
}
