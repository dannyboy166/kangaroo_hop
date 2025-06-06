import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game/kangaroo_game.dart';

void main() {
  runApp(const KangarooHopApp());
}

class KangarooHopApp extends StatelessWidget {
  const KangarooHopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kangaroo Hop',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: GameWidget<KangarooGame>.controlled(
        gameFactory: KangarooGame.new,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
