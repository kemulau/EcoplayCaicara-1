import 'package:flutter/material.dart';
import '../../../widgets/pixel_button.dart';
import '../../../widgets/game_frame.dart';
import 'game.dart' deferred as game;
import 'tutorial.dart' deferred as tutorial;
import '../../../theme/game_styles.dart';

class TocaStartScreen extends StatelessWidget {
  const TocaStartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Toca do Caranguejo',
      backgroundAsset: 'assets/images/background-toca.png',
      mobileBackgroundAsset: 'assets/images/background-toca-mobile.png',
      fill: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth;
          final btnWidth = (maxW * 0.72).clamp(200.0, 320.0);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Escolha uma opção',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                PixelButton(
                  label: 'TUTORIAL',
                  icon: Icons.menu_book_rounded,
                  iconRight: true,
                  width: btnWidth,
                  height: 52,
                  onPressed: () async {
                    await tutorial.loadLibrary();
                    // ignore: use_build_context_synchronously
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => tutorial.TocaTutorialScreen()),
                    );
                  },
                ),
                const SizedBox(height: 6),
                Builder(builder: (context) {
                  final styles = Theme.of(context).extension<GameStyles>();
                  return Text('Aprenda as regras rapidamente', style: styles?.hint);
                }),
                const SizedBox(height: 12),
                PixelButton(
                  label: 'JOGAR',
                  icon: Icons.play_arrow_rounded,
                  iconRight: true,
                  width: btnWidth,
                  height: 52,
                  onPressed: () async {
                    await game.loadLibrary();
                    // ignore: use_build_context_synchronously
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => game.TocaGameScreen()),
                    );
                  },
                ),
                const SizedBox(height: 6),
                Builder(builder: (context) {
                  final styles = Theme.of(context).extension<GameStyles>();
                  return Text('Ir direto para o jogo', style: styles?.hint);
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

