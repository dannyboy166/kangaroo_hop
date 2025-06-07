import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../game/kangaroo_game.dart';
import 'power_up.dart';

class StoreScreen extends Component with HasGameReference<KangarooGame> {
  late RectangleComponent background;
  late RectangleComponent storePanel;
  late TextComponent titleText;
  late TextComponent coinText;
  late TextComponent closeButtonText;
  late RectangleComponent closeButton;

  final List<StoreItem> storeItems = [];

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // CRITICAL: Set very high priority to ensure store appears on top
    priority = 2000; // Higher than UI overlay (1000)

    // Semi-transparent background that covers ENTIRE screen
    background = RectangleComponent(
      size: game.size,
      paint: Paint()..color = Colors.black.withValues(alpha: 0.8),
    );
    add(background);

    // Store panel - much larger and responsive with rounded corners
    final panelWidth = game.size.x * 0.9;
    final panelHeight = game.size.y * 0.8;
    storePanel = RectangleComponent(
      size: Vector2(panelWidth, panelHeight),
      position: game.size / 2,
      anchor: Anchor.center,
      paint: Paint()
        ..color = const Color(0xFF1A1A2E)
        ..style = PaintingStyle.fill,
    );
    
    // Add subtle gradient effect with overlays
    final gradientOverlay = RectangleComponent(
      size: Vector2(panelWidth, panelHeight * 0.3),
      position: Vector2.zero(),
      paint: Paint()
        ..color = const Color(0xFF4F9DFF).withValues(alpha: 0.1)
        ..style = PaintingStyle.fill,
    );
    storePanel.add(gradientOverlay);
    add(storePanel);

    // Simple clean border
    final panelBorder = RectangleComponent(
      size: Vector2(panelWidth, panelHeight),
      position: Vector2.zero(),
      paint: Paint()
        ..color = const Color(0xFF4F9DFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    storePanel.add(panelBorder);

    // Title - only animated element, positioned responsively
    titleText = TextComponent(
      text: 'POWER-UP STORE',
      position: Vector2(panelWidth / 2, panelHeight * 0.1),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF4F9DFF),
          fontSize: 32,
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
    storePanel.add(titleText);

    // Coin display with image and custom color
    final coinContainer = PositionComponent(
      position: Vector2(panelWidth / 2, panelHeight * 0.18),
    );
    
    // Add coin image
    Sprite.load('coin.png').then((coinSprite) {
      final coinImage = SpriteComponent(
        sprite: coinSprite,
        size: Vector2(28, 28),
        position: Vector2(-55, -14), // Move coin further left
      );
      coinContainer.add(coinImage);
    });
    
    // Add coin text with new color
    coinText = TextComponent(
      text: '${game.storeManager.totalCoins + game.sessionCoins}',
      position: Vector2(5, 0), // Move text further right for better separation
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFF7B027), // Your custom color
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
    coinContainer.add(coinText);
    storePanel.add(coinContainer);

    // Close button with cross image - positioned relative to panel size
    closeButton = RectangleComponent(
      size: Vector2(40, 40), // Square button for the cross
      position: Vector2(panelWidth - 60, 20),
      paint: Paint()..color = Colors.transparent, // Transparent background
    );
    storePanel.add(closeButton);

    // Load and add cross image
    Sprite.load('cross.png').then((crossSprite) {
      final crossImage = SpriteComponent(
        sprite: crossSprite,
        size: Vector2(32, 32), // Slightly smaller than button
        position: Vector2(20, 20), // Center in button
        anchor: Anchor.center,
      );
      closeButton.add(crossImage);
    });

    // Keep text component for reference but make it empty
    closeButtonText = TextComponent(
      text: '',
      position: Vector2(20, 20),
      anchor: Anchor.center,
    );
    closeButton.add(closeButtonText);

    // Create store items with proper responsive spacing
    _createStoreItems();

    // Simple entrance animation for panel only
    storePanel.scale = Vector2.all(0.3);
    storePanel.add(
      ScaleEffect.to(
        Vector2.all(1),
        EffectController(
          duration: 0.3,
          curve: Curves.easeOut,
        ),
      ),
    );

    // Only animate the title with subtle pulsing
    titleText.add(
      ScaleEffect.to(
        Vector2.all(1.05),
        EffectController(
          duration: 1.5,
          reverseDuration: 1.5,
          infinite: true,
        ),
      ),
    );
  }

  void _createStoreItems() {
    final powerUps = [
      PowerUpType.doubleJump,
      PowerUpType.shield,
      PowerUpType.magnet
    ];

    // Calculate item positioning with much better spacing
    final itemWidth = 240.0; // Wider items
    final totalWidth = storePanel.size.x;
    final usableWidth = totalWidth - 60; // Smaller margins for more space
    final spacing = (usableWidth - (itemWidth * powerUps.length)) / (powerUps.length + 1);
    
    for (int i = 0; i < powerUps.length; i++) {
      final powerUpType = powerUps[i];
      final xPos = 30 + spacing + (i * (itemWidth + spacing));

      final item = StoreItem(
        powerUpType: powerUpType,
        position: Vector2(xPos, storePanel.size.y * 0.32),
      );
      storeItems.add(item);
      storePanel.add(item);
    }
  }

  void updateCoinDisplay() {
    coinText.text = '${game.storeManager.totalCoins + game.sessionCoins}';

    // Update all store items
    for (final item in storeItems) {
      item.updateDisplay();
    }
  }

  bool onTapDown(TapDownInfo info) {
    final localPoint = info.eventPosition.global;

    // Convert to local coordinates relative to store panel
    final storeLocalPoint = localPoint - storePanel.absolutePosition + storePanel.size / 2;

    // Check close button with proper bounds checking
    final closeButtonBounds = Rect.fromLTWH(
      closeButton.position.x,
      closeButton.position.y,
      closeButton.size.x,
      closeButton.size.y,
    );

    if (closeButtonBounds.contains(storeLocalPoint.toOffset())) {
      game.hideStore();
      return true;
    }

    // Check store items
    for (final item in storeItems) {
      if (item.onTapDown(storeLocalPoint)) {
        updateCoinDisplay();
        return true;
      }
    }

    // If tapped on background (outside panel), close store
    final panelBounds = Rect.fromLTWH(
      storePanel.position.x - storePanel.size.x / 2,
      storePanel.position.y - storePanel.size.y / 2,
      storePanel.size.x,
      storePanel.size.y,
    );

    if (!panelBounds.contains(localPoint.toOffset())) {
      game.hideStore();
      return true;
    }

    // Consume the tap to prevent it from propagating
    return true;
  }
}

class StoreItem extends PositionComponent with HasGameReference<KangarooGame> {
  final PowerUpType powerUpType;
  late RectangleComponent itemBackground;
  late TextComponent nameText;
  late TextComponent descriptionText;
  late TextComponent priceText;
  late TextComponent countText;
  late RectangleComponent buyButton;
  late TextComponent buyButtonText;

  StoreItem({
    required this.powerUpType,
    required Vector2 position,
  }) : super(position: position, size: Vector2(240, 370)); // Even larger items for better spacing

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Clean item background
    itemBackground = RectangleComponent(
      size: size,
      paint: Paint()
        ..color = const Color(0xFF16213E)
        ..style = PaintingStyle.fill,
    );
    add(itemBackground);

    // Simple clean border
    final border = RectangleComponent(
      size: size,
      paint: Paint()
        ..color = const Color(0xFF4F9DFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    add(border);

    // Add subtle item gradient
    final itemGradient = RectangleComponent(
      size: Vector2(size.x, size.y * 0.3),
      position: Vector2.zero(),
      paint: Paint()
        ..color = const Color(0xFF4F9DFF).withValues(alpha: 0.05)
        ..style = PaintingStyle.fill,
    );
    add(itemGradient);
    
    // Power-up visual - well spaced and larger
    final powerUpVisual = PowerUpVisual(type: powerUpType);
    powerUpVisual.position = Vector2(size.x / 2, 90); // More spacing from top
    powerUpVisual.anchor = Anchor.center; // Center the logo
    powerUpVisual.size = Vector2(80, 80); // Even larger visual
    add(powerUpVisual);

    // Name with better spacing - moved down
    nameText = TextComponent(
      text: game.storeManager.getPowerUpName(powerUpType),
      position: Vector2(size.x / 2, 180),
      anchor: Anchor.center,
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
    add(nameText);

    // Description with proper spacing
    final description = game.storeManager.getPowerUpDescription(powerUpType);
    descriptionText = TextComponent(
      text: description,
      position: Vector2(size.x / 2, 220),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
        ),
      ),
    );
    add(descriptionText);

    // Price with good spacing
    priceText = TextComponent(
      text: '\$ ${game.storeManager.getPowerUpPrice(powerUpType)}',
      position: Vector2(size.x / 2, 260),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFFD700),
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
    add(priceText);

    // Count with proper spacing
    countText = TextComponent(
      text: 'Owned: ${game.storeManager.getPowerUpCount(powerUpType)}/3',
      position: Vector2(size.x / 2, 295),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    add(countText);

    // Buy button with good proportions and spacing
    buyButton = RectangleComponent(
      size: Vector2(200, 50), // Even larger button
      position: Vector2(20, 310), // Better positioning with more spacing
      paint: Paint()..color = const Color(0xFF2ED573),
    );
    add(buyButton);

    // Simple button border
    final buttonBorder = RectangleComponent(
      size: Vector2(200, 50),
      position: Vector2.zero(),
      paint: Paint()
        ..color = const Color(0xFF7BED9F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    buyButton.add(buttonBorder);

    buyButtonText = TextComponent(
      text: 'BUY',
      position: Vector2(100, 25),
      anchor: Anchor.center,
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
    buyButton.add(buyButtonText);

    updateDisplay();

    // NO continuous animations - items are static
  }

  void updateDisplay() {
    countText.text =
        'Owned: ${game.storeManager.getPowerUpCount(powerUpType)}/3';

    final canPurchase = game.storeManager.canPurchase(powerUpType);
    final maxReached = game.storeManager.getPowerUpCount(powerUpType) >= 3;

    if (maxReached) {
      buyButton.paint.color = const Color(0xFF57606F);
      buyButtonText.text = 'MAX';
    } else if (canPurchase) {
      buyButton.paint.color = const Color(0xFF2ED573);
      buyButtonText.text = 'BUY';
    } else {
      buyButton.paint.color = const Color(0xFFFF4757);
      buyButtonText.text = 'BUY';
    }
  }

  bool onTapDown(Vector2 storeLocalPosition) {
    // Convert store local position to item local position
    final itemLocalPoint = storeLocalPosition - position;

    final buttonBounds = Rect.fromLTWH(
      buyButton.position.x,
      buyButton.position.y,
      buyButton.size.x,
      buyButton.size.y,
    );

    if (buttonBounds.contains(itemLocalPoint.toOffset())) {
      if (game.storeManager.purchasePowerUp(powerUpType)) {
        // Simple purchase feedback - just a quick scale
        buyButton.add(
          ScaleEffect.to(
            Vector2.all(1.1),
            EffectController(duration: 0.1),
            onComplete: () {
              buyButton.add(
                ScaleEffect.to(
                  Vector2.all(1.0),
                  EffectController(duration: 0.1),
                ),
              );
            },
          ),
        );
        updateDisplay();
        return true;
      }
    }

    return false;
  }
}

class PowerUpVisual extends PositionComponent {
  final PowerUpType type;

  PowerUpVisual({required this.type}) : super(size: Vector2(80, 80));

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Use the new image assets with words for store display
    String imagePath;
    switch (type) {
      case PowerUpType.doubleJump:
        imagePath = 'double.png';
        break;
      case PowerUpType.shield:
        imagePath = 'shield.png';
        break;
      case PowerUpType.magnet:
        imagePath = 'magnet.png';
        break;
    }

    final sprite = await Sprite.load(imagePath);
    add(SpriteComponent(
      sprite: sprite,
      size: size,
      anchor: Anchor.center,
      position: size / 2,
    ));
  }
}