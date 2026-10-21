import 'dart:io';

import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as p;
import '../models/severity.dart';

/// Configuration for the QA Workbench analysis engine.
///
/// Loaded from `flutter_qa_workbench.yaml` in the project root,
/// or uses sensible defaults.
class QaConfig {
  const QaConfig({
    this.enabledRules,
    this.disabledRules = const {},
    this.severityOverrides = const {},
    this.excludePatterns = const [],
    this.excludeGenerated = true,
    this.analyzeTestFiles = false,
    this.suppressions = const {},
  });

  /// If non-null, only these rule IDs are enabled.
  /// If null, all rules are enabled (minus [disabledRules]).
  final Set<String>? enabledRules;

  /// Rule IDs explicitly disabled.
  final Set<String> disabledRules;

  /// Severity overrides by rule ID.
  final Map<String, Severity> severityOverrides;

  /// Glob patterns for files/directories to exclude.
  final List<String> excludePatterns;

  /// Whether to exclude `.g.dart`, `.freezed.dart`, etc.
  final bool excludeGenerated;

  /// Whether to analyze files under `test/`.
  final bool analyzeTestFiles;

  /// Inline suppressions: maps rule IDs to lists of file:line locations.
  final Map<String, Set<String>> suppressions;

  /// Whether a given rule is enabled.
  bool isRuleEnabled(String ruleId) {
    if (disabledRules.contains(ruleId)) return false;
    if (enabledRules != null && !enabledRules!.contains(ruleId)) return false;
    return true;
  }

  /// Get effective severity for a rule.
  Severity effectiveSeverity(String ruleId, Severity defaultSeverity) {
    return severityOverrides[ruleId] ?? defaultSeverity;
  }

  /// Whether a finding at the given location is suppressed.
  bool isSuppressed(String ruleId, String filePath, int line) {
    final locations = suppressions[ruleId];
    if (locations == null) return false;
    return locations.contains('$filePath:$line');
  }

  /// Whether a file should be excluded from analysis.
  bool isExcluded(String filePath) {
    final basename = p.basename(filePath);

    // Exclude generated files.
    if (excludeGenerated) {
      if (basename.endsWith('.g.dart') ||
          basename.endsWith('.freezed.dart') ||
          basename.endsWith('.mocks.dart') ||
          basename.endsWith('.gr.dart')) {
        return true;
      }
    }

    // Exclude build artifacts and tool directories.
    final parts = p.split(filePath);
    const excludedDirs = [
      '.dart_tool',
      '.pub-cache',
      'build',
      '.build',
      'Pods',
      '.symlinks',
      '.plugin_symlinks',
    ];
    for (final dir in excludedDirs) {
      if (parts.contains(dir)) return true;
    }

    // Exclude test files if configured.
    if (!analyzeTestFiles) {
      if (parts.contains('test') || parts.contains('test_driver')) {
        return true;
      }
    }

    // Check custom exclusion patterns (simple glob).
    for (final pattern in excludePatterns) {
      if (_matchesGlob(filePath, pattern)) return true;
    }

    return false;
  }

  /// Simple glob matching for exclusion patterns.
  static bool _matchesGlob(String path, String pattern) {
    // Handle ** prefix
    if (pattern.startsWith('**/')) {
      final suffix = pattern.substring(3);
      return path.contains(suffix);
    }
    // Handle * suffix
    if (pattern.endsWith('*')) {
      final prefix = pattern.substring(0, pattern.length - 1);
      return path.contains(prefix);
    }
    return path.contains(pattern);
  }

  /// Load config from a project directory.
  /// Returns default config if no config file exists.
  static QaConfig load(String projectRoot) {
    final configFile = File(p.join(projectRoot, 'flutter_qa_workbench.yaml'));
    if (!configFile.existsSync()) return const QaConfig();

    try {
      final content = configFile.readAsStringSync();
      final yaml = loadYaml(content);
      if (yaml is! YamlMap) return const QaConfig();
      return _parseYaml(yaml);
    } catch (e) {
      // Return defaults on parse error — errors reported separately.
      return const QaConfig();
    }
  }

  static QaConfig _parseYaml(YamlMap yaml) {
    Set<String>? enabledRules;
    final enabledList = yaml['enabled_rules'];
    if (enabledList is YamlList) {
      enabledRules = enabledList.cast<String>().toSet();
    }

    var disabledRules = <String>{};
    final disabledList = yaml['disabled_rules'];
    if (disabledList is YamlList) {
      disabledRules = disabledList.cast<String>().toSet();
    }

    final severityOverrides = <String, Severity>{};
    final overridesMap = yaml['severity_overrides'];
    if (overridesMap is YamlMap) {
      for (final entry in overridesMap.entries) {
        final severity = Severity.tryParse(entry.value as String);
        if (severity != null) {
          severityOverrides[entry.key as String] = severity;
        }
      }
    }

    var excludePatterns = <String>[];
    final excludeList = yaml['exclude'];
    if (excludeList is YamlList) {
      excludePatterns = excludeList.cast<String>();
    }

    final excludeGenerated = yaml['exclude_generated'] as bool? ?? true;
    final analyzeTestFiles = yaml['analyze_test_files'] as bool? ?? false;

    return QaConfig(
      enabledRules: enabledRules,
      disabledRules: disabledRules,
      severityOverrides: severityOverrides,
      excludePatterns: excludePatterns,
      excludeGenerated: excludeGenerated,
      analyzeTestFiles: analyzeTestFiles,
    );
  }
}
