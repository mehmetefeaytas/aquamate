import 'package:aquamate/core/app_info.dart';
import 'package:aquamate/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Selamlama', () {
    test('ad varsa "Merhaba, ad" döner', () {
      expect(AppInfo.greeting('Efe'), 'Merhaba, Efe');
      expect(AppInfo.greeting('Mehmet Efe'), 'Merhaba, Mehmet Efe');
    });

    test('ad yoksa veya boşsa sade selamlama döner', () {
      expect(AppInfo.greeting(null), 'Merhaba!');
      expect(AppInfo.greeting(''), 'Merhaba!');
      expect(AppInfo.greeting('    '), 'Merhaba!');
    });

    test('baştaki ve sondaki boşluklar temizlenir', () {
      expect(AppInfo.greeting('  Efe  '), 'Merhaba, Efe');
    });

    test('UserSettings.displayName selamlamaya girdi olur', () {
      final UserSettings settings = UserSettings.defaults().copyWith(
        userName: '  Efe ',
      );
      expect(AppInfo.greeting(settings.displayName), 'Merhaba, Efe');
      expect(AppInfo.greeting(UserSettings.defaults().displayName), 'Merhaba!');
    });
  });

  group('İletişim ve geliştirici bilgisi', () {
    test('destek e-postası doğru', () {
      expect(AppInfo.supportEmail, 'efeyapiyor@gmail.com');
      expect(AppInfo.supportEmail, contains('@'));
    });

    test('geliştirici adı ve bağlantısı doğru', () {
      expect(AppInfo.developerName, 'Mehmet Efe Aytaş');
      expect(AppInfo.developerUrl, 'https://linktr.ee/efeyapiyor');
      expect(AppInfo.developerUrlLabel, 'linktr.ee/efeyapiyor');
    });
  });

  group('Sürüm bilgisi', () {
    test('sürüm etiketi version + build içerir', () {
      expect(AppInfo.version, '1.0.0');
      expect(AppInfo.buildNumber, '5');
      expect(AppInfo.versionLabel, '1.0.0 (5)');
    });
  });

  group('Temiz başlangıç', () {
    test('boş kullanıcı adı veritabanına null yazılır', () {
      final UserSettings settings = UserSettings.defaults().copyWith(
        userName: '   ',
      );
      expect(settings.toMap()['user_name'], isNull);
    });

    test('varsayılan ayarlarda ad ve onboarding işareti yoktur', () {
      final UserSettings defaults = UserSettings.defaults();
      expect(defaults.displayName, isNull);
      expect(defaults.onboardingDone, isFalse);
    });
  });
}
