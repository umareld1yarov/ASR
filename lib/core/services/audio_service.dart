import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Сервис для воспроизведения звуковых эффектов в приложении.
class AudioService {
  AudioService._();

  static final AudioPlayer _player = AudioPlayer();

  /// Воспроизвести звук смены активности из `assets/sounds/activity_switch.mp3`.
  static Future<void> playSwitchSound() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/activity_switch.mp3'));
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'Звук смены активности не найден (положите activity_switch.mp3 в assets/sounds/): $e',
        );
      }
    }
  }
}
