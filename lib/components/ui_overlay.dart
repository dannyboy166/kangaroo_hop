import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../game/kangaroo_game.dart';
import '../game/audio_manager.dart';
import 'obstacle.dart';
import 'power_up.dart';

class UiOverlay extends PositionComponent with HasGameReference<KangarooGame> {
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
  
  // Store buttons
  late RectangleComponent menuStoreButton;
  late TextComponent menuStoreButtonText;
  late RectangleComponent gameOverStoreButton;
  late TextComponent gameOverStoreButtonText;
  
  // Power-up display in game
  late RectangleComponent powerUpPanel;
  late TextComponent doubleJumpCountText;
  late TextComponent shieldCountText;
  late TextComponent magnetCountText;
  late PositionComponent doubleJumpButton;
  late PositionComponent shieldButton;
  late PositionComponent magnetButton;

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
      fontSize: 24,
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
    
    // Set size to cover the entire game area for tap detection
    size = game.size;

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

    // Coin display - ONLY TOTAL COINS
    coinText = TextComponent(
      text: '\$ ${game.storeManager.totalCoins}',
      position: Vector2(20, 90),
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
        ..color = Colors.black.withValues(alpha: 0.85)
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

    // Game over store button
    gameOverStoreButton = RectangleComponent(
      size: Vector2(180, 40),
      position: Vector2(250, 250),
      anchor: Anchor.center,
      paint: Paint()..color = Colors.brown.shade700,
    );
    
    // Add border to store button
    gameOverStoreButton.add(RectangleComponent(
      size: Vector2(180, 40),
      paint: Paint()
        ..color = Colors.orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    ));
    
    gameOverStoreButtonText = TextComponent(
      text: 'STORE',
      position: Vector2(90, 20),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    gameOverStoreButton.add(gameOverStoreButtonText);

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
    gameOverPanel.add(gameOverStoreButton);
    gameOverPanel.add(restartText);

    // Power-up notification
    powerUpNotification = TextComponent(
      text: '',
      position: game.size / 2 - Vector2(0, 100),
      anchor: Anchor.center,
      textRenderer: _powerUpRenderer,
    );
    
    // Menu store button with better design
    menuStoreButton = RectangleComponent(
      size: Vector2(200, 50),
      position: game.size / 2 + Vector2(0, 100),
      anchor: Anchor.center,
      paint: Paint()..color = Colors.brown.shade700,
    );
    
    // Add gradient effect to store button
    menuStoreButton.add(RectangleComponent(
      size: Vector2(200, 25),
      paint: Paint()..color = Colors.brown.shade600.withValues(alpha: 0.5),
    ));
    
    // Add border
    menuStoreButton.add(RectangleComponent(
      size: Vector2(200, 50),
      paint: Paint()
        ..color = Colors.orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    ));
    
    menuStoreButtonText = TextComponent(
      text: 'STORE',
      position: Vector2(100, 25),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black,
              offset: Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
    );
    menuStoreButton.add(menuStoreButtonText);
    
    // Power-up panel for in-game display with better design
    powerUpPanel = RectangleComponent(
      size: Vector2(180, 140),
      position: Vector2(game.size.x - 200, game.size.y - 160),
      paint: Paint()
        ..color = Colors.black.withValues(alpha: 0.7)
        ..style = PaintingStyle.fill,
    );
    
    // Add gradient background
    powerUpPanel.add(RectangleComponent(
      size: Vector2(180, 70),
      paint: Paint()..color = Colors.black.withValues(alpha: 0.3),
    ));
    
    final powerUpBorder = RectangleComponent(
      size: Vector2(180, 140),
      position: Vector2.zero(),
      paint: Paint()
        ..color = Colors.orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    powerUpPanel.add(powerUpBorder);
    
    // Power-up buttons and counts
    _createPowerUpButtons();
  }
  
  void _createPowerUpButtons() {
    // Double Jump button with better visuals
    doubleJumpButton = PositionComponent(
      position: Vector2(20, 20),
      size: Vector2(50, 50),
    );
    
    // Background circle
    doubleJumpButton.add(CircleComponent(
      radius: 25,
      paint: Paint()..color = Colors.purple.shade800,
    ));
    
    // Inner circle for depth
    doubleJumpButton.add(CircleComponent(
      radius: 20,
      position: Vector2(5, 5),
      paint: Paint()..color = Colors.purple.shade600,
    ));
    
    // Icon
    doubleJumpButton.add(TextComponent(
      text: '⬆⬆',
      position: Vector2(25, 25),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    ));
    
    powerUpPanel.add(doubleJumpButton);
    
    doubleJumpCountText = TextComponent(
      text: '0',
      position: Vector2(45, 75),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    powerUpPanel.add(doubleJumpCountText);
    
    // Shield button with better visuals
    shieldButton = PositionComponent(
      position: Vector2(75, 20),
      size: Vector2(50, 50),
    );
    
    // Background circle
    shieldButton.add(CircleComponent(
      radius: 25,
      paint: Paint()..color = Colors.blue.shade800,
    ));
    
    // Inner circle
    shieldButton.add(CircleComponent(
      radius: 20,
      position: Vector2(5, 5),
      paint: Paint()..color = Colors.blue.shade600,
    ));
    
    // Shield shape
    final shieldIcon = PolygonComponent(
      [
        Vector2(25, 15),
        Vector2(35, 20),
        Vector2(35, 30),
        Vector2(25, 37),
        Vector2(15, 30),
        Vector2(15, 20),
      ],
      paint: Paint()..color = Colors.white,
    );
    shieldButton.add(shieldIcon);
    
    powerUpPanel.add(shieldButton);
    
    shieldCountText = TextComponent(
      text: '0',
      position: Vector2(100, 75),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    powerUpPanel.add(shieldCountText);
    
    // Magnet button with better visuals
    magnetButton = PositionComponent(
      position: Vector2(130, 20),
      size: Vector2(50, 50),
    );
    
    // Background circle
    magnetButton.add(CircleComponent(
      radius: 25,
      paint: Paint()..color = Colors.red.shade800,
    ));
    
    // Inner circle
    magnetButton.add(CircleComponent(
      radius: 20,
      position: Vector2(5, 5),
      paint: Paint()..color = Colors.red.shade600,
    ));
    
    // Magnet shape
    magnetButton.add(RectangleComponent(
      size: Vector2(8, 15),
      position: Vector2(17, 20),
      paint: Paint()..color = Colors.white,
    ));
    magnetButton.add(RectangleComponent(
      size: Vector2(8, 15),
      position: Vector2(27, 20),
      paint: Paint()..color = Colors.white,
    ));
    magnetButton.add(RectangleComponent(
      size: Vector2(18, 6),
      position: Vector2(17, 20),
      paint: Paint()..color = Colors.grey.shade300,
    ));
    
    powerUpPanel.add(magnetButton);
    
    magnetCountText = TextComponent(
      text: '0',
      position: Vector2(155, 75),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    powerUpPanel.add(magnetCountText);
    
    // Instructions
    powerUpPanel.add(TextComponent(
      text: 'Tap to use',
      position: Vector2(90, 100),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
      ),
    ));
    
    // Add key bindings
    powerUpPanel.add(TextComponent(
      text: '1        2        3',
      position: Vector2(90, 118),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.orange,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    ));
  }

  void showMenu() {
    add(menuTitle);
    add(menuSubtitle);
    add(menuStoreButton);
    add(coinText);
    
    // Update coin display
    updateCoins();

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
    
    // Add hover effect to store button
    menuStoreButton.add(
      ScaleEffect.to(
        Vector2.all(1.05),
        EffectController(
          duration: 1.5,
          reverseDuration: 1.5,
          infinite: true,
        ),
      ),
    );
  }

  void hideMenu() {
    menuTitle.removeFromParent();
    menuSubtitle.removeFromParent();
    menuStoreButton.removeFromParent();
    coinText.removeFromParent();
  }

  void showGameUI() {
    add(scoreText);
    add(highScoreText);
    add(coinText);
    add(powerUpPanel);

    // Update displays
    updateCoins();
    updatePowerUpCounts();
  }

  void updateScore(int score) {
    scoreText.text = 'Score: $score';
  }

  void updateCoins() {
    coinText.text = '\$ ${game.storeManager.totalCoins}';
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

    gameOverCoins.text = 'Coins Earned: $coins \$';

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
      PowerUpType.doubleJump: 'Double Jump!',
      PowerUpType.shield: 'Shield Active!',
      PowerUpType.magnet: 'Coin Magnet!',
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
  
  void updatePowerUpCounts() {
    doubleJumpCountText.text = '${game.storeManager.doubleJumpCount}';
    shieldCountText.text = '${game.storeManager.shieldCount}';
    magnetCountText.text = '${game.storeManager.magnetCount}';
  }
  
  void hideGameUI() {
    scoreText.removeFromParent();
    highScoreText.removeFromParent();
    coinText.removeFromParent();
    powerUpPanel.removeFromParent();
  }
  
  bool handleStoreButtonTap(TapDownInfo info) {
    final worldPosition = info.eventPosition.global;
    
    // Check menu store button with proper bounds
    if (menuStoreButton.parent != null) {
      final buttonBounds = menuStoreButton.toRect();
      if (buttonBounds.contains(worldPosition.toOffset())) {
        AudioManager().playButtonClick();
        game.showStore();
        return true;
      }
    }
    
    // Check game over store button
    if (gameOverStoreButton.parent != null && gameOverPanel.parent != null) {
      final panelPos = gameOverPanel.absolutePosition;
      final buttonPos = gameOverStoreButton.position - Vector2(90, 20); // Account for anchor
      final absoluteButtonPos = panelPos + buttonPos;
      final buttonBounds = Rect.fromLTWH(
        absoluteButtonPos.x,
        absoluteButtonPos.y,
        gameOverStoreButton.size.x,
        gameOverStoreButton.size.y,
      );
      
      if (buttonBounds.contains(worldPosition.toOffset())) {
        AudioManager().playButtonClick();
        game.showStore();
        return true;
      }
    }
    
    return false;
  }
  
  bool onTapDown(TapDownInfo info) {
    final worldPosition = info.eventPosition.global;
    
    // Check store buttons first (highest priority)
    if (handleStoreButtonTap(info)) {
      return true;
    }
    
    // Check power-up buttons (only during gameplay)
    if (game.gameState == GameState.playing && powerUpPanel.parent != null) {
      final panelPos = powerUpPanel.absolutePosition;
      
      // Convert tap position to local coordinates relative to panel
      final localPos = worldPosition - panelPos;
      
      // Check each button with proper bounds
      if (_checkButtonTap(localPos, doubleJumpButton)) {
        _usePowerUp(PowerUpType.doubleJump);
        return true;
      }
      
      if (_checkButtonTap(localPos, shieldButton)) {
        _usePowerUp(PowerUpType.shield);
        return true;
      }
      
      if (_checkButtonTap(localPos, magnetButton)) {
        _usePowerUp(PowerUpType.magnet);
        return true;
      }
    }
    
    return false;
  }
  
  bool _checkButtonTap(Vector2 localPos, PositionComponent button) {
    final buttonBounds = Rect.fromLTWH(
      button.position.x,
      button.position.y,
      button.size.x,
      button.size.y,
    );
    return buttonBounds.contains(localPos.toOffset());
  }
  
  void _usePowerUp(PowerUpType type) {
    if (game.storeManager.usePowerUp(type)) {
      AudioManager().playButtonClick();
      game.activatePowerUp(type);
      updatePowerUpCounts();
      
      // Add button press animation
      PositionComponent button;
      switch (type) {
        case PowerUpType.doubleJump:
          button = doubleJumpButton;
          break;
        case PowerUpType.shield:
          button = shieldButton;
          break;
        case PowerUpType.magnet:
          button = magnetButton;
          break;
      }
      
      button.add(
        ScaleEffect.to(
          Vector2.all(0.9),
          EffectController(duration: 0.1),
          onComplete: () {
            button.add(
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
}