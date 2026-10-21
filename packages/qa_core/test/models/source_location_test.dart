import 'package:test/test.dart';
import 'package:qa_core/qa_core.dart';

void main() {
  group('SourceLocation', () {
    test('serialization round-trip', () {
      const loc = SourceLocation(
        filePath: '/path/to/file.dart',
        line: 42,
        column: 10,
        endLine: 42,
        endColumn: 25,
        offset: 1000,
        length: 15,
      );

      final json = loc.toJson();
      final restored = SourceLocation.fromJson(json);

      expect(restored.filePath, loc.filePath);
      expect(restored.line, loc.line);
      expect(restored.column, loc.column);
      expect(restored.endLine, loc.endLine);
      expect(restored.endColumn, loc.endColumn);
      expect(restored.offset, loc.offset);
      expect(restored.length, loc.length);
    });

    test('displayPath strips workspace root', () {
      const loc = SourceLocation(
        filePath: '/home/user/project/lib/main.dart',
        line: 1,
        column: 1,
      );

      expect(loc.displayPath('/home/user/project'), 'lib/main.dart');
    });

    test('displayPath returns full path when not in workspace', () {
      const loc = SourceLocation(
        filePath: '/other/path/file.dart',
        line: 1,
        column: 1,
      );

      expect(loc.displayPath('/home/user/project'), '/other/path/file.dart');
    });

    test('toString format', () {
      const loc = SourceLocation(
        filePath: '/path/file.dart',
        line: 10,
        column: 5,
      );

      expect(loc.toString(), '/path/file.dart:10:5');
    });

    test('equality', () {
      const loc1 = SourceLocation(
        filePath: '/path/file.dart',
        line: 10,
        column: 5,
      );
      const loc2 = SourceLocation(
        filePath: '/path/file.dart',
        line: 10,
        column: 5,
      );
      const loc3 = SourceLocation(
        filePath: '/path/file.dart',
        line: 11,
        column: 5,
      );

      expect(loc1, equals(loc2));
      expect(loc1, isNot(equals(loc3)));
    });
  });
}
