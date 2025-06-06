import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/kangaroo_game.dart';

class Background extends Component with HasGameReference<KangarooGame> {
  double gameSpeed = 250.0;
  
  late RectangleComponent sky;
  late List<Mountain> mountains;
  late List<Tree> trees;
  late RectangleComponent sun;
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Sky gradient background (handled by game backgroundColor)
    
    // Add sun
    sun = RectangleComponent(
      size: Vector2(60, 60),
      position: Vector2(game.size.x - 100, 50),
      paint: Paint()..color = const Color(0xFFFFD700),
    );
    
    // Add sun rays as children of the sun so they rotate together
    for (int i = 0; i < 8; i++) {
      final angle = (i * pi / 4);
      final ray = RectangleComponent(
        size: Vector2(80, 3),
        position: Vector2(30, 30), // Relative to sun center
        anchor: Anchor.centerLeft,
        angle: angle,
        paint: Paint()..color = const Color(0xFFFFD700).withValues(alpha: 0.5),
      );
      sun.add(ray); // Add rays as children of sun
    }
    
    add(sun);
    
    // Create parallax mountain layers
    mountains = [];
    
    // Far mountains (move slowest)
    for (int i = 0; i < 3; i++) {
      mountains.add(
        Mountain(
          position: Vector2(i * 600.0, 200),
          size: Vector2(600, 250),
          color: const Color(0xFF9370DB).withValues(alpha: 0.5),
          speed: 0.1,
        ),
      );
      add(mountains.last);
    }
    
    // Mid mountains
    for (int i = 0; i < 3; i++) {
      mountains.add(
        Mountain(
          position: Vector2(i * 500.0, 250),
          size: Vector2(500, 200),
          color: const Color(0xFF8B7D6B).withValues(alpha: 0.7),
          speed: 0.3,
        ),
      );
      add(mountains.last);
    }
    
    // Near hills
    for (int i = 0; i < 4; i++) {
      mountains.add(
        Mountain(
          position: Vector2(i * 400.0, 320),
          size: Vector2(400, 120),
          color: const Color(0xFF8FBC8F),
          speed: 0.5,
        ),
      );
      add(mountains.last);
    }
    
    // Create background trees
    trees = [];
    for (int i = 0; i < 5; i++) {
      trees.add(
        Tree(
          position: Vector2(i * 300.0, 350),
          speed: 0.7,
        ),
      );
      add(trees.last);
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Update all parallax elements
    for (final mountain in mountains) {
      mountain.updatePosition(dt, gameSpeed);
    }
    
    for (final tree in trees) {
      tree.updatePosition(dt, gameSpeed);
    }
    
    // Rotate sun slowly
    sun.angle += dt * 0.1;
  }
}

class Mountain extends PositionComponent {
  final Color color;
  final double speed;
  late PolygonComponent shape;
  
  Mountain({
    required Vector2 position,
    required Vector2 size,
    required this.color,
    required this.speed,
  }) : super(position: position, size: size);
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Create mountain shape
    final vertices = [
      Vector2(0, size.y),
      Vector2(size.x * 0.3, size.y * 0.2),
      Vector2(size.x * 0.5, 0),
      Vector2(size.x * 0.7, size.y * 0.3),
      Vector2(size.x, size.y),
    ];
    
    shape = PolygonComponent(
      vertices,
      paint: Paint()..color = color,
    );
    add(shape);
  }
  
  void updatePosition(double dt, double gameSpeed) {
    position.x -= gameSpeed * speed * dt;
    
    // Wrap around when off screen - spawn before entering from right
    if (position.x + size.x < 0) {
      position.x = 1600; // Spawn off-screen to the right
    }
  }
}

class Tree extends PositionComponent {
  final double speed;
  
  Tree({
    required Vector2 position,
    required this.speed,
  }) : super(position: position, size: Vector2(80, 120));
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Tree trunk
    add(RectangleComponent(
      size: Vector2(20, 60),
      position: Vector2(30, 60),
      paint: Paint()..color = const Color(0xFF8B4513),
    ));
    
    // Tree foliage (3 circles)
    add(CircleComponent(
      radius: 25,
      position: Vector2(40, 40),
      paint: Paint()..color = const Color(0xFF228B22),
    ));
    
    add(CircleComponent(
      radius: 20,
      position: Vector2(25, 50),
      paint: Paint()..color = const Color(0xFF228B22).withValues(alpha: 0.9),
    ));
    
    add(CircleComponent(
      radius: 20,
      position: Vector2(55, 50),
      paint: Paint()..color = const Color(0xFF228B22).withValues(alpha: 0.9),
    ));
  }
  
  void updatePosition(double dt, double gameSpeed) {
    position.x -= gameSpeed * speed * dt;
    
    // Wrap around when off screen
    if (position.x + size.x < 0) {
      position.x = 1500;
    }
  }
}