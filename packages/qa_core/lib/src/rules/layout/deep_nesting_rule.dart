import '../../models/finding.dart';
import '../../models/severity.dart';
import '../../models/source_location.dart';
import '../../models/rule_metadata.dart';
import '../../config/qa_config.dart';
import '../rule.dart';

/// Detects deeply nested widget trees that may indicate need for
/// refactoring into smaller extracted widgets.
class DeepNestingRule extends QaRule {
  @override
  RuleMetadata get metadata => const RuleMetadata(
    id: 'QA103',
    version: '1.0.0',
    title: 'Deeply nested widget tree',
    description:
        'Widget trees nested more than 10 levels deep are harder to read, '
        'test, and maintain. Consider extracting inner widgets into '
        'separate widget classes or helper methods.',
    category: Category.layout,
    defaultSeverity: Severity.info,
    defaultConfidence: Confidence.high,
    tags: ['layout', 'nesting', 'refactor', 'readability'],
  );

  /// Maximum nesting depth before triggering.
  static const _maxDepth = 10;

  @override
  List<Finding> analyze(String filePath, String content, QaConfig config) {
    final findings = <Finding>[];
    final lines = content.split('\n');

    var depth = 0;
    var maxDepthLine = -1;
    var currentMax = 0;
    final reportedLines = <int>{};

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Track parenthesis depth as a rough proxy for widget nesting.
      for (final ch in line.runes) {
        if (ch == 40 /* ( */) {
          depth++;
          if (depth > currentMax) {
            currentMax = depth;
            maxDepthLine = i;
          }
        } else if (ch == 41 /* ) */) {
          depth--;
          if (depth < 0) depth = 0;
        }
      }

      // If we've returned to low depth and max exceeded threshold, report.
      if (depth <= 2 && currentMax > _maxDepth && maxDepthLine >= 0) {
        if (!reportedLines.contains(maxDepthLine)) {
          reportedLines.add(maxDepthLine);

          final severity = config.effectiveSeverity(
            metadata.id,
            metadata.defaultSeverity,
          );

          findings.add(Finding(
            ruleId: metadata.id,
            ruleVersion: metadata.version,
            title: 'Widget nesting depth of $currentMax exceeds $_maxDepth',
            description: metadata.description,
            severity: severity,
            confidence: metadata.defaultConfidence,
            category: metadata.category,
            location: SourceLocation(
              filePath: filePath,
              line: maxDepthLine + 1,
              column: 1,
            ),
            codeContext: lines[maxDepthLine].trim(),
            evidence:
                'Parenthesis nesting depth reached $currentMax at this point.',
            recommendation:
                'Extract deeply nested subtrees into separate widget classes '
                'or builder methods for better readability and testability.',
            quickFixAvailable: false,
          ));
        }
        currentMax = depth;
        maxDepthLine = -1;
      }
    }

    return findings;
  }
}
