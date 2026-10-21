import '../models/finding.dart';
import '../models/rule_metadata.dart';
import '../config/qa_config.dart';

/// Base class for all quality analysis rules.
///
/// Each rule inspects Dart source content and produces [Finding]s.
/// Rules operate on raw source text with line-by-line analysis for
/// reliability across Dart SDK versions, avoiding fragile dependency
/// on internal analyzer APIs that change frequently.
abstract class QaRule {
  /// Metadata describing this rule.
  RuleMetadata get metadata;

  /// Analyze a single Dart source file.
  ///
  /// [filePath] is the absolute path to the file.
  /// [content] is the raw source text.
  /// [config] is the active configuration.
  ///
  /// Returns findings for this file, possibly empty.
  List<Finding> analyze(String filePath, String content, QaConfig config);
}
