import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/background.dart';
import '../components/cloud.dart';
import '../components/coin.dart';
import '../components/ground.dart';
import '../components/kangaroo.dart';
import '../components/obstacle.dart';
import '../components/power_up.dart';
import '../components/ui_overlay.dart';
import 'audio_manager.dart';

enum GameState { menu, playing, gameOver }

class KangarooGame extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection, TapDetector {
  late Kangaroo kangaroo;
  late Background background;
  late Ground ground;
  late UiOverlay uiOverlay;

  GameState gameState = GameState.menu;
  int score = 0;
  int highScore = 0;
  int coins = 0;
  int totalCoins = 0;
  double gameSpeed = 250.0;
  double baseSpeed = 250.0;
  double speedMultiplier = 1.0;
  bool hasDoubleJump = false;
  bool hasShield = false;
  bool isMagnetActive = false;

  // For distance-based scoring
  double distanceTraveled = 0.0;

  // For game over delay
  bool gameOverTriggered = false;

  // For jump input handling
  Set<LogicalKeyboardKey> pressedKeys = <LogicalKeyboardKey>{};
  bool wasJumpPressed = false;

  late TimerComponent obstacleTimer;
  late TimerComponent cloudTimer;
  late TimerComponent coinTimer;
  late TimerComponent powerUpTimer;

  Random random = Random();

  static const double minObstacleSpacing = 1.5;
  static const double maxObstacleSpacing = 2.5;
  static const double minGapSpacing = 0.1;
  static const double maxGapSpacing = 1.5;

  bool lastWasGap = false;

  // Performance optimization: Cache moving components
  final List<Obstacle> _obstacles = [];
  final List<Coin> _coins = [];
  final List<PowerUp> _powerUps = [];
  final List<Cloud> _clouds = [];

  // Performance: Reduce particle effects at high speeds
  bool get shouldReduceEffects => gameSpeed > 500;

  @override
  Color backgroundColor() => const Color(0xFF87CEEB);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Set up camera to match screen size
    camera.viewfinder.visibleGameSize = size;

    // Load saved data
    await loadSavedData();

    // Preload audio files
    await AudioManager().preloadAudio();

    // Initialize components
    background = Background();
    ground = Ground();
    kangaroo = Kangaroo();
    uiOverlay = UiOverlay();

    // Set explicit priorities to control rendering order
    background.priority = 0; // Bottom layer
    ground.priority = 10; // Above background
    kangaroo.priority = 100; // Above ground and obstacles
    uiOverlay.priority = 1000; // Top layer (UI)

    await add(background);
    await add(ground);
    await add(kangaroo);
    await add(uiOverlay);

    // Start cloud spawning
    startCloudSpawning();

    showMenu();
  }

  @override
  void onChildrenChanged(Component child, ChildrenChangeType type) {
    super.onChildrenChanged(child, type);

    // Performance: Maintain cached lists
    if (type == ChildrenChangeType.added) {
      if (child is Obstacle)
        _obstacles.add(child);
      else if (child is Coin)
        _coins.add(child);
      else if (child is PowerUp)
        _powerUps.add(child);
      else if (child is Cloud) _clouds.add(child);
    } else if (type == ChildrenChangeType.removed) {
      if (child is Obstacle)
        _obstacles.remove(child);
      else if (child is Coin)
        _coins.remove(child);
      else if (child is PowerUp)
        _powerUps.remove(child);
      else if (child is Cloud) _clouds.remove(child);
    }
  }

  @override
  KeyEventResult onKeyEvent(
      KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    super.onKeyEvent(event, keysPressed);

    pressedKeys = keysPressed;

    // Check for jump keys
    final jumpKeys = {
      LogicalKeyboardKey.space,
      LogicalKeyboardKey.arrowUp,
    };

    final isJumpPressed = jumpKeys.any((key) => keysPressed.contains(key));

    // Only jump if key was just pressed (not held)
    if (isJumpPressed && !wasJumpPressed) {
      handleJumpInput();
    }

    wasJumpPressed = isJumpPressed;
    return KeyEventResult.handled;
  }

  void handleJumpInput() {
    switch (gameState) {
      case GameState.menu:
        AudioManager().playButtonClick();
        startGame();
        break;
      case GameState.playing:
        kangaroo.jump();
        break;
      case GameState.gameOver:
        if (!gameOverTriggered) {
          AudioManager().playButtonClick();
          restart();
        }
        break;
    }
  }

  void showMenu() {
    gameState = GameState.menu;
    kangaroo.reset();
    gameSpeed = 0.0; // Stop background movement in menu
    speedMultiplier = 1.0;
    distanceTraveled = 0.0;
    gameOverTriggered = false;
    lastWasGap = false;

    // Clear cached lists
    _obstacles.clear();
    _coins.clear();
    _powerUps.clear();

    // Clear all gameplay elements
    removeWhere((component) =>
        component is Obstacle || component is Coin || component is PowerUp);

    // Stop background movement
    background.gameSpeed = 0.0;
    ground.gameSpeed = 0.0;

    uiOverlay.showMenu();

    // Update high score display in menu
    uiOverlay.highScoreText.text = 'Best: $highScore';
  }

  void startGame() {
    if (gameOverTriggered) return;

    gameState = GameState.playing;
    score = 0;
    coins = 0;
    distanceTraveled = 0.0;
    gameSpeed = baseSpeed;
    speedMultiplier = 1.0;
    hasDoubleJump = false;
    hasShield = false;
    isMagnetActive = false;
    lastWasGap = false;

    // IMPORTANT: Reset audio counters to prevent sound issues
    AudioManager().resetCounters();

    kangaroo.reset();
    uiOverlay.hideMenu();
    uiOverlay.showGameUI();

    // Update high score display
    uiOverlay.highScoreText.text = 'Best: $highScore';

    // Start spawning game elements
    scheduleNextObstacle();
    startCoinSpawning();
    startPowerUpSpawning();
  }

  void gameOver([ObstacleType? obstacleType]) {
    if (gameOverTriggered) return;

    gameOverTriggered = true;
    gameState = GameState.gameOver;

    // Play game over sound and stop music
    AudioManager().playGameOver();
    AudioManager().stopMusic();

    // Stop background movement immediately
    gameSpeed = 0;
    background.gameSpeed = 0;
    ground.gameSpeed = 0;

    // Stop all moving components using cached lists
    for (final obstacle in _obstacles) {
      obstacle.gameSpeed = 0;
    }
    for (final coin in _coins) {
      coin.gameSpeed = 0;
    }
    for (final powerUp in _powerUps) {
      powerUp.gameSpeed = 0;
    }
    for (final cloud in _clouds) {
      cloud.gameSpeed = 0;
    }

    // Stop all spawning
    obstacleTimer.removeFromParent();
    coinTimer.removeFromParent();
    powerUpTimer.removeFromParent();

    // Update high score and total coins
    if (score > highScore) {
      highScore = score;
    }
    totalCoins += coins;
    saveData();

    // Show game over with particle effects
    addGameOverParticles();
    uiOverlay.showGameOver(score, highScore, coins, obstacleType);

    // Add delay before allowing restart
    Future.delayed(const Duration(seconds: 1), () {
      gameOverTriggered = false;
    });
  }

  void restart() {
    if (gameOverTriggered) return;

    uiOverlay.hideGameOver();

    // Clear cached lists
    _obstacles.clear();
    _coins.clear();
    _powerUps.clear();

    // Clear all gameplay elements
    removeWhere((component) =>
        component is Obstacle || component is Coin || component is PowerUp);

    // Reset audio counters here too
    AudioManager().resetCounters();

    kangaroo.reset();
    startGame();
  }

  @override
  bool onTapDown(TapDownInfo info) {
    handleJumpInput();
    return true;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameState == GameState.playing) {
      // Update distance traveled
      distanceTraveled += gameSpeed * dt;

      // Update score based on distance (1 point per ~25 pixels = roughly 1 meter)
      score = (distanceTraveled / 25).round();
      uiOverlay.updateScore(score);

      // Increase game speed gradually based on score
      if (score < 1000) {
        // 250 to 500 over first 1000 points
        gameSpeed = 250 + (score / 1000) * 250;
      } else if (score < 1500) {
        // 500 to 600 over next 500 points
        gameSpeed = 500 + ((score - 1000) / 500) * 100;
      } else if (score < 2000) {
        // 600 to 700 over next 500 points
        gameSpeed = 600 + ((score - 1500) / 500) * 100;
      } else if (score < 3000) {
        // 700 to 750 over next 1000 points
        gameSpeed = 700 + ((score - 2000) / 1000) * 50;
      } else {
        // Cap at 750 after score 3000
        gameSpeed = 750;
      }

      // Update all moving components with new speed using cached lists
      ground.gameSpeed = gameSpeed;
      background.gameSpeed = gameSpeed;

      for (final obstacle in _obstacles) {
        obstacle.gameSpeed = gameSpeed;
      }

      for (final coin in _coins) {
        coin.gameSpeed = gameSpeed;
      }

      for (final powerUp in _powerUps) {
        powerUp.gameSpeed = gameSpeed;
      }

      for (final cloud in _clouds) {
        cloud.gameSpeed = gameSpeed;
      }
      if (isMagnetActive) {
        final kangarooPos = kangaroo.position;
        // Target position should be at the kangaroo's center, lowered
        final targetPos = kangarooPos + Vector2(70, 85);

        for (final coin in List.from(_coins)) {
          // Create copy to avoid modification during iteration
          if (coin.isCollected) continue; // Skip already collected coins

          final distance = coin.position.distanceTo(kangarooPos);
          if (distance < 300) {
            // Increased attraction range
            final direction = (targetPos - coin.position).normalized();
            // Much stronger pull force
            coin.position += direction * 800 * dt;

            // Auto-collect when coin gets close enough
            if (distance < 80) {
              // Mark as collected first to prevent double collection
              coin.isCollected = true;

              // Manually trigger collection effects
              collectCoin(); // This updates score and plays sound
              coin.collect(); // This handles visual animation and removal
            }
          }
        }
      }
    }
  }
// In lib/game/kangaroo_game.dart - Update scheduleNextObstacle method

  void scheduleNextObstacle() {
    if (gameState != GameState.playing) return;

    double spacing;
    bool willBeGap = false;

    // After score 1500, introduce gaps (close double obstacles) - MOVED FROM 1000
    if (score >= 1500 && !lastWasGap) {
      // 30% chance to create a gap (close double obstacles)
      if (random.nextDouble() < 0.3) {
        willBeGap = true;
        // Calculate gap spacing that scales with speed (random between min and max)
        final speedRatio =
            gameSpeed / 600.0; // Updated to 600 (speed at score 1500)
        final baseGapSpacing = minGapSpacing +
            random.nextDouble() * (maxGapSpacing - minGapSpacing);
        spacing = baseGapSpacing * speedRatio;
      } else {
        // Normal spacing
        spacing = minObstacleSpacing +
            random.nextDouble() * (maxObstacleSpacing - minObstacleSpacing);
      }
    } else {
      // Either score < 1500 or last was a gap, use normal spacing
      spacing = minObstacleSpacing +
          random.nextDouble() * (maxObstacleSpacing - minObstacleSpacing);
    }

    final adjustedSpacing = spacing / speedMultiplier;

    obstacleTimer = TimerComponent(
      period: adjustedSpacing,
      repeat: false,
      onTick: () {
        if (gameState == GameState.playing) {
          // Choose obstacle type based on score
          ObstacleType obstacleType;
          if (score >= 1500) {
            // After score 1500: cactus, croc, emu, or camel (no more rocks)
            final availableTypes = [
              ObstacleType.cactus,
              ObstacleType.croc,
              ObstacleType.emu,
              ObstacleType.camel
            ];
            obstacleType =
                availableTypes[random.nextInt(availableTypes.length)];
          } else if (score >= 1000) {
            // Score 1000-1499: rock, cactus, croc, or emu (no more logs)
            final availableTypes = [
              ObstacleType.rock,
              ObstacleType.cactus,
              ObstacleType.croc,
              ObstacleType.emu
            ];
            obstacleType =
                availableTypes[random.nextInt(availableTypes.length)];
          } else if (score >= 500) {
            // Score 500-999: rock, cactus, log, or emu (crocs not yet)
            final availableTypes = [
              ObstacleType.rock,
              ObstacleType.cactus,
              ObstacleType.log,
              ObstacleType.emu
            ];
            obstacleType =
                availableTypes[random.nextInt(availableTypes.length)];
          } else {
            // Before score 500: rock, cactus, or log (no crocs or emus yet)
            final availableTypes = [
              ObstacleType.rock,
              ObstacleType.cactus,
              ObstacleType.log
            ];
            obstacleType =
                availableTypes[random.nextInt(availableTypes.length)];
          }

          final obstacle = Obstacle(type: obstacleType);
          obstacle.gameSpeed = gameSpeed;
          obstacle.priority = 20; // Above ground but below kangaroo
          add(obstacle);

          // Update gap tracking
          lastWasGap = willBeGap;

          scheduleNextObstacle();
        }
      },
    );
    add(obstacleTimer);
  }

  void startCloudSpawning() {
    cloudTimer = TimerComponent(
      period: 3.0,
      repeat: true,
      onTick: () {
        final cloud = Cloud();
        cloud.gameSpeed = gameSpeed;
        cloud.priority = 5; // Behind kangaroo but above background
        add(cloud);
      },
    );
    add(cloudTimer);
  }

  void startCoinSpawning() {
    coinTimer = TimerComponent(
      period: 2.5,
      repeat: true,
      onTick: () {
        if (gameState == GameState.playing && random.nextDouble() < 0.4) {
          final startX = size.x + 50;
          final coinY = 250 + random.nextDouble() * 120;

          final coin1 = Coin();
          coin1.position = Vector2(startX, coinY);
          coin1.gameSpeed = gameSpeed;
          coin1.priority = 50; // Same level as kangaroo or slightly above
          add(coin1);

          if (random.nextDouble() < 0.3) {
            final coin2 = Coin();
            coin2.position =
                Vector2(startX + 60, coinY + random.nextDouble() * 40 - 20);
            coin2.gameSpeed = gameSpeed;
            coin2.priority = 50;
            add(coin2);
          }
        }
      },
    );
    add(coinTimer);
  }

  void startPowerUpSpawning() {
    powerUpTimer = TimerComponent(
      period: 15.0,
      repeat: true,
      onTick: () {
        if (gameState == GameState.playing) {
          final type =
              PowerUpType.values[random.nextInt(PowerUpType.values.length)];

          final powerUp = PowerUp(type: type);
          powerUp.position =
              Vector2(size.x + 50, 250 + random.nextDouble() * 100);
          powerUp.gameSpeed = gameSpeed;
          powerUp.priority = 50; // Same level as coins
          add(powerUp);
        }
      },
    );
    add(powerUpTimer);
  }

  void collectCoin() {
    coins += 5; // Each coin is now worth 5!
    uiOverlay.updateCoins(coins);

    // Play coin collect sound with current game speed for smart throttling
    AudioManager().playCoinCollect(gameSpeed: gameSpeed);

    // Performance: Skip particles if reducing effects
    if (shouldReduceEffects) return;

    // Add particle effect
    add(
      ParticleSystemComponent(
        position: kangaroo.position + Vector2(20, 20),
        particle: Particle.generate(
          count: 5,
          generator: (i) => AcceleratedParticle(
            acceleration: Vector2(0, 200),
            speed: Vector2(
                random.nextDouble() * 200 - 100, -random.nextDouble() * 200),
            position: Vector2.zero(),
            child: CircleParticle(
              radius: 3,
              paint: Paint()..color = Colors.yellow,
            ),
          ),
        ),
      ),
    );
  }

  void activatePowerUp(PowerUpType type) {
    switch (type) {
      case PowerUpType.doubleJump:
        AudioManager().playDoubleJump();
        hasDoubleJump = true;
        kangaroo.hasDoubleJump = true;
        kangaroo.activateDoubleJumpIndicator();
        Future.delayed(const Duration(seconds: 10), () {
          hasDoubleJump = false;
          kangaroo.hasDoubleJump = false;
          kangaroo.removeDoubleJumpIndicator();
        });
        break;
      case PowerUpType.shield:
        AudioManager().playShieldActivate();
        hasShield = true;
        kangaroo.activateShield();
        Future.delayed(const Duration(seconds: 8), () {
          hasShield = false;
          kangaroo.deactivateShield();
        });
        break;
      case PowerUpType.magnet:
        AudioManager().playMagnetActivate();
        isMagnetActive = true;
        kangaroo.activateMagnetIndicator();
        Future.delayed(const Duration(seconds: 10), () {
          isMagnetActive = false;
          kangaroo.removeMagnetIndicator();
        });
        break;
    }

    uiOverlay.showPowerUpNotification(type);
  }

  void onObstacleCollision(ObstacleType obstacleType) {
    if (gameState == GameState.playing) {
      if (hasShield) {
        hasShield = false;
        kangaroo.deactivateShield();
        // Play collision sound for shield break
        AudioManager().playCollision();
        // Add shield break effect
        addShieldBreakParticles();
      } else {
        // Play collision sound before game over
        AudioManager().playCollision();
        gameOver(obstacleType);
      }
    }
  }

  void addGameOverParticles() {
    // Performance: Reduce particles
    add(
      ParticleSystemComponent(
        position: size / 2,
        particle: Particle.generate(
          count: shouldReduceEffects ? 15 : 30,
          generator: (i) => AcceleratedParticle(
            acceleration: Vector2(0, 300),
            speed: Vector2(
              random.nextDouble() * 400 - 200,
              -random.nextDouble() * 400,
            ),
            position: Vector2.zero(),
            child: CircleParticle(
              radius: random.nextDouble() * 5 + 2,
              paint: Paint()..color = Colors.orange.withValues(alpha: 0.8),
            ),
          ),
        ),
      ),
    );
  }

  void addShieldBreakParticles() {
    add(
      ParticleSystemComponent(
        position: kangaroo.position + kangaroo.size / 2,
        particle: Particle.generate(
          count: shouldReduceEffects ? 15 : 30,
          generator: (i) => AcceleratedParticle(
            acceleration: Vector2(0, 100),
            speed: Vector2(
              random.nextDouble() * 300 - 150,
              -random.nextDouble() * 200,
            ),
            position: Vector2.zero(),
            child: CircleParticle(
              radius: 4,
              paint: Paint()..color = Colors.blue.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    highScore = prefs.getInt('kangaroo_hop_high_score') ?? 0;
    totalCoins = prefs.getInt('kangaroo_hop_total_coins') ?? 0;
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('kangaroo_hop_high_score', highScore);
    await prefs.setInt('kangaroo_hop_total_coins', totalCoins);
  }
}
