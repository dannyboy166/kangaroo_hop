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

class Kangaroo extends SpriteComponent
    with HasGameReference<KangarooGame>, CollisionCallbacks {
  static const double jumpSpeed = -500.0;
  static const double doubleJumpSpeed = -450.0;
  static const double gravity = 1200.0;
  static const double groundY = 400.0;

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

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    size = Vector2(40, 40);
    position = Vector2(150, groundY - size.y);

    // Load a single sprite
    sprite = await game.images.load('kangaroo_animations.png').then((image) => 
      Sprite(image, srcSize: Vector2(40, 40), srcPosition: Vector2.zero()));

    // Add collision detection
    add(RectangleHitbox(size: Vector2(30, 35), position: Vector2(5, 5)));
  }


  @override
  void update(double dt) {
    super.update(dt);

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
      // First jump
      performJump(jumpSpeed);
      jumpCount = 1;
      hasUsedDoubleJump = false;
    } else if (hasDoubleJump && !hasUsedDoubleJump && jumpCount == 1) {
      // Double jump
      performJump(doubleJumpSpeed);
      hasUsedDoubleJump = true;
      jumpCount = 2;
      addDoubleJumpParticles();
    }
  }

  void performJump(double speed) {
    verticalSpeed = speed;
    isOnGround = false;
    isJumping = true;
    hasPlayedLandingSound = false;

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

    if (isShielded) {
      deactivateShield();
    }

    removeDoubleJumpIndicator();
    removeMagnetIndicator();
  }

  // Keep all your existing methods:
  void activateShield() {
    isShielded = true;
    shieldVisual = CircleComponent(
      radius: 40,
      position: Vector2(32, 32),
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
      final radius = 35.0;
      final sparkle = CircleComponent(
        radius: 3,
        position: Vector2(
          32 + cos(angle) * radius,
          32 + sin(angle) * radius,
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

    magnetIndicator = PositionComponent(position: Vector2(32, 60));

    if (game.shouldReduceEffects) {
      magnetIndicator!.add(TextComponent(
        text: '🧲',
        position: Vector2(0, 0),
        anchor: Anchor.center,
        textRenderer: TextPaint(
          style: const TextStyle(fontSize: 12),
        ),
      ));
    } else {
      for (int i = 0; i < 3; i++) {
        magnetIndicator!.add(CircleComponent(
          radius: 6 + i * 3,
          paint: Paint()
            ..color = Colors.cyan.withValues(alpha: 0.5 - i * 0.15)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        ));
      }

      magnetIndicator!.add(TextComponent(
        text: '🧲',
        position: Vector2(0, 0),
        anchor: Anchor.center,
        textRenderer: TextPaint(
          style: const TextStyle(fontSize: 12),
        ),
      ));

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
      game.onObstacleCollision();
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
