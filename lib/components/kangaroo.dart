import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/kangaroo_game.dart';
import 'obstacle.dart';

class Kangaroo extends RectangleComponent with HasGameReference<KangarooGame>, CollisionCallbacks {
  static const double jumpSpeed = -400.0;
  static const double gravity = 980.0;
  static const double groundY = 400.0;
  
  double verticalSpeed = 0.0;
  bool isOnGround = true;
  bool isJumping = false;
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    size = Vector2(40, 60);
    position = Vector2(100, groundY - size.y);
    paint = Paint()..color = const Color(0xFFD2691E); // Australian red-brown
    
    // Add collision detection
    add(RectangleHitbox());
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Apply gravity
    if (!isOnGround || isJumping) {
      verticalSpeed += gravity * dt;
      position.y += verticalSpeed * dt;
      
      // Check if landed
      if (position.y >= groundY - size.y) {
        position.y = groundY - size.y;
        verticalSpeed = 0.0;
        isOnGround = true;
        isJumping = false;
      }
    }
  }
  
  void jump() {
    if (isOnGround && game.gameState == GameState.playing) {
      verticalSpeed = jumpSpeed;
      isOnGround = false;
      isJumping = true;
    }
  }
  
  void reset() {
    position.y = groundY - size.y;
    verticalSpeed = 0.0;
    isOnGround = true;
    isJumping = false;
  }
  
  @override
  bool onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Obstacle) {
      game.onObstacleCollision();
      return true;
    }
    return false;
  }
}