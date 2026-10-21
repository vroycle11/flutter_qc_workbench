import 'dart:io';

import 'package:test/test.dart';
import 'package:qa_core/qa_core.dart';

void main() {
  group('AnalysisEngine', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('qa_core_test_');

      // Create a minimal Flutter project structure.
      File('${tempDir.path}/pubspec.yaml').writeAsStringSync(
        'name: test_project\n',
      );
      Directory('${tempDir.path}/lib').createSync();
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('analyzes a simple project and returns findings', () async {
      // Write a file with a known issue.
      File('${tempDir.path}/lib/main.dart').writeAsStringSync('''
import 'package:flutter/material.dart';

Widget build(BuildContext context) {
  return IconButton(
    onPressed: () {},
    icon: Icon(Icons.search),
  );
}
''');

      final engine = AnalysisEngine();
      final result = await engine.analyze(tempDir.path);

      expect(result.filesAnalyzed, 1);
      expect(result.rulesApplied, greaterThan(0));
      expect(result.findings, isNotEmpty);
      expect(
        result.findings.any((f) => f.ruleId == 'QA001'),
        isTrue,
        reason: 'Should detect IconButton without tooltip',
      );
    });

    test('returns empty findings for clean code', () async {
      File('${tempDir.path}/lib/main.dart').writeAsStringSync('''
import 'package:flutter/material.dart';

Widget build(BuildContext context) {
  return IconButton(
    onPressed: () {},
    icon: Icon(Icons.search),
    tooltip: 'Search',
  );
}
''');

      final engine = AnalysisEngine();
      final result = await engine.analyze(tempDir.path);

      expect(result.filesAnalyzed, 1);
      final iconButtonFindings =
          result.findings.where((f) => f.ruleId == 'QA001');
      expect(iconButtonFindings, isEmpty);
    });

    test('respects disabled rules', () async {
      File('${tempDir.path}/lib/main.dart').writeAsStringSync('''
import 'package:flutter/material.dart';

Widget build(BuildContext context) {
  return IconButton(
    onPressed: () {},
    icon: Icon(Icons.search),
  );
}
''');

      final engine = AnalysisEngine(
        config: const QaConfig(disabledRules: {'QA001'}),
      );
      final result = await engine.analyze(tempDir.path);

      expect(
        result.findings.any((f) => f.ruleId == 'QA001'),
        isFalse,
      );
    });

    test('excludes generated files', () async {
      File('${tempDir.path}/lib/model.g.dart').writeAsStringSync('''
Widget build(BuildContext context) {
  return IconButton(
    onPressed: () {},
    icon: Icon(Icons.search),
  );
}
''');

      final engine = AnalysisEngine();
      final result = await engine.analyze(tempDir.path);

      expect(result.filesAnalyzed, 0);
    });

    test('cancellation stops analysis', () async {
      // Create multiple files.
      for (var i = 0; i < 10; i++) {
        File('${tempDir.path}/lib/file_$i.dart').writeAsStringSync('''
Widget build(BuildContext context) {
  return IconButton(onPressed: () {}, icon: Icon(Icons.add));
}
''');
      }

      final engine = AnalysisEngine();

      // Cancel on first progress callback, during the scan.
      final result = await engine.analyze(
        tempDir.path,
        onProgress: (processed, total) {
          if (processed == 1) engine.cancel();
        },
      );

      expect(result.cancelled, isTrue);
    });

    test('handles empty projects', () async {
      final engine = AnalysisEngine();
      final result = await engine.analyze(tempDir.path);

      expect(result.filesAnalyzed, 0);
      expect(result.findings, isEmpty);
      expect(result.cancelled, isFalse);
    });

    test('progress callback is invoked', () async {
      File('${tempDir.path}/lib/main.dart').writeAsStringSync(
        'void main() {}',
      );

      final progressCalls = <(int, int)>[];
      final engine = AnalysisEngine();
      await engine.analyze(
        tempDir.path,
        onProgress: (processed, total) {
          progressCalls.add((processed, total));
        },
      );

      expect(progressCalls, isNotEmpty);
      expect(progressCalls.last.$1, progressCalls.last.$2);
    });
  });

  group('ReportGenerator', () {
    const reporter = ReportGenerator();

    test('generates valid JSON', () {
      final result = ScanResult(
        findings: [],
        filesAnalyzed: 5,
        rulesApplied: 8,
        duration: const Duration(milliseconds: 100),
        timestamp: DateTime(2024, 1, 15),
      );

      final json = reporter.toJson(result);
      expect(json, contains('"filesAnalyzed": 5'));
    });

    test('generates text report', () {
      final result = ScanResult(
        findings: [
          Finding(
            ruleId: 'QA001',
            ruleVersion: '1.0.0',
            title: 'Test Finding',
            description: 'Test description',
            severity: Severity.warning,
            confidence: Confidence.high,
            category: Category.accessibility,
            location: const SourceLocation(
              filePath: '/path/file.dart',
              line: 10,
              column: 5,
            ),
          ),
        ],
        filesAnalyzed: 1,
        rulesApplied: 8,
        duration: const Duration(milliseconds: 50),
        timestamp: DateTime(2024, 1, 15),
        workspaceRoot: '/path',
      );

      final text = reporter.toText(result);
      expect(text, contains('QA001'));
      expect(text, contains('Test Finding'));
      expect(text, contains('file.dart:10:5'));
    });

    test('generates SARIF report', () {
      final result = ScanResult(
        findings: [
          Finding(
            ruleId: 'QA001',
            ruleVersion: '1.0.0',
            title: 'Test',
            description: 'Test',
            severity: Severity.warning,
            confidence: Confidence.high,
            category: Category.accessibility,
            location: const SourceLocation(
              filePath: '/test.dart',
              line: 1,
              column: 1,
            ),
          ),
        ],
        filesAnalyzed: 1,
        rulesApplied: 1,
        duration: const Duration(milliseconds: 10),
        timestamp: DateTime(2024, 1, 15),
      );

      final sarif = reporter.toSarif(result);
      expect(sarif, contains('"version": "2.1.0"'));
      expect(sarif, contains('"QA001"'));
      expect(sarif, contains('"warning"'));
    });
  });

  group('RuleRegistry', () {
    test('contains expected rules', () {
      final registry = RuleRegistry.instance;
      expect(registry.rules.length, greaterThanOrEqualTo(8));

      // Verify each rule has valid metadata.
      for (final rule in registry.rules) {
        expect(rule.metadata.id, isNotEmpty);
        expect(rule.metadata.version, isNotEmpty);
        expect(rule.metadata.title, isNotEmpty);
        expect(rule.metadata.description, isNotEmpty);
      }
    });

    test('getRule finds by ID', () {
      final registry = RuleRegistry.instance;
      expect(registry.getRule('QA001'), isNotNull);
      expect(registry.getRule('NONEXISTENT'), isNull);
    });

    test('all rules have unique IDs', () {
      final registry = RuleRegistry.instance;
      final ids = registry.rules.map((r) => r.metadata.id).toSet();
      expect(ids.length, equals(registry.rules.length));
    });
  });
}
