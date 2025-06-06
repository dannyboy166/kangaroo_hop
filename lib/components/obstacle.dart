import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/kangaroo_game.dart';

class Obstacle extends RectangleComponent with HasGameReference<KangarooGame> {
  double gameSpeed = 200.0;
  static const double groundY = 400.0;
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    size = Vector2(30, 80);
    position = Vector2(800, groundY - size.y); // Start off-screen to the right
    paint = Paint()..color = const Color(0xFF8B4513); // Saddle brown for rocks/obstacles
    
    // Add collision detection
    add(RectangleHitbox());
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Move obstacle left
    position.x -= gameSpeed * dt;
    
    // Remove obstacle when it goes off screen
    if (position.x + size.x < 0) {
      removeFromParent();
    }
  }
}