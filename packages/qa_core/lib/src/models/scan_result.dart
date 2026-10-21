import 'finding.dart';

/// Result of a complete analysis scan.
class ScanResult {
  const ScanResult({
    required this.findings,
    required this.filesAnalyzed,
    required this.rulesApplied,
    required this.duration,
    required this.timestamp,
    this.workspaceRoot,
    this.cancelled = false,
    this.errors = const [],
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) => ScanResult(
    findings: (json['findings'] as List)
        .map((e) => Finding.fromJson(e as Map<String, dynamic>))
        .toList(),
    filesAnalyzed: json['filesAnalyzed'] as int,
    rulesApplied: json['rulesApplied'] as int,
    duration: Duration(milliseconds: json['durationMs'] as int),
    timestamp: DateTime.parse(json['timestamp'] as String),
    workspaceRoot: json['workspaceRoot'] as String?,
    cancelled: json['cancelled'] as bool? ?? false,
    errors: (json['errors'] as List?)?.cast<String>() ?? [],
  );

  /// All findings from the scan.
  final List<Finding> findings;

  /// Number of files that were analyzed.
  final int filesAnalyzed;

  /// Number of rules that were applied.
  final int rulesApplied;

  /// Total scan duration.
  final Duration duration;

  /// When the scan completed.
  final DateTime timestamp;

  /// Root path of the analyzed workspace.
  final String? workspaceRoot;

  /// Whether the scan was cancelled before completion.
  final bool cancelled;

  /// Non-fatal errors encountered during scanning.
  final List<String> errors;

  /// Findings grouped by severity.
  Map<String, int> get severityCounts {
    final counts = <String, int>{};
    for (final f in findings) {
      counts[f.severity.name] = (counts[f.severity.name] ?? 0) + 1;
    }
    return counts;
  }

  /// Findings grouped by category.
  Map<String, int> get categoryCounts {
    final counts = <String, int>{};
    for (final f in findings) {
      counts[f.category.name] = (counts[f.category.name] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, dynamic> toJson() => {
    'findings': findings.map((f) => f.toJson()).toList(),
    'filesAnalyzed': filesAnalyzed,
    'rulesApplied': rulesApplied,
    'durationMs': duration.inMilliseconds,
    'timestamp': timestamp.toIso8601String(),
    if (workspaceRoot != null) 'workspaceRoot': workspaceRoot,
    'cancelled': cancelled,
    'errors': errors,
    'severityCounts': severityCounts,
    'categoryCounts': categoryCounts,
  };
}
