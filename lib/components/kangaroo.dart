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

class Kangaroo extends PositionComponent
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

  late PositionComponent visualContainer;
  late RectangleComponent body;
  late RectangleComponent tail;
  late RectangleComponent ear1;
  late RectangleComponent ear2;
  late CircleComponent eye;
  late RectangleComponent pouch;
  late RectangleComponent armFront;
  late RectangleComponent armBack;
  late RectangleComponent legFront;
  late RectangleComponent legBack;

  CircleComponent? shieldVisual;
  PositionComponent? doubleJumpIndicator;
  PositionComponent? magnetIndicator;
  double rotation = 0;

  // Performance: Track animation state
  double _animationTime = 0;
  bool _hasActiveScaleEffect = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    size = Vector2(60, 80);
    position = Vector2(150, groundY - size.y);

    // Create visual container for scaling effects
    visualContainer = PositionComponent();
    add(visualContainer);

    // Create kangaroo body parts
    body = RectangleComponent(
      size: Vector2(40, 50),
      position: Vector2(10, 20),
      paint: Paint()..color = const Color(0xFFD2691E),
    );

    tail = RectangleComponent(
      size: Vector2(25, 35),
      position: Vector2(-15, 40),
      paint: Paint()..color = const Color(0xFFCD853F),
      angle: 0.3,
    );

    ear1 = RectangleComponent(
      size: Vector2(8, 15),
      position: Vector2(15, 5),
      paint: Paint()..color = const Color(0xFFD2691E),
      angle: -0.2,
    );

    ear2 = RectangleComponent(
      size: Vector2(8, 15),
      position: Vector2(30, 5),
      paint: Paint()..color = const Color(0xFFD2691E),
      angle: 0.2,
    );

    eye = CircleComponent(
      radius: 3,
      position: Vector2(35, 25),
      paint: Paint()..color = Colors.black,
    );

    pouch = RectangleComponent(
      size: Vector2(20, 15),
      position: Vector2(20, 45),
      paint: Paint()..color = const Color(0xFFDEB887),
    );

    armFront = RectangleComponent(
      size: Vector2(8, 20),
      position: Vector2(35, 35),
      paint: Paint()..color = const Color(0xFFD2691E),
      angle: 0.3,
    );

    armBack = RectangleComponent(
      size: Vector2(8, 20),
      position: Vector2(15, 35),
      paint: Paint()..color = const Color(0xFFCD853F),
      angle: -0.3,
    );

    legFront = RectangleComponent(
      size: Vector2(12, 25),
      position: Vector2(30, 55),
      paint: Paint()..color = const Color(0xFFD2691E),
    );

    legBack = RectangleComponent(
      size: Vector2(12, 25),
      position: Vector2(15, 55),
      paint: Paint()..color = const Color(0xFFCD853F),
    );

    // Add all body parts to visual container
    visualContainer.add(tail);
    visualContainer.add(legBack);
    visualContainer.add(armBack);
    visualContainer.add(body);
    visualContainer.add(pouch);
    visualContainer.add(legFront);
    visualContainer.add(armFront);
    visualContainer.add(ear1);
    visualContainer.add(ear2);
    visualContainer.add(eye);

    // Add collision detection - separate from visual scaling
    final hitbox =
        RectangleHitbox(size: Vector2(40, 70), position: Vector2(10, 10));
    add(hitbox);

    // Add idle animation
    addIdleAnimation();
  }

  void addIdleAnimation() {
    // Subtle breathing animation
    body.add(
      SizeEffect.to(
        Vector2(42, 52),
        EffectController(
          duration: 2,
          reverseDuration: 2,
          infinite: true,
        ),
      ),
    );

    // Ear twitch
    ear1.add(
      RotateEffect.by(
        0.1,
        EffectController(
          duration: 3,
          reverseDuration: 3,
          infinite: true,
          startDelay: 1,
        ),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Apply gravity and physics
    if (!isOnGround || isJumping) {
      verticalSpeed += gravity * dt;
      position.y += verticalSpeed * dt;

      // Rotate slightly while jumping
      rotation = (verticalSpeed / jumpSpeed) * 0.2;
      angle = rotation;

      // Check if landed
      if (position.y >= groundY - size.y) {
        land();
      }
    } else {
      angle = 0;
    }

    // Animate legs while running (optimized)
    if (isOnGround && game.gameState == GameState.playing) {
      _animationTime += dt;

      // Performance: Reduce animation calculations at high speeds
      final animSpeed = game.gameSpeed > 500 ? 0.7 : 1.0;
      final time = _animationTime * animSpeed;

      // Use cached sin values
      final sin10 = sin(time * 10);
      final sin8 = sin(time * 8);
      final sin12 = sin(time * 12);

      legFront.angle = sin10 * 0.3;
      legBack.angle = -sin10 * 0.3;
      armFront.angle = 0.3 + sin8 * 0.2;
      armBack.angle = -0.3 - sin8 * 0.2;

      // Bob up and down slightly (reduced at high speeds)
      body.position.y = 20 + sin12 * 2;
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

      // Add double jump particles
      addDoubleJumpParticles();
    }
  }

  void performJump(double speed) {
    verticalSpeed = speed;
    isOnGround = false;
    isJumping = true;

    AudioManager().playJump();

    // Add jump particles
    addJumpParticles();

    // Performance: Skip scale effect if one is active
    if (!_hasActiveScaleEffect) {
      _hasActiveScaleEffect = true;

      // Reset scale first
      visualContainer.scale = Vector2.all(1.0);

      // Squash and stretch effect
      visualContainer.add(
        ScaleEffect.to(
          Vector2(1.2, 0.8),
          EffectController(duration: 0.1),
          onComplete: () {
            visualContainer.add(
              ScaleEffect.to(
                Vector2(1.0, 1.0),
                EffectController(duration: 0.2),
                onComplete: () => _hasActiveScaleEffect = false,
              ),
            );
          },
        ),
      );
    }
  }

  void land() {
    position.y = groundY - size.y;
    verticalSpeed = 0.0;
    isOnGround = true;
    isJumping = false;
    jumpCount = 0;

    // Landing particles
    addLandingParticles();

    if (!_hasActiveScaleEffect) {
      _hasActiveScaleEffect = true;

      // Reset scale first
      visualContainer.scale = Vector2.all(1.0);

      // Squash effect on landing
      visualContainer.add(
        ScaleEffect.to(
          Vector2(1.3, 0.7),
          EffectController(duration: 0.1),
          onComplete: () {
            visualContainer.add(
              ScaleEffect.to(
                Vector2(1.0, 1.0),
                EffectController(duration: 0.15),
                onComplete: () => _hasActiveScaleEffect = false,
              ),
            );
          },
        ),
      );
    }
  }

  void reset() {
    position = Vector2(150, groundY - size.y);
    verticalSpeed = 0.0;
    isOnGround = true;
    isJumping = false;
    hasDoubleJump = false;
    hasUsedDoubleJump = false;
    jumpCount = 0;
    angle = 0;
    visualContainer.scale = Vector2.all(1);
    _animationTime = 0;
    _hasActiveScaleEffect = false;

    if (isShielded) {
      deactivateShield();
    }

    // Remove power-up indicators
    removeDoubleJumpIndicator();
    removeMagnetIndicator();
  }

  void activateShield() {
    isShielded = true;

    // Add shield visual as a bubble around the kangaroo
    shieldVisual = CircleComponent(
      radius: 50,
      position: Vector2(30, 40), // Center around kangaroo
      anchor: Anchor.center,
      paint: Paint()
        ..color = Colors.blue.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );

    add(shieldVisual!); // Add to main component, not visual container

    // Add pulsing effect to shield
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

    // Performance: Reduce sparkle count
    final sparkleCount = game.shouldReduceEffects ? 4 : 8;

    // Create sparkles around the kangaroo for double jump
    for (int i = 0; i < sparkleCount; i++) {
      final angle = (i * pi / (sparkleCount / 2));
      final radius = 45.0;
      final sparkle = CircleComponent(
        radius: 4,
        position: Vector2(
          30 + cos(angle) * radius,
          40 + sin(angle) * radius,
        ),
        paint: Paint()..color = Colors.purple.withValues(alpha: 0.7),
      );

      doubleJumpIndicator!.add(sparkle);

      // Performance: Simpler animation at high speeds
      if (!game.shouldReduceEffects) {
        // Add twinkling animation to each sparkle
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

        // Add floating motion
        sparkle.add(
          MoveEffect.by(
            Vector2(sin(angle) * 8, cos(angle) * 8),
            EffectController(
              duration: 1.5 + (i * 0.2),
              reverseDuration: 1.5 + (i * 0.2),
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

    magnetIndicator = PositionComponent(position: Vector2(30, 75));

    // Performance: Simpler magnet effect at high speeds
    if (game.shouldReduceEffects) {
      // Just show magnet symbol
      magnetIndicator!.add(TextComponent(
        text: '🧲',
        position: Vector2(0, 0),
        anchor: Anchor.center,
        textRenderer: TextPaint(
          style: const TextStyle(fontSize: 14),
        ),
      ));
    } else {
      // Magnetic field effect
      for (int i = 0; i < 3; i++) {
        magnetIndicator!.add(CircleComponent(
          radius: 8 + i * 4,
          paint: Paint()
            ..color = Colors.cyan.withValues(alpha: 0.5 - i * 0.15)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        ));
      }

      // Magnet symbol
      magnetIndicator!.add(TextComponent(
        text: '🧲',
        position: Vector2(0, 0),
        anchor: Anchor.center,
        textRenderer: TextPaint(
          style: const TextStyle(
            fontSize: 14,
            shadows: [
              Shadow(
                color: Colors.cyan,
                offset: Offset(0, 0),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ));

      // Add rotating magnetic field animation
      magnetIndicator!.add(
        RotateEffect.by(
          2 * pi,
          EffectController(
            duration: 2,
            infinite: true,
          ),
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
    // Performance: Skip particles at very high speeds
    if (game.gameSpeed > 600) return;

    // Reduce particles at high speeds for better performance
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
    // Performance: Reduce particles at high speeds
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
    // Performance: Skip particles at very high speeds
    if (game.gameSpeed > 600) return;

    // Reduce particles at high speeds for better performance
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
