import 'package:test/test.dart';
import 'package:qa_core/qa_core.dart';

void main() {
  group('Finding', () {
    test('serialization round-trip', () {
      final finding = Finding(
        ruleId: 'QA001',
        ruleVersion: '1.0.0',
        title: 'Test finding',
        description: 'Description',
        severity: Severity.warning,
        confidence: Confidence.high,
        category: Category.accessibility,
        location: const SourceLocation(
          filePath: '/path/file.dart',
          line: 10,
          column: 5,
        ),
        codeContext: 'IconButton(',
        evidence: 'Missing tooltip',
        recommendation: 'Add tooltip',
        quickFixAvailable: false,
        documentationUrl: 'https://example.com',
      );

      final json = finding.toJson();
      final restored = Finding.fromJson(json);

      expect(restored.ruleId, finding.ruleId);
      expect(restored.title, finding.title);
      expect(restored.severity, finding.severity);
      expect(restored.confidence, finding.confidence);
      expect(restored.category, finding.category);
      expect(restored.location.line, 10);
      expect(restored.codeContext, finding.codeContext);
      expect(restored.evidence, finding.evidence);
      expect(restored.recommendation, finding.recommendation);
    });

    test('fingerprint is stable', () {
      final f1 = Finding(
        ruleId: 'QA001',
        ruleVersion: '1.0.0',
        title: 'Test',
        description: 'Desc',
        severity: Severity.warning,
        confidence: Confidence.high,
        category: Category.accessibility,
        location: const SourceLocation(
          filePath: '/path/file.dart',
          line: 10,
          column: 5,
        ),
      );

      final f2 = Finding(
        ruleId: 'QA001',
        ruleVersion: '1.0.0',
        title: 'Different title',
        description: 'Different desc',
        severity: Severity.error,
        confidence: Confidence.low,
        category: Category.accessibility,
        location: const SourceLocation(
          filePath: '/path/file.dart',
          line: 10,
          column: 5,
        ),
      );

      expect(f1.fingerprint, equals(f2.fingerprint));
    });

    test('copyWith preserves values', () {
      final finding = Finding(
        ruleId: 'QA001',
        ruleVersion: '1.0.0',
        title: 'Test',
        description: 'Desc',
        severity: Severity.warning,
        confidence: Confidence.high,
        category: Category.accessibility,
        location: const SourceLocation(
          filePath: '/path/file.dart',
          line: 10,
          column: 5,
        ),
      );

      final updated = finding.copyWith(status: FindingStatus.suppressed);
      expect(updated.status, FindingStatus.suppressed);
      expect(updated.ruleId, finding.ruleId);
      expect(updated.title, finding.title);
    });
  });

  group('ScanResult', () {
    test('severityCounts aggregation', () {
      final result = ScanResult(
        findings: [
          _makeFinding(Severity.warning),
          _makeFinding(Severity.warning),
          _makeFinding(Severity.error),
          _makeFinding(Severity.info),
        ],
        filesAnalyzed: 10,
        rulesApplied: 4,
        duration: const Duration(milliseconds: 500),
        timestamp: DateTime.now(),
      );

      expect(result.severityCounts['warning'], 2);
      expect(result.severityCounts['error'], 1);
      expect(result.severityCounts['info'], 1);
    });

    test('serialization round-trip', () {
      final result = ScanResult(
        findings: [_makeFinding(Severity.warning)],
        filesAnalyzed: 5,
        rulesApplied: 8,
        duration: const Duration(milliseconds: 250),
        timestamp: DateTime(2024, 1, 15, 10, 30),
        workspaceRoot: '/project',
        errors: ['test error'],
      );

      final json = result.toJson();
      final restored = ScanResult.fromJson(json);

      expect(restored.filesAnalyzed, 5);
      expect(restored.rulesApplied, 8);
      expect(restored.duration.inMilliseconds, 250);
      expect(restored.findings.length, 1);
      expect(restored.errors, ['test error']);
    });
  });
}

Finding _makeFinding(Severity severity) => Finding(
  ruleId: 'TEST',
  ruleVersion: '1.0.0',
  title: 'Test',
  description: 'Test',
  severity: severity,
  confidence: Confidence.medium,
  category: Category.accessibility,
  location: const SourceLocation(
    filePath: '/test.dart',
    line: 1,
    column: 1,
  ),
);
