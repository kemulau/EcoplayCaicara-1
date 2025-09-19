import 'dart:convert';
import 'dart:io';

/// Builds the Flutter web bundle directly into the repo-level `docs/` folder
/// configured for GitHub Pages. Forces the HTML renderer, which is the only
/// option with full support across Safari, Edge e Chrome for this project.
Future<void> main(List<String> args) async {
  if (!File('pubspec.yaml').existsSync()) {
    stderr.writeln('Run this script from the Flutter project root.');
    exitCode = 64;
    return;
  }

  final docsDir = Directory('../docs');
  final docsPath = docsDir.absolute.path;

  stdout.writeln('Running flutter pub get...');
  final pubGet = await _run('flutter', ['pub', 'get']);
  if (pubGet.exitCode != 0) {
    exitCode = pubGet.exitCode;
    return;
  }

  if (!docsDir.existsSync()) {
    docsDir.createSync(recursive: true);
  }

  stdout.writeln(
    'Building flutter web (renderer: html, base href: /ecoplaycaicara/) into docs/...',
  );
  final commonArgs = [
    'build',
    'web',
    '--release',
    '--base-href',
    '/ecoplaycaicara/',
    '--output',
    docsPath,
  ];
  final rendererArgs = [...commonArgs, '--web-renderer', 'html'];

  var buildResult = await _run('flutter', rendererArgs, captureOutput: true);
  if (buildResult.exitCode != 0) {
    final combined = '${buildResult.stdout ?? ''}\n${buildResult.stderr ?? ''}';
    if (combined.contains('--web-renderer')) {
      stdout.writeln(
        'Falling back to legacy renderer flags (FLUTTER_WEB_USE_SKIA=false).',
      );
      buildResult = await _run(
        'flutter',
        [...commonArgs, '--dart-define=FLUTTER_WEB_USE_SKIA=false'],
        environment: {
          'FLUTTER_WEB_RENDERER': 'html',
          'FLUTTER_WEB_USE_SKIA': 'false',
        },
        captureOutput: true,
      );
    }

    if (buildResult.exitCode != 0) {
      exitCode = buildResult.exitCode;
      return;
    }
  }

  final bootstrapPath =
      File('${docsDir.absolute.path}${Platform.pathSeparator}flutter_bootstrap.js');
  if (bootstrapPath.existsSync()) {
    final bootstrap = bootstrapPath.readAsStringSync();
    const target =
        '{"compileTarget":"dart2js","renderer":"canvaskit","mainJsPath":"main.dart.js"}';
    if (bootstrap.contains(target)) {
      stdout.writeln('Tweaking flutter_bootstrap.js to pin renderer=html.');
      final patched = bootstrap.replaceFirst(
        target,
        '{"compileTarget":"dart2js","renderer":"html","mainJsPath":"main.dart.js"}',
      );
      bootstrapPath.writeAsStringSync(patched);
    }
  }

  final noJekyllPath =
      File('${docsDir.absolute.path}${Platform.pathSeparator}.nojekyll');
  if (!noJekyllPath.existsSync()) {
    noJekyllPath.createSync(recursive: true);
  }

  stdout.writeln('Web bundle ready in ${docsDir.absolute.path}');
  stdout.writeln('Commit the docs/ folder and push to GitHub to update Pages.');
}

class _RunResult {
  const _RunResult(this.exitCode, this.stdout, this.stderr);

  final int exitCode;
  final String? stdout;
  final String? stderr;
}

Future<_RunResult> _run(
  String executable,
  List<String> args, {
  Map<String, String>? environment,
  bool captureOutput = false,
}) async {
  final process = await Process.start(
    executable,
    args,
    runInShell: true,
    environment: environment,
  );

  final stdoutBuffer = captureOutput ? StringBuffer() : null;
  final stderrBuffer = captureOutput ? StringBuffer() : null;

  final stdoutFuture = process.stdout.transform(utf8.decoder).listen((data) {
    stdout.write(data);
    stdoutBuffer?.write(data);
  }).asFuture<void>();

  final stderrFuture = process.stderr.transform(utf8.decoder).listen((data) {
    stderr.write(data);
    stderrBuffer?.write(data);
  }).asFuture<void>();

  await Future.wait([stdoutFuture, stderrFuture]);
  final code = await process.exitCode;

  return _RunResult(
    code,
    stdoutBuffer?.toString(),
    stderrBuffer?.toString(),
  );
}
