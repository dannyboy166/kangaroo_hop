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
    
    // Slightly larger size for more valuable coins
    size = Vector2(40, 40);
    
    // Outer glow effect
    add(CircleComponent(
      radius: 22,
      paint: Paint()..color = const Color(0xFFFFD700).withValues(alpha: 0.3),
    ));
    
    // Outer circle
    add(CircleComponent(
      radius: 20,
      paint: Paint()..color = const Color(0xFFFFD700),
    ));
    
    // Inner circle
    add(CircleComponent(
      radius: 16,
      position: Vector2(4, 4),
      paint: Paint()..color = const Color(0xFFFFA500),
    ));
    
    // Dollar sign (bigger)
    add(TextComponent(
      text: '\$',
      position: Vector2(20, 20),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF8B4513),
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    ));
    
    // Number 5 to show value
    add(TextComponent(
      text: '5',
      position: Vector2(20, 35),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black,
              offset: Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
    ));
    
    // Add collision detection
    add(CircleHitbox(radius: 20));
    
    // Add rotation animation (slower for less CPU usage)
    add(
      RotateEffect.by(
        2 * 3.14159,
        EffectController(
          duration: 3, // Slower rotation
          infinite: true,
        ),
      ),
    );
    
    // Add floating animation
    add(
      MoveEffect.by(
        Vector2(0, -8),
        EffectController(
          duration: 1.5,
          reverseDuration: 1.5,
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