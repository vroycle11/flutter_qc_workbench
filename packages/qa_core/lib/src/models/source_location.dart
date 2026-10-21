/// Represents a location in a source file.
class SourceLocation {
  const SourceLocation({
    required this.filePath,
    required this.line,
    required this.column,
    this.endLine,
    this.endColumn,
    this.offset,
    this.length,
  });

  factory SourceLocation.fromJson(Map<String, dynamic> json) => SourceLocation(
    filePath: json['filePath'] as String,
    line: json['line'] as int,
    column: json['column'] as int,
    endLine: json['endLine'] as int?,
    endColumn: json['endColumn'] as int?,
    offset: json['offset'] as int?,
    length: json['length'] as int?,
  );

  /// Absolute path to the file.
  final String filePath;

  /// 1-based line number.
  final int line;

  /// 1-based column number.
  final int column;

  /// 1-based end line number (inclusive).
  final int? endLine;

  /// 1-based end column number.
  final int? endColumn;

  /// 0-based byte offset into the file.
  final int? offset;

  /// Length in bytes of the source span.
  final int? length;

  /// Relative display path for UI.
  String displayPath(String workspaceRoot) {
    if (filePath.startsWith(workspaceRoot)) {
      var rel = filePath.substring(workspaceRoot.length);
      if (rel.startsWith('/') || rel.startsWith('\\')) {
        rel = rel.substring(1);
      }
      return rel;
    }
    return filePath;
  }

  Map<String, dynamic> toJson() => {
    'filePath': filePath,
    'line': line,
    'column': column,
    if (endLine != null) 'endLine': endLine,
    if (endColumn != null) 'endColumn': endColumn,
    if (offset != null) 'offset': offset,
    if (length != null) 'length': length,
  };

  @override
  String toString() => '$filePath:$line:$column';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SourceLocation &&
          filePath == other.filePath &&
          line == other.line &&
          column == other.column;

  @override
  int get hashCode => Object.hash(filePath, line, column);
}
