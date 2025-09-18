import 'dart:async' as async;
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

/// Pergaminho com abertura e fechamento, usando 3 frames de sprite.
class ScrollIntro extends PositionComponent with HasGameRef<FlameGame> {
  ScrollIntro({
    required Vector2 position,
    TextPaint? textPaint,
    this.extraTextDelayMs = 500, // atraso após abrir, antes do texto
    this.displayMs = 1600,       // tempo com o texto visível
    this.stepTimeOpen = 0.16,    // velocidade por frame na abertura
    this.stepTimeClose = 0.16,   // velocidade por frame no fechamento
  })  : _externalTextPaint = textPaint,
        super(position: position, anchor: Anchor.center, priority: 900);

  final TextPaint? _externalTextPaint;

  // Timings (iguais para mobile/desktop para manter o "sentir" do mobile)
  final int extraTextDelayMs;
  final int displayMs;
  final double stepTimeOpen;
  final double stepTimeClose;

  // Componentes
  late final SpriteAnimationComponent _anim;
  late final TextComponent _line1;
  late final TextComponent _line2;

  // Estado
  late TextStyle _baseTextStyle;
  final async.Completer<void> _ready = async.Completer<void>();
  bool _loaded = false;

  // Frames
  List<Sprite>? _openFrames;   // [fechado, meio, aberto]
  List<Sprite>? _closeFrames;  // [aberto, meio, fechado]

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

      add(RectangleComponent(
        position: Vector2.zero(),
        size: Vector2(panelW, panelH),
        anchor: Anchor.center,
        paint: Paint()..color = const Color(0xFFF8F3E6),
      ));

      add(RectangleComponent(
        position: Vector2.zero(),
        size: Vector2(panelW, panelH),
        anchor: Anchor.center,
        paint: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..color = const Color(0xFF7A4E2F),
      ));

      _openFrames = null;
      _closeFrames = null;
    }

    _anim = SpriteAnimationComponent()
      ..anchor = Anchor.center
      ..paint = (Paint()..filterQuality = FilterQuality.none)
      ..playing = false
      ..opacity = 0.0;

    // Tamanho responsivo do pergaminho
    final bool isPortrait = gameRef.size.y > gameRef.size.x;
    const double wFracLand = 1.50;
    const double hFracLand = 1.30;
    const double wFracPort = 0.98;
    const double hFracPort = 0.78;

    final double maxW = (isPortrait ? wFracPort : wFracLand) * gameRef.size.x;
    final double maxH = (isPortrait ? hFracPort : hFracLand) * gameRef.size.y;
    final double scaleVal = (maxW / _SRC_W < maxH / _SRC_H)
        ? (maxW / _SRC_W)
        : (maxH / _SRC_H);

    _anim.size = Vector2(_SRC_W * scaleVal, _SRC_H * scaleVal);
    add(_anim);

    // Texto
    const String L1 = 'PERÍODO';
    const String L2 = 'DEFESO';

    final double scaleX = _anim.size.x / _SRC_W;
    final double scaleY = _anim.size.y / _SRC_H;
    final double innerW = (_INNER_W - _PAD_X * 2) * scaleX;
    final double innerH = (_INNER_H - _PAD_Y * 2) * scaleY;

    final double innerCenterX =
        (_INNER_X + _INNER_W / 2 - _SRC_W / 2) * scaleX;
    final double innerCenterY =
        (_INNER_Y + _INNER_H / 2 - _SRC_H / 2) * scaleY;

    Size _measure(String text, double fs) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: 'PressStart2P',
            fontWeight: FontWeight.w900,
            fontSize: fs,
          ),
        ),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout();
      return Size(tp.width, tp.height);
    }

    double fs = (innerH * 0.42).clamp(10.0, 120.0).toDouble();
    while (fs > 8) {
      final Size m1 = _measure(L1, fs);
      final Size m2 = _measure(L2, fs);
      final double gap = fs * _LINE_GAP;
      final double totalH = m1.height + gap + m2.height;
      final bool fitsW = m1.width <= innerW && m2.width <= innerW;
      final bool fitsH = totalH <= innerH;
      if (fitsW && fitsH) break;
      fs -= 1;
    }

    final double extSize = _externalTextPaint?.style.fontSize ?? fs;
    final double finalFs = (extSize > fs ? fs : extSize) * _TEXT_SAFETY;

    _baseTextStyle = (_externalTextPaint?.style ??
        const TextStyle(
          fontFamily: 'PressStart2P',
          fontWeight: FontWeight.w900,
          color: Colors.brown,
          shadows: [
            Shadow(color: Colors.black26, blurRadius: 2, offset: Offset(1, 1)),
          ],
        )).copyWith(fontSize: finalFs);

    _line1 = TextComponent(text: L1, textRenderer: TextPaint(style: _baseTextStyle))
      ..anchor = Anchor.center;
    _line2 = TextComponent(text: L2, textRenderer: TextPaint(style: _baseTextStyle))
      ..anchor = Anchor.center;

    final Size m1 = _measure(L1, finalFs);
    final Size m2 = _measure(L2, finalFs);
    final double gap = finalFs * _LINE_GAP;
    final double totalH = m1.height + gap + m2.height;
    final double half = totalH / 2;

    _line1.position = Vector2(innerCenterX, innerCenterY - half + m1.height / 2);
    _line2.position = Vector2(innerCenterX, innerCenterY + half - m2.height / 2);
    _line1Base = _line1.position.clone();
    _line2Base = _line2.position.clone();

    // Começam invisíveis (alpha=0) para evitar flicker/ghost.
    _setTextOpacityBoth(0.0);

    add(_line1);
    add(_line2);

    // ponto de partida do container (leve zoom-out)
    scale.setValues(0.95, 0.95);

    _loaded = true;
    if (!_ready.isCompleted) _ready.complete();
  }

  Future<void> _playAnim(List<Sprite>? frames, double stepTime) async {
    if (frames == null || frames.isEmpty) return;
    _anim.animation = SpriteAnimation.spriteList(frames, stepTime: stepTime, loop: false);
    _anim.playing = true;
    final totalMs = (frames.length * stepTime * 1000).round();
    await Future<void>.delayed(Duration(milliseconds: totalMs));
  }

  Future<void> play() async {
    if (!_loaded) await _ready.future;

    // Fade-in + micro overshoot no container para “pop” agradável
    final cIn = async.Completer<void>();
    _anim.add(
      OpacityEffect.to(1.0, EffectController(duration: 0.25, curve: Curves.easeOut))
        ..onComplete = () => cIn.complete(),
    );

    add(SequenceEffect([
      ScaleEffect.to(Vector2.all(1.03),
          EffectController(duration: 0.14, curve: Curves.easeOutBack)),
      ScaleEffect.to(Vector2.all(1.00),
          EffectController(duration: 0.12, curve: Curves.easeInOutCubic)),
    ]));
    await cIn.future;

    // Abertura (frames)
    await _playAnim(_openFrames, stepTimeOpen);

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

    if (displayMs > 0) {
      await Future<void>.delayed(Duration(milliseconds: displayMs));
    }

    // Texto sai com fade + slide e é escondido ANTES do fechamento
    await _textOut();

    // Fechamento (frames)
    await _playAnim(_closeFrames, stepTimeClose);

    // Fade-out final do pergaminho
    final out = async.Completer<void>();
    _anim.add(
      OpacityEffect.to(0.0, EffectController(duration: 0.22, curve: Curves.easeIn))
        ..onComplete = () => out.complete(),
    );
    await out.future;

    removeFromParent();
  }

  // ---------- Texto: entrada/saída com efeitos harmônicos ----------
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
    _line1.add(MoveEffect.to(
      _line1Base.clone(),
      EffectController(duration: dIn, curve: Curves.easeOutCubic),
    ));
    _line2.add(MoveEffect.to(
      _line2Base.clone(),
      EffectController(duration: dIn, startDelay: stagger, curve: Curves.easeOutCubic),
    ));

    // Fades (via TextPaint + sombras com alpha)
    futures.add(_fadeTextComp(_line1, to: 1.0, duration: Duration(milliseconds: fadeInMs)));
    futures.add(_fadeTextComp(_line2, to: 1.0,
        duration: Duration(milliseconds: fadeInMs),
        delay: Duration(milliseconds: staggerMs)));

    await Future.wait(futures);
  }

  Future<void> _textOut() async {
    const double dOut = 0.28;
    const double stagger = 0.04;
    const double dy = 10; // sai descendo levemente
    final int fadeOutMs = (dOut * 1000).round();
    final int staggerMs = (stagger * 1000).round();

    final futures = <Future<void>>[];

    _line1.add(MoveEffect.to(
      _line1Base + Vector2(0, dy),
      EffectController(duration: dOut, curve: Curves.easeInCubic),
    ));
    _line2.add(MoveEffect.to(
      _line2Base + Vector2(0, dy),
      EffectController(duration: dOut, startDelay: stagger, curve: Curves.easeInCubic),
    ));

    futures.add(_fadeTextComp(_line1, to: 0.0, duration: Duration(milliseconds: fadeOutMs)));
    futures.add(_fadeTextComp(_line2, to: 0.0,
        duration: Duration(milliseconds: fadeOutMs),
        delay: Duration(milliseconds: staggerMs)));

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
    final double from = (currentStyle.color ?? Colors.white).opacity.clamp(0.0, 1.0);

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

    final Color textColor = baseColor.withOpacity((baseColor.opacity * v).clamp(0.0, 1.0));
    final List<Shadow>? newShadows = baseShadows?.map((s) {
      final double baseOp = s.color.opacity;
      return Shadow(
        color: s.color.withOpacity((baseOp * v).clamp(0.0, 1.0)),
        offset: s.offset,
        blurRadius: s.blurRadius,
      );
    }).toList();

    final style = _baseTextStyle.copyWith(color: textColor, shadows: newShadows);
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
