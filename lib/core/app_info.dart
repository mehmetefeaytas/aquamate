/// Uygulama kimliği ve yasal metinler için tek kaynak.
class AppInfo {
  const AppInfo._();

  static const String name = 'AquaMate';
  static const String tagline =
      'Hidrasyon, kafein ve sürdürülebilirlik asistanı';
  static const String version = '1.0.0';
  static const String buildNumber = '5';
  static const String versionLabel = '$version ($buildNumber)';

  /// Destek ve geri bildirim adresi.
  static const String supportEmail = 'efeyapiyor@gmail.com';

  /// Geliştirici bilgisi (Hakkında ekranında gösterilir).
  static const String developerName = 'Mehmet Efe Aytaş';
  static const String developerUrl = 'https://linktr.ee/efeyapiyor';
  static const String developerUrlLabel = 'linktr.ee/efeyapiyor';

  /// App Store Connect'te "Privacy Policy URL" alanına yazılacak adres.
  static const String privacyUrl = 'https://aquamate.app/gizlilik';
  static const String termsUrl = 'https://aquamate.app/kosullar';

  /// Adı girilmemiş kullanıcılar için ana sayfa selamlaması.
  static String greeting(String? userName) {
    final String trimmed = (userName ?? '').trim();
    if (trimmed.isEmpty) {
      return 'Merhaba!';
    }
    return 'Merhaba, $trimmed';
  }
}
