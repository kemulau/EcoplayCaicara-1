# Acessibilidade

Este documento resume as decisões de acessibilidade adotadas no Ecoplay Caiçara e referências úteis para o TCC.

## Daltonismo (CVD)

Implementação:
- `lib/theme/color_blindness.dart`: enum `ColorVisionType`, matrizes 4x5 (para `ColorFilter.matrix`), utilitários de rótulo e persistência.
- `lib/theme/theme_provider.dart`: expõe `colorBlindnessFilter`, aplicado globalmente em `lib/main.dart` via `ColorFiltered`.

Tipos suportados:
- Normal, Protanopia, Deuteranopia, Tritanopia, Acromatopsia.

Uso:
```dart
context.read<ThemeProvider>().setColorVision(ColorVisionType.deuteranopia);
```

Notas:
- Matrizes são aproximações largamente utilizadas na literatura e na prática. Ver comentários no arquivo para referências.
- O filtro não substitui testes de contraste/legibilidade e uso adequado de ícones/forma/semântica.

## Alto Contraste

Quando `highContrast` está ativo (`ThemeProvider`):
- Ajustamos `background/surface` e `onBackground/onSurface` para pares coerentes preto ↔ branco.
- Mantemos cores de realce (`primary`) adaptadas à legibilidade (ex.: teal/amber mais saturados no escuro).

## Tamanho do Texto

- Controlado por `ThemeProvider.textScale` e aplicado em `MaterialApp.builder` via `MediaQuery(textScaleFactor)`.
- A UI oferece um slider na tela de cadastro (0.9x–1.6x). Evita o uso de `TextStyle.apply(fontSizeFactor)` para não gerar asserts com estilos sem `fontSize` definido.

## Persistência

Preferências guardadas em `SharedPreferences`:
- `a11y.cvd_type`: tipo de daltonismo (string)
- `a11y.high_contrast`: alto contraste (bool)
- `a11y.text_scale`: escala de texto (double)

## Recomendações de Teste

- Testar com pessoas usuárias (formativa) e usar ferramentas de simulação CVD.
- Garantir que informação crítica não dependa exclusivamente de cor.
- Avaliar contraste (WCAG) quando possível.

