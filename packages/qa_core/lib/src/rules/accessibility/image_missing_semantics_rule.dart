import '../../models/finding.dart';
import '../../models/severity.dart';
import '../../models/source_location.dart';
import '../../models/rule_metadata.dart';
import '../../config/qa_config.dart';
import '../rule.dart';

/// Detects `Image` and `Image.asset/network` without `semanticLabel`.
///
/// Content images should have a semantic label for screen readers.
/// Decorative images may legitimately omit this — confidence is medium.
class ImageMissingSemanticsRule extends QaRule {
  @override
  RuleMetadata get metadata => const RuleMetadata(
    id: 'QA003',
    version: '1.0.0',
    title: 'Image may be missing semanticLabel',
    description:
        'Image widgets that convey meaningful content should include '
        'a semanticLabel so screen readers can describe them. '
        'Decorative images may intentionally omit this.',
    category: Category.accessibility,
    defaultSeverity: Severity.info,
    defaultConfidence: Confidence.medium,
    documentationUrl:
        'https://api.flutter.dev/flutter/widgets/Image-class.html',
    tags: ['a11y', 'image', 'semantics'],
  );

  static final _imagePattern = RegExp(
    r'\bImage\s*\.\s*(asset|network|file|memory)\s*\('
    r'|'
    r'\bImage\s*\(',
  );

  @override
  List<Finding> analyze(String filePath, String content, QaConfig config) {
    final findings = <Finding>[];
    final lines = content.split('\n');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final match = _imagePattern.firstMatch(line);
      if (match == null) continue;

      // Look at constructor body for semanticLabel.
      final body = _extractBody(lines, i);
      if (body != null && RegExp(r'\bsemanticLabel\s*:').hasMatch(body)) {
        continue;
      }

      // Check if wrapped in Semantics.
      final contextStart = (i - 3).clamp(0, lines.length);
      final ctx = lines.sublist(contextStart, i + 1).join('\n');
      if (RegExp(r'\bSemantics\s*\(').hasMatch(ctx)) continue;

      // Check for excludeFromSemantics: true — intentionally decorative.
      if (body != null &&
          RegExp(r'\bexcludeFromSemantics\s*:\s*true').hasMatch(body)) {
        continue;
      }

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
        evidence: 'Image constructor without semanticLabel parameter.',
        recommendation:
            "Add semanticLabel: 'Description of the image content', "
            'or set excludeFromSemantics: true for decorative images.',
        quickFixAvailable: false,
        documentationUrl: metadata.documentationUrl,
      ));
    }

    return findings;
  }

  String? _extractBody(List<String> lines, int startLine) {
    final buffer = StringBuffer();
    var depth = 0;
    var started = false;

    for (var i = startLine; i < lines.length && i < startLine + 30; i++) {
      for (var j = 0; j < lines[i].length; j++) {
        final ch = lines[i][j];
        if (ch == '(') {
          depth++;
          started = true;
        } else if (ch == ')') {
          depth--;
          if (started && depth == 0) return buffer.toString();
        }
        if (started) buffer.write(ch);
      }
      buffer.write('\n');
    }
    return null;
  }
}
