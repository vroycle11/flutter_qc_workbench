import 'severity.dart';

/// Metadata about a quality rule.
class RuleMetadata {
  const RuleMetadata({
    required this.id,
    required this.version,
    required this.title,
    required this.description,
    required this.category,
    required this.defaultSeverity,
    required this.defaultConfidence,
    this.documentationUrl,
    this.applicableFilePatterns = const ['**.dart'],
    this.tags = const [],
  });

  /// Stable identifier, e.g. 'QA001'.
  final String id;

  /// Semantic version of the rule definition.
  final String version;

  /// Short human-readable title.
  final String title;

  /// Detailed description of what the rule checks.
  final String description;

  /// Rule category.
  final Category category;

  /// Default severity when not overridden by config.
  final Severity defaultSeverity;

  /// Default confidence level.
  final Confidence defaultConfidence;

  /// Link to external documentation.
  final String? documentationUrl;

  /// Glob patterns for files this rule applies to.
  final List<String> applicableFilePatterns;

  /// Additional tags for filtering.
  final List<String> tags;

  Map<String, dynamic> toJson() => {
    'id': id,
    'version': version,
    'title': title,
    'description': description,
    'category': category.name,
    'defaultSeverity': defaultSeverity.name,
    'defaultConfidence': defaultConfidence.name,
    if (documentationUrl != null) 'documentationUrl': documentationUrl,
    'applicableFilePatterns': applicableFilePatterns,
    'tags': tags,
  };
}
