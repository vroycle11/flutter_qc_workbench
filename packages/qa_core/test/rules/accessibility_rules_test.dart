import 'package:test/test.dart';
import 'package:qa_core/qa_core.dart';
import 'package:qa_core/src/rules/accessibility/icon_button_no_tooltip_rule.dart';
import 'package:qa_core/src/rules/accessibility/missing_semantic_label_rule.dart';
import 'package:qa_core/src/rules/accessibility/image_missing_semantics_rule.dart';
import 'package:qa_core/src/rules/accessibility/excludes_semantics_rule.dart';

void main() {
  const config = QaConfig();

  group('IconButtonNoTooltipRule (QA001)', () {
    final rule = IconButtonNoTooltipRule();

    test('detects IconButton without tooltip', () {
      const source = '''
Widget build(BuildContext context) {
  return IconButton(
    onPressed: () {},
    icon: Icon(Icons.search),
  );
}
''';
      final findings = rule.analyze('/test.dart', source, config);
      expect(findings, hasLength(1));
      expect(findings.first.ruleId, 'QA001');
      expect(findings.first.severity, Severity.warning);
    });

    test('does not flag IconButton with tooltip', () {
      const source = '''
Widget build(BuildContext context) {
  return IconButton(
    onPressed: () {},
    icon: Icon(Icons.search),
    tooltip: 'Search',
  );
}
''';
      final findings = rule.analyze('/test.dart', source, config);
      expect(findings, isEmpty);
    });

    test('handles multi-line constructors', () {
      const source = '''
IconButton(
  onPressed: callback,
  icon: Icon(
    Icons.menu,
  ),
)
''';
      final findings = rule.analyze('/test.dart', source, config);
      expect(findings, hasLength(1));
    });
  });

  group('MissingSemanticLabelRule (QA002)', () {
    final rule = MissingSemanticLabelRule();

    test('detects GestureDetector without Semantics', () {
      const source = '''
Widget build(BuildContext context) {
  return GestureDetector(
    onTap: () {},
    child: Text('tap me'),
  );
}
''';
      final findings = rule.analyze('/test.dart', source, config);
      expect(findings, hasLength(1));
      expect(findings.first.ruleId, 'QA002');
    });

    test('does not flag GestureDetector with Semantics wrapper', () {
      const source = '''
Widget build(BuildContext context) {
  return Semantics(
    label: 'Tap to do something',
    child: GestureDetector(
      onTap: () {},
      child: Text('tap me'),
    ),
  );
}
''';
      final findings = rule.analyze('/test.dart', source, config);
      expect(findings, isEmpty);
    });

    test('detects InkWell without Semantics', () {
      const source = '''
Widget build(BuildContext context) {
  return InkWell(
    onTap: () {},
    child: Text('tap me'),
  );
}
''';
      final findings = rule.analyze('/test.dart', source, config);
      expect(findings, hasLength(1));
    });
  });

  group('ImageMissingSemanticsRule (QA003)', () {
    final rule = ImageMissingSemanticsRule();

    test('detects Image.network without semanticLabel', () {
      const source = '''
Widget build(BuildContext context) {
  return Image.network('https://example.com/photo.jpg');
}
''';
      final findings = rule.analyze('/test.dart', source, config);
      expect(findings, hasLength(1));
      expect(findings.first.ruleId, 'QA003');
    });

    test('does not flag Image with semanticLabel', () {
      const source = '''
Widget build(BuildContext context) {
  return Image.network(
    'https://example.com/photo.jpg',
    semanticLabel: 'A photo',
  );
}
''';
      final findings = rule.analyze('/test.dart', source, config);
      expect(findings, isEmpty);
    });

    test('does not flag decorative Image with excludeFromSemantics', () {
      const source = '''
Widget build(BuildContext context) {
  return Image.network(
    'https://example.com/bg.jpg',
    excludeFromSemantics: true,
  );
}
''';
      final findings = rule.analyze('/test.dart', source, config);
      expect(findings, isEmpty);
    });
  });

  group('ExcludesSemanticsRule (QA004)', () {
    final rule = ExcludesSemanticsRule();

    test('detects ExcludeSemantics usage', () {
      const source = '''
Widget build(BuildContext context) {
  return ExcludeSemantics(
    child: Button(),
  );
}
''';
      final findings = rule.analyze('/test.dart', source, config);
      expect(findings, hasLength(1));
      expect(findings.first.ruleId, 'QA004');
    });

    test('does not flag ExcludeSemantics with excluding: false', () {
      const source = '''
Widget build(BuildContext context) {
  return ExcludeSemantics(
    excluding: false,
    child: Button(),
  );
}
''';
      final findings = rule.analyze('/test.dart', source, config);
      expect(findings, isEmpty);
    });
  });
}
