import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/kangaroo_game.dart';

enum ObstacleType { rock, cactus, log, croc, emu, camel }

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
      case ObstacleType.camel:
        // Base: 120x140, Scale: 80%-100%
        final scale = 0.8 + random.nextDouble() * 0.2; // 0.8 to 1.0
        size = Vector2(120 * scale, 140 * scale);
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
    // Load the emu sprite sheet for animation
    final emuSpriteSheet = await game.images.load('emu_sheet.png');
    
    // Create running animation with 4 frames (512x128 = 4 frames of 128x128)
    final emuRunningAnimation = SpriteAnimation.fromFrameData(
      emuSpriteSheet,
      SpriteAnimationData([
        // Frame 1
        SpriteAnimationFrameData(
          srcPosition: Vector2(0, 0),
          srcSize: Vector2(128, 128),
          stepTime: 0.12, // Slightly slower than kangaroo for variety
        ),
        // Frame 2
        SpriteAnimationFrameData(
          srcPosition: Vector2(128, 0),
          srcSize: Vector2(128, 128),
          stepTime: 0.12,
        ),
        // Frame 3
        SpriteAnimationFrameData(
          srcPosition: Vector2(256, 0),
          srcSize: Vector2(128, 128),
          stepTime: 0.12,
        ),
        // Frame 4
        SpriteAnimationFrameData(
          srcPosition: Vector2(384, 0),
          srcSize: Vector2(128, 128),
          stepTime: 0.12,
        ),
      ]),
    );
    
    // Add the animated emu sprite
    add(SpriteAnimationComponent(
      animation: emuRunningAnimation,
      size: size, // Use the obstacle's size
      position: Vector2.zero(), // Position relative to obstacle
    ));
  }

  Future<void> _createCamel() async {
    // Load and add the camel image sprite
    final camelSprite = await game.loadSprite('camel.png');
    
    add(SpriteComponent(
      sprite: camelSprite,
      size: size, // Use the obstacle's size (120x140)
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
    } else if (type == ObstacleType.camel) {
      position = Vector2(game.size.x + 100, groundY - size.y + 5);
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
        await _createEmu(); // Now uses animated sprite!
        break;
      case ObstacleType.camel:
        await _createCamel();
        break;
    }
    
    // Add collision detection with custom sizes per obstacle type
    Vector2 hitboxSize;
    Vector2 hitboxPosition;
    
    switch (type) {
      case ObstacleType.cactus:
        // Cactus: less wide (60% width, 80% height)
        hitboxSize = Vector2(size.x * 0.6, size.y * 0.8);
        hitboxPosition = Vector2(size.x * 0.2, size.y * 0.1);
        break;
      case ObstacleType.log:
        // Log: less high (80% width, 60% height)
        hitboxSize = Vector2(size.x * 0.8, size.y * 0.6);
        hitboxPosition = Vector2(size.x * 0.1, size.y * 0.2);
        break;
      case ObstacleType.rock:
        // Rock: slightly less wide (70% width, 80% height)
        hitboxSize = Vector2(size.x * 0.7, size.y * 0.8);
        hitboxPosition = Vector2(size.x * 0.15, size.y * 0.1);
        break;
      default:
        // Other obstacles: normal size (80% of original size)
        hitboxSize = size * 0.8;
        hitboxPosition = size * 0.1;
        break;
    }
    
    add(RectangleHitbox(size: hitboxSize, position: hitboxPosition));
    
    // Debug: Add visual collision box (remove this in production)
    add(RectangleComponent(
      size: hitboxSize,
      position: hitboxPosition,
      paint: Paint()
        ..color = Colors.red.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    ));
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