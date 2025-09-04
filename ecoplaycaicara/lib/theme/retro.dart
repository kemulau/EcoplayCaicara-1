import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Earthy, game-oriented base theme. Final colors are refined by ThemeProvider.
final ThemeData retroGameTheme = ThemeData(
  brightness: Brightness.light,
  // Warm parchment-like background for light mode
  scaffoldBackgroundColor: const Color(0xFFF3EEE6),
  primaryColor: const Color(0xFF7A5230), // saddle brown

  textTheme: GoogleFonts.pressStart2pTextTheme().copyWith(
    titleLarge: GoogleFonts.pressStart2p(
      fontSize: 18,
      color: const Color(0xFF523823),
    ),
    bodyMedium: GoogleFonts.pressStart2p(
      fontSize: 12,
      color: const Color(0xFF2B241E),
    ),
  ),

  appBarTheme: AppBarTheme(
    backgroundColor: const Color(0xFF6D4A2F),
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: GoogleFonts.pressStart2p(
      fontSize: 14,
      color: Colors.white,
    ),
    shape: const Border(
      bottom: BorderSide(color: Color(0xFF3F2A1D), width: 4),
    ),
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white.withOpacity(0.95),
    labelStyle: GoogleFonts.pressStart2p(fontSize: 10, color: Color(0xFF3A2C20)),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: Color(0xFF6B4E33), width: 2),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: Color(0xFF6B4E33), width: 2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: Color(0xFFD29B59), width: 2), // sand highlight
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: Colors.red, width: 2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: Colors.redAccent, width: 2),
    ),
  ),

  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFFD29B59);
      return const Color(0xFFB08C6B);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF5E3E27);
      return const Color(0xFF8C6A4C);
    }),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF6D4A2F),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      textStyle: GoogleFonts.pressStart2p(fontSize: 12),
      elevation: 6,
      shadowColor: const Color(0xFF3F2A1D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFF3F2A1D), width: 1),
      ),
    ),
  ),
);
