import 'package:flame_audio/flame_audio.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  bool _soundEnabled = true; // Enable by default
  bool _musicEnabled = true; // Enable by default

  // Simplified throttling - only for frequent sounds
  DateTime _lastJumpSound = DateTime.now();
  DateTime _lastLandSound = DateTime.now();
  DateTime _lastCoinSound = DateTime.now();

  // Audio volume control based on game speed
  double _getVolumeForSpeed(double gameSpeed) {
    if (gameSpeed > 600) return 0.4;
    if (gameSpeed > 500) return 0.6;
    if (gameSpeed > 400) return 0.8;
    return 1.0;
  }

  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;

  void toggleSound() {
    _soundEnabled = !_soundEnabled;
  }

  void toggleMusic() {
    _musicEnabled = !_musicEnabled;
    if (!_musicEnabled) {
      FlameAudio.bgm.stop();
    }
  }

  // Play jump sound - using your jump.mp3 file
  void playJump() {
    if (!_soundEnabled) return;

    // Always play jump sounds, but with minimal delay to prevent audio overlap
    if (_canPlaySound(_lastJumpSound, minDelay: 100)) {
      _lastJumpSound = DateTime.now();
      _playSoundSafely('sfx/jump.mp3', volume: 0.7);
    }
  }

  // Play land sound - using your land.mp3 file
  void playLand() {
    if (!_soundEnabled) return;

    // Throttle landing sounds to prevent spam
    if (_canPlaySound(_lastLandSound, minDelay: 150)) {
      _lastLandSound = DateTime.now();
      _playSoundSafely('sfx/land.mp3', volume: 0.6);
    }
  }

  // Play coin collect sound - using your coin_collect.mp3 file
  void playCoinCollect({double gameSpeed = 250}) {
    if (!_soundEnabled) return;

    // Play EVERY coin collect sound, but with throttling to prevent overlap
    if (_canPlaySound(_lastCoinSound, minDelay: 50)) {
      // Shorter delay
      _lastCoinSound = DateTime.now();
      final volume = _getVolumeForSpeed(gameSpeed);
      _playSoundSafely('sfx/coin_collect.mp3', volume: volume * 0.9);
    }
  }

  bool _canPlaySound(DateTime lastPlayed, {int minDelay = 80}) {
    return DateTime.now().difference(lastPlayed).inMilliseconds > minDelay;
  }

  // Other game sounds using your available files
  void playCollision() {
    if (_soundEnabled) {
      _playSoundSafely('sfx/collision.mp3', volume: 0.8);
    }
  }

  void playGameOver() {
    if (_soundEnabled) {
      _playSoundSafely('sfx/game_over.mp3', volume: 1.0);
    }
  }

  void playDoubleJump() {
    if (_soundEnabled) {
      _playSoundSafely('sfx/double_jump.mp3', volume: 0.8);
    }
  }

  void playShieldActivate() {
    if (_soundEnabled) {
      _playSoundSafely('sfx/shield_activate.mp3', volume: 0.8);
    }
  }

  void playMagnetActivate() {
    if (_soundEnabled) {
      _playSoundSafely('sfx/magnet_activate.mp3', volume: 0.8);
    }
  }

  void playButtonClick() {
    if (_soundEnabled) {
      _playSoundSafely('sfx/button_click.mp3', volume: 0.6);
    }
  }

  // Helper method with volume control
  void _playSoundSafely(String path, {double volume = 1.0}) {
    try {
      FlameAudio.play(path, volume: volume);
    } catch (e) {
      print('Audio error playing $path: $e');
      // Silently handle audio errors in production
    }
  }

  // Background Music - if you have music files
  void playGameplayMusic() {
    if (_musicEnabled) {
      try {
        FlameAudio.bgm.play('music/gameplay.mp3', volume: 0.4);
      } catch (e) {
        print('Music error: $e');
      }
    }
  }

  void playMenuMusic() {
    if (_musicEnabled) {
      try {
        FlameAudio.bgm.play('music/menu.mp3', volume: 0.4);
      } catch (e) {
        print('Music error: $e');
      }
    }
  }

  void stopMusic() {
    try {
      FlameAudio.bgm.stop();
    } catch (e) {
      print('Error stopping music: $e');
    }
  }

  // Reset counters when game restarts
  void resetCounters() {}

  // Preload your specific audio files
  Future<void> preloadAudio() async {
    try {
      await FlameAudio.audioCache.loadAll([
        // Your available sound files
        'sfx/jump.mp3',
        'sfx/land.mp3',
        'sfx/coin_collect.mp3',
        'sfx/collision.mp3',
        'sfx/game_over.mp3',
        'sfx/double_jump.mp3',
        'sfx/shield_activate.mp3',
        'sfx/magnet_activate.mp3',
        'sfx/button_click.mp3',
        // Add music if you have it
        // 'music/gameplay.mp3',
        // 'music/menu.mp3',
      ]);
      print('Audio files preloaded successfully');
    } catch (e) {
      print('Error preloading audio: $e');
      // Continue without audio if files are missing
    }
  }
}
