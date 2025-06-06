import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/kangaroo_game.dart';

class Background extends Component with HasGameReference<KangarooGame> {
  double gameSpeed = 200.0;
  late RectangleComponent sky;
  late RectangleComponent mountains1;
  late RectangleComponent mountains2;
  double mountainOffset1 = 0;
  double mountainOffset2 = 400;
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Sky background
    sky = RectangleComponent(
      size: Vector2(800, 600),
      paint: Paint()..color = const Color(0xFF87CEEB), // Sky blue
    );
    add(sky);
    
    // Create mountain layers for parallax effect
    mountains1 = RectangleComponent(
      size: Vector2(800, 150),
      position: Vector2(0, 300),
      paint: Paint()..color = const Color(0xFF8FBC8F), // Dark sea green
    );
    add(mountains1);
    
    mountains2 = RectangleComponent(
      size: Vector2(800, 150),
      position: Vector2(400, 300),
      paint: Paint()..color = const Color(0xFF8FBC8F), // Dark sea green
    );
    add(mountains2);
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Move mountains for parallax effect (slower than foreground)
    mountainOffset1 -= gameSpeed * 0.3 * dt;
    mountainOffset2 -= gameSpeed * 0.3 * dt;
    
    mountains1.position.x = mountainOffset1;
    mountains2.position.x = mountainOffset2;
    
    // Reset mountain positions when they go off screen
    if (mountainOffset1 <= -800) {
      mountainOffset1 = 800;
    }
    if (mountainOffset2 <= -800) {
      mountainOffset2 = 800;
    }
  }
}