import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/kangaroo_game.dart';

class Ground extends Component with HasGameReference<KangarooGame> {
  double gameSpeed = 250.0;
  late List<GroundSegment> segments;
  static const double groundY = 400.0;
  static const double groundHeight = 200.0;
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    segments = [];
    
    // Create multiple ground segments for seamless scrolling
    for (int i = 0; i < 3; i++) {
      final segment = GroundSegment(
        position: Vector2(i * 800.0, groundY),
        size: Vector2(800, groundHeight),
      );
      segments.add(segment);
      add(segment);
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Move and wrap ground segments
    for (final segment in segments) {
      segment.position.x -= gameSpeed * dt;
      
      // Wrap around when off screen
      if (segment.position.x + segment.size.x < 0) {
        // Find the rightmost segment
        double maxX = -double.infinity;
        for (final s in segments) {
          if (s.position.x > maxX) {
            maxX = s.position.x;
          }
        }
        segment.position.x = maxX + segment.size.x;
      }
    }
  }
}

class GroundSegment extends PositionComponent {
  final Random random = Random();
  
  GroundSegment({
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size);
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Base ground
    add(RectangleComponent(
      size: size,
      paint: Paint()..color = const Color(0xFFD2691E),
    ));
    
    // Add texture details
    // Dirt patches
    for (int i = 0; i < 8; i++) {
      add(CircleComponent(
        radius: random.nextDouble() * 20 + 10,
        position: Vector2(
          random.nextDouble() * size.x,
          random.nextDouble() * 40,
        ),
        paint: Paint()..color = const Color(0xFFCD853F).withOpacity(0.5),
      ));
    }
    
    // Small rocks
    for (int i = 0; i < 12; i++) {
      add(CircleComponent(
        radius: random.nextDouble() * 5 + 2,
        position: Vector2(
          random.nextDouble() * size.x,
          random.nextDouble() * 30,
        ),
        paint: Paint()..color = const Color(0xFF8B7355),
      ));
    }
    
    // Grass tufts
    for (int i = 0; i < 15; i++) {
      final x = random.nextDouble() * size.x;
      final y = random.nextDouble() * 20;
      
      // Create grass blades
      for (int j = 0; j < 3; j++) {
        add(RectangleComponent(
          size: Vector2(2, 10 + random.nextDouble() * 5),
          position: Vector2(x + j * 3, y),
          paint: Paint()..color = const Color(0xFF556B2F),
          angle: (random.nextDouble() - 0.5) * 0.3,
        ));
      }
    }
    
    // Ground lines for texture
    for (int i = 0; i < 5; i++) {
      add(RectangleComponent(
        size: Vector2(random.nextDouble() * 100 + 50, 2),
        position: Vector2(
          random.nextDouble() * size.x,
          random.nextDouble() * 50,
        ),
        paint: Paint()..color = const Color(0xFFBC9A6A).withOpacity(0.3),
      ));
    }
  }
}