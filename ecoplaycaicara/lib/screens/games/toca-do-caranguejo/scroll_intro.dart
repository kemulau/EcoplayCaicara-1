import 'dart:async' as async;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

/// Pergaminho com abertura e fechamento, usando 3 frames de sprite.
class ScrollIntro extends PositionComponent
    with HasGameRef<FlameGame>, TapCallbacks {
  ScrollIntro({
    required Vector2 position,
    TextPaint? textPaint,
    this.extraTextDelayMs = 700, // atraso após abrir, antes do texto
    this.displayMs = 1600, // tempo com o texto visível
    this.stepTimeOpen = 0.16, // velocidade por frame na abertura
    this.stepTimeClose = 0.16, // velocidade por frame no fechamento
    this.animated = true,
    this.dismissOnTap = false,
  }) : _externalTextPaint = textPaint,
       super(position: position, anchor: Anchor.center, priority: 900);
  final TextPaint? _externalTextPaint;
  // Timings (iguais para mobile/desktop para manter o "sentir" do mobile)
  final int extraTextDelayMs;
  final int displayMs;
  final double stepTimeOpen;
  final double stepTimeClose;
  final bool animated;
  final bool dismissOnTap;
  // Componentes
  late final SpriteAnimationComponent _anim;
  late final TextComponent _line1;
  late final TextComponent _line2;
  // Estado
  late TextStyle _baseTextStyle;
  final async.Completer<void> _ready = async.Completer<void>();
  bool _loaded = false;
  // Frames
  List<Sprite>? _openFrames; // [fechado, meio, aberto]
  List<Sprite>? _closeFrames; // [aberto, meio, fechado]
  async.Completer<void>? _tapCompleter;
  // Posições base do texto (para animações)
  late Vector2 _line1Base;
  late Vector2 _line2Base;
  // Medidas do sprite original
  static const double _SRC_W = 1920.0;
  static const double _SRC_H = 1080.0;
  // Área clara interna (no PNG original)
  static const double _INNER_X = 632.0;
  static const double _INNER_Y = 324.0;
  static const double _INNER_W = 716.0;
  static const double _INNER_H = 387.0;
  static const double _PAD_X = 44.0;
  static const double _PAD_Y = 28.0;
  static const double _TEXT_SAFETY = 0.65;
  static const double _LINE_GAP = 0.20;
  static const String _lineText1 = 'PERÍODO';
  static const String _lineText2 = 'DEFESO';
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    Future<Sprite?> _tryLoad(String path) async {
      try {
        return await gameRef.loadSprite(path);
      } catch (_) {
        // ignore: avoid_print
        print('ScrollIntro: não encontrou "$path".');
        return null;
      }
    }

    Future<Sprite?> _loadPerg(String name) =>
        _tryLoad('games/toca-do-caranguejo/$name');
    final s1 = await _loadPerg('pergaminho-fechado-1.png');
    final s2 = await _loadPerg('pergaminho-entreaberto-2.png');
    final s3 = await _loadPerg('pergaminho-aberto-3.png');
    if (s1 != null && s2 != null && s3 != null) {
      _openFrames = [s1, s2, s3];
      _closeFrames = [s3, s2, s1];
    } else {
      // Fallback simples
      final panelW = (gameRef.size.x * 0.70).clamp(320, 900).toDouble();
      final panelH = (gameRef.size.y * 0.42).clamp(220, 620).toDouble();
      add(
        RectangleComponent(
          position: Vector2.zero(),
          size: Vector2(panelW, panelH),
          anchor: Anchor.center,
          paint: Paint()..color = const Color(0xFFF8F3E6),
        ),
      );
      add(
        RectangleComponent(
          position: Vector2.zero(),
          size: Vector2(panelW, panelH),
          anchor: Anchor.center,
          paint: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6
            ..color = const Color(0xFF7A4E2F),
        ),
      );
      _openFrames = null;
      _closeFrames = null;
    }
    _anim = SpriteAnimationComponent()
      ..anchor = Anchor.center
      ..paint = (Paint()..filterQuality = FilterQuality.none)
      ..playing = false
      ..opacity = 0.0;
    add(_anim);
    final TextStyle baseStyle =
        _externalTextPaint?.style ??
        const TextStyle(
          fontFamily: 'PressStart2P',
          fontWeight: FontWeight.w900,
          color: Colors.brown,
          shadows: [
            Shadow(color: Colors.black26, blurRadius: 2, offset: Offset(1, 1)),
          ],
        );
    _baseTextStyle = baseStyle;
    _line1 = TextComponent(
      text: _lineText1,
      textRenderer: TextPaint(style: baseStyle),
    )..anchor = Anchor.center;
    _line2 = TextComponent(
      text: _lineText2,
      textRenderer: TextPaint(style: baseStyle),
    )..anchor = Anchor.center;
    add(_line1);
    add(_line2);
    _setTextOpacityBoth(0.0);
    _updateLayout(gameRef.size);
    // Mantém invisível até a sprite do pergaminho abrir.
    _setTextOpacityBoth(0.0);
    // Ponto de partida do container (leve zoom-out)
    scale.setValues(0.95, 0.95);
    _loaded = true;
    if (!_ready.isCompleted) {
      _ready.complete();
    }
  }

  void _updateLayout(Vector2 viewSize) {
    if (viewSize.x <= 0 || viewSize.y <= 0) {
      return;
    }
    position = viewSize / 2;
    final bool isPortrait = viewSize.y > viewSize.x;
    const double wFracLand = 1.50;
    const double hFracLand = 1.30;
    const double wFracPort = 0.98;
    const double hFracPort = 0.78;
    final double maxW = (isPortrait ? wFracPort : wFracLand) * viewSize.x;
    final double maxH = (isPortrait ? hFracPort : hFracLand) * viewSize.y;
    final double scaleVal = (maxW / _SRC_W < maxH / _SRC_H)
        ? (maxW / _SRC_W)
        : (maxH / _SRC_H);
    final Vector2 animSize = Vector2(_SRC_W * scaleVal, _SRC_H * scaleVal);
    final Vector2 origin = animSize / 2;
    _anim
      ..size = animSize
      ..position = origin;
    size = animSize.clone();
    final double scaleX = animSize.x / _SRC_W;
    final double scaleY = animSize.y / _SRC_H;
    final double innerW = (_INNER_W - _PAD_X * 2) * scaleX;
    final double innerH = (_INNER_H - _PAD_Y * 2) * scaleY;
    final double innerCenterX =
        origin.x + (_INNER_X + _INNER_W / 2 - _SRC_W / 2) * scaleX;
    final double innerCenterY =
        origin.y + (_INNER_Y + _INNER_H / 2 - _SRC_H / 2) * scaleY;
    TextStyle measureStyle(double fontSize) =>
        (_externalTextPaint?.style ??
                const TextStyle(
                  fontFamily: 'PressStart2P',
                  fontWeight: FontWeight.w900,
                ))
            .copyWith(fontSize: fontSize);
    Size measure(String text, double fontSize) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: measureStyle(fontSize)),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout();
      return Size(painter.width, painter.height);
    }

    double fs = (innerH * 0.42).clamp(10.0, 120.0);
    while (fs > 8) {
      final Size m1 = measure(_lineText1, fs);
      final Size m2 = measure(_lineText2, fs);
      final double gap = fs * _LINE_GAP;
      final double totalH = m1.height + gap + m2.height;
      final bool fitsW = m1.width <= innerW && m2.width <= innerW;
      final bool fitsH = totalH <= innerH;
      if (fitsW && fitsH) {
        break;
      }
      fs -= 1;
    }
    final double extSize = _externalTextPaint?.style.fontSize ?? fs;
    final double finalFs = (extSize > fs ? fs : extSize) * _TEXT_SAFETY;
    _baseTextStyle =
        (_externalTextPaint?.style ??
                const TextStyle(
                  fontFamily: 'PressStart2P',
                  fontWeight: FontWeight.w900,
                  color: Colors.brown,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 2,
                      offset: Offset(1, 1),
                    ),
                  ],
                ))
            .copyWith(fontSize: finalFs);
    _line1.textRenderer = TextPaint(style: _baseTextStyle);
    _line2.textRenderer = TextPaint(style: _baseTextStyle);
    final Size m1 = measure(_lineText1, finalFs);
    final Size m2 = measure(_lineText2, finalFs);
    final double gap = finalFs * _LINE_GAP;
    final double totalH = m1.height + gap + m2.height;
    final double half = totalH / 2;
    _line1Base = Vector2(innerCenterX, innerCenterY - half + m1.height / 2);
    _line2Base = Vector2(innerCenterX, innerCenterY + half - m2.height / 2);
    _line1.position = _line1Base.clone();
    _line2.position = _line2Base.clone();
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);
    if (_loaded) {
      _updateLayout(newSize);
    }
  }

  Future<void> _playAnim(List<Sprite>? frames, double stepTime) async {
    if (frames == null || frames.isEmpty) return;
    _anim.animation = SpriteAnimation.spriteList(
      frames,
      stepTime: stepTime,
      loop: false,
    );
    _anim.playing = true;
    final totalMs = (frames.length * stepTime * 1000).round();
    await Future<void>.delayed(Duration(milliseconds: totalMs));
  }

  Future<void> play() async {
    if (!_loaded) await _ready.future;

    add(
      SequenceEffect([
        ScaleEffect.to(
          Vector2.all(1.03),
          EffectController(duration: 0.14, curve: Curves.easeOutBack),
        ),
        ScaleEffect.to(
          Vector2.all(1.00),
          EffectController(duration: 0.12, curve: Curves.easeInOutCubic),
        ),
      ]),
    );

    _anim.opacity = 0.0;

    await _playAnim(_openFrames, stepTimeOpen);

    final fadeIn = async.Completer<void>();
    _anim.add(
      OpacityEffect.to(
        1.0,
        EffectController(duration: 0.26, curve: Curves.easeOut),
      )..onComplete = () => fadeIn.complete(),
    );
    await fadeIn.future;

    // Garantia: texto ainda oculto após a abertura
    _setTextOpacityBoth(0.0);

    // Espera breve antes do texto (sincronizado com o fim da abertura)
    if (extraTextDelayMs > 0) {
      await Future<void>.delayed(Duration(milliseconds: extraTextDelayMs));
    }
    // Texto entra com fade + slide, linhas em leve stagger
    await _textIn();
    // Respiração sutil do pergaminho enquanto o texto fica visível
    final breatheDur = (displayMs / 1000.0).clamp(0.3, 3.0).toDouble();
    final breathe = MoveEffect.by(
      Vector2(0, -6),
      EffectController(
        duration: breatheDur / 2,
        alternate: true,
        curve: Curves.easeInOut,
      ),
    );
    _anim.add(breathe);
    Future<void>? wait;
    if (dismissOnTap) {
      wait = _waitForTapOrTimeout(duration: displayMs);
    } else if (displayMs > 0) {
      wait = Future<void>.delayed(Duration(milliseconds: displayMs));
    }
    if (wait != null) {
      await wait;
    }
    // Texto sai com fade + slide e é escondido ANTES do fechamento
    await _textOut();
    // Fechamento (frames)
    await _playAnim(_closeFrames, stepTimeClose);
    // Fade-out final do pergaminho
    final out = async.Completer<void>();
    _anim.add(
      OpacityEffect.to(
        0.0,
        EffectController(duration: 0.22, curve: Curves.easeIn),
      )..onComplete = () => out.complete(),
    );
    await out.future;
    removeFromParent();
  }

  // ---------- Texto: entrada/saída com efeitos harmônicos ----------
  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    if (!dismissOnTap) {
      return;
    }
    if (_tapCompleter != null && !_tapCompleter!.isCompleted) {
      _tapCompleter!.complete();
    }
  }

  void registerTap() {
    final completer = _tapCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  Future<void> _waitForTapOrTimeout({int? duration}) async {
    if (!dismissOnTap) {
      if (duration != null && duration > 0) {
        await Future<void>.delayed(Duration(milliseconds: duration));
      }
      return;
    }
    _tapCompleter = async.Completer<void>();
    Future<void>? timeout;
    if (duration != null && duration > 0) {
      timeout = Future<void>.delayed(Duration(milliseconds: duration));
    }
    if (timeout != null) {
      await Future.any([_tapCompleter!.future, timeout]);
    } else {
      await _tapCompleter!.future;
    }
    _tapCompleter = null;
  }

  Future<void> _textIn() async {
    // ponto inicial levemente abaixo + transparente
    const double dy1 = 10;
    const double dy2 = 14;
    _line1.position = _line1Base + Vector2(0, dy1);
    _line2.position = _line2Base + Vector2(0, dy2);
    _setTextOpacityBoth(0.0);
    const double dIn = 0.20;
    const double stagger = 0.05;
    final int fadeInMs = (dIn * 1000).round();
    final int staggerMs = (stagger * 1000).round();
    final futures = <Future<void>>[];
    // Movimentos (easeOutCubic dá um “assentar” gostoso)
    _line1.add(
      MoveEffect.to(
        _line1Base.clone(),
        EffectController(duration: dIn, curve: Curves.easeOutCubic),
      ),
    );
    _line2.add(
      MoveEffect.to(
        _line2Base.clone(),
        EffectController(
          duration: dIn,
          startDelay: stagger,
          curve: Curves.easeOutCubic,
        ),
      ),
    );
    // Fades (via TextPaint + sombras com alpha)
    futures.add(
      _fadeTextComp(
        _line1,
        to: 1.0,
        duration: Duration(milliseconds: fadeInMs),
      ),
    );
    futures.add(
      _fadeTextComp(
        _line2,
        to: 1.0,
        duration: Duration(milliseconds: fadeInMs),
        delay: Duration(milliseconds: staggerMs),
      ),
    );
    await Future.wait(futures);
  }

  Future<void> _textOut() async {
    const double dOut = 0.28;
    const double stagger = 0.04;
    const double dy = 10; // sai descendo levemente
    final int fadeOutMs = (dOut * 1000).round();
    final int staggerMs = (stagger * 1000).round();
    final futures = <Future<void>>[];
    _line1.add(
      MoveEffect.to(
        _line1Base + Vector2(0, dy),
        EffectController(duration: dOut, curve: Curves.easeInCubic),
      ),
    );
    _line2.add(
      MoveEffect.to(
        _line2Base + Vector2(0, dy),
        EffectController(
          duration: dOut,
          startDelay: stagger,
          curve: Curves.easeInCubic,
        ),
      ),
    );
    futures.add(
      _fadeTextComp(
        _line1,
        to: 0.0,
        duration: Duration(milliseconds: fadeOutMs),
      ),
    );
    futures.add(
      _fadeTextComp(
        _line2,
        to: 0.0,
        duration: Duration(milliseconds: fadeOutMs),
        delay: Duration(milliseconds: staggerMs),
      ),
    );
    await Future.wait(futures);
    // Segurança extra: garante que nada do texto renderize após o fade.
    _line1.removeFromParent();
    _line2.removeFromParent();
  }

  // ---------- Utilitários de fade para TextComponent (Flame 1.18) ----------
  Future<void> _fadeTextComp(
    TextComponent comp, {
    required double to,
    required Duration duration,
    Duration? delay,
  }) async {
    if (delay != null && delay.inMilliseconds > 0) {
      await Future<void>.delayed(delay);
    }
    // Opacidade inicial a partir do renderer atual
    final currentStyle = (comp.textRenderer as TextPaint).style;
    final double from = (currentStyle.color ?? Colors.white).opacity.clamp(
      0.0,
      1.0,
    );
    if (duration.inMilliseconds <= 0) {
      _applyOpacity(comp, to);
      return;
    }
    final int steps = (duration.inMilliseconds / 16).ceil().clamp(1, 6000);
    int i = 0;
    final c = async.Completer<void>();
    final timer = async.Timer.periodic(const Duration(milliseconds: 16), (t) {
      i++;
      final p = (i / steps).clamp(0.0, 1.0);
      final v = from + (to - from) * p;
      _applyOpacity(comp, v);
      if (p >= 1.0) {
        t.cancel();
        if (!c.isCompleted) c.complete();
      }
    });
    await c.future;
    timer.cancel();
  }

  void _applyOpacity(TextComponent comp, double v) {
    // Aplica alpha tanto na cor do texto quanto nas sombras (para não “sobrar” fantasma)
    final baseColor = _baseTextStyle.color ?? Colors.white;
    final List<Shadow>? baseShadows = _baseTextStyle.shadows;
    final Color textColor = baseColor.withOpacity(
      (baseColor.opacity * v).clamp(0.0, 1.0),
    );
    final List<Shadow>? newShadows = baseShadows?.map((s) {
      final double baseOp = s.color.opacity;
      return Shadow(
        color: s.color.withOpacity((baseOp * v).clamp(0.0, 1.0)),
        offset: s.offset,
        blurRadius: s.blurRadius,
      );
    }).toList();
    final style = _baseTextStyle.copyWith(
      color: textColor,
      shadows: newShadows,
    );
    comp.textRenderer = TextPaint(style: style);
  }

  void _setTextOpacityBoth(double v) {
    _applyOpacity(_line1, v);
    _applyOpacity(_line2, v);
  }

  @override
  void onRemove() {
    // Fades usam timers aguardados via Future; nada pendente aqui.
    super.onRemove();
  }
}
