import '../../models/finding.dart';
import '../../models/severity.dart';
import '../../models/source_location.dart';
import '../../models/rule_metadata.dart';
import '../../config/qa_config.dart';
import '../rule.dart';

/// Detects `Expanded` or `Flexible` used inside a `Column` that may
/// itself be inside an unbounded-height parent.
class ExpandedInColumnRule extends QaRule {
  @override
  RuleMetadata get metadata => const RuleMetadata(
    id: 'QA102',
    version: '1.0.0',
    title: 'Expanded/Flexible in potentially unbounded Column',
    description:
        'Using Expanded or Flexible inside a Column that does not have '
        'bounded height constraints can cause a "RenderFlex children have '
        'non-zero flex but incoming height constraints are unbounded" error.',
    category: Category.layout,
    defaultSeverity: Severity.warning,
    defaultConfidence: Confidence.medium,
    tags: ['layout', 'flex', 'expanded', 'unbounded'],
  );

  @override
  List<Finding> analyze(String filePath, String content, QaConfig config) {
    final findings = <Finding>[];
    final lines = content.split('\n');

    // Track nesting: look for Column -> Expanded/Flexible patterns
    // inside SingleChildScrollView or ListView.
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (!RegExp(r'\b(Expanded|Flexible)\s*\(').hasMatch(line)) continue;

      // Check the surrounding context (20 lines back) for Column inside
      // a scroll view or similar unbounded parent.
      final contextStart = (i - 20).clamp(0, lines.length);
      final context = lines.sublist(contextStart, i + 1).join('\n');

      final hasColumn = RegExp(r'\bColumn\s*\(').hasMatch(context);
      if (!hasColumn) continue;

      final hasScrollParent = RegExp(
        r'\b(SingleChildScrollView|ListView|CustomScrollView)\s*\(',
      ).hasMatch(context);

      if (!hasScrollParent) continue;

      final severity = config.effectiveSeverity(
        metadata.id,
        metadata.defaultSeverity,
      );

      final match = RegExp(r'\b(Expanded|Flexible)\s*\(').firstMatch(line)!;
      findings.add(Finding(
        ruleId: metadata.id,
        ruleVersion: metadata.version,
        title: '${match.group(1)} in potentially unbounded Column',
        description: metadata.description,
        severity: severity,
        confidence: metadata.defaultConfidence,
        category: metadata.category,
        location: SourceLocation(
          filePath: filePath,
          line: i + 1,
          column: match.start + 1,
        ),
        codeContext: line.trim(),
        evidence:
            '${match.group(1)} found inside Column within a scrollable parent.',
        recommendation:
            'Remove ${match.group(1)} and use fixed or intrinsic sizing, '
            'or ensure the Column has bounded height constraints.',
        quickFixAvailable: false,
      ));
    }

    return findings;
  }
}
