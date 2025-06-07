import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../game/kangaroo_game.dart';
import 'obstacle.dart';
import 'power_up.dart';

class UiOverlay extends Component with HasGameReference<KangarooGame> {
  late TextComponent scoreText;
  late TextComponent highScoreText;
  late TextComponent coinText;
  late TextComponent menuTitle;
  late TextComponent menuSubtitle;
  late RectangleComponent gameOverPanel;
  late TextComponent gameOverTitle;
  late TextComponent gameOverMessage;
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
      fontSize: 36,
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(
          color: Colors.black,
          offset: Offset(2, 2),
          blurRadius: 4,
        ),
      ],
    ),
  );

  static final _gameOverMessageRenderer = TextPaint(
    style: const TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.w500,
    ),
  );

  static final _gameOverScoreRenderer = TextPaint(
    style: const TextStyle(
      color: Colors.white,
      fontSize: 24,
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

    // Game over panel (semi-transparent background)
    gameOverPanel = RectangleComponent(
      size: Vector2(500, 320),
      position: game.size / 2,
      anchor: Anchor.center,
      paint: Paint()
        ..color = Colors.black.withOpacity(0.85)
        ..style = PaintingStyle.fill,
    );

    // Add border to the panel
    final panelBorder = RectangleComponent(
      size: Vector2(500, 320),
      position: Vector2.zero(),
      paint: Paint()
        ..color = Colors.orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    gameOverPanel.add(panelBorder);

    // Game over title
    gameOverTitle = TextComponent(
      text: 'GAME OVER',
      position: Vector2(250, 40),
      anchor: Anchor.center,
      textRenderer: _gameOverTitleRenderer,
    );

    // Game over message (fun fact)
    gameOverMessage = TextComponent(
      text: '',
      position: Vector2(250, 90),
      anchor: Anchor.center,
      textRenderer: _gameOverMessageRenderer,
    );

    // Game over score
    gameOverScore = TextComponent(
      text: '',
      position: Vector2(250, 160),
      anchor: Anchor.center,
      textRenderer: _gameOverScoreRenderer,
    );

    // Game over high score
    gameOverHighScore = TextComponent(
      text: '',
      position: Vector2(250, 190),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.yellow,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    // Game over coins
    gameOverCoins = TextComponent(
      text: '',
      position: Vector2(250, 220),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.yellow,
          fontSize: 18,
        ),
      ),
    );

    // Restart text
    restartText = TextComponent(
      text: 'Tap to Play Again',
      position: Vector2(250, 280),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    // Add all game over elements to the panel
    gameOverPanel.add(gameOverTitle);
    gameOverPanel.add(gameOverMessage);
    gameOverPanel.add(gameOverScore);
    gameOverPanel.add(gameOverHighScore);
    gameOverPanel.add(gameOverCoins);
    gameOverPanel.add(restartText);

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

    // Make sure coin display starts with 0
    updateCoins(0);
  }

  void updateScore(int score) {
    scoreText.text = 'Score: $score';
  }

  void updateCoins(int coins) {
    coinText.text = '🪙 $coins'; // Always show the coin symbol with the number

    // Performance: Skip pulse animation at high speeds
    if (game.shouldReduceEffects) return;

    // Only pulse when coins are actually collected (not when setting to 0)
    if (coins > 0) {
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
  }

  void showGameOver(int score, int highScore, int coins,
      [ObstacleType? obstacleType]) {
    // Set obstacle-specific game over message with shorter, punchier text
    String gameOverMessageText = 'Better luck next time!';
    String emojiIcon = '💥';

    if (obstacleType != null) {
      switch (obstacleType) {
        case ObstacleType.croc:
          gameOverMessageText =
              'Uh oh, you were caught by a crocodile! 🐊\nCrocs use a death roll to catch prey.';
          emojiIcon = '🐊';
          break;
        case ObstacleType.emu:
          gameOverMessageText =
              'I think you were run over by an emu! 🦆\nEmus can run over 50km/h!';
          emojiIcon = '🦆';
          break;
        case ObstacleType.rock:
          gameOverMessageText =
              'You were tripped over a boulder! 🪨\nWatch where you\'re hopping!';
          emojiIcon = '🪨';
          break;
        case ObstacleType.log:
          gameOverMessageText =
              'Whoops, you faceplanted into a log! That must of hurt.';
          emojiIcon = '🪵';
          break;
        case ObstacleType.cactus:
          gameOverMessageText =
              'Ouch! Jumped into a cactus! 🌵\nThose spines are sharp!';
          emojiIcon = '🌵';
          break;
        case ObstacleType.camel:
          gameOverMessageText =
              'You got bumped by a camel! 🐪\nCamels can be grumpy!';
          emojiIcon = '🐪';
          break;
      }
    }

    // Add emoji to title
    gameOverTitle.text = '$emojiIcon GAME OVER $emojiIcon';
    gameOverMessage.text = gameOverMessageText;
    gameOverScore.text = 'Score: $score';

    if (score > game.highScore) {
      gameOverHighScore.text = '🎉 NEW BEST: $score! 🎉';
    } else {
      gameOverHighScore.text = 'Best: $highScore';
    }

    gameOverCoins.text = 'Coins Earned: $coins 🪙';

    add(gameOverPanel);

    // Animate game over panel
    gameOverPanel.scale = Vector2.all(0.3);
    gameOverPanel.add(
      ScaleEffect.to(
        Vector2.all(1),
        EffectController(
          duration: 0.5,
          curve: Curves.elasticOut,
        ),
      ),
    );

    // Pulse effect for restart text
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
    gameOverPanel.removeFromParent();
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
