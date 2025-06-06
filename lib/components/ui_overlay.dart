import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../game/kangaroo_game.dart';
import 'power_up.dart';

class UiOverlay extends Component with HasGameReference<KangarooGame> {
  late TextComponent scoreText;
  late TextComponent highScoreText;
  late TextComponent coinText;
  late TextComponent menuTitle;
  late TextComponent menuSubtitle;
  late TextComponent gameOverTitle;
  late TextComponent gameOverScore;
  late TextComponent gameOverHighScore;
  late TextComponent gameOverCoins;
  late TextComponent restartText;
  late TextComponent powerUpNotification;
  
  // Performance: Cache text renderers
  static final _scoreRenderer = TextPaint(
    style: const TextStyle(
      color: Colors.white,
      fontSize: 28,
      fontWeight: FontWeight.bold,
    ),
  );
  
  static final _highScoreRenderer = TextPaint(
    style: const TextStyle(
      color: Colors.white70,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  );
  
  static final _coinRenderer = TextPaint(
    style: const TextStyle(
      color: Colors.yellow,
      fontSize: 28,
      fontWeight: FontWeight.bold,
    ),
  );
  
  static final _menuTitleRenderer = TextPaint(
    style: const TextStyle(
      color: Colors.orange,
      fontSize: 64,
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(
          color: Colors.black,
          offset: Offset(4, 4),
          blurRadius: 8,
        ),
      ],
    ),
  );
  
  static final _menuSubtitleRenderer = TextPaint(
    style: const TextStyle(
      color: Colors.white,
      fontSize: 32,
      fontWeight: FontWeight.bold,
    ),
  );
  
  static final _gameOverTitleRenderer = TextPaint(
    style: const TextStyle(
      color: Colors.red,
      fontSize: 56,
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(
          color: Colors.black,
          offset: Offset(3, 3),
          blurRadius: 6,
        ),
      ],
    ),
  );
  
  static final _gameOverScoreRenderer = TextPaint(
    style: const TextStyle(
      color: Colors.white,
      fontSize: 32,
      fontWeight: FontWeight.bold,
    ),
  );
  
  static final _powerUpRenderer = TextPaint(
    style: const TextStyle(
      color: Colors.white,
      fontSize: 36,
      fontWeight: FontWeight.bold,
    ),
  );
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Score display
    scoreText = TextComponent(
      text: 'Score: 0',
      position: Vector2(20, 20),
      textRenderer: _scoreRenderer,
    );
    
    // High score display
    highScoreText = TextComponent(
      text: 'Best: ${game.highScore}',
      position: Vector2(20, 55),
      textRenderer: _highScoreRenderer,
    );
    
    // Coin display
    coinText = TextComponent(
      text: '🪙 0',
      position: Vector2(game.size.x - 120, 20),
      textRenderer: _coinRenderer,
    );
    
    // Menu title
    menuTitle = TextComponent(
      text: 'KANGAROO HOP',
      position: game.size / 2 - Vector2(0, 50),
      anchor: Anchor.center,
      textRenderer: _menuTitleRenderer,
    );
    
    // Menu subtitle
    menuSubtitle = TextComponent(
      text: 'Tap to Start!',
      position: game.size / 2 + Vector2(0, 30),
      anchor: Anchor.center,
      textRenderer: _menuSubtitleRenderer,
    );
    
    // Game over title
    gameOverTitle = TextComponent(
      text: 'GAME OVER',
      anchor: Anchor.center,
      textRenderer: _gameOverTitleRenderer,
    );
    
    // Game over score
    gameOverScore = TextComponent(
      text: '',
      anchor: Anchor.center,
      textRenderer: _gameOverScoreRenderer,
    );
    
    // Game over high score
    gameOverHighScore = TextComponent(
      text: '',
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.yellow,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    
    // Game over coins
    gameOverCoins = TextComponent(
      text: '',
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.yellow,
          fontSize: 24,
        ),
      ),
    );
    
    // Restart text
    restartText = TextComponent(
      text: 'Tap to Play Again',
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    
    // Power-up notification
    powerUpNotification = TextComponent(
      text: '',
      position: game.size / 2 - Vector2(0, 100),
      anchor: Anchor.center,
      textRenderer: _powerUpRenderer,
    );
  }
  
  void showMenu() {
    add(menuTitle);
    add(menuSubtitle);
    
    // Animate menu
    menuTitle.add(
      ScaleEffect.to(
        Vector2.all(1.05),
        EffectController(
          duration: 2,
          reverseDuration: 2,
          infinite: true,
        ),
      ),
    );
    
    // Pulse effect using scale instead of opacity
    menuSubtitle.add(
      ScaleEffect.to(
        Vector2.all(0.95),
        EffectController(
          duration: 1,
          reverseDuration: 1,
          infinite: true,
        ),
      ),
    );
  }
  
  void hideMenu() {
    menuTitle.removeFromParent();
    menuSubtitle.removeFromParent();
  }
  
  void showGameUI() {
    add(scoreText);
    add(highScoreText);
    add(coinText);
  }
  
  void updateScore(int score) {
    scoreText.text = 'Score: $score';
  }
  
  void updateCoins(int coins) {
    coinText.text = '🪙 $coins';
    
    // Performance: Skip pulse animation at high speeds
    if (game.shouldReduceEffects) return;
    
    // Pulse animation
    coinText.add(
      ScaleEffect.to(
        Vector2.all(1.2),
        EffectController(duration: 0.1),
        onComplete: () {
          coinText.add(
            ScaleEffect.to(
              Vector2.all(1.0),
              EffectController(duration: 0.1),
            ),
          );
        },
      ),
    );
  }
  
  void showGameOver(int score, int highScore, int coins) {
    gameOverTitle.position = game.size / 2 - Vector2(0, 80);
    gameOverScore.position = game.size / 2 - Vector2(0, 20);
    gameOverScore.text = 'Score: $score';
    
    if (score > game.highScore) {
      gameOverHighScore.text = 'NEW BEST: $score! 🎉';
      gameOverHighScore.position = game.size / 2 + Vector2(0, 20);
    } else {
      gameOverHighScore.text = 'Best: $highScore';
      gameOverHighScore.position = game.size / 2 + Vector2(0, 20);
    }
    
    gameOverCoins.text = 'Coins: $coins 🪙';
    gameOverCoins.position = game.size / 2 + Vector2(0, 60);
    
    restartText.position = game.size / 2 + Vector2(0, 120);
    
    add(gameOverTitle);
    add(gameOverScore);
    add(gameOverHighScore);
    add(gameOverCoins);
    add(restartText);
    
    // Animate game over screen
    gameOverTitle.scale = Vector2.zero();
    gameOverTitle.add(
      ScaleEffect.to(
        Vector2.all(1),
        EffectController(
          duration: 0.5,
          curve: Curves.elasticOut,
        ),
      ),
    );
    
    // Pulse effect using scale instead of opacity
    restartText.add(
      ScaleEffect.to(
        Vector2.all(0.95),
        EffectController(
          duration: 1,
          reverseDuration: 1,
          infinite: true,
        ),
      ),
    );
  }
  
  void hideGameOver() {
    gameOverTitle.removeFromParent();
    gameOverScore.removeFromParent();
    gameOverHighScore.removeFromParent();
    gameOverCoins.removeFromParent();
    restartText.removeFromParent();
  }
  
  void showPowerUpNotification(PowerUpType type) {
    final notifications = {
      PowerUpType.doubleJump: 'Double Jump! 🦘',
      PowerUpType.shield: 'Shield Active! 🛡️',
      PowerUpType.magnet: 'Coin Magnet! 🧲',
    };
    
    powerUpNotification.text = notifications[type]!;
    
    if (powerUpNotification.parent == null) {
      add(powerUpNotification);
    }
    
    // Reset and animate
    powerUpNotification.scale = Vector2.all(0);
    
    powerUpNotification.add(
      ScaleEffect.to(
        Vector2.all(1),
        EffectController(
          duration: 0.3,
          curve: Curves.elasticOut,
        ),
        onComplete: () {
          Future.delayed(const Duration(seconds: 2), () {
            powerUpNotification.add(
              ScaleEffect.to(
                Vector2.all(0),
                EffectController(duration: 0.5),
                onComplete: () => powerUpNotification.removeFromParent(),
              ),
            );
          });
        },
      ),
    );
  }
}