# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter web game called "Kangaroo Hop" - an endless runner game for kids in Australian schools. The game uses the Flame game engine for 2D game development and is optimized for web browsers and Chromebooks.

## Development Commands

**Setup and Dependencies:**
```bash
flutter pub get                 # Install dependencies
flutter pub upgrade            # Upgrade dependencies
```

**Development:**
```bash
flutter run -d web-server      # Run the game on web (recommended for testing)
flutter run -d chrome          # Run in Chrome browser
flutter run --release -d web   # Run in release mode for performance testing
```

**Code Quality:**
```bash
flutter analyze               # Run static analysis
flutter test                 # Run all tests
flutter test test/widget_test.dart  # Run specific test file
```

**Build:**
```bash
flutter build web            # Build for web deployment
```

## Game Architecture

### Core Game Structure
- **Entry Point:** `lib/main.dart` - Initializes the Flutter app with Flame GameWidget
- **Main Game:** `lib/game/kangaroo_game.dart` - Core game logic, state management, and UI
- **Game States:** Menu, Playing, Game Over with proper state transitions

### Components (lib/components/)
- **kangaroo.dart:** Player character with jump mechanics and collision detection
- **obstacle.dart:** Scrolling obstacles with collision hitboxes
- **background.dart:** Parallax scrolling background with Australian outback theme
- **ground.dart:** Scrolling ground texture

### Game Features
- **Controls:** Tap/click to jump (works on both touch and mouse)
- **Physics:** Gravity-based jumping with ground collision
- **Scoring:** Time-based scoring with local high score persistence
- **Difficulty:** Progressive speed increase based on score
- **Theme:** Australian colors (red dirt, eucalyptus green, sky blue)

## Key Dependencies

- `flutter`: Core Flutter framework  
- `flame: ^1.29.0`: 2D game engine for components, collision detection, and game loop
- `shared_preferences: ^2.3.2`: Local storage for high scores
- `cupertino_icons`: iOS-style icons
- `flutter_lints`: Dart/Flutter linting rules

## Game Development Notes

- Uses Flame's `HasCollisionDetection` for obstacle collision
- `TimerComponent` for obstacle spawning intervals
- `RectangleComponent` for simple colored sprite rendering
- Local storage via SharedPreferences for offline high score persistence
- Responsive design works on various screen sizes
- Australian theme colors: #D2691E (red dirt), #87A96B (eucalyptus), #87CEEB (sky blue)

## Code Style

The project uses `flutter_lints` with default Flutter linting rules. All game components extend Flame's base classes and follow the component-based architecture pattern.