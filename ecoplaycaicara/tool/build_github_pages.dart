import 'dart:convert';
import 'dart:io';

/// Builds the Flutter web bundle directly into the repo-level `docs/` folder
/// configured for GitHub Pages. Ensures the HTML renderer is used so plugins
/// that depend on `dart:html` keep working.
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
  final buildArgs = [
    'build',
    'web',
    '--release',
    '--web-renderer',
    'html',
    '--base-href',
    '/ecoplaycaicara/',
    '--output',
    docsPath,
  ];

  var buildResult = await _run('flutter', buildArgs, captureOutput: true);
  if (buildResult.exitCode != 0) {
    final combinedOutput = '${buildResult.stdout ?? ''}\n${buildResult.stderr ?? ''}';
    if (combinedOutput.contains('--web-renderer')) {
      stdout.writeln('Falling back to FLUTTER_WEB_RENDERER=html for older Flutter.');
      final fallbackArgs = [
        'build',
        'web',
        '--release',
        '--base-href',
        '/ecoplaycaicara/',
        '--output',
        docsPath,
      ];
      buildResult = await _run(
        'flutter',
        fallbackArgs,
        environment: {'FLUTTER_WEB_RENDERER': 'html'},
      );
    }

    if (buildResult.exitCode != 0) {
      exitCode = buildResult.exitCode;
      return;
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
  _RunResult(this.exitCode, this.stdout, this.stderr);

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
