import 'package:audioplayers/audioplayers.dart';

/// Kısa ses efektlerini (su damlası) yöneten yardımcı servis.
class SoundService {
  SoundService._();

  static AudioPlayer? _dropPlayer;

  /// Su eklendiğinde çalan "su damlası" ses efekti.
  static Future<void> playDrop() async {
    try {
      final AudioPlayer player = _dropPlayer ??= AudioPlayer();
      await player.stop();
      await player.play(AssetSource('audio/drop.mp3'));
    } catch (_) {
      // Ses dosyası yoksa veya çalınamazsa uygulama akışı kesilmez.
    }
  }

  static Future<void> dispose() async {
    try {
      await _dropPlayer?.dispose();
    } catch (_) {
      // Yoksayılır.
    }
    _dropPlayer = null;
  }
}
