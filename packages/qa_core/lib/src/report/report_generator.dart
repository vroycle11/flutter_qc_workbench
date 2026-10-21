import 'dart:convert';

import '../models/scan_result.dart';
import '../models/severity.dart';

/// Generates structured reports from scan results.
class ReportGenerator {
  const ReportGenerator();

  /// Generate a JSON report.
  String toJson(ScanResult result, {bool pretty = true}) {
    final encoder = pretty
        ? const JsonEncoder.withIndent('  ')
        : const JsonEncoder();
    return encoder.convert(result.toJson());
  }

  /// Generate a human-readable text report.
  String toText(ScanResult result) {
    final buffer = StringBuffer();

    buffer.writeln('╔══════════════════════════════════════════╗');
    buffer.writeln('║     Flutter QA Workbench Report         ║');
    buffer.writeln('╚══════════════════════════════════════════╝');
    buffer.writeln();

    buffer.writeln('Scan completed: ${result.timestamp.toLocal()}');
    buffer.writeln('Duration: ${result.duration.inMilliseconds}ms');
    buffer.writeln('Files analyzed: ${result.filesAnalyzed}');
    buffer.writeln('Rules applied: ${result.rulesApplied}');

    if (result.cancelled) {
      buffer.writeln('⚠ Scan was cancelled before completion.');
    }

    buffer.writeln();
    buffer.writeln('─── Summary ───');

    final counts = result.severityCounts;
    final critical = counts['critical'] ?? 0;
    final errors = counts['error'] ?? 0;
    final warnings = counts['warning'] ?? 0;
    final infos = counts['info'] ?? 0;

    buffer.writeln('  Critical: $critical');
    buffer.writeln('  Errors:   $errors');
    buffer.writeln('  Warnings: $warnings');
    buffer.writeln('  Info:     $infos');
    buffer.writeln('  Total:    ${result.findings.length}');

    if (result.findings.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('─── Findings ───');

      for (final finding in result.findings) {
        final icon = switch (finding.severity) {
          Severity.critical => '🔴',
          Severity.error => '🟠',
          Severity.warning => '🟡',
          Severity.info => '🔵',
        };

        final loc = finding.location;
        final relPath = result.workspaceRoot != null
            ? loc.displayPath(result.workspaceRoot!)
            : loc.filePath;

        buffer.writeln();
        buffer.writeln(
          '$icon [${finding.ruleId}] ${finding.title}',
        );
        buffer.writeln('  $relPath:${loc.line}:${loc.column}');
        buffer.writeln('  ${finding.description}');

        if (finding.recommendation != null) {
          buffer.writeln('  💡 ${finding.recommendation}');
        }
      }
    }

    if (result.errors.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('─── Errors ───');
      for (final error in result.errors) {
        buffer.writeln('  ⚠ $error');
      }
    }

    buffer.writeln();

    return buffer.toString();
  }

  /// Generate a SARIF-compatible report.
  String toSarif(ScanResult result) {
    final runs = <Map<String, dynamic>>[];

    final ruleMap = <String, int>{};
    final rules = <Map<String, dynamic>>[];

    for (final finding in result.findings) {
      if (!ruleMap.containsKey(finding.ruleId)) {
        ruleMap[finding.ruleId] = rules.length;
        rules.add({
          'id': finding.ruleId,
          'shortDescription': {'text': finding.title},
          'fullDescription': {'text': finding.description},
          'defaultConfiguration': {
            'level': _sarifLevel(finding.severity),
          },
        });
      }
    }

    final results = result.findings.map((f) {
      return {
        'ruleId': f.ruleId,
        'ruleIndex': ruleMap[f.ruleId],
        'level': _sarifLevel(f.severity),
        'message': {'text': f.description},
        'locations': [
          {
            'physicalLocation': {
              'artifactLocation': {
                'uri': f.location.filePath,
              },
              'region': {
                'startLine': f.location.line,
                'startColumn': f.location.column,
                if (f.location.endLine != null)
                  'endLine': f.location.endLine,
                if (f.location.endColumn != null)
                  'endColumn': f.location.endColumn,
              },
            },
          },
        ],
      };
    }).toList();

    runs.add({
      'tool': {
        'driver': {
          'name': 'Flutter QA Workbench',
          'version': '0.1.0',
          'rules': rules,
        },
      },
      'results': results,
    });

    final sarif = {
      'version': '2.1.0',
      '\$schema':
          'https://raw.githubusercontent.com/oasis-tcs/sarif-spec/main/'
              'sarif-2.1/schema/sarif-schema-2.1.0.json',
      'runs': runs,
    };

    return const JsonEncoder.withIndent('  ').convert(sarif);
  }

  String _sarifLevel(Severity severity) => switch (severity) {
    Severity.critical => 'error',
    Severity.error => 'error',
    Severity.warning => 'warning',
    Severity.info => 'note',
  };
}
