import 'dart:async' as async;
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CrabGame extends FlameGame {
  CrabGame({required this.onGameOver});

  // State exposed to overlays
  final ValueNotifier<int> score = ValueNotifier<int>(0);
  final ValueNotifier<int> timeLeft = ValueNotifier<int>(60);
  final ValueNotifier<String?> popupMessage = ValueNotifier<String?>(null);
  final ValueNotifier<String?> actionMessage = ValueNotifier<String?>(null);

  // Callback to notify Flutter UI when game ends
  final VoidCallback onGameOver;

  late final SpriteComponent _background;
  late final CrabComponent _crab;

  final List<Offset> _burrows = [];
  final Random _rand = Random();

  async.Timer? _moveTimer;
  async.Timer? _countdownTimer;
  async.Timer? _popupTimer;

  final List<String> _messages = const [
    '🦀 Os caranguejos ajudam a manter o solo do mangue saudável!',
    '🌱 O manguezal é o berçário de muitas espécies marinhas!',
    '🚯 Não jogue lixo no mangue. Preserve a natureza!'
  ];

  @override
  async.Future<void> onLoad() async {
    await super.onLoad();

    // Use default viewport; positions are computed relative to size

    // Background full screen
    final backgroundSprite = await loadSprite(
      'lib/assets/games/toca-do-caranguejo/background.png',
    );
    _background = SpriteComponent(sprite: backgroundSprite, size: size)
      ..position = Vector2.zero();
    add(_background);

    _setupBurrows();

    // Crab
    final crabSprite = await loadSprite(
      'lib/assets/games/toca-do-caranguejo/caranguejo.png',
    );
    _crab = CrabComponent(sprite: crabSprite);
    _placeCrab(randomizeSize: true);
    add(_crab);

    // Timers
    _moveTimer = async.Timer.periodic(const Duration(seconds: 2), (_) {
      if (timeLeft.value > 0) {
        _placeCrab(randomizeSize: true);
      }
    });

    _countdownTimer = async.Timer.periodic(const Duration(seconds: 1), (_) {
      if (timeLeft.value <= 0) return;
      timeLeft.value = timeLeft.value - 1;
      if (timeLeft.value <= 0) {
        _endGame();
      }
    });

    _popupTimer = async.Timer.periodic(const Duration(seconds: 15), (t) {
      if (timeLeft.value <= 0) return;
      final idx = t.tick % _messages.length;
      popupMessage.value = _messages[idx];
      async.Future.delayed(const Duration(seconds: 4), () {
        if (!isMounted) return;
        if (timeLeft.value > 0) popupMessage.value = null;
      });
    });
  }

  void _setupBurrows() {
    // Mirrors Flutter version using relative screen positions
    final w = size.x;
    final h = size.y;
    _burrows
      ..clear()
      ..addAll([
        Offset(w * 0.12, h * 0.75),
        Offset(w * 0.23, h * 0.72),
        Offset(w * 0.34, h * 0.70),
        Offset(w * 0.45, h * 0.69),
        Offset(w * 0.56, h * 0.70),
        Offset(w * 0.67, h * 0.72),
        Offset(w * 0.78, h * 0.74),
        Offset(w * 0.89, h * 0.76),
        Offset(w * 0.17, h * 0.82),
        Offset(w * 0.29, h * 0.80),
        Offset(w * 0.41, h * 0.79),
        Offset(w * 0.53, h * 0.79),
        Offset(w * 0.65, h * 0.80),
        Offset(w * 0.77, h * 0.82),
        Offset(w * 0.89, h * 0.84),
      ]);
  }

  void _placeCrab({required bool randomizeSize}) {
    if (_burrows.isEmpty) return;
    final pos = _burrows[_rand.nextInt(_burrows.length)];
    final small = _rand.nextBool();
    final width = size.x * (small ? 0.05 : 0.08);
    final height = width; // keep square
    _crab
      ..size = Vector2(width, height)
      ..position = Vector2(pos.dx, pos.dy)
      ..isSmall = small;
  }

  void _onCrabTapped() {
    if (timeLeft.value <= 0) return;
    if (_crab.isSmall) {
      score.value = score.value - 20;
      actionMessage.value =
          '⚠️ Capturar caranguejo jovem prejudica o ciclo do mangue!';
    } else {
      score.value = score.value + 15;
      actionMessage.value =
          '✅ Proteger o ciclo reprodutivo mantém o mangue vivo!';
    }
    // Hide action popup after 4s
    async.Future.delayed(const Duration(seconds: 4), () {
      if (!isMounted) return;
      if (timeLeft.value > 0) actionMessage.value = null;
    });

    // Move crab after tap
    _placeCrab(randomizeSize: true);
  }

  void _endGame() {
    _moveTimer?.cancel();
    _popupTimer?.cancel();
    _countdownTimer?.cancel();
    onGameOver();
  }

  // Hit test using overlay gestures
  Rect get crabRect => Rect.fromLTWH(
        _crab.position.x,
        _crab.position.y,
        _crab.size.x,
        _crab.size.y,
      );

  void handleTap(Offset position) {
    if (crabRect.contains(position)) {
      _onCrabTapped();
    }
  }

  @override
  void onRemove() {
    _moveTimer?.cancel();
    _popupTimer?.cancel();
    _countdownTimer?.cancel();
    score.dispose();
    timeLeft.dispose();
    popupMessage.dispose();
    actionMessage.dispose();
    super.onRemove();
  }
}

class CrabComponent extends SpriteComponent {
  CrabComponent({required super.sprite}) : super(priority: 10);
  bool isSmall = false;
}
