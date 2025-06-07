import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

import '../game/kangaroo_game.dart';
import '../game/audio_manager.dart';
import 'coin.dart';
import 'obstacle.dart';
import 'power_up.dart';

class Kangaroo extends SpriteAnimationComponent
    with HasGameReference<KangarooGame>, CollisionCallbacks {
  static const double jumpSpeed = -600.0;
  static const double doubleJumpSpeed = -450.0;
  static const double gravity = 1200.0;
  static const double groundY = 403.0;

  double verticalSpeed = 0.0;
  bool isOnGround = true;
  bool isJumping = false;
  bool hasDoubleJump = false;
  bool hasUsedDoubleJump = false;
  bool isShielded = false;
  int jumpCount = 0;

  CircleComponent? shieldVisual;
  PositionComponent? doubleJumpIndicator;
  PositionComponent? magnetIndicator;

  bool hasPlayedLandingSound = false;

  // Animation states
  late SpriteAnimation idleAnimation;
  late SpriteAnimation runningAnimation;
  late SpriteAnimation normalJumpAnimation;
  late SpriteAnimation highJumpAnimation;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    size = Vector2(140, 140); // 3x bigger (was 40x40)
    position = Vector2(150, groundY - size.y);

    // Load the NEW 12-frame sprite sheet (768x256 with 6x2 frames, each 128x128)
    final spriteSheet = await game.images.load('kangaroos.png');

    // Create idle animation (just the first frame - for menu screen)
    idleAnimation = SpriteAnimation.fromFrameData(
      spriteSheet,
      SpriteAnimationData.sequenced(
        amount: 1,
        stepTime: 1.0,
        textureSize: Vector2(128, 128),
        texturePosition: Vector2(0, 0), // Top-left frame (idle)
      ),
    );

    // Create AMAZING 12-frame running animation (all frames in sequence)
    runningAnimation = SpriteAnimation.fromFrameData(
      spriteSheet,
      SpriteAnimationData([
        // Top row - frames 1-6
        SpriteAnimationFrameData(
          srcPosition: Vector2(0, 0), // Frame 1
          srcSize: Vector2(128, 128),
          stepTime: 0.08, // Fast for smooth animation
        ),
        SpriteAnimationFrameData(
          srcPosition: Vector2(128, 0), // Frame 2
          srcSize: Vector2(128, 128),
          stepTime: 0.08,
        ),
        SpriteAnimationFrameData(
          srcPosition: Vector2(256, 0), // Frame 3
          srcSize: Vector2(128, 128),
          stepTime: 0.08,
        ),
        SpriteAnimationFrameData(
          srcPosition: Vector2(384, 0), // Frame 4
          srcSize: Vector2(128, 128),
          stepTime: 0.08,
        ),
        SpriteAnimationFrameData(
          srcPosition: Vector2(512, 0), // Frame 5
          srcSize: Vector2(128, 128),
          stepTime: 0.08,
        ),
        SpriteAnimationFrameData(
          srcPosition: Vector2(640, 0), // Frame 6
          srcSize: Vector2(128, 128),
          stepTime: 0.08,
        ),
        // Bottom row - frames 7-12
        SpriteAnimationFrameData(
          srcPosition: Vector2(0, 128), // Frame 7
          srcSize: Vector2(128, 128),
          stepTime: 0.08,
        ),
        SpriteAnimationFrameData(
          srcPosition: Vector2(128, 128), // Frame 8
          srcSize: Vector2(128, 128),
          stepTime: 0.08,
        ),
        SpriteAnimationFrameData(
          srcPosition: Vector2(256, 128), // Frame 9
          srcSize: Vector2(128, 128),
          stepTime: 0.08,
        ),
        SpriteAnimationFrameData(
          srcPosition: Vector2(384, 128), // Frame 10
          srcSize: Vector2(128, 128),
          stepTime: 0.08,
        ),
        SpriteAnimationFrameData(
          srcPosition: Vector2(512, 128), // Frame 11
          srcSize: Vector2(128, 128),
          stepTime: 0.08,
        ),
        SpriteAnimationFrameData(
          srcPosition: Vector2(640, 128), // Frame 12
          srcSize: Vector2(128, 128),
          stepTime: 0.08,
        ),
      ]),
    );

    // Create normal jump animation (use a good jumping frame - let's try frame 3)
    normalJumpAnimation = SpriteAnimation.fromFrameData(
      spriteSheet,
      SpriteAnimationData.sequenced(
        amount: 1,
        stepTime: 1.0,
        textureSize: Vector2(128, 128),
        texturePosition: Vector2(256, 0), // Frame 3 from top row
      ),
    );

    // Create high jump animation (use frame 9 from bottom row for variety)
    highJumpAnimation = SpriteAnimation.fromFrameData(
      spriteSheet,
      SpriteAnimationData.sequenced(
        amount: 1,
        stepTime: 1.0,
        textureSize: Vector2(128, 128),
        texturePosition: Vector2(256, 128), // Frame 9 from bottom row
      ),
    );

    // Start with running animation (since game starts in playing state)
    animation = runningAnimation;

    // Add collision detection (made slightly less wide)
    final hitbox =
        RectangleHitbox(size: Vector2(60, 40), position: Vector2(55, 80));

    // Make the collision box visible for testing
    hitbox.paint = Paint()
      ..color = Colors.red.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    hitbox.renderShape = true;

    add(hitbox);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Update animation based on state
    if (isOnGround && !isJumping) {
      // Use running animation when on ground during gameplay, idle only for menu
      if (game.gameState == GameState.playing) {
        if (animation != runningAnimation) {
          animation = runningAnimation;
        }
      } else {
        if (animation != idleAnimation) {
          animation = idleAnimation;
        }
      }
    }

    // Apply gravity and physics
    if (!isOnGround || isJumping) {
      verticalSpeed += gravity * dt;
      position.y += verticalSpeed * dt;

      // Check if about to land
      final distanceToGround = groundY - size.y - position.y;

      if (distanceToGround <= 30 &&
          verticalSpeed > 0 &&
          !hasPlayedLandingSound) {
        AudioManager().playLand();
        hasPlayedLandingSound = true;
      }

      // Check if actually landed
      if (position.y >= groundY - size.y) {
        land();
      }
    }
  }

  void jump() {
    if (game.gameState != GameState.playing) return;

    if (isOnGround) {
      // First jump - use normal jump animation
      performJump(jumpSpeed, false);
      jumpCount = 1;
      hasUsedDoubleJump = false;
    } else if (hasDoubleJump && !hasUsedDoubleJump && jumpCount == 1) {
      // Double jump - use high jump animation
      performJump(doubleJumpSpeed, true);
      hasUsedDoubleJump = true;
      jumpCount = 2;
      addDoubleJumpParticles();
    }
  }

  void performJump(double speed, bool isHighJump) {
    verticalSpeed = speed;
    isOnGround = false;
    isJumping = true;
    hasPlayedLandingSound = false;

    // Play the appropriate jump animation
    if (isHighJump) {
      animation = highJumpAnimation;
    } else {
      animation = normalJumpAnimation;
    }

    AudioManager().playJump();
    addJumpParticles();
  }

  void land() {
    position.y = groundY - size.y;
    verticalSpeed = 0.0;
    isOnGround = true;
    isJumping = false;
    jumpCount = 0;

    addLandingParticles();
  }

  void reset() {
    position = Vector2(150, groundY - size.y);
    verticalSpeed = 0.0;
    isOnGround = true;
    isJumping = false;
    hasDoubleJump = false;
    hasUsedDoubleJump = false;
    jumpCount = 0;
    hasPlayedLandingSound = false;

    // Reset to appropriate animation based on game state
    if (game.gameState == GameState.playing) {
      animation = runningAnimation;
    } else {
      animation = idleAnimation;
    }

    if (isShielded) {
      deactivateShield();
    }

    removeDoubleJumpIndicator();
    removeMagnetIndicator();
  }

  void activateShield() {
    isShielded = true;
    shieldVisual = CircleComponent(
      radius: 60,
      position: Vector2(70, 85), // Moved closer to kangaroo center (was 60, 60)
      anchor: Anchor.center,
      paint: Paint()
        ..color = Colors.blue.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );
    add(shieldVisual!);

    shieldVisual!.add(
      ScaleEffect.to(
        Vector2.all(1.1),
        EffectController(
          duration: 0.5,
          reverseDuration: 0.5,
          infinite: true,
        ),
      ),
    );
  }

  void deactivateShield() {
    isShielded = false;
    shieldVisual?.removeFromParent();
    shieldVisual = null;
  }

  void activateDoubleJumpIndicator() {
    if (doubleJumpIndicator != null) return;

    doubleJumpIndicator = PositionComponent();
    final sparkleCount = game.shouldReduceEffects ? 4 : 8;

    for (int i = 0; i < sparkleCount; i++) {
      final angle = (i * pi / (sparkleCount / 2));
      final radius = 90.0; // Reduced from 105 to bring closer to kangaroo
      final sparkle = CircleComponent(
        radius: 9,
        position: Vector2(
          70 + cos(angle) * radius, // Adjusted to center on kangaroo (was 60)
          85 + sin(angle) * radius, // Moved lower (was 70)
        ),
        paint: Paint()..color = Colors.purple.withValues(alpha: 0.7),
      );

      doubleJumpIndicator!.add(sparkle);

      if (!game.shouldReduceEffects) {
        sparkle.add(
          OpacityEffect.to(
            0.3,
            EffectController(
              duration: 0.5 + (i * 0.1),
              reverseDuration: 0.5 + (i * 0.1),
              infinite: true,
            ),
          ),
        );
      }
    }
    add(doubleJumpIndicator!);
  }

  void removeDoubleJumpIndicator() {
    doubleJumpIndicator?.removeFromParent();
    doubleJumpIndicator = null;
  }

  void activateMagnetIndicator() {
    if (magnetIndicator != null) return;

    magnetIndicator =
        PositionComponent(position: Vector2(70, 85)); // Centered on kangaroo

    if (game.shouldReduceEffects) {
      // Just the blue circles for reduced effects
      for (int i = 0; i < 3; i++) {
        magnetIndicator!.add(CircleComponent(
          radius: (18 + i * 9),
          paint: Paint()
            ..color = Colors.cyan.withValues(alpha: 0.5 - i * 0.15)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6,
        ));
      }
    } else {
      // Full effect with rotating blue circles (no magnet emoji)
      for (int i = 0; i < 3; i++) {
        magnetIndicator!.add(CircleComponent(
          radius: (18 + i * 9),
          paint: Paint()
            ..color = Colors.cyan.withValues(alpha: 0.5 - i * 0.15)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6,
        ));
      }

      magnetIndicator!.add(
        RotateEffect.by(
          2 * pi,
          EffectController(duration: 2, infinite: true),
        ),
      );
    }
    add(magnetIndicator!);
  }

  void removeMagnetIndicator() {
    magnetIndicator?.removeFromParent();
    magnetIndicator = null;
  }

  void addJumpParticles() {
    if (game.gameSpeed > 600) return;

    final particleCount = game.shouldReduceEffects ? 3 : 8;
    game.add(
      ParticleSystemComponent(
        position: position + Vector2(size.x / 2, size.y),
        particle: Particle.generate(
          count: particleCount,
          generator: (i) => AcceleratedParticle(
            acceleration: Vector2(0, 100),
            speed: Vector2(
              game.random.nextDouble() * 100 - 50,
              game.random.nextDouble() * 50,
            ),
            position: Vector2.zero(),
            child: CircleParticle(
              radius: 2,
              paint: Paint()..color = const Color(0xFFD2B48C),
            ),
          ),
        ),
      ),
    );
  }

  void addDoubleJumpParticles() {
    final particleCount = game.shouldReduceEffects ? 10 : 20;
    game.add(
      ParticleSystemComponent(
        position: position + Vector2(size.x / 2, size.y / 2),
        particle: Particle.generate(
          count: particleCount,
          generator: (i) => AcceleratedParticle(
            acceleration: Vector2(0, 50),
            speed: Vector2(
              cos(i * pi / 10) * 150,
              sin(i * pi / 10) * 150,
            ),
            position: Vector2.zero(),
            child: CircleParticle(
              radius: 3,
              paint: Paint()..color = Colors.purple.withValues(alpha: 0.8),
            ),
          ),
        ),
      ),
    );
  }

  void addLandingParticles() {
    if (game.gameSpeed > 600) return;

    final particleCount = game.shouldReduceEffects ? 5 : 12;
    game.add(
      ParticleSystemComponent(
        position: position + Vector2(size.x / 2, size.y),
        particle: Particle.generate(
          count: particleCount,
          generator: (i) => AcceleratedParticle(
            acceleration: Vector2(0, 200),
            speed: Vector2(
              game.random.nextDouble() * 200 - 100,
              -game.random.nextDouble() * 100,
            ),
            position: Vector2.zero(),
            child: CircleParticle(
              radius: 2,
              paint: Paint()..color = const Color(0xFFD2B48C),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Obstacle) {
      game.onObstacleCollision(other.type);
      return true;
    } else if (other is Coin) {
      other.collect();
      game.collectCoin();
      return true;
    } else if (other is PowerUp) {
      other.collect();
      game.activatePowerUp(other.type);
      return true;
    }

    return false;
  }
}
