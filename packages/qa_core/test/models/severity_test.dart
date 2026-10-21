import 'package:test/test.dart';
import 'package:qa_core/qa_core.dart';

void main() {
  group('Severity', () {
    test('label returns human-readable text', () {
      expect(Severity.critical.label, 'Critical');
      expect(Severity.error.label, 'Error');
      expect(Severity.warning.label, 'Warning');
      expect(Severity.info.label, 'Info');
    });

    test('tryParse handles valid values', () {
      expect(Severity.tryParse('critical'), Severity.critical);
      expect(Severity.tryParse('ERROR'), Severity.error);
      expect(Severity.tryParse('Warning'), Severity.warning);
    });

    test('tryParse returns null for invalid values', () {
      expect(Severity.tryParse('unknown'), isNull);
      expect(Severity.tryParse(''), isNull);
    });
  });

  group('Confidence', () {
    test('label returns human-readable text', () {
      expect(Confidence.high.label, 'High');
      expect(Confidence.medium.label, 'Medium');
      expect(Confidence.low.label, 'Low');
    });
  });

  group('Category', () {
    test('label returns human-readable text', () {
      expect(Category.accessibility.label, 'Accessibility');
      expect(Category.layout.label, 'Layout');
    });

    test('tryParse handles valid values', () {
      expect(Category.tryParse('accessibility'), Category.accessibility);
      expect(Category.tryParse('bestPractice'), Category.bestPractice);
    });
  });
}
