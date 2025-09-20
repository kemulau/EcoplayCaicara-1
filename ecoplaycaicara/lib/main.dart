import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_scroll_behavior.dart';
import 'screens/home.dart';
import 'theme/theme_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
    debugPrintStack(stackTrace: details.stack);
  };

  WidgetsBinding.instance.platformDispatcher.onError = (
    Object error,
    StackTrace stack,
  ) {
    debugPrint('PlatformDispatcher error: ${error.runtimeType} - $error');
    debugPrintStack(stackTrace: stack);
    return true;
  };

  runZonedGuarded<void>(() {
    runApp(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const EcoplayCaicaraApp(),
      ),
    );
  }, (Object error, StackTrace stack) {
    debugPrint('Uncaught zone error: ${error.runtimeType} - $error');
    debugPrintStack(stackTrace: stack);
  });
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
