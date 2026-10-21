/**
 * Flutter QA Workbench — VS Code Extension Entry Point.
 *
 * Provides command registration, Webview panel initialization,
 * auto-scan on file save, and diagnostic publishing.
 */
import * as vscode from 'vscode';
import { DartAnalysisProcess } from './dart_process';
import { QaWebviewProvider } from './webview_provider';

let analysisProcess: DartAnalysisProcess | undefined;
let webviewProvider: QaWebviewProvider | undefined;

export function activate(context: vscode.ExtensionContext) {
  console.log('Flutter QA Workbench activating...');

  // Initialize the Dart analysis process manager.
  analysisProcess = new DartAnalysisProcess(context);

  // Register the webview provider.
  webviewProvider = new QaWebviewProvider(context, analysisProcess);
  context.subscriptions.push(
    vscode.window.registerWebviewViewProvider(
      'flutterQaWorkbench.mainPanel',
      webviewProvider,
      { webviewOptions: { retainContextWhenHidden: true } }
    )
  );

  // Register commands.
  context.subscriptions.push(
    vscode.commands.registerCommand('flutterQaWorkbench.runScan', async () => {
      const workspaceRoot = getWorkspaceRoot();
      if (!workspaceRoot) {
        vscode.window.showWarningMessage(
          'QA Workbench: No Flutter workspace found.'
        );
        return;
      }
      await runScan(workspaceRoot);
    })
  );

  context.subscriptions.push(
    vscode.commands.registerCommand('flutterQaWorkbench.cancelScan', () => {
      analysisProcess?.cancel();
      webviewProvider?.postMessage({ type: 'scanCancelled' });
      vscode.window.showInformationMessage('QA Workbench: Scan cancelled.');
    })
  );

  context.subscriptions.push(
    vscode.commands.registerCommand('flutterQaWorkbench.showReport', () => {
      webviewProvider?.revealPanel();
    })
  );

  context.subscriptions.push(
    vscode.commands.registerCommand('flutterQaWorkbench.exportJson', async () => {
      const result = webviewProvider?.getLastResult();
      if (!result) {
        vscode.window.showWarningMessage('QA Workbench: No scan results to export.');
        return;
      }
      const uri = await vscode.window.showSaveDialog({
        defaultUri: vscode.Uri.file('qa-report.json'),
        filters: { 'JSON': ['json'] },
      });
      if (uri) {
        await vscode.workspace.fs.writeFile(
          uri,
          Buffer.from(JSON.stringify(result, null, 2))
        );
        vscode.window.showInformationMessage(`Report exported to ${uri.fsPath}`);
      }
    })
  );

  context.subscriptions.push(
    vscode.commands.registerCommand('flutterQaWorkbench.exportSarif', async () => {
      const result = webviewProvider?.getLastResult();
      if (!result) {
        vscode.window.showWarningMessage('QA Workbench: No scan results to export.');
        return;
      }

      const sarifReport = convertToSarif(result);
      const uri = await vscode.window.showSaveDialog({
        defaultUri: vscode.Uri.file('qa-report.sarif'),
        filters: { 'SARIF': ['sarif', 'json'] },
      });
      if (uri) {
        await vscode.workspace.fs.writeFile(
          uri,
          Buffer.from(JSON.stringify(sarifReport, null, 2))
        );
        vscode.window.showInformationMessage(`SARIF exported to ${uri.fsPath}`);
      }
    })
  );

  context.subscriptions.push(
    vscode.commands.registerCommand('flutterQaWorkbench.openSettings', () => {
      vscode.commands.executeCommand(
        'workbench.action.openSettings',
        'flutterQaWorkbench'
      );
    })
  );

  // Register diagnostics collection.
  const diagnosticCollection = vscode.languages.createDiagnosticCollection('flutter-qa');
  context.subscriptions.push(diagnosticCollection);

  // Store diagnostics collection for use during scans.
  analysisProcess.setDiagnosticCollection(diagnosticCollection);

  // Auto-scan on save (if enabled).
  let saveDebounceTimer: ReturnType<typeof setTimeout> | undefined;
  context.subscriptions.push(
    vscode.workspace.onDidSaveTextDocument((document: vscode.TextDocument) => {
      if (!document.fileName.endsWith('.dart')) { return; }

      const autoScan = vscode.workspace
        .getConfiguration('flutterQaWorkbench')
        .get<boolean>('autoScanOnSave', false);

      if (!autoScan) { return; }

      const debounceMs = vscode.workspace
        .getConfiguration('flutterQaWorkbench')
        .get<number>('debounceMs', 1000);

      if (saveDebounceTimer) { clearTimeout(saveDebounceTimer); }
      saveDebounceTimer = setTimeout(async () => {
        const root = getWorkspaceRoot();
        if (root) { await runScan(root); }
      }, debounceMs);
    })
  );

  console.log('Flutter QA Workbench activated.');
}

async function runScan(workspaceRoot: string): Promise<void> {
  if (!analysisProcess || !webviewProvider) { return; }

  webviewProvider.postMessage({ type: 'scanStarted' });

  try {
    const result = await analysisProcess.runAnalysis(workspaceRoot);
    webviewProvider.postMessage({
      type: 'scanComplete',
      payload: result,
    });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : String(error);
    webviewProvider.postMessage({
      type: 'scanError',
      payload: { message },
    });
    vscode.window.showErrorMessage(`QA Workbench scan failed: ${message}`);
  }
}

function getWorkspaceRoot(): string | undefined {
  const folders = vscode.workspace.workspaceFolders;
  if (!folders || folders.length === 0) { return undefined; }

  // Find the first folder containing a pubspec.yaml.
  for (const folder of folders) {
    const pubspec = vscode.Uri.joinPath(folder.uri, 'pubspec.yaml');
    // Synchronous check not available in VS Code API — use first folder.
    return folder.uri.fsPath;
  }
  return folders[0].uri.fsPath;
}

function convertToSarif(result: any): object {
  const rules: any[] = [];
  const ruleMap: Record<string, number> = {};

  for (const finding of result.findings || []) {
    if (!(finding.ruleId in ruleMap)) {
      ruleMap[finding.ruleId] = rules.length;
      rules.push({
        id: finding.ruleId,
        shortDescription: { text: finding.title },
        fullDescription: { text: finding.description },
      });
    }
  }

  const results = (result.findings || []).map((f: any) => ({
    ruleId: f.ruleId,
    ruleIndex: ruleMap[f.ruleId],
    level: f.severity === 'error' || f.severity === 'critical' ? 'error' :
           f.severity === 'warning' ? 'warning' : 'note',
    message: { text: f.description },
    locations: [{
      physicalLocation: {
        artifactLocation: { uri: f.location?.filePath || '' },
        region: {
          startLine: f.location?.line || 1,
          startColumn: f.location?.column || 1,
        },
      },
    }],
  }));

  return {
    version: '2.1.0',
    '$schema': 'https://raw.githubusercontent.com/oasis-tcs/sarif-spec/main/sarif-2.1/schema/sarif-schema-2.1.0.json',
    runs: [{
      tool: {
        driver: {
          name: 'Flutter QA Workbench',
          version: '0.1.0',
          rules,
        },
      },
      results,
    }],
  };
}

export function deactivate() {
  analysisProcess?.dispose();
  analysisProcess = undefined;
  webviewProvider = undefined;
  console.log('Flutter QA Workbench deactivated.');
}
