import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
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
import '../components/store_screen.dart';
import 'audio_manager.dart';
import 'store_manager.dart';

enum GameState { menu, playing, gameOver }

class KangarooGame extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection, TapDetector {
  late Kangaroo kangaroo;
  late Background background;
  late Ground ground;
  late UiOverlay uiOverlay;
  late StoreManager storeManager;
  StoreScreen? storeScreen;

  GameState gameState = GameState.menu;
  int score = 0;
  int highScore = 0;
  int sessionCoins = 0; // Coins earned in current game session
  double gameSpeed = 250.0;
  double baseSpeed = 250.0;
  double speedMultiplier = 1.0;
  bool hasDoubleJump = false;
  // Shield system is now handled in kangaroo component
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

  static const double minObstacleSpacing = 1;
  static const double maxObstacleSpacing = 2.5;
  static const double minGapSpacing = 0.1;
  static const double maxGapSpacing = 1.5;

  bool lastWasGap = false;

  // Performance optimization: Cache moving components
  final List<Obstacle> _obstacles = [];
  final List<Coin> _coins = [];
  final List<PowerUp> _powerUps = [];
  final List<Cloud> _clouds = [];

  bool get shouldReduceEffects =>
      kIsWeb || gameSpeed > 500; // Force reduction for web

  @override
  Color backgroundColor() => const Color(0xFF87CEEB);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Set up camera to match screen size
    camera.viewfinder.visibleGameSize = size;

    // Initialize store manager
    storeManager = StoreManager();
    await storeManager.loadData();

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

    // Check for power-up keys during gameplay
    if (gameState == GameState.playing) {
      if (keysPressed.contains(LogicalKeyboardKey.digit1)) {
        _tryUsePowerUp(PowerUpType.doubleJump);
      }
      if (keysPressed.contains(LogicalKeyboardKey.digit2)) {
        _tryUsePowerUp(PowerUpType.shield);
      }
      if (keysPressed.contains(LogicalKeyboardKey.digit3)) {
        _tryUsePowerUp(PowerUpType.magnet);
      }
    }

    wasJumpPressed = isJumpPressed;
    return KeyEventResult.handled;
  }

  void handleJumpInput() {
    // IMMEDIATE audio call - don't wait for animation
    if (gameState == GameState.playing) {
      AudioManager().playJump(); // Call FIRST for immediate response
      kangaroo.jump(); // Then process jump
      return; // Exit early for playing state
    }

    AudioManager().initializeAudio(); // Initialize on any input

    switch (gameState) {
      case GameState.menu:
        AudioManager().playButtonClick(); // Immediate click sound
        startGame();
        break;
      case GameState.gameOver:
        if (!gameOverTriggered) {
          AudioManager().playButtonClick(); // Immediate click sound
          restart();
        }
        break;
      case GameState.playing:
        // Already handled above
        break;
    }
  }

  void showMenu() {
    gameState = GameState.menu;
    kangaroo.reset();
    gameSpeed = 0.0;
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
    uiOverlay.highScoreText.text = 'Best: $highScore';
    uiOverlay.updateCoins();

    // PRE-WARM audio system for web (ADD THIS)
    if (kIsWeb) {
      _prewarmAudio();
    }
  }

  void _prewarmAudio() async {
    // Play sounds at 0 volume to initialize audio buffers
    try {
      await Future.delayed(Duration(milliseconds: 100));
      FlameAudio.play('sfx/jump.mp3', volume: 0.0);
      await Future.delayed(Duration(milliseconds: 50));
      FlameAudio.play('sfx/coin_collect.mp3', volume: 0.0);
      await Future.delayed(Duration(milliseconds: 50));
      FlameAudio.play('sfx/button_click.mp3', volume: 0.0);
      print('Audio pre-warming complete');
    } catch (e) {
      print('Audio prewarm failed: $e');
    }
  }

  void startGame() {
    if (gameOverTriggered) return;

    gameState = GameState.playing;
    score = 0;
    sessionCoins = 0; // Reset session coins
    distanceTraveled = 0.0;
    gameSpeed = baseSpeed;
    speedMultiplier = 1.0;
    hasDoubleJump = false;
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

    // Update high score
    if (score > highScore) {
      highScore = score;
    }

    // DEBUG: Log the original sessionCoins value
    print('DEBUG gameOver(): Original sessionCoins = $sessionCoins');

    // CRITICAL FIX: Store the original sessionCoins value before modifying it
    final coinsEarnedThisSession = sessionCoins;
    print(
        'DEBUG gameOver(): Stored coinsEarnedThisSession = $coinsEarnedThisSession');

    // Add session coins to total and reset session coins
    storeManager.addCoins(sessionCoins);
    sessionCoins = 0; // Reset session coins after adding to total
    print('DEBUG gameOver(): After reset, sessionCoins = $sessionCoins');

    saveData();

    // Show game over with particle effects
    addGameOverParticles();

    // FIXED: Pass the original coins earned value, not the reset sessionCoins
    print(
        'DEBUG gameOver(): Calling showGameOver with coinsEarnedThisSession = $coinsEarnedThisSession');
    uiOverlay.showGameOver(
        score, highScore, coinsEarnedThisSession, obstacleType);

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
    print('Game received tap at: ${info.eventPosition.global}');
    print('Current game state: $gameState');
    print('Store screen exists: ${storeScreen != null}');

    // CRITICAL: Store screen has HIGHEST priority - check first
    if (storeScreen != null) {
      print('Store is open - delegating to store screen');
      // Store is open - let it handle ALL taps exclusively
      return storeScreen!.onTapDown(info);
    }

    // Store is not open - check UI overlay for buttons
    print('Checking UI overlay for button taps');
    if (uiOverlay.onTapDown(info)) {
      // UI handled the tap (like store button) - don't do anything else
      print('UI overlay handled the tap');
      return true;
    }

    // No UI elements were tapped - handle game input
    print('No UI elements tapped - handling as game input');
    handleJumpInput();
    return true;
  }

  void showStore() {
    print('showStore() called');

// CRITICAL: Add session coins to total before showing store
// This ensures the store shows the most up-to-date coin count
    if (sessionCoins > 0) {
      storeManager.addCoins(sessionCoins);
      sessionCoins = 0;
    }

    if (storeScreen == null) {
      storeScreen = StoreScreen();
      storeScreen!.priority = 2000; // Ensure it's on top
      add(storeScreen!);
      print('Store screen added with priority 2000');
    }
    // Update store display to show current coin balance and power-up counts
    storeScreen!.updateCoinDisplay();
  }

  void hideStore() {
    print('hideStore() called');
    if (storeScreen != null) {
      storeScreen!.removeFromParent();
      storeScreen = null;
      print('Store screen removed');
    }
    // Update coin display when closing store - now should show only totalCoins since sessionCoins is 0
    uiOverlay.updateCoins();
    uiOverlay.updatePowerUpCounts();
  }

// Add a method to get current total coins for display
  int getCurrentTotalCoins() {
    return storeManager.totalCoins + sessionCoins;
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

      // Increase game speed at moderate pace with extra layer
      if (score < 650) {
        // 250 to 500 over first 650 points (halfway between original 1000 and fast 300)
        gameSpeed = 250 + (score / 650) * 250;
      } else if (score < 1000) {
        // 500 to 625 over next 350 points
        gameSpeed = 500 + ((score - 650) / 350) * 125;
      } else if (score < 1500) {
        // 625 to 750 over next 500 points
        gameSpeed = 625 + ((score - 1000) / 500) * 125;
      } else if (score < 2000) {
        // 750 to 875 over next 500 points
        gameSpeed = 750 + ((score - 1500) / 500) * 125;
      } else if (score < 2500) {
        // 875 to 1000 over next 500 points (extra layer)
        gameSpeed = 875 + ((score - 2000) / 500) * 125;
      } else {
        // Cap at 1000 after score 2500
        gameSpeed = 1000;
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

  void scheduleNextObstacle() {
    if (gameState != GameState.playing) return;

    double spacing;
    bool willBeGap = false;

    // After score 1000, introduce gaps with TRUE 30% probability
    if (score >= 1000) {
      // After a gap, force minimum spacing to prevent triple obstacles
      if (lastWasGap) {
        // Force normal spacing after a gap (no immediate obstacles)
        spacing = minObstacleSpacing +
            random.nextDouble() * (maxObstacleSpacing - minObstacleSpacing);
        willBeGap = false;
      } else {
        // TRUE 30% chance for gaps (only when last wasn't a gap)
        if (random.nextDouble() < 0.3) {
          willBeGap = true;
          // Gaps: random between 0.1-0.3 seconds
          spacing = 0.1 + random.nextDouble() * 0.2; // 0.1 to 0.3 seconds
        } else {
          // Normal obstacles: constant time spacing (1.5-2.5 seconds)
          spacing = minObstacleSpacing +
              random.nextDouble() * (maxObstacleSpacing - minObstacleSpacing);
        }
      }
    } else {
      // Before score 1000: only normal obstacles
      spacing = minObstacleSpacing +
          random.nextDouble() * (maxObstacleSpacing - minObstacleSpacing);
    }

    // Use spacing directly - no speed adjustment needed
    // The difficulty comes from speed increase alone
    obstacleTimer = TimerComponent(
      period: spacing,
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
    // IMMEDIATE audio response
    AudioManager().playCoinCollect(gameSpeed: gameSpeed);

    sessionCoins += 5;
    uiOverlay.updateCoins();

    // Skip particles if reducing effects
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
        kangaroo.addShield();
        // Each shield lasts 8 seconds independently
        Future.delayed(const Duration(seconds: 8), () {
          kangaroo.removeOneShield();
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
      // IMMEDIATE audio response
      AudioManager().playCollision();

      if (kangaroo.hasAnyShield) {
        kangaroo.removeOneShield();
        addShieldBreakParticles();
      } else {
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
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('kangaroo_hop_high_score', highScore);
  }

  void _tryUsePowerUp(PowerUpType type) {
    if (storeManager.usePowerUp(type)) {
      activatePowerUp(type);
      uiOverlay.updatePowerUpCounts();
    }
  }
}
