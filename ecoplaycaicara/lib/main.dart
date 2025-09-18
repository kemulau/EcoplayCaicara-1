import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_scroll_behavior.dart';
import 'screens/cadastro.dart';
import 'screens/home.dart';
import 'screens/book_demo.dart';
import 'theme/theme_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const EcoplayCaicaraApp(),
    ),
  );
}

class EcoplayCaicaraApp extends StatelessWidget {
  const EcoplayCaicaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return ColorFiltered(
      colorFilter: themeProvider.colorBlindnessFilter,
      child: MaterialApp(
        title: 'Ecoplay Caiçara',
        debugShowCheckedModeBanner: false,
        theme: themeProvider.currentTheme,
        scrollBehavior: const AppScrollBehavior(),
        builder: (context, child) {
          final scale = themeProvider.textScale;
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(textScaleFactor: scale),
            child: child!,
          );
        },
        home: const HomeScreen(),
      ),
    );
  }
}
