import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import '../game/kangaroo_game.dart';

class Coin extends PositionComponent
    with HasGameReference<KangarooGame>, HasPaint {
  double gameSpeed = 250.0;
  bool isCollected = false;

  // Debug: Add unique ID to track coins
  static int _nextId = 0;
  final int id = _nextId++;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Debug: Log coin creation
    print('Coin $id created');

    // Set size for coin sprite
    size = Vector2(40, 40);

    // Load and add the new coin sprite
    final sprite = await Sprite.load('coin.png');
    add(SpriteComponent(
      sprite: sprite,
      size: size,
      anchor: Anchor.center,
      position: size / 2,
    ));

    // Add collision detection
    add(CircleHitbox(radius: 20));

    // Add rotation animation (slower for less CPU usage)
    add(
      RotateEffect.by(
        2 * 3.14159,
        EffectController(
          duration: 3, // Slower rotation
          infinite: true,
        ),
      ),
    );

    // Add floating animation
    add(
      MoveEffect.by(
        Vector2(0, -8),
        EffectController(
          duration: 1.5,
          reverseDuration: 1.5,
          infinite: true,
        ),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!isCollected) {
      // Move with game speed
      position.x -= gameSpeed * dt;

      // Remove when off screen
      if (position.x + size.x < -50) {
        print('Coin $id removed - went off screen');
        removeFromParent();
      }
    }
  }

  /// ATOMIC COLLECTION METHOD
  /// Returns true if coin was successfully collected, false if already collected
  bool tryCollect() {
    if (isCollected) {
      print('Coin $id - tryCollect() FAILED: already collected');
      return false; // Already collected
    }

    print('Coin $id - tryCollect() SUCCESS: collecting now');
    isCollected = true; // Mark as collected atomically

    // Start collection animation
    _startCollectionAnimation();
    return true; // Successfully collected
  }

  /// LEGACY METHOD - now uses atomic tryCollect()
  void collect() {
    print('Coin $id - collect() called');
    if (!tryCollect()) {
      print('Coin $id - collect() aborted: tryCollect() failed');
      return; // Use atomic method
    }
    // Animation is already started by tryCollect()
    print('Coin $id - collect() completed');
  }

  /// Private method to handle collection animation
  void _startCollectionAnimation() {
    print('Coin $id - starting collection animation');

    // Collection animation
    add(
      ScaleEffect.to(
        Vector2.all(1.5),
        EffectController(duration: 0.2),
        onComplete: () {
          add(
            OpacityEffect.to(
              0,
              EffectController(duration: 0.2),
              onComplete: () {
                print('Coin $id - animation complete, removing from parent');
                removeFromParent();
              },
            ),
          );
        },
      ),
    );
  }

  @override
  void removeFromParent() {
    print('Coin $id - removeFromParent() called');
    super.removeFromParent();
  }
}
