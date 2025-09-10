# Ecoplay Caiçara

Aplicativo Flutter focado em educação ambiental com estética de jogo e recursos de acessibilidade. Este README resume as decisões e os componentes principais, incluindo o “livro” com animação de virar página e as fontes acessíveis persistentes na UI.

## Sumário

- Stack e execução
- Moldura/Layouts (`GameScaffold`)
- Livro com animação (curl) e demo
- Acessibilidade: cores, tamanho do texto e fontes
- Estrutura do projeto

## Stack e execução

- Flutter 3.8+
- Provider para estado de tema/acessibilidade
- SharedPreferences para persistência local
- Flame para minijogos

Rodar:
```
cd ecoplaycaicara
flutter pub get
flutter run  # -d chrome|edge|emulator|device
```
Build Web: `flutter build web` (saída em `build/web`).

## Moldura/Layouts

- `lib/widgets/game_frame.dart`: `GameScaffold` organiza as telas com fundo, cabeçalho e painel central.
  - Aceita `panelPadding` para controlar a borda branca interna do painel.
  - O cabeçalho marrom foi ampliado para ocupar ~96% do painel.
- `lib/widgets/pixel_button.dart`: botão estilizado; agora usa `textTheme` para respeitar fontes acessíveis.

## Livro com animação (curl)

- `lib/widgets/curl_book_view.dart`: `CurlBookView` usa `page_flip` para virar páginas com efeito “page curl”.
  - Tap em qualquer lugar: próximo; tap no terço esquerdo: anterior.
  - Mantém gesto de arrastar (drag) horizontal.
  - Parâmetros: `aspectRatio`, `outerPadding` (borda do livro), `pagePadding` (margem interna do papel).
- `lib/widgets/book_view.dart`: versão alternativa leve (`BookView`) com flip 3D simples (sem curl) e `BookTextPage` com rolagem desativada.
- `lib/screens/book_demo.dart`: tela de teste que abre direto (configurada em `lib/main.dart`) mostrando Lorem Ipsum.

Exemplo de uso:
```dart
CurlBookView(
  pages: const [
    Center(child: Text('Capa')),
    BookTextPage('Lorem...'),
    BookTextPage('Lorem...'),
  ],
  aspectRatio: 3/2,
  outerPadding: EdgeInsets.all(2),
  pagePadding: EdgeInsets.fromLTRB(10, 12, 10, 12),
)
```

## Acessibilidade

- Daltonismo (CVD): `lib/theme/color_blindness.dart` + `main.dart` aplicam `ColorFiltered` global. Persistência automática.
- Tamanho de texto: `ThemeProvider.textScale` controla `MediaQuery.textScaleFactor` (slider no cadastro).
- Alto contraste: troca superfícies/textos para preto/branco com contraste elevado.

### Fontes acessíveis (integridade e persistência na UI)

- Fontes registradas (locais, offline):
  - `PressStart2P` (padrão do tema)
  - `OpenDyslexic` (Regular/Bold/Bold-Italic)
  - `ComicSansLdf` (100/300/400/700)
- Seletor na tela de cadastro: “Fonte para Dislexia” — opções: Nenhum, Arial, Comic Sans, OpenDyslexic.
- Persistência: `a11y.font` (compatível com `fonteDislexia`).
- Quando uma fonte acessível é escolhida (ex.: OpenDyslexic), ela é aplicada globalmente:
  - `ThemeData.fontFamily` e todo o `textTheme`.
  - Título da AppBar, botões elevados e rótulos de inputs.
  - Estilos auxiliares (`GameStyles`: tutorial/hint/link).

Arquivos principais:
- `lib/theme/theme_provider.dart`: estado `AccessibilityFont`, persistência e aplicação global da família.
- `lib/screens/cadastro.dart`: integra o dropdown com o `ThemeProvider` (aplica na hora e salva).
- `pubspec.yaml`: registro de todas as famílias em `assets/fonts/`.

## Estrutura

```
ecoplaycaicara/
├─ lib/
│  ├─ main.dart
│  ├─ theme/
│  │  ├─ base_theme.dart
│  │  ├─ theme_provider.dart
│  │  ├─ game_styles.dart
│  │  └─ color_blindness.dart
│  ├─ widgets/
│  │  ├─ game_frame.dart
│  │  ├─ pixel_button.dart
│  │  ├─ book_view.dart
│  │  └─ curl_book_view.dart
│  └─ screens/
│     ├─ cadastro.dart
│     ├─ home.dart
│     ├─ login.dart
│     ├─ book_demo.dart
│     └─ games/toca-do-caranguejo/
│        ├─ start.dart
│        ├─ game.dart
│        └─ flame_game.dart
└─ assets/
   └─ fonts/ (PressStart2P, OpenDyslexic, ComicSansLdf)
```

Observações
- Dependência `google_fonts` foi removida; o app usa apenas fontes locais para rodar bem no Web/offline.
- Para voltar a abrir diretamente na Home, troque a linha `home:` em `lib/main.dart` para `HomeScreen()`.
