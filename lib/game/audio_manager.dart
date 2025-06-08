import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _userHasInteracted = false;
  
  // REDUCED throttling for better responsiveness
  DateTime _lastJumpSound = DateTime.now();
  DateTime _lastLandSound = DateTime.now();
  DateTime _lastCoinSound = DateTime.now();

  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;

  // Initialize audio with pre-caching for web
  void initializeAudio() async {
    if (!_userHasInteracted) {
      _userHasInteracted = true;
      if (kIsWeb) {
        await _preloadWebAudio();
      }
    }
  }

  // PRE-LOAD AUDIO FOR WEB to reduce first-play latency
  Future<void> _preloadWebAudio() async {
    try {
      // Pre-cache the most frequently used sounds
      final frequentSounds = [
        'sfx/jump.mp3',
        'sfx/land.mp3', 
        'sfx/coin_collect.mp3',
        'sfx/button_click.mp3',
      ];
      
      for (String soundPath in frequentSounds) {
        try {
          await FlameAudio.audioCache.load(soundPath);
          print('Pre-cached: $soundPath');
        } catch (e) {
          print('Failed to pre-cache $soundPath: $e');
        }
      }
      
      print('Web audio pre-caching complete');
    } catch (e) {
      print('Web audio pre-caching failed: $e');
    }
  }

  void toggleSound() {
    _soundEnabled = !_soundEnabled;
  }

  void toggleMusic() {
    _musicEnabled = !_musicEnabled;
    if (!_musicEnabled) {
      FlameAudio.bgm.stop();
    }
  }

  // OPTIMIZED PLAY METHODS - Much reduced throttling
  
  void playJump() {
    if (!_soundEnabled || (kIsWeb && !_userHasInteracted)) return;
    
    // MUCH reduced throttling for better responsiveness
    if (_canPlaySound(_lastJumpSound, minDelay: kIsWeb ? 30 : 80)) {
      _lastJumpSound = DateTime.now();
      _playSoundImmediately('sfx/jump.mp3', volume: 0.7);
    }
  }

  void playLand() {
    if (!_soundEnabled || (kIsWeb && !_userHasInteracted)) return;
    
    // REDUCED throttling 
    if (_canPlaySound(_lastLandSound, minDelay: kIsWeb ? 50 : 100)) {
      _lastLandSound = DateTime.now();
      _playSoundImmediately('sfx/land.mp3', volume: 0.6);
    }
  }

  void playCoinCollect({double gameSpeed = 250}) {
    if (!_soundEnabled || (kIsWeb && !_userHasInteracted)) return;
    
    // SHORT delay for coin collect responsiveness
    if (_canPlaySound(_lastCoinSound, minDelay: kIsWeb ? 20 : 40)) {
      _lastCoinSound = DateTime.now();
      final volume = _getVolumeForSpeed(gameSpeed);
      _playSoundImmediately('sfx/coin_collect.mp3', volume: volume * 0.9);
    }
  }

  // INSTANT PLAY - No throttling for important game events
  void playCollision() {
    if (_soundEnabled && _userHasInteracted) {
      _playSoundImmediately('sfx/collision.mp3', volume: 0.8);
    }
  }

  void playGameOver() {
    if (_soundEnabled && _userHasInteracted) {
      _playSoundImmediately('sfx/game_over.mp3', volume: 1.0);
    }
  }

  void playDoubleJump() {
    if (_soundEnabled && _userHasInteracted) {
      _playSoundImmediately('sfx/double_jump.mp3', volume: 0.8);
    }
  }

  void playShieldActivate() {
    if (_soundEnabled && _userHasInteracted) {
      _playSoundImmediately('sfx/shield_activate.mp3', volume: 0.8);
    }
  }

  void playMagnetActivate() {
    if (_soundEnabled && _userHasInteracted) {
      _playSoundImmediately('sfx/magnet_activate.mp3', volume: 0.8);
    }
  }

  void playButtonClick() {
    if (_soundEnabled && _userHasInteracted) {
      _playSoundImmediately('sfx/button_click.mp3', volume: 0.6);
    }
  }

  bool _canPlaySound(DateTime lastPlayed, {int minDelay = 30}) {
    return DateTime.now().difference(lastPlayed).inMilliseconds > minDelay;
  }

  double _getVolumeForSpeed(double gameSpeed) {
    if (gameSpeed > 600) return 0.4;
    if (gameSpeed > 500) return 0.6;
    if (gameSpeed > 400) return 0.8;
    return 1.0;
  }

  // OPTIMIZED: Use direct play method for lower latency
  void _playSoundImmediately(String path, {double volume = 1.0}) {
    try {
      FlameAudio.play(path, volume: volume);
    } catch (e) {
      print('Audio error playing $path: $e');
    }
  }

  // UPDATED: Minimal preloading for web to avoid blocking
  Future<void> preloadAudio() async {
    if (kIsWeb) {
      // On web, minimal preloading to avoid blocking
      print('Web detected - minimal audio preload');
      try {
        await FlameAudio.audioCache.load('sfx/button_click.mp3');
      } catch (e) {
        print('Minimal web preload failed: $e');
      }
      return;
    }
    
    // Full preload for mobile
    try {
      await FlameAudio.audioCache.loadAll([
        'sfx/jump.mp3',
        'sfx/land.mp3',
        'sfx/coin_collect.mp3',
        'sfx/collision.mp3',
        'sfx/game_over.mp3',
        'sfx/double_jump.mp3',
        'sfx/shield_activate.mp3',
        'sfx/magnet_activate.mp3',
        'sfx/button_click.mp3',
      ]);
      print('Mobile audio preloaded successfully');
    } catch (e) {
      print('Mobile audio preload error: $e');
    }
  }

  // Background Music methods
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

  void resetCounters() {
    // Reset timing counters when game restarts
    _lastJumpSound = DateTime.now().subtract(Duration(seconds: 1));
    _lastLandSound = DateTime.now().subtract(Duration(seconds: 1));
    _lastCoinSound = DateTime.now().subtract(Duration(seconds: 1));
  }
}