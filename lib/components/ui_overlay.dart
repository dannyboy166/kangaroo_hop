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
  late PositionComponent coinDisplay;
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
  
  // Obstacle icon components for game over screen
  late PositionComponent obstacleIconLeft;
  late PositionComponent obstacleIconRight;

  // Store buttons
  late RectangleComponent menuStoreButton;
  late TextComponent menuStoreButtonText;
  late RectangleComponent gameOverStoreButton;
  late TextComponent gameOverStoreButtonText;
  
  // Play Again button
  late RectangleComponent gameOverPlayAgainButton;
  late TextComponent gameOverPlayAgainButtonText;

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
      color: Color(0xFFF7B027), // Custom gold color
      fontSize: 28,
      fontWeight: FontWeight.bold,
    ),
  );

  static final _menuTitleRenderer = TextPaint(
    style: const TextStyle(
      color: Color(0xFF4F9DFF), // Same blue as store
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

    // Coin display with image - create a container
    final coinContainer = PositionComponent(
      position: Vector2(20, 90),
    );

    // Add coin image with spinning animation
    Sprite.load('coin.png').then((coinSprite) {
      final coinImage = SpriteComponent(
        sprite: coinSprite,
        size: Vector2(30, 30),
        position: Vector2(15, 17), // Centered within the icon area for rotation
        anchor: Anchor.center,
      );
      
      // Add horizontal spinning animation like power-ups
      coinImage.add(
        ScaleEffect.to(
          Vector2(-1, 1), // Flip horizontally for 3D spinning effect
          EffectController(
            duration: 2.0, // Slower than power-ups for UI element
            reverseDuration: 2.0,
            infinite: true,
            curve: Curves.easeInOut,
          ),
        ),
      );
      
      coinContainer.add(coinImage);
    });

    // Coin text positioned next to image
    coinText = TextComponent(
      text: '${game.storeManager.totalCoins}',
      position: Vector2(40, 2), // More space for larger coin
      textRenderer: _coinRenderer,
    );
    coinContainer.add(coinText);

    // Store reference to container
    coinDisplay = coinContainer;

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

    // CREATE THE GAME OVER PANEL
    _createGameOverPanel();

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
      paint: Paint()..color = const Color(0xFF2ED573), // Modern green
    );

    // Add gradient effect to store button
    menuStoreButton.add(RectangleComponent(
      size: Vector2(200, 25),
      paint: Paint()..color = const Color(0xFF7BED9F).withValues(alpha: 0.5),
    ));

    // Add border
    menuStoreButton.add(RectangleComponent(
      size: Vector2(200, 50),
      paint: Paint()
        ..color = const Color(0xFF4F9DFF) // Same blue as store
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
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

    // Power-up panel for in-game display with modern design
    powerUpPanel = RectangleComponent(
      size: Vector2(200, 150), // Slightly larger
      position: Vector2(game.size.x - 220, game.size.y - 170),
      paint: Paint()
        ..color = const Color(0xFF1A1A2E) // Same as store background
        ..style = PaintingStyle.fill,
    );

    // Add subtle gradient overlay like the store
    powerUpPanel.add(RectangleComponent(
      size: Vector2(200, 45), // Top third
      paint: Paint()..color = const Color(0xFF4F9DFF).withValues(alpha: 0.1),
    ));

    final powerUpBorder = RectangleComponent(
      size: Vector2(200, 150),
      position: Vector2.zero(),
      paint: Paint()
        ..color = const Color(0xFF4F9DFF) // Same blue as store
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2, // Thinner border
    );
    powerUpPanel.add(powerUpBorder);

    // Power-up buttons and counts
    _createPowerUpButtons();
  }

  void _createGameOverPanel() {
    // Game over panel - MADE BIGGER to accommodate buttons properly
    gameOverPanel = RectangleComponent(
      size: Vector2(600, 420), // Increased height from 320 to 420
      position: game.size / 2,
      anchor: Anchor.center,
      paint: Paint()
        ..color =
            const Color(0xFF1A1A2E).withValues(alpha: 0.95) // Same as store
        ..style = PaintingStyle.fill,
    );

    // Add border to the panel
    final panelBorder = RectangleComponent(
      size: Vector2(600, 420),
      position: Vector2.zero(),
      paint: Paint()
        ..color = const Color(0xFF4F9DFF) // Same blue as store
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    gameOverPanel.add(panelBorder);

    // Obstacle icon containers (positioned on either side of title)
    obstacleIconLeft = PositionComponent(
      position: Vector2(150, 40),
      anchor: Anchor.center,
      size: Vector2(60, 60),
    );
    
    obstacleIconRight = PositionComponent(
      position: Vector2(450, 40),
      anchor: Anchor.center,
      size: Vector2(60, 60),
    );

    // Game over title
    gameOverTitle = TextComponent(
      text: 'GAME OVER',
      position: Vector2(300, 40),
      anchor: Anchor.center,
      textRenderer: _gameOverTitleRenderer,
    );

    // Game over message (fun fact)
    gameOverMessage = TextComponent(
      text: '',
      position: Vector2(300, 90),
      anchor: Anchor.center,
      textRenderer: _gameOverMessageRenderer,
    );

    // Game over score
    gameOverScore = TextComponent(
      text: '',
      position: Vector2(300, 160),
      anchor: Anchor.center,
      textRenderer: _gameOverScoreRenderer,
    );

    // Game over high score
    gameOverHighScore = TextComponent(
      text: '',
      position: Vector2(300, 190),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFF7B027), // Custom gold color
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    // Game over coins
    gameOverCoins = TextComponent(
      text: '',
      position: Vector2(300, 220),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFF7B027), // Custom gold color
          fontSize: 18,
        ),
      ),
    );

    // STORE BUTTON - Much better positioned and sized (now red and positioned to the right)
    gameOverStoreButton = RectangleComponent(
      size: Vector2(220, 50), // Made wider and taller
      position: Vector2(450, 270), // Positioned to the right of play again button
      anchor: Anchor.center,
      paint: Paint()..color = const Color(0xFFE74C3C), // Modern red
    );

    // Add gradient effect to store button
    gameOverStoreButton.add(RectangleComponent(
      size: Vector2(220, 25),
      paint: Paint()..color = const Color(0xFFEC7063).withValues(alpha: 0.5),
    ));

    // Add border to store button
    gameOverStoreButton.add(RectangleComponent(
      size: Vector2(220, 50),
      paint: Paint()
        ..color = const Color(0xFF4F9DFF) // Same blue as store
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    ));

    gameOverStoreButtonText = TextComponent(
      text: 'STORE',
      position: Vector2(110, 25),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22, // Bigger text
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black,
              offset: Offset(2, 2),
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
    gameOverStoreButton.add(gameOverStoreButtonText);

    // PLAY AGAIN BUTTON - Identical to store button but positioned to the left
    gameOverPlayAgainButton = RectangleComponent(
      size: Vector2(220, 50), // Same size as store button
      position: Vector2(150, 270), // Positioned to the left of store button
      anchor: Anchor.center,
      paint: Paint()..color = const Color(0xFF2ED573), // Same green for now, will change store to red
    );

    // Add gradient effect to play again button
    gameOverPlayAgainButton.add(RectangleComponent(
      size: Vector2(220, 25),
      paint: Paint()..color = const Color(0xFF7BED9F).withValues(alpha: 0.5),
    ));

    // Add border to play again button
    gameOverPlayAgainButton.add(RectangleComponent(
      size: Vector2(220, 50),
      paint: Paint()
        ..color = const Color(0xFF4F9DFF) // Same blue as store
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    ));

    gameOverPlayAgainButtonText = TextComponent(
      text: 'PLAY AGAIN',
      position: Vector2(110, 25),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22, // Same size as store button
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black,
              offset: Offset(2, 2),
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
    gameOverPlayAgainButton.add(gameOverPlayAgainButtonText);

    // RESTART TEXT - Moved down to make room
    restartText = TextComponent(
      text: 'or tap anywhere else to restart',
      position: Vector2(300, 340), // Moved down
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
    );

    // Add a separator line between store and restart
    final separatorLine = RectangleComponent(
      size: Vector2(400, 2),
      position: Vector2(100, 310),
      paint: Paint()..color = const Color(0xFF4F9DFF).withValues(alpha: 0.5),
    );
    gameOverPanel.add(separatorLine);

    // Add all game over elements to the panel
    gameOverPanel.add(obstacleIconLeft);
    gameOverPanel.add(obstacleIconRight);
    gameOverPanel.add(gameOverTitle);
    gameOverPanel.add(gameOverMessage);
    gameOverPanel.add(gameOverScore);
    gameOverPanel.add(gameOverHighScore);
    gameOverPanel.add(gameOverCoins);
    gameOverPanel.add(gameOverPlayAgainButton);
    gameOverPanel.add(gameOverStoreButton);
    gameOverPanel.add(restartText);
  }

  Future<void> _loadObstacleIcons(ObstacleType obstacleType) async {
    // Clear existing icons
    obstacleIconLeft.removeWhere((component) => component is SpriteComponent || component is RectangleComponent);
    obstacleIconRight.removeWhere((component) => component is SpriteComponent || component is RectangleComponent);
    
    String spritePath;
    switch (obstacleType) {
      case ObstacleType.rock:
        spritePath = 'rock.png';
        break;
      case ObstacleType.cactus:
        spritePath = 'cactus.png';
        break;
      case ObstacleType.log:
        spritePath = 'log.png';
        break;
      case ObstacleType.croc:
        spritePath = 'croc.png';
        break;
      case ObstacleType.emu:
        spritePath = 'emu.png';
        break;
      case ObstacleType.camel:
        spritePath = 'camel.png';
        break;
    }
    
    try {
      final sprite = await game.loadSprite(spritePath);
      
      // Add sprite to left icon
      final leftIcon = SpriteComponent(
        sprite: sprite,
        size: Vector2(40, 40),
        anchor: Anchor.center,
        position: Vector2(30, 30), // Center within the container
      );
      obstacleIconLeft.add(leftIcon);
      
      // Add sprite to right icon
      final rightIcon = SpriteComponent(
        sprite: sprite,
        size: Vector2(40, 40),
        anchor: Anchor.center,
        position: Vector2(30, 30), // Center within the container
      );
      obstacleIconRight.add(rightIcon);
    } catch (e) {
      print('Error loading obstacle sprite: $e');
      // Fallback: add colored rectangles if sprite fails to load
      final fallbackColor = _getObstacleColor(obstacleType);
      
      obstacleIconLeft.add(RectangleComponent(
        size: Vector2(60, 60),
        paint: Paint()..color = fallbackColor,
        anchor: Anchor.center,
        position: Vector2(30, 30),
      ));
      
      obstacleIconRight.add(RectangleComponent(
        size: Vector2(60, 60),
        paint: Paint()..color = fallbackColor,
        anchor: Anchor.center,
        position: Vector2(30, 30),
      ));
    }
  }
  
  Color _getObstacleColor(ObstacleType obstacleType) {
    switch (obstacleType) {
      case ObstacleType.rock:
        return Colors.grey;
      case ObstacleType.cactus:
        return Colors.green;
      case ObstacleType.log:
        return Colors.brown;
      case ObstacleType.croc:
        return Colors.green.shade800;
      case ObstacleType.emu:
        return Colors.brown.shade600;
      case ObstacleType.camel:
        return Colors.brown.shade400;
    }
  }

  void _createPowerUpButtons() {
    // Double Jump button with new image
    doubleJumpButton = PositionComponent(
      position: Vector2(20, 20),
      size: Vector2(50, 50),
    );

    // Load and add the double jump sprite (without words)
    Sprite.load('double.png').then((sprite) {
      doubleJumpButton.add(SpriteComponent(
        sprite: sprite,
        size: Vector2(50, 50),
        anchor: Anchor.center,
        position: Vector2(25, 25),
      ));
    });

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

    // Shield button with new image
    shieldButton = PositionComponent(
      position: Vector2(75, 20),
      size: Vector2(50, 50),
    );

    // Load and add the shield sprite (without words)
    Sprite.load('shield.png').then((sprite) {
      shieldButton.add(SpriteComponent(
        sprite: sprite,
        size: Vector2(50, 50),
        anchor: Anchor.center,
        position: Vector2(25, 25),
      ));
    });

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

    // Magnet button with new image
    magnetButton = PositionComponent(
      position: Vector2(130, 20),
      size: Vector2(50, 50),
    );

    // Load and add the magnet sprite (without words)
    Sprite.load('magnet.png').then((sprite) {
      magnetButton.add(SpriteComponent(
        sprite: sprite,
        size: Vector2(50, 50),
        anchor: Anchor.center,
        position: Vector2(25, 25),
      ));
    });

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
          color: Color(0xFF4F9DFF), // Same blue as store
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
    add(coinDisplay);

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
    coinDisplay.removeFromParent();
  }

  void showGameUI() {
    add(scoreText);
    add(highScoreText);
    add(coinDisplay);
    add(powerUpPanel);

    // Update displays
    updateCoins();
    updatePowerUpCounts();
  }

  void updateScore(int score) {
    scoreText.text = 'Score: $score';
  }
// In ui_overlay.dart - Fix the updateCoins method

  void updateCoins() {
    // Always show the current total coins consistently
    final totalDisplayCoins = game.getCurrentTotalCoins(); // Use the new method
    coinText.text = '$totalDisplayCoins';
  }

// Update the showGameOver method to show the coins that were actually earned this session
  void showGameOver(int score, int highScore, int coinsEarned,
      [ObstacleType? obstacleType]) {
    // Set obstacle-specific game over message with shorter, punchier text
    String gameOverMessageText = 'Better luck next time!';

    if (obstacleType != null) {
      switch (obstacleType) {
        case ObstacleType.croc:
          gameOverMessageText =
              'Uh oh, you were caught by a crocodile!\nCrocs use a death roll to catch prey.';
          break;
        case ObstacleType.emu:
          gameOverMessageText =
              'You were run over by an emu!\nEmus can run over 50km/h!';
          break;
        case ObstacleType.rock:
          gameOverMessageText =
              'You were tripped over a boulder!\nWatch where you\'re hopping!';
          break;
        case ObstacleType.log:
          gameOverMessageText =
              'Whoops, you faceplanted into a log!\nThat must of hurt.';
          break;
        case ObstacleType.cactus:
          gameOverMessageText =
              'Ouch! Jumped into a cactus!\nThose spines are sharp!';
          break;
        case ObstacleType.camel:
          gameOverMessageText =
              'You got bumped by a camel!\nCamels can be grumpy!';
          break;
      }
      
      // Load obstacle icons
      _loadObstacleIcons(obstacleType);
    }

    // Set title without emojis (icons will show the obstacle)
    gameOverTitle.text = 'GAME OVER';
    gameOverMessage.text = gameOverMessageText;
    gameOverScore.text = 'Score: $score';

    if (score > game.highScore) {
      gameOverHighScore.text = '🎉 NEW BEST: $score! 🎉';
    } else {
      gameOverHighScore.text = 'Best: $highScore';
    }

    // FIXED: Show the actual coins earned this session (passed as parameter)
    gameOverCoins.text = 'Coins Earned: $coinsEarned';

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
    coinDisplay.removeFromParent();
    powerUpPanel.removeFromParent();
  }

  bool handleStoreButtonTap(TapDownInfo info) {
    final worldPosition = info.eventPosition.global;

    // Check menu store button with proper bounds
    if (menuStoreButton.parent != null) {
      final buttonAbsolutePos = menuStoreButton.absolutePosition;
      final buttonBounds = Rect.fromLTWH(
        buttonAbsolutePos.x -
            menuStoreButton.size.x / 2, // Account for center anchor
        buttonAbsolutePos.y - menuStoreButton.size.y / 2,
        menuStoreButton.size.x,
        menuStoreButton.size.y,
      );

      if (buttonBounds.contains(worldPosition.toOffset())) {
        print('Menu store button clicked!');
        AudioManager().playButtonClick();
        game.showStore();
        return true;
      }
    }

    // Check game over play again button
    if (gameOverPlayAgainButton.parent != null && gameOverPanel.parent != null) {
      // Get the game over panel's absolute position (center anchor)
      final panelAbsolutePos = gameOverPanel.absolutePosition;
      final panelCenterOffset = Vector2(
        panelAbsolutePos.x - gameOverPanel.size.x / 2,
        panelAbsolutePos.y - gameOverPanel.size.y / 2,
      );

      // Play again button position is relative to panel, with center anchor
      final buttonRelativePos = gameOverPlayAgainButton.position;
      final buttonAbsolutePos = Vector2(
        panelCenterOffset.x +
            buttonRelativePos.x -
            gameOverPlayAgainButton.size.x / 2,
        panelCenterOffset.y +
            buttonRelativePos.y -
            gameOverPlayAgainButton.size.y / 2,
      );

      final buttonBounds = Rect.fromLTWH(
        buttonAbsolutePos.x,
        buttonAbsolutePos.y,
        gameOverPlayAgainButton.size.x,
        gameOverPlayAgainButton.size.y,
      );

      if (buttonBounds.contains(worldPosition.toOffset())) {
        print('Game over play again button clicked!');
        AudioManager().playButtonClick();
        game.startGame();
        return true;
      }
    }

    // Check game over store button - COMPLETELY REWRITTEN for accuracy
    if (gameOverStoreButton.parent != null && gameOverPanel.parent != null) {
      // Get the game over panel's absolute position (center anchor)
      final panelAbsolutePos = gameOverPanel.absolutePosition;
      final panelCenterOffset = Vector2(
        panelAbsolutePos.x - gameOverPanel.size.x / 2,
        panelAbsolutePos.y - gameOverPanel.size.y / 2,
      );

      // Store button position is relative to panel, with center anchor
      final buttonRelativePos = gameOverStoreButton.position;
      final buttonAbsolutePos = Vector2(
        panelCenterOffset.x +
            buttonRelativePos.x -
            gameOverStoreButton.size.x / 2,
        panelCenterOffset.y +
            buttonRelativePos.y -
            gameOverStoreButton.size.y / 2,
      );

      final buttonBounds = Rect.fromLTWH(
        buttonAbsolutePos.x,
        buttonAbsolutePos.y,
        gameOverStoreButton.size.x,
        gameOverStoreButton.size.y,
      );

      print('Game over store button bounds: $buttonBounds');
      print('Tap position: ${worldPosition.toOffset()}');
      print(
          'Button contains tap: ${buttonBounds.contains(worldPosition.toOffset())}');

      if (buttonBounds.contains(worldPosition.toOffset())) {
        print('Game over store button clicked!');
        AudioManager().playButtonClick();
        game.showStore();
        return true;
      }
    }

    return false;
  }

  bool onTapDown(TapDownInfo info) {
    print('UI Overlay tap detected at: ${info.eventPosition.global}');

    // HIGHEST PRIORITY: Check store buttons first
    if (handleStoreButtonTap(info)) {
      print('Store button handled the tap');
      return true; // Store button was clicked - prevent any other handling
    }

    // Check power-up buttons (only during gameplay)
    if (game.gameState == GameState.playing && powerUpPanel.parent != null) {
      final worldPosition = info.eventPosition.global;
      final panelAbsolutePos = powerUpPanel.absolutePosition;

      // Convert tap position to local coordinates relative to panel
      final localPos = worldPosition - panelAbsolutePos;

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

    print('No UI elements handled the tap');
    // If no UI elements were tapped, return false to let game handle it
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
