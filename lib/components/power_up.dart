import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

import '../game/kangaroo_game.dart';

enum PowerUpType { doubleJump, shield, magnet, speed }

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
      case PowerUpType.speed:
        _createSpeed();
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
    // Background circle
    add(CircleComponent(
      radius: 20,
      paint: Paint()..color = Colors.purple.withOpacity(0.8),
    ));
    
    // Jump arrows
    add(TextComponent(
      text: '⬆⬆',
      position: Vector2(20, 20),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    ));
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
    // Magnet shape (horseshoe)
    add(RectangleComponent(
      size: Vector2(10, 20),
      position: Vector2(10, 10),
      paint: Paint()..color = Colors.red,
    ));
    
    add(RectangleComponent(
      size: Vector2(10, 20),
      position: Vector2(20, 10),
      paint: Paint()..color = Colors.blue,
    ));
    
    add(RectangleComponent(
      size: Vector2(20, 8),
      position: Vector2(10, 10),
      paint: Paint()..color = Colors.grey,
    ));
    
    // Magnetic field lines
    for (int i = 0; i < 3; i++) {
      add(CircleComponent(
        radius: 15 + i * 5,
        position: Vector2(20, 20),
        paint: Paint()
          ..color = Colors.white.withOpacity(0.3 - i * 0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      ));
    }
  }
  
  void _createSpeed() {
    // Lightning bolt background
    add(CircleComponent(
      radius: 20,
      paint: Paint()..color = Colors.yellow.withOpacity(0.8),
    ));
    
    // Lightning bolt
    final vertices = [
      Vector2(15, 10),
      Vector2(20, 18),
      Vector2(18, 18),
      Vector2(25, 30),
      Vector2(20, 22),
      Vector2(22, 22),
    ];
    
    add(PolygonComponent(
      vertices,
      paint: Paint()..color = Colors.orange,
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
      PowerUpType.speed: Colors.yellow,
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
              paint: Paint()..color = particleColors[type]!.withOpacity(0.8),
            ),
          ),
        ),
      ),
    );
  }
}