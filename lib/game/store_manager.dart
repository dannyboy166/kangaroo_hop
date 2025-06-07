import 'package:shared_preferences/shared_preferences.dart';

import '../components/power_up.dart';

class StoreManager {
  static const String _totalCoinsKey = 'kangaroo_hop_total_coins';
  static const String _doubleJumpCountKey = 'kangaroo_hop_double_jump_count';
  static const String _shieldCountKey = 'kangaroo_hop_shield_count';
  static const String _magnetCountKey = 'kangaroo_hop_magnet_count';
  
  // Power-up prices
  static const int doubleJumpPrice = 75;
  static const int shieldPrice = 100;
  static const int magnetPrice = 50;
  
  // Maximum items per power-up type
  static const int maxItemCount = 3;
  
  int totalCoins = 0;
  int doubleJumpCount = 0;
  int shieldCount = 0;
  int magnetCount = 0;
  
  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    totalCoins = prefs.getInt(_totalCoinsKey) ?? 0;
    doubleJumpCount = prefs.getInt(_doubleJumpCountKey) ?? 0;
    shieldCount = prefs.getInt(_shieldCountKey) ?? 0;
    magnetCount = prefs.getInt(_magnetCountKey) ?? 0;
  }
  
  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_totalCoinsKey, totalCoins);
    await prefs.setInt(_doubleJumpCountKey, doubleJumpCount);
    await prefs.setInt(_shieldCountKey, shieldCount);
    await prefs.setInt(_magnetCountKey, magnetCount);
  }
  
  bool canPurchase(PowerUpType type) {
    final price = getPowerUpPrice(type);
    final currentCount = getPowerUpCount(type);
    return totalCoins >= price && currentCount < maxItemCount;
  }
  
  bool purchasePowerUp(PowerUpType type) {
    if (!canPurchase(type)) return false;
    
    final price = getPowerUpPrice(type);
    totalCoins -= price;
    
    switch (type) {
      case PowerUpType.doubleJump:
        doubleJumpCount++;
        break;
      case PowerUpType.shield:
        shieldCount++;
        break;
      case PowerUpType.magnet:
        magnetCount++;
        break;
    }
    
    saveData();
    return true;
  }
  
  bool usePowerUp(PowerUpType type) {
    switch (type) {
      case PowerUpType.doubleJump:
        if (doubleJumpCount > 0) {
          doubleJumpCount--;
          saveData();
          return true;
        }
        break;
      case PowerUpType.shield:
        if (shieldCount > 0) {
          shieldCount--;
          saveData();
          return true;
        }
        break;
      case PowerUpType.magnet:
        if (magnetCount > 0) {
          magnetCount--;
          saveData();
          return true;
        }
        break;
    }
    return false;
  }
  
  int getPowerUpCount(PowerUpType type) {
    switch (type) {
      case PowerUpType.doubleJump:
        return doubleJumpCount;
      case PowerUpType.shield:
        return shieldCount;
      case PowerUpType.magnet:
        return magnetCount;
    }
  }
  
  int getPowerUpPrice(PowerUpType type) {
    switch (type) {
      case PowerUpType.doubleJump:
        return doubleJumpPrice;
      case PowerUpType.shield:
        return shieldPrice;
      case PowerUpType.magnet:
        return magnetPrice;
    }
  }
  
  String getPowerUpName(PowerUpType type) {
    switch (type) {
      case PowerUpType.doubleJump:
        return 'Double Jump';
      case PowerUpType.shield:
        return 'Shield';
      case PowerUpType.magnet:
        return 'Coin Magnet';
    }
  }
  
  String getPowerUpDescription(PowerUpType type) {
    switch (type) {
      case PowerUpType.doubleJump:
        return 'Jump twice in the air!\nLasts 10 seconds';
      case PowerUpType.shield:
        return 'Protects from one hit!\nLasts 8 seconds';
      case PowerUpType.magnet:
        return 'Attracts nearby coins!\nLasts 10 seconds';
    }
  }
  
  void addCoins(int amount) {
    totalCoins += amount;
    saveData();
  }
}