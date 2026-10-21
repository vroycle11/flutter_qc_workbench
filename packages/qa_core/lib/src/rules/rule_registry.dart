import 'rule.dart';
import 'accessibility/missing_semantic_label_rule.dart';
import 'accessibility/icon_button_no_tooltip_rule.dart';
import 'accessibility/image_missing_semantics_rule.dart';
import 'accessibility/excludes_semantics_rule.dart';
import 'layout/unbounded_column_in_scroll_rule.dart';
import 'layout/expanded_in_column_rule.dart';
import 'layout/deep_nesting_rule.dart';
import 'layout/hardcoded_dimensions_rule.dart';

/// Registry of all available quality rules.
class RuleRegistry {
  RuleRegistry._();

  static final RuleRegistry instance = RuleRegistry._();

  /// All registered rules.
  late final List<QaRule> rules = _buildRules();

  List<QaRule> _buildRules() => [
    // Accessibility
    MissingSemanticLabelRule(),
    IconButtonNoTooltipRule(),
    ImageMissingSemanticsRule(),
    ExcludesSemanticsRule(),
    // Layout
    UnboundedColumnInScrollRule(),
    ExpandedInColumnRule(),
    DeepNestingRule(),
    HardcodedDimensionsRule(),
  ];

  /// Get a rule by its ID.
  QaRule? getRule(String id) {
    for (final rule in rules) {
      if (rule.metadata.id == id) return rule;
    }
    return null;
  }

  /// All rule metadata for documentation/UI.
  List<Map<String, dynamic>> get allMetadata =>
      rules.map((r) => r.metadata.toJson()).toList();
}
