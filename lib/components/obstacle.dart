
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/kangaroo_game.dart';

enum ObstacleType { rock, cactus, log, croc }

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
        size = Vector2(60, 100); // Made bigger (was 40x80)
        break;
      case ObstacleType.log:
        size = Vector2(80, 40);
        break;
      case ObstacleType.croc:
        size = Vector2(120, 60); // Made bigger (was 100x50)
        break;
    }
  }
  Future<void> _createCroc() async {
    // Load and add the crocodile image sprite
    final crocSprite = await game.loadSprite('croc.png');
    
    add(SpriteComponent(
      sprite: crocSprite,
      size: size, // Use the obstacle's size (120x60)
      position: Vector2.zero(), // Position relative to obstacle
    ));
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
        await _createCactus();
        break;
      case ObstacleType.log:
        _createLog();
        break;
      case ObstacleType.croc:
        await _createCroc();
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
  
  Future<void> _createCactus() async {
    // Load and add the cactus image sprite
    final cactusSprite = await game.loadSprite('cactus.png');
    
    add(SpriteComponent(
      sprite: cactusSprite,
      size: size, // Use the obstacle's size (60x100)
      position: Vector2.zero(), // Position relative to obstacle
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
  
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Move obstacle left
    position.x -= gameSpeed * dt;
    
    
    // Remove when off screen
    if (position.x + size.x < -50) {
      removeFromParent();
    }
  }
}