
import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../game/kangaroo_game.dart';

enum ObstacleType { rock, cactus, log, croc, emu }

class Obstacle extends PositionComponent with HasGameReference<KangarooGame>, CollisionCallbacks {
  double gameSpeed = 250.0;
  static const double groundY = 400.0;
  final ObstacleType type;
  
  Obstacle({required this.type}) : super() {
    final random = Random();
    
    // Set base size and apply random scaling based on type
    switch (type) {
      case ObstacleType.rock:
        // Base: 75x90, Scale: 40%-120%
        final scale = 0.4 + random.nextDouble() * 0.8; // 0.4 to 1.2
        size = Vector2(75 * scale, 90 * scale);
        break;
      case ObstacleType.cactus:
        // Base: 60x100, Scale: 80%-105%
        final scale = 0.8 + random.nextDouble() * 0.25; // 0.8 to 1.05
        size = Vector2(60 * scale, 100 * scale);
        break;
      case ObstacleType.log:
        // Base: 136x68, Scale: 70%-110%
        final scale = 0.7 + random.nextDouble() * 0.4; // 0.7 to 1.1
        size = Vector2(136 * scale, 68 * scale);
        break;
      case ObstacleType.croc:
        // Base: 144x72, Scale: 80%-100%
        final scale = 0.8 + random.nextDouble() * 0.2; // 0.8 to 1.0
        size = Vector2(144 * scale, 72 * scale);
        break;
      case ObstacleType.emu:
        // Base: 72x108, Scale: 80%-100%
        final scale = 0.8 + random.nextDouble() * 0.2; // 0.8 to 1.0
        size = Vector2(72 * scale, 108 * scale);
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

  Future<void> _createEmu() async {
    // Load and add the emu image sprite
    final emuSprite = await game.loadSprite('emu.png');
    
    add(SpriteComponent(
      sprite: emuSprite,
      size: size, // Use the obstacle's size (80x120)
      position: Vector2.zero(), // Position relative to obstacle
    ));
  }
  
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Start position off screen
    if (type == ObstacleType.croc) {
      position = Vector2(game.size.x + 100, groundY - size.y + 15);
    } else if (type == ObstacleType.log) {
      position = Vector2(game.size.x + 100, groundY - size.y + 10);
    } else {
      position = Vector2(game.size.x + 100, groundY - size.y);
    }
    
    // Create obstacle based on type
    switch (type) {
      case ObstacleType.rock:
        await _createRock();
        break;
      case ObstacleType.cactus:
        await _createCactus();
        break;
      case ObstacleType.log:
        await _createLog();
        break;
      case ObstacleType.croc:
        await _createCroc();
        break;
      case ObstacleType.emu:
        await _createEmu();
        break;
    }
    
    // Add collision detection
    add(RectangleHitbox(size: size * 0.8, position: size * 0.1));
  }
  
  Future<void> _createRock() async {
    // Load and add the rock image sprite
    final rockSprite = await game.loadSprite('rock.png');
    
    add(SpriteComponent(
      sprite: rockSprite,
      size: size, // Use the obstacle's size (50x60)
      position: Vector2.zero(), // Position relative to obstacle
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
  
  Future<void> _createLog() async {
    // Load and add the log image sprite
    final logSprite = await game.loadSprite('log.png');
    
    add(SpriteComponent(
      sprite: logSprite,
      size: size, // Use the obstacle's size (80x40)
      position: Vector2.zero(), // Position relative to obstacle
    ));
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