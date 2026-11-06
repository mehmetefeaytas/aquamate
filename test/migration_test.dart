import 'package:aquamate/data/database_helper.dart';
import 'package:aquamate/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// v1 şeması (kafein ve ambalaj kolonları yok) — migrasyon doğrulaması için.
const String _v1WaterLogs = '''
  CREATE TABLE water_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    drink_type TEXT NOT NULL,
    raw_amount INTEGER NOT NULL,
    effective_amount INTEGER NOT NULL,
    created_at TEXT NOT NULL
  )
''';

const String _v1Settings = '''
  CREATE TABLE user_settings (
    id INTEGER PRIMARY KEY,
    weight INTEGER NOT NULL DEFAULT 70,
    activity_minutes INTEGER NOT NULL DEFAULT 30,
    daily_goal INTEGER NOT NULL DEFAULT 2500,
    reminder_interval INTEGER NOT NULL DEFAULT 2,
    notifications_enabled INTEGER NOT NULL DEFAULT 0
  )
''';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Veritabanı v1 -> v2 migrasyonu', () {
    late Database db;

    setUp(() async {
      db = await databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(version: 1),
      );
      await db.execute(_v1WaterLogs);
      await db.execute(_v1Settings);
      await db.insert('user_settings', <String, Object?>{
        'id': 1,
        'weight': 82,
        'activity_minutes': 45,
        'daily_goal': 3100,
        'reminder_interval': 3,
        'notifications_enabled': 1,
      });
      await db.insert('water_logs', <String, Object?>{
        'drink_type': 'Kahve',
        'raw_amount': 200,
        'effective_amount': 160,
        'created_at': '2026-10-15T09:30:00.000',
      });
    });

    tearDown(() async {
      await db.close();
    });

    /// Üretim koduyla aynı migrasyon adımlarını uygular.
    Future<void> migrate() => DatabaseHelper.migrate(db, 1, 3);

    test('eski kayıtlar korunur ve yeni kolonlar varsayılanla gelir', () async {
      await migrate();

      final rows = await db.query('water_logs');
      expect(rows, hasLength(1));
      expect(rows.first['drink_type'], 'Kahve');
      expect(rows.first['raw_amount'], 200);
      expect(rows.first['caffeine_mg'], 0);
      expect(rows.first['container_type'], isNull);
      expect(rows.first['recycled'], 0);
    });

    test('eski ayarlar korunur, yeni ayarlar varsayılan alır', () async {
      await migrate();

      final rows = await db.query('user_settings');
      expect(rows, hasLength(1));
      final UserSettings settings = UserSettings.fromMap(rows.first);
      expect(settings.weight, 82);
      expect(settings.dailyGoal, 3100);
      expect(settings.reminderInterval, 3);
      expect(settings.caffeineLimitMg, 400);
      expect(settings.bedtimeMinutes, 23 * 60);
      expect(settings.askContainer, isTrue);
      expect(settings.onboardingDone, isFalse);
    });

    test('custom_drinks tablosu oluşturulur', () async {
      await migrate();

      await db.insert('custom_drinks', <String, Object?>{
        'label': 'Ev Limonatası',
        'hydration_factor': 0.92,
        'caffeine_per_100ml': 0,
        'icon_index': 2,
        'color_value': 0xFFFACC15,
        'category': 'juice',
        'default_container': 'glass_cup',
        'created_at': DateTime(2026, 11, 6).toIso8601String(),
      });

      final rows = await db.query('custom_drinks');
      expect(rows, hasLength(1));
      expect(rows.first['label'], 'Ev Limonatası');
    });

    test('user_name kolonu eklenir ve ad okunur', () async {
      await migrate();

      await db.update('user_settings', <String, Object?>{
        'user_name': 'Efe',
      }, where: 'id = 1');
      final rows = await db.query('user_settings', where: 'id = 1');
      final UserSettings settings = UserSettings.fromMap(rows.first);
      expect(settings.userName, 'Efe');
      expect(settings.displayName, 'Efe');
    });

    test('migrasyon iki kez çağrılırsa hata vermez (idempotent)', () async {
      await migrate();
      await migrate();

      final columns = await db.rawQuery('PRAGMA table_info(water_logs)');
      final names = columns.map((c) => c['name']).toList();
      expect(names.where((n) => n == 'caffeine_mg'), hasLength(1));
    });

    test('yeni kayıt tüm alanlarla yazılıp okunabilir', () async {
      await migrate();

      await db.insert('water_logs', <String, Object?>{
        'drink_type': 'Kahve',
        'raw_amount': 250,
        'effective_amount': 200,
        'caffeine_mg': 100,
        'container_type': 'paper_cup',
        'recycled': 1,
        'created_at': DateTime(2026, 11, 6, 9).toIso8601String(),
      });

      final rows = await db.query(
        'water_logs',
        where: 'caffeine_mg > ?',
        whereArgs: <Object?>[0],
      );
      final WaterLog log = WaterLog.fromMap(rows.first);
      expect(log.caffeineMg, 100);
      expect(log.containerId, 'paper_cup');
      expect(log.recycled, isTrue);
    });
  });
}
