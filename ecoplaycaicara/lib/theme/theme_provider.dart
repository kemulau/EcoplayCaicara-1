import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'color_blindness.dart';
import 'retro.dart';

class ThemeProvider with ChangeNotifier {
  ThemeProvider() {
    loadPreferences();
  }

  // Estado
  bool isDark = false;
  bool highContrast = false;
  bool largeText = false; // legacy toggle for migration
  double textScale = 1.0; // new precise control 0.9..1.6
  ColorVisionType colorVision = ColorVisionType.normal;
  List<ColorVisionType> get availableCvdTypes => ColorVisionType.values;
  AppPalette palette = AppPalette.teal; // default maps to earthy seed below

  // Chaves de persistência
  static const _kDark = 'theme.dark';
  static const _kHighContrast = 'a11y.high_contrast';
  static const _kLargeText = 'a11y.large_text';
  static const _kCvdType = 'a11y.cvd_type';
  static const _kPalette = 'theme.palette';
  static const _kTextScale = 'a11y.text_scale';

  // Carregar preferências
  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    // Migração: usa chaves antigas se as novas não existirem
    isDark = prefs.getBool(_kDark) ?? prefs.getBool('modoEscuro') ?? false;
    highContrast =
        prefs.getBool(_kHighContrast) ?? prefs.getBool('textoAltoContraste') ?? false;
    largeText = prefs.getBool(_kLargeText) ?? prefs.getBool('textoGrande') ?? false;
    textScale = prefs.getDouble(_kTextScale) ?? (largeText ? 1.3 : 1.0);
    colorVision = cvdFromStorage(
      prefs.getString(_kCvdType) ?? prefs.getString('cvdTipo'),
    );
    palette = _paletteFromStorage(prefs.getString(_kPalette));
    final legacyPaletteLabel = prefs.getString('temaPaleta');
    if (legacyPaletteLabel != null) {
      palette = _paletteFromLabel(legacyPaletteLabel);
    }
    notifyListeners();
  }

  // Setters individuais (mais claros e previsíveis)
  Future<void> setDark(bool value) async {
    isDark = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDark, value);
    notifyListeners();
  }

  Future<void> setHighContrast(bool value) async {
    highContrast = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHighContrast, value);
    notifyListeners();
  }

  Future<void> setLargeText(bool value) async {
    largeText = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLargeText, value);
    // keep textScale in sync for legacy toggle
    textScale = value ? 1.3 : 1.0;
    await prefs.setDouble(_kTextScale, textScale);
    notifyListeners();
  }

  Future<void> setTextScale(double value) async {
    // clamp
    final v = value.clamp(0.8, 2.0);
    textScale = v;
    // keep legacy flag in sync for other screens reading it
    largeText = v > 1.05;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kTextScale, textScale);
    await prefs.setBool(_kLargeText, largeText);
    notifyListeners();
  }

  Future<void> setColorVision(ColorVisionType type) async {
    colorVision = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCvdType, cvdToStorage(type));
    notifyListeners();
  }

  Future<void> setPalette(AppPalette value) async {
    palette = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPalette, _paletteToStorage(value));
    notifyListeners();
  }

  /// Filtro de cor global para simulação/correção de daltonismo
  ColorFilter get colorBlindnessFilter => colorFilterFor(colorVision);

  /// Tema do app: compõe o retroGameTheme com ajustes de acessibilidade
  ThemeData get currentTheme {
    final base = retroGameTheme;

    final brightness = isDark ? Brightness.dark : Brightness.light;
    final seed = _seedForPalette(palette);
    var scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);

    if (highContrast) {
      final bg = brightness == Brightness.dark ? Colors.black : Colors.white;
      final onBg = brightness == Brightness.dark ? Colors.white : Colors.black;
      scheme = scheme.copyWith(
        background: bg,
        surface: bg,
        onBackground: onBg,
        onSurface: onBg,
        primary: brightness == Brightness.dark ? Colors.tealAccent : Colors.teal.shade800,
        onPrimary: Colors.black,
      );
    }

    return base.copyWith(
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.background,
      canvasColor: scheme.background,
      inputDecorationTheme: _buildInputDecorationTheme(base, scheme, brightness, highContrast),
      textTheme: base.textTheme.apply(
        // Escala de texto é aplicada via MediaQuery (ver main.dart)
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
    );
  }
}

enum AppPalette { teal, blue, green, amber, purple }

String _paletteToStorage(AppPalette p) => p.name;

AppPalette _paletteFromStorage(String? value) {
  if (value == null) return AppPalette.teal;
  return AppPalette.values.firstWhere(
    (e) => e.name == value,
    orElse: () => AppPalette.teal,
  );
}

Color _seedForPalette(AppPalette p) {
  switch (p) {
    case AppPalette.teal:
      // Use earthy seed as default
      return const Color(0xFF7A5230); // saddle brown
    case AppPalette.blue:
      return Colors.blue;
    case AppPalette.green:
      return const Color(0xFF4F6F52); // moss green
    case AppPalette.amber:
      return const Color(0xFFD29B59); // sand/amber
    case AppPalette.purple:
      return const Color(0xFF6E4E74); // muted plum
  }
}

AppPalette _paletteFromLabel(String label) {
  switch (label) {
    case 'Azul':
      return AppPalette.blue;
    case 'Verde':
      return AppPalette.green;
    case 'Âmbar':
      return AppPalette.amber;
    case 'Roxo':
      return AppPalette.purple;
    case 'Turquesa':
    default:
      return AppPalette.teal;
  }
}

InputDecorationTheme _buildInputDecorationTheme(
  ThemeData base,
  ColorScheme scheme,
  Brightness brightness,
  bool highContrast,
) {
  final baseInput = base.inputDecorationTheme;
  final fill = brightness == Brightness.dark
      ? scheme.surface.withOpacity(highContrast ? 0.18 : 0.12)
      : Colors.white.withOpacity(highContrast ? 1.0 : 0.95);
  final borderColor = highContrast
      ? scheme.onSurface
      : (brightness == Brightness.dark
          ? scheme.outline.withOpacity(0.6)
          : const Color(0xFF6B4226));

  OutlineInputBorder outline(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: c, width: 2),
      );

  return baseInput.copyWith(
    filled: true,
    fillColor: fill,
    labelStyle: baseInput.labelStyle?.copyWith(color: scheme.onSurface) ??
        TextStyle(color: scheme.onSurface, fontSize: 12),
    hintStyle: TextStyle(color: scheme.onSurface.withOpacity(0.7), fontSize: 12),
    border: outline(borderColor),
    enabledBorder: outline(borderColor),
    focusedBorder: outline(scheme.primary),
    errorBorder: outline(Colors.red),
    focusedErrorBorder: outline(Colors.redAccent),
  );
}
