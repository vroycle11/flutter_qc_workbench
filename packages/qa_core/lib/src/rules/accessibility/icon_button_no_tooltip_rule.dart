import '../../models/finding.dart';
import '../../models/severity.dart';
import '../../models/source_location.dart';
import '../../models/rule_metadata.dart';
import '../../config/qa_config.dart';
import '../rule.dart';

/// Detects `IconButton` widgets without a `tooltip` parameter.
///
/// Screen readers use the tooltip as the accessible label for icon buttons.
/// Without it, users relying on assistive technology cannot understand
/// the button's purpose.
class IconButtonNoTooltipRule extends QaRule {
  @override
  RuleMetadata get metadata => const RuleMetadata(
    id: 'QA001',
    version: '1.0.0',
    title: 'IconButton missing tooltip',
    description:
        'IconButton should include a tooltip for screen reader accessibility. '
        'The tooltip serves as the accessible label that describes the '
        "button's action.",
    category: Category.accessibility,
    defaultSeverity: Severity.warning,
    defaultConfidence: Confidence.high,
    documentationUrl:
        'https://api.flutter.dev/flutter/material/IconButton-class.html',
    tags: ['a11y', 'icon-button', 'tooltip'],
  );

  // Matches IconButton( with optional whitespace/newline before paren.
  static final _iconButtonPattern = RegExp(r'\bIconButton\s*\(');

  @override
  List<Finding> analyze(String filePath, String content, QaConfig config) {
    final findings = <Finding>[];
    final lines = content.split('\n');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final match = _iconButtonPattern.firstMatch(line);
      if (match == null) continue;

      // Look ahead to find the matching closing paren and check for tooltip.
      final constructorBody = _extractConstructorBody(lines, i, match.start);
      if (constructorBody == null) continue;

      // Skip if tooltip is present.
      if (RegExp(r'\btooltip\s*:').hasMatch(constructorBody)) continue;

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
        evidence: 'IconButton constructor found without tooltip parameter.',
        recommendation:
            "Add a tooltip parameter: IconButton(tooltip: 'Description', ...)",
        quickFixAvailable: false,
        documentationUrl: metadata.documentationUrl,
      ));
    }

    return findings;
  }

  /// Extract the constructor body text from the opening paren.
  String? _extractConstructorBody(
    List<String> lines,
    int startLine,
    int startCol,
  ) {
    final buffer = StringBuffer();
    var depth = 0;
    var started = false;

    for (var i = startLine; i < lines.length && i < startLine + 50; i++) {
      final line = lines[i];
      final start = (i == startLine) ? startCol : 0;

      for (var j = start; j < line.length; j++) {
        final ch = line[j];
        if (ch == '(') {
          depth++;
          started = true;
        } else if (ch == ')') {
          depth--;
          if (started && depth == 0) {
            return buffer.toString();
          }
        }
        if (started) buffer.write(ch);
      }
      if (started) buffer.write('\n');
    }

    return null;
  }
}
