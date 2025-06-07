
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
    
    // Use the new image assets (without words for floating power-ups)
    String imagePath;
    switch (type) {
      case PowerUpType.doubleJump:
        imagePath = 'double.png';
        break;
      case PowerUpType.shield:
        imagePath = 'shield.png';
        break;
      case PowerUpType.magnet:
        imagePath = 'magnet.png';
        break;
    }

    final sprite = await Sprite.load(imagePath);
    final spriteComponent = SpriteComponent(
      sprite: sprite,
      size: size,
      anchor: Anchor.center,
      position: size / 2,
    );
    add(spriteComponent);

    // Add horizontal spinning animation (like a spinning top)
    spriteComponent.add(
      ScaleEffect.to(
        Vector2(-1, 1), // Flip horizontally
        EffectController(
          duration: 1.5, // Slightly faster than store for more dynamic feel
          reverseDuration: 1.5,
          infinite: true,
          curve: Curves.easeInOut, // Smooth acceleration/deceleration
        ),
      ),
    );
    
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
  
  // These methods are no longer needed since we're using sprite images
  // But keeping them as comments for reference
  
  /*
  void _createDoubleJump() { ... }
  void _createShield() { ... }
  void _createMagnet() { ... }
  */
  
  
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