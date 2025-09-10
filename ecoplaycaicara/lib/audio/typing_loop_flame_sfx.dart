import 'dart:async';
import 'package:flame_audio/flame_audio.dart';

/// Helper específico para FlameAudio BGM que reproduz
/// um pequeno trecho em loop (simulação de "typing").
///
/// Observações de compatibilidade com Flame:
/// - Não altera o `audioCache.prefix` global permanentemente; restaura após uso.
/// - Inicializa o BGM apenas uma vez e faz preload do arquivo.
/// - Usa `FlameAudio.bgm` (recomendado para loops longos),
///   controlando o reinício por Timer do segmento desejado.
class TypingLoopFlameSfx {
  TypingLoopFlameSfx({this.volume = 0.25});

  // Usa caminho completo para evitar ambiguidade no Web (Edge/HTMLAudio)
  // e garantir que o AssetSource resolva exatamente a chave do Manifest.
  static const String _assetPath = 'assets/audio/tech-ui-typing-30790.mp3';

  final double volume;
  Timer? _timer;
  bool _initialized = false;
  // Não é mais necessário ajustar o prefixo do cache do Flame,
  // pois usamos o diretório padrão 'assets/'.

  Future<void> unlock() async {
    if (_initialized) return;
    FlameAudio.bgm.initialize();
    await FlameAudio.audioCache.load(_assetPath); // preload para reduzir latência
    _initialized = true;
  }

  Future<void> start({Duration segment = const Duration(seconds: 4)}) async {
    await unlock();
    await FlameAudio.bgm.stop();
    await FlameAudio.bgm.play(_assetPath, volume: volume);

    _timer?.cancel();
    _timer = Timer.periodic(segment, (_) async {
      await FlameAudio.bgm.stop();
      await FlameAudio.bgm.play(_assetPath, volume: volume);
    });
  }

  Future<void> stop() async {
    _timer?.cancel();
    await FlameAudio.bgm.stop();
  }

  Future<void> dispose() async {
    _timer?.cancel();
    await FlameAudio.bgm.stop();
  }
}
