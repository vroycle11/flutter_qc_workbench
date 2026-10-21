import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:qa_core/qa_core.dart';

/// CLI entry point for Flutter QA Workbench.
Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('project',
        abbr: 'p',
        help: 'Path to the Flutter project to analyze.',
        defaultsTo: '.')
    ..addOption('format',
        abbr: 'f',
        help: 'Output format: text, json, sarif.',
        defaultsTo: 'text',
        allowed: ['text', 'json', 'sarif'])
    ..addOption('output',
        abbr: 'o', help: 'Output file path. Prints to stdout if not set.')
    ..addOption('config',
        abbr: 'c', help: 'Path to flutter_qa_workbench.yaml config file.')
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help.')
    ..addFlag('verbose',
        abbr: 'v', negatable: false, help: 'Verbose output.');

  late final ArgResults results;
  try {
    results = parser.parse(args);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}');
    stderr.writeln();
    _printUsage(parser);
    exit(64);
  }

  if (results.flag('help')) {
    _printUsage(parser);
    exit(0);
  }

  final projectPath = p.absolute(results.option('project')!);
  final format = results.option('format')!;
  final outputPath = results.option('output');
  final verbose = results.flag('verbose');

  // Validate project exists.
  final pubspec = File(p.join(projectPath, 'pubspec.yaml'));
  if (!pubspec.existsSync()) {
    stderr.writeln('Error: No pubspec.yaml found at $projectPath');
    stderr.writeln('Specify a Flutter project with --project <path>');
    exit(1);
  }

  // Load config.
  final config = QaConfig.load(projectPath);

  if (verbose) {
    stderr.writeln('Analyzing: $projectPath');
    stderr.writeln('Format: $format');
  }

  // Run analysis.
  final engine = AnalysisEngine(config: config);
  final scanResult = await engine.analyze(
    projectPath,
    onProgress: verbose
        ? (processed, total) {
            stderr.write('\rProgress: $processed/$total files');
          }
        : null,
  );

  if (verbose) {
    stderr.writeln();
  }

  // Generate report.
  const reporter = ReportGenerator();
  final report = switch (format) {
    'json' => reporter.toJson(scanResult),
    'sarif' => reporter.toSarif(scanResult),
    _ => reporter.toText(scanResult),
  };

  // Output.
  if (outputPath != null) {
    File(outputPath).writeAsStringSync(report);
    if (verbose) {
      stderr.writeln('Report written to: $outputPath');
    }
  } else {
    stdout.write(report);
  }

  // Exit code: 0 = clean, 1 = findings, 2 = errors.
  if (scanResult.errors.isNotEmpty) {
    exit(2);
  } else if (scanResult.findings
      .any((f) => f.severity == Severity.error || f.severity == Severity.critical)) {
    exit(1);
  } else {
    exit(0);
  }
}

void _printUsage(ArgParser parser) {
  stdout.writeln('Flutter QA Workbench CLI');
  stdout.writeln();
  stdout.writeln('Usage: dart run qa_core:cli [options]');
  stdout.writeln();
  stdout.writeln(parser.usage);
}
