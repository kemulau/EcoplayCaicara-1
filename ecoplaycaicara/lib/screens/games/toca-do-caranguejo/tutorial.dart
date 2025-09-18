import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../widgets/pixel_button.dart';
import '../../../widgets/game_frame.dart';
import '../../../widgets/typing_text.dart';
import '../../../audio/typing_loop_sfx.dart';
import '../../../widgets/link_button.dart';
import '../../../theme/game_styles.dart';
import 'game.dart' deferred as game;

class TocaTutorialScreen extends StatefulWidget {
  const TocaTutorialScreen({super.key});

  @override
  State<TocaTutorialScreen> createState() => _TocaTutorialScreenState();
}

class _TocaTutorialScreenState extends State<TocaTutorialScreen>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<bool> _sfxEnabled = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _typingRunning = ValueNotifier<bool>(false);
  final ValueNotifier<int> _paraIndex = ValueNotifier<int>(0);
  final TypingTextController _typingController = TypingTextController();
  final ValueNotifier<bool> _showScrollHint = ValueNotifier<bool>(false);
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _arrowCtrl;
  late final Animation<Offset> _arrowOffset;
  // SFX
  late final TypingLoopSfx _typingSfx;
  final ValueNotifier<bool> _audioUnlocked = ValueNotifier<bool>(false);
  bool _audioStarted = false;

  @override
  void initState() {
    super.initState();
    _typingSfx = TypingLoopSfx(volume: 0.25);
    _arrowCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
          ..repeat(reverse: true);
    _arrowOffset = Tween<Offset>(begin: Offset.zero, end: const Offset(0, 0.18))
        .animate(CurvedAnimation(parent: _arrowCtrl, curve: Curves.easeInOut));
    _scrollController.addListener(_updateScrollHint);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollHint());
  }

  @override
  void dispose() {
    _sfxEnabled.dispose();
    _typingRunning.dispose();
    _paraIndex.dispose();
    _showScrollHint.dispose();
    _audioUnlocked.dispose();
    _scrollController.removeListener(_updateScrollHint);
    _scrollController.dispose();
    _arrowCtrl.dispose();
    _typingSfx.dispose();
    super.dispose();
  }

  void _updateScrollHint() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final show = max > 10 && _scrollController.position.pixels < max - 10;
    if (_showScrollHint.value != show) _showScrollHint.value = show;
  }

  Future<void> _scrollStepDown() async {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final step = pos.viewportDimension * 0.8;
    final target = (pos.pixels + step).clamp(0.0, pos.maxScrollExtent);
    await _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    _updateScrollHint();
  }

  Future<void> _scrollToBottom() async {
    if (!_scrollController.hasClients) return;
    await _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
    _showScrollHint.value = false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final styles = theme.extension<GameStyles>();

    final List<String> paragraphs = [
      'Clique nos caranguejos para capturá-los 🎯, mas preste atenção ao tamanho e ao período reprodutivo! 🦀',
      '❌ Capturar caranguejos em defeso ou muito pequenos gera -20 pontos e mostra uma explicação sobre a importância da preservação.',
      '✅ Se você respeitar o defeso ou evitar os jovens, recebe +15 pontos e um aviso: “Proteger o ciclo reprodutivo mantém o mangue vivo!” 🌱',
      '🧹 Ao clicar em objetos de lixo, como latas e sacolas, você ajuda a limpar o mangue e ganha +20 pontos!',
      '📚 Leia as curiosidades e jogue por 60 segundos ⏱️!',
    ];

    final listenAll = Listenable.merge([
      _typingRunning,
      _paraIndex,
      _sfxEnabled,
      _showScrollHint,
    ]);

    return GameScaffold(
      title: 'Toca do Caranguejo',
      backgroundAsset: 'assets/games/toca-do-caranguejo/background.png',
      mobileBackgroundAsset: 'assets/games/toca-do-caranguejo/background-mobile.png',
      fill: false,
      child: Listener(
        onPointerDown: (_) async {
          final firstUnlock = !_audioUnlocked.value;
          if (firstUnlock) {
            _audioUnlocked.value = true;
            await _typingSfx.unlock();
            // Se já estiver digitando, inicia o loop imediatamente na 1ª interação
            if (_typingRunning.value && _sfxEnabled.value && !_audioStarted) {
              await _typingSfx.start(segment: const Duration(seconds: 4));
              _audioStarted = true;
            }
            return; // não pular na 1ª interação (desbloqueio)
          }
          if (_typingRunning.value) _typingController.skip();
        },
        child: Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.space ||
                  event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.arrowRight) {
                if (_typingRunning.value) {
                  _typingController.skip();
                  return KeyEventResult.handled;
                }
              }
            }
            return KeyEventResult.ignored;
          },
          child: AnimatedBuilder(
            animation: listenAll,
            builder: (context, _) => Stack(
              children: [
                SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const GameSectionTitle('Como Jogar'),
                          const Spacer(),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              border: Border.all(color: Colors.brown),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: IconButton(
                              tooltip: 'Som do Texto',
                              icon: Icon(
                                _sfxEnabled.value
                                    ? Icons.volume_up_rounded
                                    : Icons.volume_off_rounded,
                                color: Colors.brown,
                              ),
                              onPressed: () async {
                                _sfxEnabled.value = !_sfxEnabled.value;
                                if (!_sfxEnabled.value && _audioStarted) {
                                  await _typingSfx.stop();
                                  _audioStarted = false;
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_paraIndex.value > 0) ...[
                        for (int i = 0; i < _paraIndex.value; i++) ...[
                          Text(
                            paragraphs[i],
                            textAlign: TextAlign.center,
                            style: styles?.tutorialBody,
                          ),
                          const SizedBox(height: 8),
                        ]
                      ],
                      _TypingParagraph(
                        text: paragraphs[_paraIndex.value],
                        controller: _typingController,
                        enableSound: _sfxEnabled.value,
                        showSkipAll:
                            _paraIndex.value < paragraphs.length - 1,
                        onStart: () {
                          _typingRunning.value = true;
                          if (_sfxEnabled.value && _audioUnlocked.value && !_audioStarted) {
                            _typingSfx.start(segment: const Duration(seconds: 4));
                            _audioStarted = true;
                          }
                        },
                        onFinished: () {
                          _typingRunning.value = false;
                          if (_audioStarted) {
                            _typingSfx.stop();
                            _audioStarted = false;
                          }
                          if (_paraIndex.value >= paragraphs.length - 1) {
                            _scrollToBottom();
                          }
                        },
                        onSkipAll: () {
                          _typingRunning.value = false;
                          _paraIndex.value = paragraphs.length - 1;
                          _scrollToBottom();
                          if (_audioStarted) {
                            _typingSfx.stop();
                            _audioStarted = false;
                          }
                        },
                      ),
                      if (!_typingRunning.value)
                        Center(
                          child: (_paraIndex.value < paragraphs.length - 1)
                              ? PixelButton(
                                  label: 'Continuar',
                                  icon: Icons.navigate_next_rounded,
                                  iconRight: true,
                                  width: 200,
                                  height: 48,
                                  onPressed: () async {
                                    _paraIndex.value++;
                                  },
                                )
                              : PixelButton(
                                  label: 'Começar Jogo',
                                  icon: Icons.play_arrow_rounded,
                                  iconRight: true,
                                  onPressed: () async {
                                    await game.loadLibrary();
                                    // ignore: use_build_context_synchronously
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => game.TocaGameScreen()),
                                    );
                                  },
                                  width: 220,
                                  height: 56,
                                ),
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 6,
                  left: 0,
                  right: 0,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _showScrollHint,
                    builder: (context, show, _) => AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity: show ? 1 : 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: _scrollStepDown,
                          child: SlideTransition(
                            position: _arrowOffset,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.85),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                  )
                                ],
                              ),
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.95),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingParagraph extends StatefulWidget {
  const _TypingParagraph({
    required this.text,
    required this.onStart,
    required this.onFinished,
    required this.onSkipAll,
    this.controller,
    this.showSkipAll = true,
    this.enableSound = true,
  });
  final String text;
  final VoidCallback onStart;
  final VoidCallback onFinished;
  final VoidCallback onSkipAll;
  final TypingTextController? controller;
  final bool showSkipAll;
  final bool enableSound;

  @override
  State<_TypingParagraph> createState() => _TypingParagraphState();
}

class _TypingParagraphState extends State<_TypingParagraph> {
  final TypingTextController _controller = TypingTextController();

  @override
  Widget build(BuildContext context) {
    final styles = Theme.of(context).extension<GameStyles>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TypingText(
          key: ValueKey<bool>(widget.enableSound),
          controller: widget.controller ?? _controller,
          showSkipButton: false,
          text: widget.text,
          charDelay: const Duration(milliseconds: 45),
          clickEvery: 2,
          enableSound: widget.enableSound,
          // Garantir o mesmo tamanho do texto padrão do tutorial
          style: styles?.tutorialBody,
          onStart: widget.onStart,
          onFinished: widget.onFinished,
        ),
        if (widget.showSkipAll) ...[
          const SizedBox(height: 4),
          LinkButton(label: 'Pular', onPressed: widget.onSkipAll),
        ],
      ],
    );
  }
}

