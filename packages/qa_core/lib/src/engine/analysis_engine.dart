import 'dart:io';

import 'package:path/path.dart' as p;

import '../config/qa_config.dart';
import '../models/finding.dart';
import '../models/scan_result.dart';
import '../rules/rule_registry.dart';

/// The main analysis engine that orchestrates scanning of Flutter projects.
class AnalysisEngine {
  AnalysisEngine({
    QaConfig? config,
    RuleRegistry? registry,
  })  : _config = config ?? const QaConfig(),
        _registry = registry ?? RuleRegistry.instance;

  final QaConfig _config;
  final RuleRegistry _registry;

  /// Whether a scan is currently in progress.
  bool get isScanning => _scanning;
  bool _scanning = false;

  /// Cancel a running scan.
  void cancel() => _cancelled = true;
  bool _cancelled = false;

  /// Analyze a Flutter project at [projectRoot].
  ///
  /// [onProgress] is called with (filesProcessed, totalFiles).
  /// Returns the complete scan result.
  Future<ScanResult> analyze(
    String projectRoot, {
    void Function(int processed, int total)? onProgress,
  }) async {
    _scanning = true;
    _cancelled = false;

    final stopwatch = Stopwatch()..start();
    final findings = <Finding>[];
    final errors = <String>[];

    try {
      // Discover Dart files.
      final dartFiles = _discoverDartFiles(projectRoot);
      final enabledRules = _registry.rules
          .where((r) => _config.isRuleEnabled(r.metadata.id))
          .toList();

      var processed = 0;

      for (final file in dartFiles) {
        if (_cancelled) break;

        try {
          final content = File(file).readAsStringSync();

          for (final rule in enabledRules) {
            if (_cancelled) break;

            try {
              final ruleFindings = rule.analyze(file, content, _config);

              // Filter suppressed findings.
              for (final finding in ruleFindings) {
                if (!_config.isSuppressed(
                  finding.ruleId,
                  finding.location.filePath,
                  finding.location.line,
                )) {
                  findings.add(finding);
                }
              }
            } catch (e) {
              errors.add(
                'Rule ${rule.metadata.id} failed on $file: $e',
              );
            }
          }
        } catch (e) {
          errors.add('Failed to read $file: $e');
        }

        processed++;
        onProgress?.call(processed, dartFiles.length);
      }

      stopwatch.stop();

      return ScanResult(
        findings: findings,
        filesAnalyzed: processed,
        rulesApplied: enabledRules.length,
        duration: stopwatch.elapsed,
        timestamp: DateTime.now(),
        workspaceRoot: projectRoot,
        cancelled: _cancelled,
        errors: errors,
      );
    } finally {
      _scanning = false;
      _cancelled = false;
    }
  }

  /// Discover all `.dart` files in the project, respecting exclusions.
  List<String> _discoverDartFiles(String projectRoot) {
    final libDir = Directory(p.join(projectRoot, 'lib'));
    if (!libDir.existsSync()) return [];

    final files = <String>[];

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.dart')) continue;
      if (_config.isExcluded(entity.path)) continue;
      files.add(entity.path);
    }

    // Sort for deterministic results.
    files.sort();
    return files;
  }
}
