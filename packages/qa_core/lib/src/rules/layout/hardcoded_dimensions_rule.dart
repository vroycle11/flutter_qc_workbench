import '../../models/finding.dart';
import '../../models/severity.dart';
import '../../models/source_location.dart';
import '../../models/rule_metadata.dart';
import '../../config/qa_config.dart';
import '../rule.dart';

/// Detects hardcoded pixel dimensions that may cause layout issues
/// on different screen sizes and densities.
class HardcodedDimensionsRule extends QaRule {
  @override
  RuleMetadata get metadata => const RuleMetadata(
    id: 'QA104',
    version: '1.0.0',
    title: 'Hardcoded dimension value',
    description:
        'Large hardcoded pixel values in width/height constraints may not '
        'adapt well to different screen sizes and pixel densities. '
        'Consider using MediaQuery, LayoutBuilder, or relative sizing.',
    category: Category.layout,
    defaultSeverity: Severity.info,
    defaultConfidence: Confidence.low,
    tags: ['layout', 'responsive', 'dimensions', 'hardcoded'],
  );

  /// Minimum pixel value to flag (small values like padding are fine).
  static const _threshold = 300.0;

  static final _dimensionPattern = RegExp(
    r'\b(width|height|maxWidth|maxHeight|minWidth|minHeight)\s*:\s*(\d+\.?\d*)',
  );

  @override
  List<Finding> analyze(String filePath, String content, QaConfig config) {
    final findings = <Finding>[];
    final lines = content.split('\n');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      for (final match in _dimensionPattern.allMatches(line)) {
        final value = double.tryParse(match.group(2)!);
        if (value == null || value < _threshold) continue;

        // Skip if inside MediaQuery or LayoutBuilder context.
        final contextStart = (i - 5).clamp(0, lines.length);
        final ctx = lines.sublist(contextStart, i + 1).join('\n');
        if (RegExp(r'\bMediaQuery\b').hasMatch(ctx)) continue;
        if (RegExp(r'\bLayoutBuilder\b').hasMatch(ctx)) continue;

        final severity = config.effectiveSeverity(
          metadata.id,
          metadata.defaultSeverity,
        );

        findings.add(Finding(
          ruleId: metadata.id,
          ruleVersion: metadata.version,
          title: 'Hardcoded ${match.group(1)}: ${value.toStringAsFixed(0)}',
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
              '${match.group(1)} set to ${value.toStringAsFixed(0)} pixels.',
          recommendation:
              'Use MediaQuery.sizeOf(context), LayoutBuilder, '
              'FractionallySizedBox, or relative sizing instead of '
              'hardcoded pixel values for better responsiveness.',
          quickFixAvailable: false,
        ));
      }
    }

    return findings;
  }
}
