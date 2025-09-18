import 'package:flutter/material.dart';
import '../theme/game_chrome.dart';

// Modern game-style button with gradient, hover/press animations, and glow
class PixelButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final double width;
  final double height;
  final IconData? icon;
  final bool iconRight;

  const PixelButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.width = 220,
    this.height = 56,
    this.icon,
    this.iconRight = false,
  });

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chrome = Theme.of(context).extension<GameChrome>();
    final primary = scheme.primary;
    final top = chrome?.buttonGradientTop ?? _tint(primary, 0.18);
    final bottom = chrome?.buttonGradientBottom ?? _shade(primary, 0.20);

    final scale = _isPressed
        ? 0.97
        : (_isHovered ? 1.03 : 1.0);

    final borderColor = _isPressed
        ? bottom
        : (chrome?.buttonBorder ?? _shade(primary, 0.40));
    final onPrimary = scheme.onPrimary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _isPressed ? [bottom, primary] : [top, bottom],
              ),
              borderRadius:
                  BorderRadius.circular(chrome?.buttonRadius ?? 12),
              border: Border.all(color: borderColor, width: 2),
              boxShadow: [
                if (!_isPressed)
                  ...(chrome?.buttonShadow ??
                      [
                        BoxShadow(
                          offset: const Offset(0, 8),
                          blurRadius: 18,
                          color: Colors.black.withOpacity(0.35),
                        )
                      ]),
                // subtle neon edge
                if (_isHovered)
                  BoxShadow(
                    color: primary.withOpacity(0.35),
                    blurRadius: 22,
                    spreadRadius: 1,
                  ),
                BoxShadow(
                  offset: const Offset(0, 1),
                  blurRadius: 0,
                  spreadRadius: 0,
                  color: Colors.white.withOpacity(0.08),
                ),
              ],
            ),
            child: Stack(
              children: [
                // bevel lines (top light, bottom dark) for extra depth
                Positioned(
                  left: 1,
                  right: 1,
                  top: 1,
                  height: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(_isPressed ? 0.08 : 0.18),
                          Colors.white.withOpacity(0.02),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 1,
                  right: 1,
                  bottom: 1,
                  height: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.12),
                          Colors.black.withOpacity(0.28),
                        ],
                      ),
                    ),
                  ),
                ),
                // glossy highlight
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: widget.height * 0.45,
                  child: IgnorePointer(
                    ignoring: true,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(_isPressed ? 0.05 : 0.12),
                            Colors.white.withOpacity(0.02),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // content
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!widget.iconRight && widget.icon != null) ...[
                          Icon(widget.icon, color: onPrimary, size: 18),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            widget.label.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            // Usa o textTheme para respeitar fontes acessíveis (ex.: OpenDyslexic)
                            style: (Theme.of(context).textTheme.labelLarge ?? const TextStyle())
                                .copyWith(
                                  fontSize: 12,
                                  letterSpacing: 1.2,
                                  color: onPrimary,
                                  shadows: [
                                    Shadow(
                                      offset: const Offset(0, 1),
                                      blurRadius: 0,
                                      color: Colors.black54,
                                    ),
                                  ],
                                ),
                          ),
                        ),
                        if (widget.iconRight && widget.icon != null) ...[
                          const SizedBox(width: 8),
                          Icon(widget.icon, color: onPrimary, size: 18),
                        ],
                      ],
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

Color _tint(Color c, double amount) {
  final hsl = HSLColor.fromColor(c);
  final light = (hsl.lightness + amount).clamp(0.0, 1.0);
  return hsl.withLightness(light.toDouble()).toColor();
}

Color _shade(Color c, double amount) {
  final hsl = HSLColor.fromColor(c);
  final light = (hsl.lightness - amount).clamp(0.0, 1.0);
  return hsl.withLightness(light.toDouble()).toColor();
}
