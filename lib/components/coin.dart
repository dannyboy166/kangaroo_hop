import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../game/kangaroo_game.dart';

class Coin extends PositionComponent with HasGameReference<KangarooGame>, HasPaint {
  double gameSpeed = 250.0;
  bool isCollected = false;
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    size = Vector2(30, 30);
    
    // Outer circle
    add(CircleComponent(
      radius: 15,
      paint: Paint()..color = const Color(0xFFFFD700),
    ));
    
    // Inner circle
    add(CircleComponent(
      radius: 12,
      position: Vector2(3, 3),
      paint: Paint()..color = const Color(0xFFFFA500),
    ));
    
    // Dollar sign
    add(TextComponent(
      text: '\$',
      position: Vector2(15, 15),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF8B4513),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    ));
    
    // Add collision detection
    add(CircleHitbox(radius: 15));
    
    // Add rotation animation
    add(
      RotateEffect.by(
        2 * 3.14159,
        EffectController(
          duration: 2,
          infinite: true,
        ),
      ),
    );
    
    // Add floating animation
    add(
      MoveEffect.by(
        Vector2(0, -5),
        EffectController(
          duration: 1,
          reverseDuration: 1,
          infinite: true,
        ),
      ),
    );
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
        Vector2.all(1.5),
        EffectController(duration: 0.2),
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
  }
}