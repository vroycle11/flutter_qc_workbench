/// Severity levels for QA findings, ordered from least to most severe.
enum Severity {
  /// Informational note; no action required.
  info,

  /// Potential issue that deserves review.
  warning,

  /// Likely defect that should be fixed.
  error,

  /// Critical defect that blocks release.
  critical;

  /// Returns a human-readable label.
  String get label => switch (this) {
    Severity.info => 'Info',
    Severity.warning => 'Warning',
    Severity.error => 'Error',
    Severity.critical => 'Critical',
  };

  /// Parse from string, case-insensitive. Returns null on failure.
  static Severity? tryParse(String value) {
    final lower = value.toLowerCase();
    for (final s in values) {
      if (s.name == lower) return s;
    }
    return null;
  }
}

/// Confidence level indicating how certain the tool is about the finding.
enum Confidence {
  /// Low confidence – may be a false positive.
  low,

  /// Medium confidence – likely a real issue.
  medium,

  /// High confidence – almost certainly a real issue.
  high;

  String get label => switch (this) {
    Confidence.low => 'Low',
    Confidence.medium => 'Medium',
    Confidence.high => 'High',
  };

  static Confidence? tryParse(String value) {
    final lower = value.toLowerCase();
    for (final c in values) {
      if (c.name == lower) return c;
    }
    return null;
  }
}

/// Category of a quality check.
enum Category {
  accessibility,
  layout,
  performance,
  bestPractice,
  visualRegression,
  journey;

  String get label => switch (this) {
    Category.accessibility => 'Accessibility',
    Category.layout => 'Layout',
    Category.performance => 'Performance',
    Category.bestPractice => 'Best Practice',
    Category.visualRegression => 'Visual Regression',
    Category.journey => 'Journey',
  };

  static Category? tryParse(String value) {
    final lower = value.toLowerCase().replaceAll('_', '').replaceAll('-', '');
    for (final c in values) {
      if (c.name.toLowerCase() == lower) return c;
    }
    return null;
  }
}
