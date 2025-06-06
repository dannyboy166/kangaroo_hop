import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/kangaroo_game.dart';

class Ground extends Component with HasGameReference<KangarooGame> {
  double gameSpeed = 200.0;
  late RectangleComponent ground1;
  late RectangleComponent ground2;
  double groundOffset1 = 0;
  double groundOffset2 = 800;
  static const double groundY = 400.0;
  static const double groundHeight = 200.0;
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Create two ground segments for seamless scrolling
    ground1 = RectangleComponent(
      size: Vector2(800, groundHeight),
      position: Vector2(0, groundY),
      paint: Paint()..color = const Color(0xFFD2691E), // Australian red dirt
    );
    add(ground1);
    
    ground2 = RectangleComponent(
      size: Vector2(800, groundHeight),
      position: Vector2(800, groundY),
      paint: Paint()..color = const Color(0xFFD2691E), // Australian red dirt
    );
    add(ground2);
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Move ground segments
    groundOffset1 -= gameSpeed * dt;
    groundOffset2 -= gameSpeed * dt;
    
    ground1.position.x = groundOffset1;
    ground2.position.x = groundOffset2;
    
    // Reset ground positions when they go off screen
    if (groundOffset1 <= -800) {
      groundOffset1 = 800;
    }
    if (groundOffset2 <= -800) {
      groundOffset2 = 800;
    }
  }
}