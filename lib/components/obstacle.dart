import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/kangaroo_game.dart';

enum ObstacleType { rock, cactus, log, bird }

class Obstacle extends PositionComponent with HasGameReference<KangarooGame>, CollisionCallbacks {
  double gameSpeed = 250.0;
  static const double groundY = 400.0;
  final ObstacleType type;
  
  Obstacle({required this.type}) : super() {
    // Set size based on type
    switch (type) {
      case ObstacleType.rock:
        size = Vector2(50, 60);
        break;
      case ObstacleType.cactus:
        size = Vector2(40, 80);
        break;
      case ObstacleType.log:
        size = Vector2(80, 40);
        break;
      case ObstacleType.bird:
        size = Vector2(60, 40);
        break;
    }
  }
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Start position off screen
    position = Vector2(game.size.x + 100, groundY - size.y);
    
    // Create obstacle based on type
    switch (type) {
      case ObstacleType.rock:
        _createRock();
        break;
      case ObstacleType.cactus:
        _createCactus();
        break;
      case ObstacleType.log:
        _createLog();
        break;
      case ObstacleType.bird:
        _createBird();
        position.y = groundY - size.y - 100 - game.random.nextDouble() * 100;
        break;
    }
    
    // Add collision detection
    add(RectangleHitbox(size: size * 0.8, position: size * 0.1));
  }
  
  void _createRock() {
    // Main rock body vertices
    final vertices = [
      Vector2(10, size.y),
      Vector2(0, size.y * 0.6),
      Vector2(5, size.y * 0.3),
      Vector2(size.x * 0.3, 0),
      Vector2(size.x * 0.7, size.y * 0.1),
      Vector2(size.x * 0.9, size.y * 0.4),
      Vector2(size.x, size.y * 0.7),
      Vector2(size.x - 5, size.y),
    ];
    
    // Shadow layer (bottom-right)
    final shadowVertices = vertices.map((v) => v + Vector2(3, 3)).toList();
    add(PolygonComponent(
      shadowVertices,
      paint: Paint()..color = Colors.black.withValues(alpha: 0.5),
    ));
    
    // Main rock body
    add(PolygonComponent(
      vertices,
      paint: Paint()..color = const Color(0xFF696969),
    ));
    
    // Highlight layer (top-left)
    final highlightVertices = vertices.map((v) => v + Vector2(-1, -1)).toList();
    add(PolygonComponent(
      highlightVertices,
      paint: Paint()..color = const Color(0xFF909090).withValues(alpha: 0.7),
    ));
    
    // Add some texture
    add(CircleComponent(
      radius: 8,
      position: Vector2(size.x * 0.3, size.y * 0.5),
      paint: Paint()..color = const Color(0xFF808080),
    ));
    
    add(CircleComponent(
      radius: 5,
      position: Vector2(size.x * 0.7, size.y * 0.6),
      paint: Paint()..color = const Color(0xFF505050),
    ));
  }
  
  void _createCactus() {
    // Shadow for main trunk
    add(RectangleComponent(
      size: Vector2(20, 60),
      position: Vector2(13, 23),
      paint: Paint()..color = Colors.black.withValues(alpha: 0.5),
    ));
    
    // Main trunk
    add(RectangleComponent(
      size: Vector2(20, 60),
      position: Vector2(10, 20),
      paint: Paint()..color = const Color(0xFF1F5F3F),
    ));
    
    // Highlight for main trunk
    add(RectangleComponent(
      size: Vector2(20, 60),
      position: Vector2(9, 19),
      paint: Paint()..color = const Color(0xFF2E8B57).withValues(alpha: 0.6),
    ));
    
    // Arms
    add(RectangleComponent(
      size: Vector2(15, 30),
      position: Vector2(-5, 30),
      paint: Paint()..color = const Color(0xFF228B22),
    ));
    
    add(RectangleComponent(
      size: Vector2(15, 25),
      position: Vector2(25, 35),
      paint: Paint()..color = const Color(0xFF228B22),
    ));
    
    // Spikes
    for (int i = 0; i < 8; i++) {
      add(RectangleComponent(
        size: Vector2(2, 6),
        position: Vector2(
          game.random.nextDouble() * 30 + 5,
          game.random.nextDouble() * 50 + 20,
        ),
        paint: Paint()..color = const Color(0xFF3C5030),
        angle: game.random.nextDouble() * pi,
      ));
    }
    
    // Flower on top
    add(CircleComponent(
      radius: 6,
      position: Vector2(20, 15),
      paint: Paint()..color = Colors.pink,
    ));
  }
  
  void _createLog() {
    // Shadow for log body
    add(RectangleComponent(
      size: Vector2(size.x, size.y),
      position: Vector2(3, 3),
      paint: Paint()..color = Colors.black.withValues(alpha: 0.5),
    ));
    
    // Main log body
    add(RectangleComponent(
      size: Vector2(size.x, size.y),
      paint: Paint()..color = const Color(0xFF8B4513),
    ));
    
    // Highlight for log body
    add(RectangleComponent(
      size: Vector2(size.x, size.y),
      position: Vector2(-1, -1),
      paint: Paint()..color = const Color(0xFFCD853F).withValues(alpha: 0.6),
    ));
    
    // Wood rings
    add(CircleComponent(
      radius: 15,
      position: Vector2(20, size.y / 2),
      paint: Paint()
        ..color = const Color(0xFF654321)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    ));
    
    add(CircleComponent(
      radius: 10,
      position: Vector2(20, size.y / 2),
      paint: Paint()
        ..color = const Color(0xFF654321)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    ));
    
    // Bark texture
    for (int i = 0; i < 5; i++) {
      add(RectangleComponent(
        size: Vector2(3, size.y * 0.8),
        position: Vector2(i * 15 + 10, size.y * 0.1),
        paint: Paint()..color = const Color(0xFF654321),
      ));
    }
  }
  
  void _createBird() {
    // Shadow for body
    add(CircleComponent(
      radius: 15,
      position: Vector2(33, 23),
      paint: Paint()..color = Colors.black.withValues(alpha: 0.5),
    ));
    
    // Body
    add(CircleComponent(
      radius: 15,
      position: Vector2(30, 20),
      paint: Paint()..color = const Color(0xFF8B008B),
    ));
    
    // Highlight for body
    add(CircleComponent(
      radius: 15,
      position: Vector2(29, 19),
      paint: Paint()..color = const Color(0xFFDA70D6).withValues(alpha: 0.6),
    ));
    
    // Head
    add(CircleComponent(
      radius: 10,
      position: Vector2(45, 18),
      paint: Paint()..color = const Color(0xFF9932CC),
    ));
    
    // Beak
    final beakVertices = [
      Vector2(55, 18),
      Vector2(65, 20),
      Vector2(55, 22),
    ];
    add(PolygonComponent(
      beakVertices,
      paint: Paint()..color = Colors.orange,
    ));
    
    // Eye
    add(CircleComponent(
      radius: 3,
      position: Vector2(48, 16),
      paint: Paint()..color = Colors.white,
    ));
    add(CircleComponent(
      radius: 2,
      position: Vector2(49, 16),
      paint: Paint()..color = Colors.black,
    ));
    
    // Wings
    final wingVertices = [
      Vector2(15, 15),
      Vector2(5, 20),
      Vector2(10, 30),
      Vector2(25, 25),
    ];
    add(PolygonComponent(
      wingVertices,
      paint: Paint()..color = const Color(0xFF8B008B).withValues(alpha: 0.8),
    ));
    
    // Note: Bird movement handled in update() method to sync with collision
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Move obstacle left
    position.x -= gameSpeed * dt;
    
    // Special movement for bird
    if (type == ObstacleType.bird) {
      final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
      position.y += sin(time * 3) * 30 * dt;
    }
    
    // Remove when off screen
    if (position.x + size.x < -50) {
      removeFromParent();
    }
  }
}