import 'package:test/test.dart';
import 'package:qa_core/qa_core.dart';
import 'package:qa_core/src/rules/layout/unbounded_column_in_scroll_rule.dart';
import 'package:qa_core/src/rules/layout/expanded_in_column_rule.dart';
import 'package:qa_core/src/rules/layout/deep_nesting_rule.dart';
import 'package:qa_core/src/rules/layout/hardcoded_dimensions_rule.dart';

void main() {
  const config = QaConfig();

  group('UnboundedColumnInScrollRule (QA101)', () {
    final rule = UnboundedColumnInScrollRule();

    test('detects Column in SingleChildScrollView', () {
      const source = '''
Widget build(BuildContext context) {
  return SingleChildScrollView(
    child: Column(
      children: [
        Text('Hello'),
      ],
    ),
  );
}
''';
      final findings = rule.analyze('/test.dart', source, config);
      expect(findings, hasLength(1));
      expect(findings.first.ruleId, 'QA101');
    });

    test('does not flag Column with mainAxisSize.min', () {
      const source = '''
Widget build(BuildContext context) {
  return SingleChildScrollView(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Hello'),
      ],
    ),
  );
}
''';
      final findings = rule.analyze('/test.dart', source, config);
      expect(findings, isEmpty);
    });
  });

  group('ExpandedInColumnRule (QA102)', () {
    final rule = ExpandedInColumnRule();

    test('detects Expanded in Column inside ScrollView', () {
      const source = '''
Widget build(BuildContext context) {
  return SingleChildScrollView(
    child: Column(
      children: [
        Expanded(
          child: Text('Hello'),
        ),
      ],
    ),
  );
}
''';
      final findings = rule.analyze('/test.dart', source, config);
      expect(findings, hasLength(1));
      expect(findings.first.ruleId, 'QA102');
    });

    test('does not flag Expanded in Column without scroll parent', () {
      const source = '''
Widget build(BuildContext context) {
  return Column(
    children: [
      Expanded(
        child: Text('Hello'),
      ),
    ],
  );
}
''';
      final findings = rule.analyze('/test.dart', source, config);
      expect(findings, isEmpty);
    });
  });

  group('DeepNestingRule (QA103)', () {
    final rule = DeepNestingRule();

    test('detects deeply nested widget trees', () {
      // Build a deeply nested structure (>10 levels).
      final buffer = StringBuffer('Widget build(BuildContext context) {\n');
      buffer.writeln('  return Container(');
      for (var i = 0; i < 12; i++) {
        buffer.writeln('    child: Padding(');
        buffer.writeln('      padding: EdgeInsets.all(8),');
      }
      buffer.writeln('      child: Text("deep"),');
      for (var i = 0; i < 12; i++) {
        buffer.writeln('    ),');
      }
      buffer.writeln('  );');
      buffer.writeln('}');

      final findings = rule.analyze('/test.dart', buffer.toString(), config);
      expect(findings, isNotEmpty);
      expect(findings.first.ruleId, 'QA103');
    });

    test('does not flag shallow nesting', () {
      const source = '''
Widget build(BuildContext context) {
  return Container(
    child: Column(
      children: [
        Text('Hello'),
      ],
    ),
  );
}
''';
      final findings = rule.analyze('/test.dart', source, config);
      expect(findings, isEmpty);
    });
  });

  group('HardcodedDimensionsRule (QA104)', () {
    final rule = HardcodedDimensionsRule();

    test('detects large hardcoded width', () {
      const source = '''
Widget build(BuildContext context) {
  return Container(
    width: 500,
    height: 100,
    child: Text('Hello'),
  );
}
''';
      final findings = rule.analyze('/test.dart', source, config);
      expect(findings.any((f) => f.ruleId == 'QA104'), isTrue);
    });

    test('does not flag small dimensions', () {
      const source = '''
Widget build(BuildContext context) {
  return Container(
    width: 100,
    height: 50,
    child: Text('Hello'),
  );
}
''';
      final findings = rule.analyze('/test.dart', source, config);
      expect(findings, isEmpty);
    });

    test('does not flag MediaQuery-relative dimensions', () {
      const source = '''
Widget build(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return Container(
    width: 500,
    child: Text('Hello'),
  );
}
''';
      final findings = rule.analyze('/test.dart', source, config);
      expect(findings, isEmpty);
    });
  });
}
