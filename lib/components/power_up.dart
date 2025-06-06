import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

import '../game/kangaroo_game.dart';

enum PowerUpType { doubleJump, shield, magnet }

class PowerUp extends PositionComponent with HasGameReference<KangarooGame>, HasPaint {
  double gameSpeed = 250.0;
  final PowerUpType type;
  bool isCollected = false;
  
  PowerUp({required this.type}) : super(size: Vector2(40, 40));
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Create power-up visual based on type
    switch (type) {
      case PowerUpType.doubleJump:
        _createDoubleJump();
        break;
      case PowerUpType.shield:
        _createShield();
        break;
      case PowerUpType.magnet:
        _createMagnet();
        break;
    }
    
    // Add collision detection
    add(CircleHitbox(radius: 20));
    
    // Add floating animation
    add(
      MoveEffect.by(
        Vector2(0, -10),
        EffectController(
          duration: 1.5,
          reverseDuration: 1.5,
          infinite: true,
        ),
      ),
    );
    
    // Add glow effect
    add(
      ScaleEffect.to(
        Vector2.all(1.1),
        EffectController(
          duration: 0.8,
          reverseDuration: 0.8,
          infinite: true,
        ),
      ),
    );
  }
  
  void _createDoubleJump() {
    // Enhanced background with glow effect
    add(CircleComponent(
      radius: 22,
      paint: Paint()..color = Colors.purple.withValues(alpha: 0.3),
    ));
    add(CircleComponent(
      radius: 18,
      paint: Paint()..color = Colors.purple.withValues(alpha: 0.7),
    ));
    
    // Enhanced jump arrows with better visibility
    add(TextComponent(
      text: '⬆⬆',
      position: Vector2(20, 20),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.purple,
              offset: Offset(0, 0),
              blurRadius: 8,
            ),
          ],
        ),
      ),
    ));
    
    // Add sparkle effects around the power-up
    for (int i = 0; i < 6; i++) {
      final angle = (i * pi / 3);
      add(CircleComponent(
        radius: 3,
        position: Vector2(
          20 + cos(angle) * 25,
          20 + sin(angle) * 25,
        ),
        paint: Paint()..color = Colors.white.withValues(alpha: 0.8),
      ));
    }
  }
  
  void _createShield() {
    // Shield shape
    final vertices = [
      Vector2(20, 5),
      Vector2(35, 15),
      Vector2(35, 30),
      Vector2(20, 38),
      Vector2(5, 30),
      Vector2(5, 15),
    ];
    
    add(PolygonComponent(
      vertices,
      paint: Paint()..color = Colors.blue,
    ));
    
    // Shield emblem
    add(CircleComponent(
      radius: 8,
      position: Vector2(20, 20),
      paint: Paint()..color = Colors.lightBlue,
    ));
  }
  
  void _createMagnet() {
    // Enhanced background glow
    add(CircleComponent(
      radius: 22,
      paint: Paint()..color = Colors.red.withValues(alpha: 0.3),
    ));
    
    // Magnet shape (horseshoe) with better colors
    add(RectangleComponent(
      size: Vector2(12, 22),
      position: Vector2(8, 9),
      paint: Paint()..color = Colors.red.shade700,
    ));
    
    add(RectangleComponent(
      size: Vector2(12, 22),
      position: Vector2(20, 9),
      paint: Paint()..color = Colors.blue.shade700,
    ));
    
    add(RectangleComponent(
      size: Vector2(24, 10),
      position: Vector2(8, 9),
      paint: Paint()..color = Colors.grey.shade600,
    ));
    
    // Enhanced magnetic field lines with pulsing effect
    for (int i = 0; i < 4; i++) {
      final fieldLine = CircleComponent(
        radius: 12 + i * 4,
        position: Vector2(20, 20),
        paint: Paint()
          ..color = Colors.cyan.withValues(alpha: 0.6 - i * 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      add(fieldLine);
      
      // Add pulsing animation to field lines
      fieldLine.add(
        ScaleEffect.to(
          Vector2.all(1.2),
          EffectController(
            duration: 1.0 + i * 0.2,
            reverseDuration: 1.0 + i * 0.2,
            infinite: true,
          ),
        ),
      );
    }
    
    // Add attraction symbols
    add(TextComponent(
      text: '🪙',
      position: Vector2(12, 32),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 12,
        ),
      ),
    ));
    
    add(TextComponent(
      text: '🪙',
      position: Vector2(28, 32),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 12,
        ),
      ),
    ));
  }
  
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (!isCollected) {
      // Move with game speed
      position.x -= gameSpeed * dt;
      
      // Remove when off screen
      if (position.x + size.x < -50) {
        removeFromParent();
      }
    }
  }
  
  void collect() {
    if (isCollected) return;
    isCollected = true;
    
    // Collection animation
    add(
      ScaleEffect.to(
        Vector2.all(2),
        EffectController(duration: 0.3),
        onComplete: () {
          add(
            OpacityEffect.to(
              0,
              EffectController(duration: 0.2),
              onComplete: () => removeFromParent(),
            ),
          );
        },
      ),
    );
    
    // Add particle burst
    final particleColors = {
      PowerUpType.doubleJump: Colors.purple,
      PowerUpType.shield: Colors.blue,
      PowerUpType.magnet: Colors.red,
    };
    
    game.add(
      ParticleSystemComponent(
        position: position + size / 2,
        particle: Particle.generate(
          count: 20,
          generator: (i) => AcceleratedParticle(
            acceleration: Vector2(0, 100),
            speed: Vector2(
              game.random.nextDouble() * 200 - 100,
              -game.random.nextDouble() * 200,
            ),
            position: Vector2.zero(),
            child: CircleParticle(
              radius: 4,
              paint: Paint()..color = particleColors[type]!.withValues(alpha: 0.8),
            ),
          ),
        ),
      ),
    );
  }
}