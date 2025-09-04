import 'package:flutter/material.dart';
import '../../../widgets/pixel_button.dart';
import '../../../widgets/game_frame.dart';
import 'game.dart';

class TocaStartScreen extends StatelessWidget {
  const TocaStartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const textoEscuro = Color(0xFF3B2C1A); // Marrom escuro para melhor leitura

    return GameScaffold(
      title: 'Toca do Caranguejo',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const GameSectionTitle('Como Jogar'),
            const SizedBox(height: 12),
            Text(
              'Clique nos caranguejos para capturá-los 🎯, mas preste atenção ao tamanho e ao período reprodutivo! 🦀\n\n'
              '❌ Capturar caranguejos em defeso ou muito pequenos gera -20 pontos e mostra uma explicação sobre a importância da preservação.\n\n'
              '✅ Se você respeitar o defeso ou evitar os jovens, recebe +15 pontos e um aviso: “Proteger o ciclo reprodutivo mantém o mangue vivo!” 🌱\n\n'
              '🧹 Ao clicar em objetos de lixo, como latas e sacolas, você ajuda a limpar o mangue e ganha +20 pontos!\n\n'
              '📚 Leia as curiosidades e jogue por 60 segundos ⏱️!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: textoEscuro),
            ),
            const SizedBox(height: 28),
            Center(
              child: PixelButton(
                label: 'Começar Jogo',
                icon: Icons.play_arrow_rounded,
                iconRight: true,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TocaGameScreen()),
                  );
                },
                width: 220,
                height: 56,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
