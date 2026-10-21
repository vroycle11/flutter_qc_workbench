<p align="center">
  <img src="resources/logo.png" alt="Flutter QA Workbench" width="160" style="border-radius: 20px;" />
</p>

<h1 align="center">Flutter QA Workbench</h1>

<p align="center">
  <strong>Professional UI Quality Inspector, Accessibility (a11y) Checker & Layout Analyzer for Flutter Applications.</strong>
</p>

<p align="center">
  <a href="https://marketplace.visualstudio.com/items?itemName=VroyCLe.flutter-qa-workbench"><img src="https://img.shields.io/badge/VS_Code-1.85+-blue.svg?logo=visualstudiocode" alt="VS Code Support" /></a>
  <a href="https://github.com/vroycle11/flutter_qc_workbench"><img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License" /></a>
  <a href="https://www.linkedin.com/in/vaibhav-ghadge-315841168/"><img src="https://img.shields.io/badge/Developer-Vaibhav%20Ghadge-0A66C2.svg?logo=linkedin" alt="LinkedIn" /></a>
</p>

---

## 🌟 Overview

**Flutter QA Workbench** transforms Flutter quality assurance inside Visual Studio Code. Catch critical accessibility violations, layout overflows, unresponsive hardcoded dimensions, and widget nesting anti-patterns directly in your editor before they hit production.

With native Activity Bar integration, interactive webview dashboard, and real-time diagnostics mapped directly to your Dart files, **Flutter QA Workbench** gives you instantaneous feedback on your app's UI health.

---

## ✨ Key Features

### 🛡️ 1. Accessibility (a11y) Auditing
Assistive technology users deserve a first-class experience. The built-in rule engine detects:
- **`QA001` (IconButton missing tooltip)**: Flags buttons that lack screen reader descriptions.
- **`QA002` (Unlabeled interactive widgets)**: Detects raw `GestureDetector` or `InkWell` taps without accessible `Semantics`.
- **`QA003` (Images missing semantic labels)**: Identifies informational images that screen readers cannot describe.
- **`QA004` (Hidden interactive content)**: Catches `ExcludeSemantics` erroneously masking clickable elements.

### 📐 2. Layout & Responsive Quality
Prevent subtle UI crashes and broken layouts across varied screen sizes:
- **`QA101` (Unbounded Column in ScrollView)**: Flags unbounded vertical layouts inside `SingleChildScrollView` lacking `MainAxisSize.min`.
- **`QA102` (Expanded in ScrollView)**: Catches illegal `Expanded`/`Flexible` widgets inside unbounded viewports.
- **`QA103` (Excessive Widget Nesting)**: Identifies pyramid-of-doom widget trees (> 12 levels) that degrade performance and readability.
- **`QA104` (Hardcoded Pixel Dimensions)**: Flags brittle fixed widths/heights (> 300px) that fail across devices.

### ⚡ 3. Interactive Webview Dashboard
- **Live Metrics**: Real-time breakdown of findings grouped by severity (Critical, Error, Warning, Info) and category.
- **Instant Search & Filter**: Real-time keyword filtering and severity toggle chips.
- **One-Click Code Navigation**: Click any finding to instantly jump to the exact line and column in your editor.
- **SARIF & JSON Export**: Export your findings for CI/CD pipelines or GitHub Code Scanning with a single click.

### 🔄 4. Automated Workflow
- **Auto-Scan on Save**: Optionally scan your workspace automatically whenever a `.dart` file is saved, with configurable debouncing.
- **VS Code Problem Matchers**: Findings appear seamlessly in the native **Problems** panel as actionable diagnostics.

---

## ⌨️ Extension Commands

Access these commands from the Command Palette (`Cmd+Shift+P` / `Ctrl+Shift+P`):

| Command | Title | Description |
|---------|-------|-------------|
| `flutterQaWorkbench.runScan` | **Run QA Scan** | Execute a full quality scan of the current workspace |
| `flutterQaWorkbench.cancelScan` | **Cancel QA Scan** | Terminate an in-progress analysis scan |
| `flutterQaWorkbench.showReport` | **Show QA Report** | Open the interactive QA Workbench webview panel |
| `flutterQaWorkbench.exportJson` | **Export JSON Report** | Save findings formatted as structured JSON |
| `flutterQaWorkbench.exportSarif` | **Export SARIF Report** | Generate a SARIF report compatible with GitHub Code Scanning |
| `flutterQaWorkbench.openSettings` | **Open QA Settings** | Configure auto-scan and threshold options |

---

## ⚙️ Configuration Settings

Configure these in your VS Code `settings.json`:

```json
{
  // Automatically trigger a QA scan when a Dart file is saved
  "flutterQaWorkbench.autoScanOnSave": false,

  // Debounce delay in milliseconds for save triggers
  "flutterQaWorkbench.debounceMs": 1000,

  // Path to the Dart SDK executable (auto-detected if omitted)
  "flutterQaWorkbench.dartSdkPath": ""
}
```

---

## 🧑‍💻 Author & Maintainer

* **Developer**: [Vaibhav Ghadge](https://www.linkedin.com/in/vaibhav-ghadge-315841168/)
* **Publisher**: **VroyCLe**
* **LinkedIn**: [https://www.linkedin.com/in/vaibhav-ghadge-315841168/](https://www.linkedin.com/in/vaibhav-ghadge-315841168/)
* **Repository**: [github.com/vroycle11/flutter_qc_workbench](https://github.com/vroycle11/flutter_qc_workbench)

---

## 📄 License

This extension is open-sourced under the [MIT License](LICENSE).
