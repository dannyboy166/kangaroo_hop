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

    // Semi-transparent background
    background = RectangleComponent(
      size: game.size,
      paint: Paint()..color = Colors.black.withValues(alpha: 0.7),
    );
    add(background);

    // Store panel
    storePanel = RectangleComponent(
      size: Vector2(600, 500),
      position: game.size / 2,
      anchor: Anchor.center,
      paint: Paint()
        ..color = Colors.brown.shade800
        ..style = PaintingStyle.fill,
    );
    add(storePanel);

    // Panel border
    final panelBorder = RectangleComponent(
      size: Vector2(600, 500),
      position: Vector2.zero(),
      paint: Paint()
        ..color = Colors.orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );
    storePanel.add(panelBorder);

    // Title
    titleText = TextComponent(
      text: 'POWER-UP STORE',
      position: Vector2(300, 40),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.orange,
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

    // Coin display
    coinText = TextComponent(
      text: '\$ ${game.storeManager.totalCoins}',
      position: Vector2(300, 80),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.yellow,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    storePanel.add(coinText);

    // Close button
    closeButton = RectangleComponent(
      size: Vector2(80, 40),
      position: Vector2(520, 20),
      paint: Paint()..color = Colors.red.shade700,
    );
    storePanel.add(closeButton);

    closeButtonText = TextComponent(
      text: 'X',
      position: Vector2(40, 20),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    closeButton.add(closeButtonText);

    // Create store items
    _createStoreItems();

    // Animate panel entrance
    storePanel.scale = Vector2.all(0.3);
    storePanel.add(
      ScaleEffect.to(
        Vector2.all(1),
        EffectController(
          duration: 0.5,
          curve: Curves.elasticOut,
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

    for (int i = 0; i < powerUps.length; i++) {
      final powerUpType = powerUps[i];
      final xPos = 100.0 + (i * 170);

      final item = StoreItem(
        powerUpType: powerUpType,
        position: Vector2(xPos, 200),
      );
      storeItems.add(item);
      storePanel.add(item);
    }
  }

  void updateCoinDisplay() {
    coinText.text = '\$ ${game.storeManager.totalCoins}';

    // Update all store items
    for (final item in storeItems) {
      item.updateDisplay();
    }
  }

  bool onTapDown(TapDownInfo info) {
    final localPoint = info.eventPosition.global;

    // Check close button
    if (closeButton
        .containsLocalPoint(localPoint - closeButton.absolutePosition)) {
      game.hideStore();
      return true;
    }

    // Check store items
    for (final item in storeItems) {
      if (item.onTapDown(localPoint)) {
        updateCoinDisplay();
        return true;
      }
    }

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
  }) : super(position: position, size: Vector2(140, 220));

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Item background
    itemBackground = RectangleComponent(
      size: size,
      paint: Paint()
        ..color = Colors.brown.shade600
        ..style = PaintingStyle.fill,
    );
    add(itemBackground);

    // Item border
    final border = RectangleComponent(
      size: size,
      paint: Paint()
        ..color = Colors.orange.shade300
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    add(border);

    // Power-up visual
    final powerUpVisual = PowerUpVisual(type: powerUpType);
    powerUpVisual.position = Vector2(70, 50);
    add(powerUpVisual);

    // Name
    nameText = TextComponent(
      text: game.storeManager.getPowerUpName(powerUpType),
      position: Vector2(70, 90),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(nameText);

    // Description
    descriptionText = TextComponent(
      text: game.storeManager.getPowerUpDescription(powerUpType),
      position: Vector2(70, 130),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
        ),
      ),
    );
    add(descriptionText);

    // Price
    priceText = TextComponent(
      text: '\$ ${game.storeManager.getPowerUpPrice(powerUpType)}',
      position: Vector2(70, 160),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.yellow,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(priceText);

    // Count
    countText = TextComponent(
      text: 'Owned: ${game.storeManager.getPowerUpCount(powerUpType)}/3',
      position: Vector2(70, 175),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
    );
    add(countText);

    // Buy button
    buyButton = RectangleComponent(
      size: Vector2(120, 30),
      position: Vector2(10, 185),
      paint: Paint()..color = Colors.green.shade700,
    );
    add(buyButton);

    buyButtonText = TextComponent(
      text: 'BUY',
      position: Vector2(60, 15),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    buyButton.add(buyButtonText);

    updateDisplay();
  }

  void updateDisplay() {
    countText.text =
        'Owned: ${game.storeManager.getPowerUpCount(powerUpType)}/3';

    final canPurchase = game.storeManager.canPurchase(powerUpType);
    final maxReached = game.storeManager.getPowerUpCount(powerUpType) >= 3;

    if (maxReached) {
      buyButton.paint.color = Colors.grey.shade600;
      buyButtonText.text = 'MAX';
    } else if (canPurchase) {
      buyButton.paint.color = Colors.green.shade700;
      buyButtonText.text = 'BUY';
    } else {
      buyButton.paint.color = Colors.red.shade700;
      buyButtonText.text = 'BUY';
    }
  }

  bool onTapDown(Vector2 worldPosition) {
    final localPoint = worldPosition - absolutePosition;

    if (buyButton.containsLocalPoint(localPoint - buyButton.position)) {
      if (game.storeManager.purchasePowerUp(powerUpType)) {
        // Purchase successful - add animation
        buyButton.add(
          ScaleEffect.to(
            Vector2.all(1.2),
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

  PowerUpVisual({required this.type}) : super(size: Vector2(30, 30));

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    switch (type) {
      case PowerUpType.doubleJump:
        add(CircleComponent(
          radius: 15,
          paint: Paint()..color = Colors.purple,
        ));
        add(TextComponent(
          text: '⬆⬆',
          position: Vector2(15, 15),
          anchor: Anchor.center,
          textRenderer: TextPaint(
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ));
        break;

      case PowerUpType.shield:
        final vertices = [
          Vector2(15, 3),
          Vector2(25, 10),
          Vector2(25, 22),
          Vector2(15, 27),
          Vector2(5, 22),
          Vector2(5, 10),
        ];
        add(PolygonComponent(
          vertices,
          paint: Paint()..color = Colors.blue,
        ));
        break;

      case PowerUpType.magnet:
        add(RectangleComponent(
          size: Vector2(8, 16),
          position: Vector2(6, 7),
          paint: Paint()..color = Colors.red,
        ));
        add(RectangleComponent(
          size: Vector2(8, 16),
          position: Vector2(16, 7),
          paint: Paint()..color = Colors.blue,
        ));
        add(RectangleComponent(
          size: Vector2(18, 7),
          position: Vector2(6, 7),
          paint: Paint()..color = Colors.grey,
        ));
        break;
    }
  }
}
