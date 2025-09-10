import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../../../widgets/pixel_button.dart';
import '../../../widgets/game_frame.dart';
import '../../../widgets/typing_text.dart';
import 'flame_game.dart';
import 'start.dart';

class TocaGameScreen extends StatefulWidget {
  const TocaGameScreen({super.key});

  @override
  State<TocaGameScreen> createState() => _TocaGameScreenState();
}

class _TocaGameScreenState extends State<TocaGameScreen> {
  late final CrabGame _game;

  @override
  void initState() {
    super.initState();
    _game = CrabGame(onGameOver: () {
      if (!mounted) return;
      _game.overlays.add('GameOver');
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Toca do Caranguejo',
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: GameWidget(
            game: _game,
            overlayBuilderMap: {
              'Hud': (context, game) => _HudOverlay(game as CrabGame),
              'Popup': (context, game) => _PopupOverlay(game as CrabGame),
              'ActionPopup': (context, game) => _ActionPopupOverlay(game as CrabGame),
              'GameOver': (context, game) => _GameOverOverlay(game as CrabGame),
            },
            initialActiveOverlays: const ['Hud'],
          ),
        ),
      ),
    );
  }
}

class _HudOverlay extends StatelessWidget {
  const _HudOverlay(this.game);
  final CrabGame game;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (details) => game.handleTap(details.localPosition),
        child: Stack(
          children: [
        // Score
        Positioned(
          top: 20,
          left: 20,
          child: ValueListenableBuilder<int>(
            valueListenable: game.score,
            builder: (context, score, _) => _infoBox('🎯 Pontuação: $score'),
          ),
        ),
        // Time
        Positioned(
          top: 20,
          right: 20,
          child: ValueListenableBuilder<int>(
            valueListenable: game.timeLeft,
            builder: (context, time, _) => _infoBox('🕒 Tempo: $time s'),
          ),
        ),
        // Sound toggle button (SFX on/off)
        Positioned(
          top: 60,
          right: 20,
          child: ValueListenableBuilder<bool>(
            valueListenable: game.sfxEnabled,
            builder: (context, enabled, _) => _hudIconButton(
              icon: enabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              onPressed: () => game.sfxEnabled.value = !enabled,
            ),
          ),
        ),
        // Periodic popup (typing + skip)
        Positioned.fill(
          child: ValueListenableBuilder<String?>(
            valueListenable: game.popupMessage,
            builder: (context, message, _) => message == null
                ? const SizedBox.shrink()
                : Center(
                    child: ValueListenableBuilder<bool>(
                      valueListenable: game.sfxEnabled,
                      builder: (context, enabled, __) => _popupMensagemDigitando(message, enableSound: enabled),
                    ),
                  ),
          ),
        ),
        // Action popup (typing + skip)
        Positioned.fill(
          child: ValueListenableBuilder<String?>(
            valueListenable: game.actionMessage,
            builder: (context, message, _) => message == null
                ? const SizedBox.shrink()
                : Center(
                    child: ValueListenableBuilder<bool>(
                      valueListenable: game.sfxEnabled,
                      builder: (context, enabled, __) => _popupMensagemDigitando(message, enableSound: enabled),
                    ),
                  ),
          ),
        ),
          ],
        ),
      ),
    );
  }

  Widget _infoBox(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.brown),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.brown,
        ),
      ),
    );
  }

  Widget _popupMensagem(String texto) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.brown, width: 3),
        boxShadow: [
          BoxShadow(
            blurRadius: 6,
            offset: const Offset(4, 4),
            color: Colors.black.withOpacity(0.4),
          ),
        ],
      ),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.brown,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _popupMensagemDigitando(String texto, {required bool enableSound}) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.brown, width: 3),
        boxShadow: [
          BoxShadow(
            blurRadius: 6,
            offset: const Offset(4, 4),
            color: Colors.black.withOpacity(0.4),
          ),
        ],
      ),
      child: TypingText(
        text: texto,
        charDelay: const Duration(milliseconds: 22),
        clickEvery: 2,
        enableSound: enableSound,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.brown,
        ),
      ),
    );
  }

  Widget _hudIconButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        border: Border.all(color: Colors.brown),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        iconSize: 24,
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.brown),
        tooltip: 'Som',
      ),
    );
  }
}

class _PopupOverlay extends StatelessWidget {
  const _PopupOverlay(this.game);
  final CrabGame game;
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _ActionPopupOverlay extends StatelessWidget {
  const _ActionPopupOverlay(this.game);
  final CrabGame game;
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay(this.game);
  final CrabGame game;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.symmetric(horizontal: 32),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.brown, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              offset: const Offset(4, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🏁 Fim de Jogo!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<int>(
              valueListenable: game.score,
              builder: (context, score, _) => Text(
                '🎯 Sua pontuação: $score',
                style: const TextStyle(fontSize: 18, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 24),
            PixelButton(
              label: '🔁 Jogar Novamente',
              onPressed: () {
                // Reset the game by replacing the current route
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const TocaGameScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            PixelButton(
              label: '🏠 Voltar ao Início',
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const TocaStartScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
