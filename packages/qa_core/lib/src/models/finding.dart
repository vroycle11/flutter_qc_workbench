import 'severity.dart';
import 'source_location.dart';

/// A single quality finding produced by the analysis engine.
class Finding {
  const Finding({
    required this.ruleId,
    required this.ruleVersion,
    required this.title,
    required this.description,
    required this.severity,
    required this.confidence,
    required this.category,
    required this.location,
    this.codeContext,
    this.evidence,
    this.recommendation,
    this.quickFixAvailable = false,
    this.documentationUrl,
    this.status = FindingStatus.newFinding,
  });

  factory Finding.fromJson(Map<String, dynamic> json) => Finding(
    ruleId: json['ruleId'] as String,
    ruleVersion: json['ruleVersion'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    severity: Severity.values.byName(json['severity'] as String),
    confidence: Confidence.values.byName(json['confidence'] as String),
    category: Category.values.byName(json['category'] as String),
    location:
        SourceLocation.fromJson(json['location'] as Map<String, dynamic>),
    codeContext: json['codeContext'] as String?,
    evidence: json['evidence'] as String?,
    recommendation: json['recommendation'] as String?,
    quickFixAvailable: json['quickFixAvailable'] as bool? ?? false,
    documentationUrl: json['documentationUrl'] as String?,
    status: json['status'] != null
        ? FindingStatus.values.byName(json['status'] as String)
        : FindingStatus.newFinding,
  );

  /// Stable rule identifier.
  final String ruleId;

  /// Rule version that produced this finding.
  final String ruleVersion;

  /// Short title.
  final String title;

  /// Human-readable explanation.
  final String description;

  /// Severity of this finding.
  final Severity severity;

  /// Confidence in the finding's accuracy.
  final Confidence confidence;

  /// Category.
  final Category category;

  /// Source location.
  final SourceLocation location;

  /// Relevant source code snippet.
  final String? codeContext;

  /// Evidence supporting the finding.
  final String? evidence;

  /// Recommended fix description.
  final String? recommendation;

  /// Whether a quick-fix is available.
  final bool quickFixAvailable;

  /// Documentation link.
  final String? documentationUrl;

  /// Status relative to previous scans.
  final FindingStatus status;

  /// A stable fingerprint for deduplication across scans.
  String get fingerprint =>
      '$ruleId:${location.filePath}:${location.line}:${location.column}';

  Map<String, dynamic> toJson() => {
    'ruleId': ruleId,
    'ruleVersion': ruleVersion,
    'title': title,
    'description': description,
    'severity': severity.name,
    'confidence': confidence.name,
    'category': category.name,
    'location': location.toJson(),
    if (codeContext != null) 'codeContext': codeContext,
    if (evidence != null) 'evidence': evidence,
    if (recommendation != null) 'recommendation': recommendation,
    'quickFixAvailable': quickFixAvailable,
    if (documentationUrl != null) 'documentationUrl': documentationUrl,
    'status': status.name,
  };

  Finding copyWith({FindingStatus? status}) => Finding(
    ruleId: ruleId,
    ruleVersion: ruleVersion,
    title: title,
    description: description,
    severity: severity,
    confidence: confidence,
    category: category,
    location: location,
    codeContext: codeContext,
    evidence: evidence,
    recommendation: recommendation,
    quickFixAvailable: quickFixAvailable,
    documentationUrl: documentationUrl,
    status: status ?? this.status,
  );
}

/// Status of a finding relative to previous scan results.
enum FindingStatus {
  /// First time this finding was seen.
  newFinding,

  /// Finding existed in previous scan and is unchanged.
  unchanged,

  /// Finding existed in previous scan but has been resolved.
  resolved,

  /// Finding has been suppressed by configuration.
  suppressed;

  String get label => switch (this) {
    FindingStatus.newFinding => 'New',
    FindingStatus.unchanged => 'Unchanged',
    FindingStatus.resolved => 'Resolved',
    FindingStatus.suppressed => 'Suppressed',
  };
}
