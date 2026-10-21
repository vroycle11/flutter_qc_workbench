import '../../models/finding.dart';
import '../../models/severity.dart';
import '../../models/source_location.dart';
import '../../models/rule_metadata.dart';
import '../../config/qa_config.dart';
import '../rule.dart';

/// Detects interactive controls that may be missing semantic labels.
///
/// Checks for `GestureDetector`, `InkWell`, and `Listener` widgets that
/// don't have a nearby `Semantics` wrapper providing a label.
class MissingSemanticLabelRule extends QaRule {
  @override
  RuleMetadata get metadata => const RuleMetadata(
    id: 'QA002',
    version: '1.0.0',
    title: 'Interactive control may lack semantic label',
    description:
        'GestureDetector, InkWell, and similar raw interactive widgets '
        'should be wrapped with Semantics to provide an accessible label '
        'for screen readers.',
    category: Category.accessibility,
    defaultSeverity: Severity.warning,
    defaultConfidence: Confidence.medium,
    documentationUrl:
        'https://api.flutter.dev/flutter/widgets/Semantics-class.html',
    tags: ['a11y', 'semantics', 'gesture'],
  );

  static final _interactivePattern = RegExp(
    r'\b(GestureDetector|InkWell|Listener)\s*\(',
  );

  @override
  List<Finding> analyze(String filePath, String content, QaConfig config) {
    final findings = <Finding>[];
    final lines = content.split('\n');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final match = _interactivePattern.firstMatch(line);
      if (match == null) continue;

      // Check surrounding context (5 lines before) for Semantics wrapper.
      final contextStart = (i - 5).clamp(0, lines.length);
      final context = lines.sublist(contextStart, i + 1).join('\n');

      if (RegExp(r'\bSemantics\s*\(').hasMatch(context)) continue;
      if (RegExp(r'\bMergeSemantics\s*\(').hasMatch(context)) continue;
      // If the interactive widget is inside a button-like parent, skip.
      if (RegExp(r'\b(ElevatedButton|TextButton|OutlinedButton|IconButton)\s*\(')
          .hasMatch(context)) {
        continue;
      }

      final severity = config.effectiveSeverity(
        metadata.id,
        metadata.defaultSeverity,
      );

      findings.add(Finding(
        ruleId: metadata.id,
        ruleVersion: metadata.version,
        title: '${match.group(1)} may lack semantic label',
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
            '${match.group(1)} found without a Semantics wrapper in '
            'the surrounding context.',
        recommendation:
            'Wrap with Semantics(label: "description", child: ...) to '
            'provide an accessible label for screen readers.',
        quickFixAvailable: false,
        documentationUrl: metadata.documentationUrl,
      ));
    }

    return findings;
  }
}
