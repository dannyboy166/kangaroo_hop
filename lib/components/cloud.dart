import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../game/kangaroo_game.dart';

class Cloud extends PositionComponent with HasGameReference<KangarooGame> {
  double gameSpeed = 250.0;
  final double speedMultiplier;
  
  Cloud() : speedMultiplier = 0.1 + Random().nextDouble() * 0.2, super();
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    final random = Random();
    
    // Random cloud size
    size = Vector2(
      80 + random.nextDouble() * 60,
      40 + random.nextDouble() * 20,
    );
    
    // Random starting position
    position = Vector2(
      game.size.x + size.x,
      50 + random.nextDouble() * 150,
    );
    
    // Create cloud shape with multiple circles
    final numCircles = 3 + random.nextInt(3);
    for (int i = 0; i < numCircles; i++) {
      final radius = 15 + random.nextDouble() * 15;
      final xOffset = random.nextDouble() * (size.x - radius * 2) + radius;
      final yOffset = random.nextDouble() * 10;
      
      add(CircleComponent(
        radius: radius,
        position: Vector2(xOffset, yOffset + radius),
        paint: Paint()..color = Colors.white.withOpacity(0.8),
      ));
    }
    
    // Add subtle animation
    add(
      MoveEffect.by(
        Vector2(0, 5),
        EffectController(
          duration: 3 + random.nextDouble() * 2,
          reverseDuration: 3 + random.nextDouble() * 2,
          infinite: true,
        ),
      ),
    );
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Move cloud with parallax effect
    position.x -= gameSpeed * speedMultiplier * dt;
    
    // Remove when off screen
    if (position.x + size.x < -100) {
      removeFromParent();
    }
  }
}