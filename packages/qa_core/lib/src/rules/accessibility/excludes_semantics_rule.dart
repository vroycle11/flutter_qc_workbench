import '../../models/finding.dart';
import '../../models/severity.dart';
import '../../models/source_location.dart';
import '../../models/rule_metadata.dart';
import '../../config/qa_config.dart';
import '../rule.dart';

/// Detects suspicious use of `ExcludeSemantics` that may hide
/// interactive content from screen readers.
class ExcludesSemanticsRule extends QaRule {
  @override
  RuleMetadata get metadata => const RuleMetadata(
    id: 'QA004',
    version: '1.0.0',
    title: 'ExcludeSemantics may hide interactive content',
    description:
        'ExcludeSemantics removes its subtree from the accessibility tree. '
        'If the subtree contains interactive widgets, users relying on '
        'screen readers will not be able to access them.',
    category: Category.accessibility,
    defaultSeverity: Severity.warning,
    defaultConfidence: Confidence.medium,
    documentationUrl:
        'https://api.flutter.dev/flutter/widgets/ExcludeSemantics-class.html',
    tags: ['a11y', 'semantics', 'exclude'],
  );

  static final _excludePattern = RegExp(r'\bExcludeSemantics\s*\(');

  @override
  List<Finding> analyze(String filePath, String content, QaConfig config) {
    final findings = <Finding>[];
    final lines = content.split('\n');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final match = _excludePattern.firstMatch(line);
      if (match == null) continue;

      // Check if excluding: false — that's fine.
      final lookahead = lines.sublist(i, (i + 5).clamp(0, lines.length)).join('\n');
      if (RegExp(r'\bexcluding\s*:\s*false').hasMatch(lookahead)) continue;

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
          line: i + 1,
          column: match.start + 1,
        ),
        codeContext: line.trim(),
        evidence: 'ExcludeSemantics widget found — review whether '
            'interactive children are being hidden from assistive technology.',
        recommendation:
            'Remove ExcludeSemantics if the subtree contains interactive '
            'widgets, or document why exclusion is intentional.',
        quickFixAvailable: false,
        documentationUrl: metadata.documentationUrl,
      ));
    }

    return findings;
  }
}
