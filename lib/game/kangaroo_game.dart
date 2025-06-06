import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/background.dart';
import '../components/ground.dart';
import '../components/kangaroo.dart';
import '../components/obstacle.dart';

enum GameState { menu, playing, gameOver }

class KangarooGame extends FlameGame with HasKeyboardHandlerComponents, HasCollisionDetection, TapDetector {
  late Kangaroo kangaroo;
  late Background background;
  late Ground ground;
  late TextComponent scoreText;
  late TextComponent highScoreText;
  late TextComponent gameOverText;
  late TextComponent restartText;
  late TextComponent menuText;
  
  GameState gameState = GameState.menu;
  int score = 0;
  int highScore = 0;
  double gameSpeed = 200.0;
  late TimerComponent obstacleTimer;
  Random random = Random();
  
  static const double minObstacleSpacing = 1.5;
  static const double maxObstacleSpacing = 3.0;
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Load high score from local storage
    await loadHighScore();
    
    // Initialize components
    background = Background();
    ground = Ground();
    kangaroo = Kangaroo();
    
    add(background);
    add(ground);
    add(kangaroo);
    
    // Initialize UI text components
    scoreText = TextComponent(
      text: 'Score: 0',
      position: Vector2(20, 20),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black,
              offset: Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
    );
    
    highScoreText = TextComponent(
      text: 'High Score: $highScore',
      position: Vector2(20, 50),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black,
              offset: Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
    );
    
    gameOverText = TextComponent(
      text: 'GAME OVER',
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.red,
          fontSize: 48,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black,
              offset: Offset(2, 2),
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
    
    restartText = TextComponent(
      text: 'Tap to Restart',
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black,
              offset: Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
    );
    
    menuText = TextComponent(
      text: 'KANGAROO HOP\n\nTap to Start!',
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          height: 1.5,
          shadows: [
            Shadow(
              color: Colors.black,
              offset: Offset(2, 2),
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
    
    add(scoreText);
    add(highScoreText);
    
    showMenu();
  }
  
  void showMenu() {
    gameState = GameState.menu;
    kangaroo.reset();
    
    // Clear obstacles
    removeWhere((component) => component is Obstacle);
    
    // Position menu text
    menuText.position = Vector2(size.x / 2, size.y / 2);
    add(menuText);
    
    // Hide game UI
    scoreText.removeFromParent();
    highScoreText.removeFromParent();
  }
  
  void startGame() {
    gameState = GameState.playing;
    score = 0;
    gameSpeed = 200.0;
    
    // Remove menu text
    menuText.removeFromParent();
    
    // Show game UI
    add(scoreText);
    add(highScoreText);
    
    // Start spawning obstacles
    scheduleNextObstacle();
  }
  
  void gameOver() {
    gameState = GameState.gameOver;
    
    // Stop obstacle spawning
    if (obstacleTimer.parent != null) {
      obstacleTimer.removeFromParent();
    }
    
    // Update high score if needed
    if (score > highScore) {
      highScore = score;
      saveHighScore();
    }
    
    // Position game over text
    gameOverText.position = Vector2(size.x / 2, size.y / 2 - 40);
    restartText.position = Vector2(size.x / 2, size.y / 2 + 40);
    
    add(gameOverText);
    add(restartText);
    
    // Update high score display
    highScoreText.text = 'High Score: $highScore';
  }
  
  void restart() {
    // Remove game over UI
    gameOverText.removeFromParent();
    restartText.removeFromParent();
    
    // Clear obstacles
    removeWhere((component) => component is Obstacle);
    
    // Reset kangaroo
    kangaroo.reset();
    
    // Start new game
    startGame();
  }
  
  @override
  bool onTapDown(TapDownInfo info) {
    switch (gameState) {
      case GameState.menu:
        startGame();
        break;
      case GameState.playing:
        kangaroo.jump();
        break;
      case GameState.gameOver:
        restart();
        break;
    }
    return true;
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (gameState == GameState.playing) {
      // Update score
      score += (dt * 10).round();
      scoreText.text = 'Score: $score';
      
      // Increase game speed gradually
      gameSpeed = 200.0 + (score * 0.1);
      
      // Update components with game speed
      ground.gameSpeed = gameSpeed;
      background.gameSpeed = gameSpeed;
      
      // Update obstacles
      for (final component in children) {
        if (component is Obstacle) {
          component.gameSpeed = gameSpeed;
        }
      }
    }
  }
  
  void scheduleNextObstacle() {
    if (gameState != GameState.playing) return;
    
    final spacing = minObstacleSpacing + random.nextDouble() * (maxObstacleSpacing - minObstacleSpacing);
    obstacleTimer = TimerComponent(
      period: spacing,
      repeat: false,
      onTick: () {
        if (gameState == GameState.playing) {
          final obstacle = Obstacle();
          obstacle.gameSpeed = gameSpeed;
          add(obstacle);
          scheduleNextObstacle();
        }
      },
    );
    add(obstacleTimer);
  }
  
  void onObstacleCollision() {
    if (gameState == GameState.playing) {
      gameOver();
    }
  }
  
  Future<void> loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    highScore = prefs.getInt('kangaroo_hop_high_score') ?? 0;
  }
  
  Future<void> saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('kangaroo_hop_high_score', highScore);
  }
}