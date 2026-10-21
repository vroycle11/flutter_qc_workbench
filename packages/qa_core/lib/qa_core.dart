/// Flutter QA Workbench – Core analysis engine.
///
/// Provides source-level accessibility and layout quality rules,
/// finding data models, configuration parsing, and report generation.
library;

export 'src/models/finding.dart';
export 'src/models/severity.dart';
export 'src/models/source_location.dart';
export 'src/models/rule_metadata.dart';
export 'src/models/scan_result.dart';
export 'src/config/qa_config.dart';
export 'src/rules/rule.dart';
export 'src/rules/rule_registry.dart';
export 'src/engine/analysis_engine.dart';
export 'src/report/report_generator.dart';
