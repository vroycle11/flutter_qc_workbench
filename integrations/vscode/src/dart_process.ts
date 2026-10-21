import * as vscode from 'vscode';
import * as cp from 'child_process';
import * as path from 'path';
import * as fs from 'fs';

interface ScanResult {
  findings: Finding[];
  filesAnalyzed: number;
  rulesApplied: number;
  durationMs: number;
  timestamp: string;
  workspaceRoot?: string;
  cancelled: boolean;
  errors: string[];
  severityCounts: Record<string, number>;
  categoryCounts: Record<string, number>;
}

interface Finding {
  ruleId: string;
  ruleVersion: string;
  title: string;
  description: string;
  severity: string;
  confidence: string;
  category: string;
  location: {
    filePath: string;
    line: number;
    column: number;
    endLine?: number;
    endColumn?: number;
  };
  codeContext?: string;
  evidence?: string;
  recommendation?: string;
  quickFixAvailable: boolean;
  documentationUrl?: string;
  status: string;
}

/**
 * Manages the Dart analysis CLI process.
 *
 * Spawns the QA Core CLI as a child process, collects JSON output,
 * and publishes VS Code diagnostics from findings.
 */
export class DartAnalysisProcess {
  private childProcess: cp.ChildProcess | undefined;
  private diagnosticCollection: vscode.DiagnosticCollection | undefined;
  private lastResult: ScanResult | undefined;
  private context: vscode.ExtensionContext;

  constructor(context: vscode.ExtensionContext) {
    this.context = context;
  }

  setDiagnosticCollection(collection: vscode.DiagnosticCollection): void {
    this.diagnosticCollection = collection;
  }

  getLastResult(): ScanResult | undefined {
    return this.lastResult;
  }

  /**
   * Run the Dart analysis CLI and return parsed results.
   */
  async runAnalysis(workspaceRoot: string): Promise<ScanResult> {
    return new Promise((resolve, reject) => {
      const dartExe = this.findDart();
      if (!dartExe) {
        reject(new Error(
          'Dart SDK not found. Install Flutter/Dart or set flutterQaWorkbench.dartSdkPath.'
        ));
        return;
      }

      const cliPath = this.findCliPath();
      if (!cliPath) {
        reject(new Error('QA Core CLI not found. Ensure packages/qa_core exists.'));
        return;
      }

      const args = [
        'run',
        cliPath,
        '--project', workspaceRoot,
        '--format', 'json',
      ];

      let stdout = '';
      let stderr = '';

      this.childProcess = cp.spawn(dartExe, args, {
        cwd: this.getQaCorePath(),
        env: { ...process.env },
      });

      this.childProcess.stdout?.on('data', (data: Buffer) => {
        stdout += data.toString();
      });

      this.childProcess.stderr?.on('data', (data: Buffer) => {
        stderr += data.toString();
      });

      this.childProcess.on('close', (code: number | null) => {
        this.childProcess = undefined;

        try {
          // The CLI outputs JSON to stdout. Extract JSON block in case of preamble (e.g. pub get / analyzer notices).
          let jsonStr = stdout.trim();
          const jsonStart = jsonStr.indexOf('{');
          const jsonEnd = jsonStr.lastIndexOf('}');
          if (jsonStart !== -1 && jsonEnd !== -1 && jsonEnd > jsonStart) {
            jsonStr = jsonStr.substring(jsonStart, jsonEnd + 1);
          }

          const result: ScanResult = JSON.parse(jsonStr);
          this.lastResult = result;

          // Publish diagnostics.
          this.publishDiagnostics(result);

          resolve(result);
        } catch (parseError) {
          // If exit code was non-zero and we can't parse, report error.
          if (code !== 0 && code !== 1) {
            reject(new Error(`CLI exited with code ${code}: ${stderr || stdout}`));
          } else {
            reject(new Error(`Failed to parse CLI output: ${parseError}`));
          }
        }
      });

      this.childProcess.on('error', (error: Error) => {
        this.childProcess = undefined;
        reject(new Error(`Failed to start CLI: ${error.message}`));
      });
    });
  }

  /**
   * Cancel a running analysis.
   */
  cancel(): void {
    if (this.childProcess) {
      this.childProcess.kill('SIGTERM');
      this.childProcess = undefined;
    }
  }

  /**
   * Publish findings as VS Code diagnostics.
   */
  private publishDiagnostics(result: ScanResult): void {
    if (!this.diagnosticCollection) { return; }
    this.diagnosticCollection.clear();

    const diagnosticMap = new Map<string, vscode.Diagnostic[]>();

    for (const finding of result.findings) {
      const filePath = finding.location.filePath;
      const range = new vscode.Range(
        new vscode.Position(finding.location.line - 1, finding.location.column - 1),
        new vscode.Position(
          (finding.location.endLine || finding.location.line) - 1,
          (finding.location.endColumn || finding.location.column + 10) - 1
        )
      );

      const severity = this.mapSeverity(finding.severity);
      const diagnostic = new vscode.Diagnostic(
        range,
        `[${finding.ruleId}] ${finding.title}: ${finding.description}`,
        severity
      );
      diagnostic.source = 'QA Workbench';
      diagnostic.code = finding.ruleId;

      const existing = diagnosticMap.get(filePath) || [];
      existing.push(diagnostic);
      diagnosticMap.set(filePath, existing);
    }

    for (const [filePath, diagnostics] of diagnosticMap) {
      this.diagnosticCollection.set(vscode.Uri.file(filePath), diagnostics);
    }
  }

  private mapSeverity(severity: string): vscode.DiagnosticSeverity {
    switch (severity) {
      case 'critical':
      case 'error':
        return vscode.DiagnosticSeverity.Error;
      case 'warning':
        return vscode.DiagnosticSeverity.Warning;
      case 'info':
      default:
        return vscode.DiagnosticSeverity.Information;
    }
  }

  private findDart(): string | undefined {
    // Check VS Code extension setting first.
    const configured = vscode.workspace
      .getConfiguration('flutterQaWorkbench')
      .get<string>('dartSdkPath', '');

    if (configured) {
      const configuredBin = path.join(configured, 'bin', process.platform === 'win32' ? 'dart.exe' : 'dart');
      if (fs.existsSync(configuredBin)) { return configuredBin; }
      if (fs.existsSync(configured)) { return configured; }
    }

    // Check PATH.
    try {
      cp.execSync('dart --version', { stdio: 'pipe' });
      return 'dart';
    } catch {
      // Continue search in other locations
    }

    // Check VS Code Dart / Flutter extension configurations.
    const dartConfig = vscode.workspace.getConfiguration('dart');
    const flutterSdk = dartConfig.get<string>('flutterSdkPath');
    if (flutterSdk) {
      const flutterDart = path.join(flutterSdk, 'bin', process.platform === 'win32' ? 'dart.bat' : 'dart');
      if (fs.existsSync(flutterDart)) { return flutterDart; }
      const cachedDart = path.join(flutterSdk, 'bin', 'cache', 'dart-sdk', 'bin', process.platform === 'win32' ? 'dart.exe' : 'dart');
      if (fs.existsSync(cachedDart)) { return cachedDart; }
    }
    const dartSdk = dartConfig.get<string>('sdkPath');
    if (dartSdk) {
      const sdkDart = path.join(dartSdk, 'bin', process.platform === 'win32' ? 'dart.exe' : 'dart');
      if (fs.existsSync(sdkDart)) { return sdkDart; }
    }

    // Common standard installations (macOS / Linux / Windows).
    const home = process.env.HOME || process.env.USERPROFILE || '';
    const candidates = [
      path.join(home, 'development', 'flutter', 'bin', process.platform === 'win32' ? 'dart.bat' : 'dart'),
      path.join(home, 'flutter', 'bin', process.platform === 'win32' ? 'dart.bat' : 'dart'),
      '/opt/homebrew/bin/dart',
      '/usr/local/bin/dart',
      '/usr/bin/dart',
      'C:\\src\\flutter\\bin\\dart.bat',
      'C:\\tools\\dart-sdk\\bin\\dart.exe',
    ];
    for (const candidate of candidates) {
      if (candidate && fs.existsSync(candidate)) {
        return candidate;
      }
    }

    return undefined;
  }

  private findCliPath(): string | undefined {
    return 'bin/cli.dart';
  }

  private getQaCorePath(): string {
    // Resolve relative to the extension root to find the qa_core package.
    const extensionPath = this.context.extensionPath;

    // In production: qa_core is bundled directly inside the extension.
    const prodPath = path.resolve(extensionPath, 'qa_core');

    // In development: extension is at integrations/vscode, qa_core at packages/qa_core.
    const devPath = path.resolve(extensionPath, '../../packages/qa_core');

    if (fs.existsSync(path.join(prodPath, 'pubspec.yaml'))) {
      return prodPath;
    }
    if (fs.existsSync(path.join(devPath, 'pubspec.yaml'))) {
      return devPath;
    }

    return prodPath; // Fallback.
  }

  dispose(): void {
    this.cancel();
    this.diagnosticCollection?.dispose();
  }
}
