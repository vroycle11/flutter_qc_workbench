import '../../models/finding.dart';
import '../../models/severity.dart';
import '../../models/source_location.dart';
import '../../models/rule_metadata.dart';
import '../../config/qa_config.dart';
import '../rule.dart';

/// Detects `Column` used inside `SingleChildScrollView` without
/// proper shrink wrapping — a common source of unbounded height errors.
class UnboundedColumnInScrollRule extends QaRule {
  @override
  RuleMetadata get metadata => const RuleMetadata(
    id: 'QA101',
    version: '1.0.0',
    title: 'Column in SingleChildScrollView may need shrinkWrap',
    description:
        'A Column inside a SingleChildScrollView can cause layout issues '
        'if the Column tries to expand to infinity. Consider using '
        'mainAxisSize: MainAxisSize.min or reviewing the constraint chain.',
    category: Category.layout,
    defaultSeverity: Severity.warning,
    defaultConfidence: Confidence.medium,
    tags: ['layout', 'scroll', 'column', 'unbounded'],
  );

  @override
  List<Finding> analyze(String filePath, String content, QaConfig config) {
    final findings = <Finding>[];
    final lines = content.split('\n');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (!RegExp(r'\bSingleChildScrollView\s*\(').hasMatch(line)) continue;

      // Look ahead for Column inside the scroll view.
      final lookaheadEnd = (i + 30).clamp(0, lines.length);
      final lookahead = lines.sublist(i, lookaheadEnd).join('\n');

      final columnMatch = RegExp(r'\bColumn\s*\(').firstMatch(lookahead);
      if (columnMatch == null) continue;

      // Check if mainAxisSize: MainAxisSize.min is set.
      final columnContext = lookahead.substring(columnMatch.start);
      if (RegExp(r'mainAxisSize\s*:\s*MainAxisSize\s*\.\s*min')
          .hasMatch(columnContext)) {
        continue;
      }

      // Find actual line number of Column.
      final columnLineOffset = '\n'.allMatches(
        lookahead.substring(0, columnMatch.start),
      ).length;

      final severity = config.effectiveSeverity(
        metadata.id,
        metadata.defaultSeverity,
      );

      findings.add(Finding(
        ruleId: metadata.id,
        ruleVersion: metadata.version,
        title: metadata.title,
        description: metadata.description,
        severity: severity,
        confidence: metadata.defaultConfidence,
        category: metadata.category,
        location: SourceLocation(
          filePath: filePath,
          line: i + 1 + columnLineOffset,
          column: 1,
        ),
        codeContext: lines[i + columnLineOffset].trim(),
        evidence:
            'Column inside SingleChildScrollView without '
            'mainAxisSize: MainAxisSize.min.',
        recommendation:
            'Add mainAxisSize: MainAxisSize.min to the Column, or '
            'verify that the parent provides bounded constraints.',
        quickFixAvailable: false,
      ));
    }

    return findings;
  }
}
