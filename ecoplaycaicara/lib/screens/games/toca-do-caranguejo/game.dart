import 'dart:async';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../../widgets/pixel_button.dart';
import '../../../widgets/game_frame.dart';
import '../../../widgets/defeso_end_toast.dart'; // toast do fim do defeso

import 'flame_game.dart';
import 'start.dart';
import 'debug_burrows_overlay.dart';

// [A11Y] painel reutilizável igual ao do cadastro
import '../../../widgets/a11y_panel.dart'; // [A11Y]

class TocaGameScreen extends StatefulWidget {
  const TocaGameScreen({super.key, this.skipStartGate = false});
  final bool skipStartGate;

  @override
  State<TocaGameScreen> createState() => _TocaGameScreenState();
}

class _TocaGameScreenState extends State<TocaGameScreen> {
  late final CrabGame _game;

  @override
  void initState() {
    super.initState();
    _game = CrabGame(
      onGameOver: () {
        if (!mounted) return;
        _game.overlays.add('GameOver');
      },
    );
    unawaited(CrabGame.preloadImages());
    unawaited(CrabGame.preloadAudio());

    // Pausa o jogo inicialmente e mostra o gate de início
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        precacheImage(
          const AssetImage('assets/games/toca-do-caranguejo/background.png'),
          context,
        ),
      );
      unawaited(
        precacheImage(
          const AssetImage(
            'assets/games/toca-do-caranguejo/background-mobile.png',
          ),
          context,
        ),
      );
      if (widget.skipStartGate) {
        _game.startGame();
        _game.resumeEngine();
      } else {
        _game.pauseEngine();
        if (!_game.overlays.isActive('StartGate')) {
          _game.overlays.add('StartGate');
        }
      }
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
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Fundo estático (evita flicker na Web)
              LayoutBuilder(
                builder: (context, _) {
                  final size = MediaQuery.of(context).size;
                  final useMobile =
                      size.width <= 720 || size.height > size.width;
                  final asset = useMobile
                      ? 'assets/games/toca-do-caranguejo/background-mobile.png'
                      : 'assets/games/toca-do-caranguejo/background.png';
                  return Image.asset(asset, fit: BoxFit.cover);
                },
              ),

              // Jogo
              GameWidget(
                game: _game,
                overlayBuilderMap: {
                  'Hud': (context, game) => _HudOverlay(game as CrabGame),
                  'ActionPopup': (context, game) =>
                      _ActionPopupOverlay(game as CrabGame),
                  'GameOver': (context, game) =>
                      _GameOverOverlay(game as CrabGame),
                  'StartGate': (context, game) =>
                      _StartGateOverlay(game as CrabGame),
                  'DebugBurrows': (context, game) =>
                      DebugBurrowsOverlay(game as CrabGame),
                },
                initialActiveOverlays: const ['Hud', 'StartGate'],
              ),

              // 🔔 Toast “Defeso encerrado”
              Positioned.fill(
                child: DefesoEndToast(
                  defesoAtivo: _game.defesoAtivo,
                  fadeIn: const Duration(milliseconds: 220),
                  hold: const Duration(milliseconds: 1600),
                  fadeOut: const Duration(milliseconds: 260),
                  bottomPadding: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HudOverlay extends StatelessWidget {
  const _HudOverlay(this.game);
  final CrabGame game;

  // [A11Y] abre o painel e pausa/resume o engine
  Future<void> _openA11y(BuildContext context) async {
    game.pauseEngine(); // pausa o loop gráfico (timers internos do jogo seguem)
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const A11yPanel(),
    );
    game.resumeEngine();
  }
  // [A11Y] fim

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (details) => game.handleTap(details.localPosition),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 560;
            final isDesktopLike = (constraints.maxWidth >= 800);
            final pad = EdgeInsets.symmetric(
              horizontal: isNarrow ? 8 : 16,
              vertical: isNarrow ? 6 : 12,
            );
            final fontSize = isNarrow ? 13.0 : 16.0;

            final hud = SafeArea(
              child: Padding(
                padding: pad,
                child: isDesktopLike
                    ? Align(
                        alignment: Alignment.topCenter,
                        child: ValueListenableBuilder<bool>(
                          valueListenable: game.defesoAtivo,
                          builder: (context, defesoAtivo, _) {
                            return Wrap(
                              spacing: 10,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              alignment: WrapAlignment.center,
                              children: [
                                ValueListenableBuilder<int>(
                                  valueListenable: game.score,
                                  builder: (context, score, __) => _infoBox(
                                    '🎯 Pontuação: $score',
                                    fontSize: fontSize,
                                  ),
                                ),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 220),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeInCubic,
                                  child: defesoAtivo
                                      ? Padding(
                                          key: const ValueKey(
                                            'defeso-badge-inline',
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 2,
                                          ),
                                          child: _defesoBadge(
                                            fontSize: fontSize,
                                          ),
                                        )
                                      : const SizedBox.shrink(
                                          key: ValueKey('defeso-badge-hidden'),
                                        ),
                                ),

                                // Tempo
                                ValueListenableBuilder<int>(
                                  valueListenable: game.timeLeft,
                                  builder: (context, time, _) => _infoBox(
                                    '🕒 Tempo: $time s',
                                    fontSize: fontSize,
                                  ),
                                ),

                                // Som on/off
                                ValueListenableBuilder<bool>(
                                  valueListenable: game.sfxEnabled,
                                  builder: (context, enabled, _) =>
                                      _hudIconButton(
                                        icon: enabled
                                            ? Icons.volume_up_rounded
                                            : Icons.volume_off_rounded,
                                        onPressed: () =>
                                            game.sfxEnabled.value = !enabled,
                                      ),
                                ),

                                // [A11Y] Botão de acessibilidade (idêntico ao do cadastro em efeito)
                                _hudIconButton(
                                  icon: Icons.accessibility_new_rounded,
                                  onPressed: () => _openA11y(context),
                                  tooltip: 'Acessibilidade',
                                ),
                                // [A11Y] fim

                                // Recarregar
                                _hudIconButton(
                                  icon: Icons.refresh_rounded,
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const TocaGameScreen(),
                                      ),
                                    );
                                  },
                                ),

                                // Debug (somente dev)
                                if (kDebugMode)
                                  _hudIconButton(
                                    icon: Icons.bug_report_rounded,
                                    onPressed: () {
                                      if (game.overlays.isActive(
                                        'DebugBurrows',
                                      )) {
                                        game.overlays.remove('DebugBurrows');
                                      } else {
                                        game.overlays.add('DebugBurrows');
                                      }
                                    },
                                  ),
                              ],
                            );
                          },
                        ),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ⬅️ Coluna: Pontuação + DEFESO logo abaixo
                          Flexible(
                            child: _scoreWithDefeso(game, fontSize: fontSize),
                          ),
                          const SizedBox(width: 8),
                          // ➡️ Demais controles
                          Flexible(
                            child: Align(
                              alignment: Alignment.topRight,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                alignment: WrapAlignment.end,
                                children: [
                                  ValueListenableBuilder<int>(
                                    valueListenable: game.timeLeft,
                                    builder: (context, time, _) => _infoBox(
                                      '🕒 Tempo: $time s',
                                      fontSize: fontSize,
                                    ),
                                  ),
                                  ValueListenableBuilder<bool>(
                                    valueListenable: game.sfxEnabled,
                                    builder: (context, enabled, _) =>
                                        _hudIconButton(
                                          icon: enabled
                                              ? Icons.volume_up_rounded
                                              : Icons.volume_off_rounded,
                                          onPressed: () =>
                                              game.sfxEnabled.value = !enabled,
                                        ),
                                  ),

                                  // [A11Y] Botão de acessibilidade também no layout compacto
                                  _hudIconButton(
                                    icon: Icons.accessibility_new_rounded,
                                    onPressed: () => _openA11y(context),
                                    tooltip: 'Acessibilidade',
                                  ),

                                  // [A11Y] fim
                                  _hudIconButton(
                                    icon: Icons.refresh_rounded,
                                    onPressed: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const TocaGameScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  if (kDebugMode)
                                    _hudIconButton(
                                      icon: Icons.bug_report_rounded,
                                      onPressed: () {
                                        if (game.overlays.isActive(
                                          'DebugBurrows',
                                        )) {
                                          game.overlays.remove('DebugBurrows');
                                        } else {
                                          game.overlays.add('DebugBurrows');
                                        }
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            );

            return Stack(
              children: [
                Positioned.fill(child: hud),
                // Popup de ação (mensagens digitando)
                Positioned.fill(
                  child: ValueListenableBuilder<String?>(
                    valueListenable: game.actionMessage,
                    builder: (context, message, _) {
                      if (message == null) return const SizedBox.shrink();
                      return GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: game.dismissActionMessage,
                        child: Center(
                          child: _popupMensagem(
                            message,
                            game.dismissActionMessage,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Constrói o bloco “Pontuação” com o badge DEFESO imediatamente abaixo.
  Widget _scoreWithDefeso(CrabGame game, {double fontSize = 16}) {
    return ValueListenableBuilder<bool>(
      valueListenable: game.defesoAtivo,
      builder: (context, ativo, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ValueListenableBuilder<int>(
              valueListenable: game.score,
              builder: (context, score, __) =>
                  _infoBox('🎯 Pontuação: $score', fontSize: fontSize),
            ),
            if (ativo)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 2),
                child: _defesoBadge(fontSize: fontSize),
              ),
          ],
        );
      },
    );
  }

  Widget _infoBox(String texto, {double fontSize = 16}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.brown),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          texto,
          softWrap: false,
          maxLines: 1,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: Colors.brown,
          ),
        ),
      ),
    );
  }

  Widget _popupMensagem(String texto, VoidCallback onDismiss) {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        padding: const EdgeInsets.all(18),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.brown, width: 3),
          boxShadow: [
            BoxShadow(
              blurRadius: 6,
              offset: const Offset(4, 4),
              color: Colors.black.withOpacity(0.35),
            ),
          ],
        ),
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.brown,
          ),
        ),
      ),
    );
  }

  Widget _hudIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
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
        tooltip: tooltip,
      ),
    );
  }

  /// Badge DEFESO: retângulo vermelho, levemente menor para harmonizar abaixo da pontuação.
  Widget _defesoBadge({double fontSize = 16}) {
    final fs = (fontSize * 1.25).clamp(15.0, 24.0); // um pouco menor que antes
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFD32F2F).withOpacity(0.98), // vermelho forte
        border: Border.all(color: const Color(0xFFB71C1C), width: 3),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 5,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Text(
        'DEFESO',
        style: TextStyle(
          fontSize: fs,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 1.0,
        ),
      ),
    );

    return AnimatedScale(
      scale: 1.0,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: chip,
      ),
    );
  }
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
    final maxW = MediaQuery.of(context).size.width;
    final btnW = (maxW * 0.75).clamp(220.0, 360.0);
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(horizontal: 20),
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
              textAlign: TextAlign.center,
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
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 24),
            PixelButton(
              label: '🔁 Jogar Novamente',
              width: btnW,
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const TocaGameScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            PixelButton(
              label: '🏠 Voltar ao Início',
              width: btnW,
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

class _StartGateOverlay extends StatelessWidget {
  const _StartGateOverlay(this.game);
  final CrabGame game;

  @override
  Widget build(BuildContext context) {
    final maxW = MediaQuery.of(context).size.width;
    final btnW = (maxW * 0.75).clamp(220.0, 360.0);
    return Container(
      color: Colors.transparent,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.98),
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
                'Pronto para iniciar?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Clique em Iniciar para começar o jogo.\nNo navegador, isso evita travamentos de animação e habilita interações corretamente.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 20),
              PixelButton(
                label: '▶ Iniciar',
                width: btnW,
                onPressed: () async {
                  await game.ensureAudioUnlocked();
                  game.overlays.remove('StartGate');
                  game.startGame();
                  game.resumeEngine();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
