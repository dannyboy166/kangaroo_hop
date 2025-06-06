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
  late TimerComponent jumpParticleTimer;
  double rotation = 0;

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

    // Animate legs while running (reduce frequency at high speeds for performance)
    if (isOnGround && game.gameState == GameState.playing) {
      final time = DateTime.now().millisecondsSinceEpoch / 1000.0;

      // Reduce animation frequency at high speeds to improve performance
      final animationMultiplier = game.gameSpeed > 500 ? 0.7 : 1.0;

      legFront.angle = sin(time * 10 * animationMultiplier) * 0.3;
      legBack.angle = -sin(time * 10 * animationMultiplier) * 0.3;
      armFront.angle = 0.3 + sin(time * 8 * animationMultiplier) * 0.2;
      armBack.angle = -0.3 - sin(time * 8 * animationMultiplier) * 0.2;

      // Bob up and down slightly (reduced at high speeds)
      body.position.y = 20 + sin(time * 12 * animationMultiplier) * 2;
    }

    // Magnet effect - attract nearby coins
    if (game.isMagnetActive) {
      game.children.whereType<Coin>().forEach((coin) {
        final distance = coin.position.distanceTo(position);
        if (distance < 200) {
          final direction = (position - coin.position).normalized();
          coin.position += direction * 300 * dt;
        }
      });
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

// Always play regular jump sound for both jumps and double jumps
    AudioManager().playJump(); // Same sound for ALL jumps

    // Add jump particles
    addJumpParticles();

    // Immediately reset scale and clear all effects to prevent interference
    visualContainer.scale = Vector2.all(1.0);
    visualContainer.removeWhere((component) => component is ScaleEffect);

    // Add a small delay to ensure clean state before animation
    Future.delayed(Duration.zero, () {
      // Squash and stretch effect on visual container only
      visualContainer.add(
        ScaleEffect.to(
          Vector2(1.2, 0.8),
          EffectController(duration: 0.1),
          onComplete: () {
            visualContainer.add(
              ScaleEffect.to(
                Vector2(1.0, 1.0),
                EffectController(duration: 0.2),
              ),
            );
          },
        ),
      );
    });
  }

  void land() {
    position.y = groundY - size.y;
    verticalSpeed = 0.0;
    isOnGround = true;
    isJumping = false;
    jumpCount = 0;

    // REMOVED: AudioManager().playLand(); - No landing sound needed!

    // Landing particles
    addLandingParticles();

    // Only apply landing squash if not immediately jumping again
    // Reset scale and clear all effects first
    visualContainer.scale = Vector2.all(1.0);
    visualContainer.removeWhere((component) => component is ScaleEffect);

    // Add a small delay to check if we're still on ground (not jumping again)
    Future.delayed(const Duration(milliseconds: 16), () {
      if (isOnGround && !isJumping) {
        // Squash effect on landing - visual container only
        visualContainer.add(
          ScaleEffect.to(
            Vector2(1.3, 0.7),
            EffectController(duration: 0.1),
            onComplete: () {
              visualContainer.add(
                ScaleEffect.to(
                  Vector2(1.0, 1.0),
                  EffectController(duration: 0.15),
                ),
              );
            },
          ),
        );
      }
    });
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
        ..color = Colors.blue.withValues(alpha: 0.6)
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

    // Create sparkles around the kangaroo for double jump
    for (int i = 0; i < 8; i++) {
      final angle = (i * pi / 4);
      final radius = 45.0;
      final sparkle = CircleComponent(
        radius: 4,
        position: Vector2(
          30 + cos(angle) * radius,
          40 + sin(angle) * radius,
        ),
        paint: Paint()..color = Colors.purple.withValues(alpha: 0.9),
      );

      doubleJumpIndicator!.add(sparkle);

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

    add(doubleJumpIndicator!);
  }

  void removeDoubleJumpIndicator() {
    doubleJumpIndicator?.removeFromParent();
    doubleJumpIndicator = null;
  }

  void activateMagnetIndicator() {
    if (magnetIndicator != null) return;

    magnetIndicator = PositionComponent(position: Vector2(30, 75));

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

    add(magnetIndicator!);

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

  void removeMagnetIndicator() {
    magnetIndicator?.removeFromParent();
    magnetIndicator = null;
  }

  void addJumpParticles() {
    // Reduce particles at high speeds for better performance
    final particleCount = game.gameSpeed > 500 ? 5 : 10;

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
    game.add(
      ParticleSystemComponent(
        position: position + Vector2(size.x / 2, size.y / 2),
        particle: Particle.generate(
          count: 20,
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
    // Reduce particles at high speeds for better performance
    final particleCount = game.gameSpeed > 500 ? 7 : 15;

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
      // REMOVED: AudioManager().playCollision(); - Game over sound plays instead!
      game.onObstacleCollision();
      return true;
    } else if (other is Coin) {
      // AudioManager().playCoinCollect(gameSpeed: game.gameSpeed);
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
