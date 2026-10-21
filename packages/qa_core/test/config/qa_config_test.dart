import 'package:test/test.dart';
import 'package:qa_core/qa_core.dart';

void main() {
  group('QaConfig', () {
    test('default config enables all rules', () {
      const config = QaConfig();
      expect(config.isRuleEnabled('QA001'), isTrue);
      expect(config.isRuleEnabled('QA999'), isTrue);
    });

    test('disabled rules are excluded', () {
      const config = QaConfig(disabledRules: {'QA001', 'QA002'});
      expect(config.isRuleEnabled('QA001'), isFalse);
      expect(config.isRuleEnabled('QA002'), isFalse);
      expect(config.isRuleEnabled('QA003'), isTrue);
    });

    test('enabled rules whitelist works', () {
      const config = QaConfig(enabledRules: {'QA001', 'QA101'});
      expect(config.isRuleEnabled('QA001'), isTrue);
      expect(config.isRuleEnabled('QA101'), isTrue);
      expect(config.isRuleEnabled('QA002'), isFalse);
    });

    test('severity overrides work', () {
      const config = QaConfig(
        severityOverrides: {'QA001': Severity.error},
      );
      expect(
        config.effectiveSeverity('QA001', Severity.warning),
        Severity.error,
      );
      expect(
        config.effectiveSeverity('QA002', Severity.warning),
        Severity.warning,
      );
    });

    test('excludes generated files by default', () {
      const config = QaConfig();
      expect(config.isExcluded('/project/lib/model.g.dart'), isTrue);
      expect(config.isExcluded('/project/lib/model.freezed.dart'), isTrue);
      expect(config.isExcluded('/project/lib/model.mocks.dart'), isTrue);
      expect(config.isExcluded('/project/lib/model.dart'), isFalse);
    });

    test('excludes build directories', () {
      const config = QaConfig();
      expect(config.isExcluded('/project/.dart_tool/file.dart'), isTrue);
      expect(config.isExcluded('/project/build/file.dart'), isTrue);
      expect(config.isExcluded('/project/.pub-cache/file.dart'), isTrue);
    });

    test('excludes test files by default', () {
      const config = QaConfig();
      expect(config.isExcluded('/project/test/widget_test.dart'), isTrue);
    });

    test('includes test files when configured', () {
      const config = QaConfig(analyzeTestFiles: true);
      expect(config.isExcluded('/project/test/widget_test.dart'), isFalse);
    });

    test('custom exclude patterns work', () {
      const config = QaConfig(excludePatterns: ['**/generated/']);
      expect(config.isExcluded('/project/lib/generated/file.dart'), isTrue);
      expect(config.isExcluded('/project/lib/src/file.dart'), isFalse);
    });

    test('suppression check works', () {
      const config = QaConfig(
        suppressions: {
          'QA001': {'/file.dart:10'},
        },
      );
      expect(config.isSuppressed('QA001', '/file.dart', 10), isTrue);
      expect(config.isSuppressed('QA001', '/file.dart', 11), isFalse);
      expect(config.isSuppressed('QA002', '/file.dart', 10), isFalse);
    });
  });
}
