import 'package:flame_audio/flame_audio.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  bool _soundEnabled = true;
  bool _musicEnabled = true;
  
  // Audio throttling to prevent performance issues
  DateTime _lastJumpSound = DateTime.now();
  DateTime _lastLandSound = DateTime.now();
  DateTime _lastCoinSound = DateTime.now();
  static const int _minSoundDelay = 50; // Minimum milliseconds between same sounds
  
  // Smart audio reduction for performance
  int _coinSoundCounter = 0;
  int _jumpSoundCounter = 0;

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

  // Sound Effects with smart throttling and performance optimization
  void playJump() {
    if (!_soundEnabled) return;
    
    _jumpSoundCounter++;
    // At high speeds, only play every 2nd jump sound
    if (_jumpSoundCounter % 2 == 0 || _canPlaySound(_lastJumpSound)) {
      _lastJumpSound = DateTime.now();
      _playSoundSafely('sfx/jump.mp3');
    }
  }

  void playLand() {
    if (_soundEnabled && _canPlaySound(_lastLandSound)) {
      _lastLandSound = DateTime.now();
      _playSoundSafely('sfx/land.mp3');
    }
  }

  void playCoinCollect({double gameSpeed = 250}) {
    if (!_soundEnabled) return;
    
    _coinSoundCounter++;
    
    // Smart coin sound reduction based on game speed
    int skipRate = 1; // Play every sound by default
    if (gameSpeed > 400) skipRate = 2;      // Play every 2nd coin
    if (gameSpeed > 550) skipRate = 3;      // Play every 3rd coin
    if (gameSpeed > 650) skipRate = 4;      // Play every 4th coin
    
    if (_coinSoundCounter % skipRate == 0 && _canPlaySound(_lastCoinSound)) {
      _lastCoinSound = DateTime.now();
      _playSoundSafely('sfx/coin_collect.mp3');
    }
  }
  
  bool _canPlaySound(DateTime lastPlayed) {
    return DateTime.now().difference(lastPlayed).inMilliseconds > _minSoundDelay;
  }

  void playCollision() {
    if (_soundEnabled) {
      _playSoundSafely('sfx/collision.mp3');
    }
  }

  void playShieldActivate() {
    if (_soundEnabled) {
      _playSoundSafely('sfx/shield_activate.mp3');
    }
  }

  void playDoubleJump() {
    if (_soundEnabled) {
      _playSoundSafely('sfx/double_jump.mp3');
    }
  }

  void playMagnetActivate() {
    if (_soundEnabled) {
      _playSoundSafely('sfx/magnet_activate.mp3');
    }
  }

  void playButtonClick() {
    if (_soundEnabled) {
      _playSoundSafely('sfx/button_click.mp3');
    }
  }

  void playGameOver() {
    if (_soundEnabled) {
      _playSoundSafely('sfx/game_over.mp3');
    }
  }

  // Helper method for safe audio playback
  void _playSoundSafely(String path) {
    try {
      FlameAudio.play(path);
    } catch (e) {
      // Silently handle audio errors to prevent crashes
    }
  }

  // Background Music
  void playGameplayMusic() {
    if (_musicEnabled) {
      try {
        FlameAudio.bgm.play('music/gameplay.mp3');
      } catch (e) {
        // Silently handle audio errors
      }
    }
  }

  void playMenuMusic() {
    if (_musicEnabled) {
      try {
        FlameAudio.bgm.play('music/menu.mp3');
      } catch (e) {
        // Silently handle audio errors
      }
    }
  }

  void stopMusic() {
    try {
      FlameAudio.bgm.stop();
    } catch (e) {
      // Silently handle audio errors
    }
  }

  // Preload audio files
  Future<void> preloadAudio() async {
    try {
      await FlameAudio.audioCache.loadAll([
        'sfx/jump.mp3',
        'sfx/land.mp3',
        'sfx/coin_collect.mp3',
        'sfx/collision.mp3',
        'sfx/shield_activate.mp3',
        'sfx/double_jump.mp3',
        'sfx/magnet_activate.mp3',
        'sfx/button_click.mp3',
        'sfx/game_over.mp3',
        'music/gameplay.mp3',
        'music/menu.mp3',
      ]);
    } catch (e) {
      // Handle missing audio files gracefully - continue without audio
    }
  }
}