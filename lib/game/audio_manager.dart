import 'package:flame_audio/flame_audio.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  bool _soundEnabled = false;
  bool _musicEnabled = false;

  // Simplified throttling - only for frequent sounds
  DateTime _lastJumpSound = DateTime.now();
  DateTime _lastCoinSound = DateTime.now();
// Reasonable delay

  // Smart audio reduction counters - only for coins now
  int _coinSoundCounter = 0;

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

  // Play EVERY jump sound - but with shorter delay and lower volume at high speeds
  void playJump() {
    if (!_soundEnabled) return;

    // Always play jump sounds, but with minimal delay to prevent audio overlap
    if (_canPlaySound(_lastJumpSound, minDelay: 30)) {
      // Shorter delay for jumps
      _lastJumpSound = DateTime.now();
      _playSoundSafely('sfx/jump.mp3', volume: 0.6); // Slightly lower volume
    }
  }

  // REMOVED: playLand() - not needed!

  void playCoinCollect({double gameSpeed = 250}) {
    if (!_soundEnabled) return;

    _coinSoundCounter++;

    // Aggressive coin sound reduction based on speed
    int skipRate = 2; // Every 2nd coin by default
    if (gameSpeed > 350) skipRate = 4; // Every 4th coin
    if (gameSpeed > 450) skipRate = 6; // Every 6th coin
    if (gameSpeed > 550) skipRate = 8; // Every 8th coin

    if (_coinSoundCounter % skipRate == 0 &&
        _canPlaySound(_lastCoinSound, minDelay: 60)) {
      _lastCoinSound = DateTime.now();
      final volume = _getVolumeForSpeed(gameSpeed);
      _playSoundSafely('sfx/coin_collect.mp3', volume: volume * 0.8);
    }
  }

  bool _canPlaySound(DateTime lastPlayed, {int minDelay = 80}) {
    return DateTime.now().difference(lastPlayed).inMilliseconds > minDelay;
  }

  // REMOVED: playCollision() - using game over sound instead!

  // Power-up sounds (infrequent, so no throttling needed)
  void playShieldActivate() {
    if (_soundEnabled) {
      _playSoundSafely('sfx/shield_activate.mp3', volume: 0.8);
    }
  }

  void playDoubleJump() {
    if (_soundEnabled) {
      _playSoundSafely('sfx/double_jump.mp3', volume: 0.8);
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

  // Game over sound - plays when you hit obstacle OR when game ends
  void playGameOver() {
    if (_soundEnabled) {
      _playSoundSafely('sfx/game_over.mp3', volume: 1.0);
    }
  }

  // Helper method with volume control
  void _playSoundSafely(String path, {double volume = 1.0}) {
    try {
      FlameAudio.play(path, volume: volume);
    } catch (e) {
      // Silently handle audio errors
    }
  }

  // Background Music
  void playGameplayMusic() {
    if (_musicEnabled) {
      try {
        FlameAudio.bgm.play('music/gameplay.mp3', volume: 0.5);
      } catch (e) {
        // Handle music errors
      }
    }
  }

  void playMenuMusic() {
    if (_musicEnabled) {
      try {
        FlameAudio.bgm.play('music/menu.mp3', volume: 0.5);
      } catch (e) {
        // Handle music errors
      }
    }
  }

  void stopMusic() {
    try {
      FlameAudio.bgm.stop();
    } catch (e) {
      // Handle stop errors
    }
  }

  // Reset counters when game restarts
  void resetCounters() {
    _coinSoundCounter = 0;
  }

  // Minimal audio preloading - only essential sounds
  Future<void> preloadAudio() async {
    try {
      await FlameAudio.audioCache.loadAll([
        'sfx/jump.mp3',
        'sfx/coin_collect.mp3',
        'sfx/game_over.mp3',
        'sfx/shield_activate.mp3',
        'sfx/double_jump.mp3',
        'sfx/magnet_activate.mp3',
        'sfx/button_click.mp3',
        'music/gameplay.mp3',
        'music/menu.mp3',
      ]);
    } catch (e) {
      // Continue without audio if files are missing
    }
  }
}
