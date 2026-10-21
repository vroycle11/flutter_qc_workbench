# Flutter QA Workbench — Core Analysis Engine (`qa_core`)

`qa_core` is a high-performance static analysis engine designed specifically for Flutter applications. It detects accessibility (a11y) barriers, layout traps, anti-patterns, and responsive design flaws with zero external daemon requirements.

---

## Features

- **Accessibility Rules**:
  - `QA001`: `IconButton` missing `tooltip`
  - `QA002`: Interactive widgets (`GestureDetector`, `InkWell`) lacking `Semantics` wrapper
  - `QA003`: `Image` widgets missing `semanticLabel` or explicit `excludeFromSemantics`
  - `QA004`: `ExcludeSemantics` hiding interactive widgets
- **Layout & Responsiveness Rules**:
  - `QA101`: Unbounded `Column` / `Row` inside `SingleChildScrollView` without `MainAxisSize.min`
  - `QA102`: `Expanded` or `Flexible` placed inside scrollable views
  - `QA103`: Excessively deep widget tree nesting (> 12 levels)
  - `QA104`: Hardcoded pixel dimensions (> 300px) that fail on variable screen sizes
- **Output Formats**:
  - JSON (machine-readable, consumable by IDEs and CI/CD)
  - SARIF (Static Analysis Results Interchange Format, compatible with GitHub Code Scanning)
  - Human-readable formatted terminal table summary
- **Configuration**:
  - Custom rules configuration via `qa_workbench.yaml` or `.qa_workbench.yaml`
  - Per-rule severity overrides (`critical`, `error`, `warning`, `info`)
  - File exclusion glob patterns (`generated/**`, `*.g.dart`, `*.freezed.dart`)

---

## Installation & CLI Usage

### Running Locally

```bash
cd packages/qa_core
dart run bin/cli.dart --project /path/to/flutter_app
```

### CLI Options

| Flag | Default | Description |
|------|---------|-------------|
| `--project`, `-p` | `.` | Target Flutter project root directory |
| `--config`, `-c` | Auto-detected | Path to `qa_workbench.yaml` configuration file |
| `--format`, `-f` | `text` | Output format: `text`, `json`, or `sarif` |
| `--output`, `-o` | stdout | Path to write report output file |
| `--verbose`, `-v` | `false` | Enable verbose logging during scan |
| `--version` | — | Display engine version |
| `--help`, `-h` | — | Display usage information |

### Example CLI Commands

```bash
# JSON output for tooling integration
dart run bin/cli.dart --project ../../example --format json

# SARIF output for GitHub Actions / CI scanning
dart run bin/cli.dart --project ../../example --format sarif --output results.sarif

# Text summary with verbose progress
dart run bin/cli.dart --project ../../example --verbose
```

---

## Configuration (`qa_workbench.yaml`)

Place a `qa_workbench.yaml` file in your Flutter project root to customize rule behavior:

```yaml
rules:
  QA001:
    enabled: true
    severity: warning
  QA002:
    enabled: true
    severity: warning
  QA104:
    enabled: true
    severity: info

exclude:
  - "lib/generated/**"
  - "**/*.g.dart"
  - "**/*.freezed.dart"
```

---

## Testing

Run all unit and integration tests:

```bash
dart test
```
