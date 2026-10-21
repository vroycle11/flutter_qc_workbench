import * as vscode from 'vscode';
import { DartAnalysisProcess } from './dart_process';

/**
 * Provides the QA Workbench webview panel with a premium developer UI.
 */
export class QaWebviewProvider implements vscode.WebviewViewProvider {
  private view?: vscode.WebviewView;
  private context: vscode.ExtensionContext;
  private analysisProcess: DartAnalysisProcess;

  constructor(context: vscode.ExtensionContext, analysisProcess: DartAnalysisProcess) {
    this.context = context;
    this.analysisProcess = analysisProcess;
  }

  resolveWebviewView(
    webviewView: vscode.WebviewView,
    _context: vscode.WebviewViewResolveContext,
    _token: vscode.CancellationToken
  ): void {
    this.view = webviewView;

    webviewView.webview.options = {
      enableScripts: true,
      localResourceRoots: [
        vscode.Uri.joinPath(this.context.extensionUri, 'resources'),
      ],
    };

    const logoUri = webviewView.webview.asWebviewUri(
      vscode.Uri.joinPath(this.context.extensionUri, 'resources', 'logo.png')
    );

    webviewView.webview.html = this.getHtml(logoUri);

    // Handle messages from webview.
    webviewView.webview.onDidReceiveMessage(
      async (message: any) => {
        switch (message.type) {
          case 'runScan':
            await vscode.commands.executeCommand('flutterQaWorkbench.runScan');
            break;
          case 'cancelScan':
            await vscode.commands.executeCommand('flutterQaWorkbench.cancelScan');
            break;
          case 'navigateToFile':
            await this.navigateToFile(
              message.filePath,
              message.line,
              message.column
            );
            break;
          case 'exportJson':
            await vscode.commands.executeCommand('flutterQaWorkbench.exportJson');
            break;
          case 'exportSarif':
            await vscode.commands.executeCommand('flutterQaWorkbench.exportSarif');
            break;
        }
      },
      undefined,
      this.context.subscriptions
    );
  }

  postMessage(message: any): void {
    this.view?.webview.postMessage(message);
  }

  revealPanel(): void {
    this.view?.show?.(true);
  }

  getLastResult(): any {
    return this.analysisProcess.getLastResult();
  }

  private async navigateToFile(
    filePath: string,
    line: number,
    column: number
  ): Promise<void> {
    try {
      const uri = vscode.Uri.file(filePath);
      const doc = await vscode.workspace.openTextDocument(uri);
      const position = new vscode.Position(line - 1, column - 1);
      await vscode.window.showTextDocument(doc, {
        selection: new vscode.Range(position, position),
        preserveFocus: false,
      });
    } catch (error) {
      vscode.window.showErrorMessage(`Could not open file: ${filePath}`);
    }
  }

  private getHtml(logoUri?: vscode.Uri): string {
    return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>QA Workbench</title>
<style>
  :root {
    --bg-primary: var(--vscode-editor-background);
    --bg-secondary: var(--vscode-sideBar-background);
    --bg-hover: var(--vscode-list-hoverBackground);
    --bg-active: var(--vscode-list-activeSelectionBackground);
    --fg-primary: var(--vscode-editor-foreground);
    --fg-secondary: var(--vscode-descriptionForeground);
    --fg-muted: var(--vscode-disabledForeground);
    --border: var(--vscode-panel-border);
    --accent: var(--vscode-focusBorder);
    --error: var(--vscode-errorForeground, #f44747);
    --warning: var(--vscode-editorWarning-foreground, #cca700);
    --info: var(--vscode-editorInfo-foreground, #3794ff);
    --success: var(--vscode-testing-iconPassed, #73c991);
    --badge-bg: var(--vscode-badge-background);
    --badge-fg: var(--vscode-badge-foreground);
    --input-bg: var(--vscode-input-background);
    --input-border: var(--vscode-input-border);
    --input-fg: var(--vscode-input-foreground);
    --button-bg: var(--vscode-button-background);
    --button-fg: var(--vscode-button-foreground);
    --button-hover: var(--vscode-button-hoverBackground);
    --font-family: var(--vscode-font-family, -apple-system, system-ui, sans-serif);
    --font-size: var(--vscode-font-size, 13px);
    --mono-family: var(--vscode-editor-font-family, 'SF Mono', Menlo, monospace);
    --radius: 4px;
    --spacing-xs: 4px;
    --spacing-sm: 8px;
    --spacing-md: 12px;
    --spacing-lg: 16px;
    --spacing-xl: 24px;
    --transition: 150ms ease;
  }

  * { margin: 0; padding: 0; box-sizing: border-box; }

  body {
    font-family: var(--font-family);
    font-size: var(--font-size);
    color: var(--fg-primary);
    background: var(--bg-primary);
    line-height: 1.5;
    overflow-x: hidden;
  }

  .container { padding: var(--spacing-md); }

  /* Header */
  .header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: var(--spacing-md);
    border-bottom: 1px solid var(--border);
    gap: var(--spacing-sm);
  }

  .header-title {
    font-size: 11px;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    color: var(--fg-secondary);
  }

  .header-actions {
    display: flex;
    gap: var(--spacing-xs);
  }

  /* Buttons */
  .btn {
    display: inline-flex;
    align-items: center;
    gap: var(--spacing-xs);
    padding: 4px 10px;
    border: none;
    border-radius: var(--radius);
    cursor: pointer;
    font-size: 12px;
    font-family: var(--font-family);
    transition: background var(--transition), opacity var(--transition);
    white-space: nowrap;
  }

  .btn-primary {
    background: var(--button-bg);
    color: var(--button-fg);
  }
  .btn-primary:hover { background: var(--button-hover); }

  .btn-ghost {
    background: transparent;
    color: var(--fg-secondary);
    padding: 4px 6px;
  }
  .btn-ghost:hover { background: var(--bg-hover); color: var(--fg-primary); }

  .btn:disabled { opacity: 0.4; cursor: default; }

  .btn-icon {
    background: transparent;
    border: none;
    color: var(--fg-secondary);
    cursor: pointer;
    padding: 2px 4px;
    border-radius: var(--radius);
    font-size: 14px;
    line-height: 1;
  }
  .btn-icon:hover { background: var(--bg-hover); color: var(--fg-primary); }

  /* Overview stats */
  .stats-grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: var(--spacing-sm);
    padding: var(--spacing-md);
  }

  .stat-card {
    padding: var(--spacing-sm) var(--spacing-md);
    border-radius: var(--radius);
    border: 1px solid var(--border);
    background: var(--bg-secondary);
  }

  .stat-value {
    font-size: 20px;
    font-weight: 700;
    line-height: 1.2;
    font-variant-numeric: tabular-nums;
  }

  .stat-label {
    font-size: 10px;
    text-transform: uppercase;
    letter-spacing: 0.3px;
    color: var(--fg-secondary);
    margin-top: 2px;
  }

  .stat-critical .stat-value { color: var(--error); }
  .stat-warning .stat-value { color: var(--warning); }
  .stat-info .stat-value { color: var(--info); }
  .stat-clean .stat-value { color: var(--success); }

  /* Scan info */
  .scan-info {
    padding: var(--spacing-sm) var(--spacing-md);
    font-size: 11px;
    color: var(--fg-secondary);
    display: flex;
    justify-content: space-between;
    border-bottom: 1px solid var(--border);
  }

  /* Search and filter */
  .toolbar {
    padding: var(--spacing-sm) var(--spacing-md);
    border-bottom: 1px solid var(--border);
    display: flex;
    flex-direction: column;
    gap: var(--spacing-xs);
  }

  .search-input {
    width: 100%;
    padding: 4px 8px;
    border: 1px solid var(--input-border);
    border-radius: var(--radius);
    background: var(--input-bg);
    color: var(--input-fg);
    font-family: var(--font-family);
    font-size: 12px;
    outline: none;
  }
  .search-input:focus { border-color: var(--accent); }
  .search-input::placeholder { color: var(--fg-muted); }

  .filter-row {
    display: flex;
    gap: var(--spacing-xs);
    flex-wrap: wrap;
  }

  .filter-chip {
    padding: 2px 8px;
    border-radius: 10px;
    font-size: 10px;
    cursor: pointer;
    border: 1px solid var(--border);
    background: transparent;
    color: var(--fg-secondary);
    transition: all var(--transition);
    font-family: var(--font-family);
  }
  .filter-chip:hover { background: var(--bg-hover); }
  .filter-chip.active {
    background: var(--accent);
    color: var(--badge-fg);
    border-color: var(--accent);
  }

  /* Findings list */
  .findings-list {
    max-height: calc(100vh - 350px);
    overflow-y: auto;
  }

  .finding-item {
    padding: var(--spacing-sm) var(--spacing-md);
    border-bottom: 1px solid var(--border);
    cursor: pointer;
    transition: background var(--transition);
  }
  .finding-item:hover { background: var(--bg-hover); }
  .finding-item.selected { background: var(--bg-active); }

  .finding-header {
    display: flex;
    align-items: center;
    gap: var(--spacing-sm);
  }

  .severity-dot {
    width: 8px;
    height: 8px;
    border-radius: 50%;
    flex-shrink: 0;
  }
  .severity-dot.critical { background: var(--error); }
  .severity-dot.error { background: var(--error); }
  .severity-dot.warning { background: var(--warning); }
  .severity-dot.info { background: var(--info); }

  .finding-title {
    font-size: 12px;
    font-weight: 500;
    flex: 1;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .finding-rule {
    font-size: 10px;
    color: var(--fg-muted);
    font-family: var(--mono-family);
  }

  .finding-location {
    font-size: 11px;
    color: var(--fg-secondary);
    margin-top: 2px;
    padding-left: calc(8px + var(--spacing-sm));
  }

  /* Finding detail */
  .finding-detail {
    padding: var(--spacing-md);
    border-top: 1px solid var(--border);
    display: none;
  }
  .finding-detail.visible { display: block; }

  .detail-section {
    margin-bottom: var(--spacing-md);
  }

  .detail-label {
    font-size: 10px;
    text-transform: uppercase;
    letter-spacing: 0.3px;
    color: var(--fg-muted);
    margin-bottom: var(--spacing-xs);
  }

  .detail-text {
    font-size: 12px;
    color: var(--fg-primary);
    line-height: 1.5;
  }

  .code-context {
    font-family: var(--mono-family);
    font-size: 11px;
    padding: var(--spacing-sm);
    background: var(--bg-secondary);
    border-radius: var(--radius);
    border: 1px solid var(--border);
    overflow-x: auto;
    white-space: pre;
  }

  .recommendation {
    padding: var(--spacing-sm);
    background: color-mix(in srgb, var(--info) 10%, transparent);
    border-left: 2px solid var(--info);
    border-radius: 0 var(--radius) var(--radius) 0;
    font-size: 12px;
  }

  /* States */
  .state-container {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: var(--spacing-xl);
    text-align: center;
    min-height: 200px;
  }

  .state-icon {
    font-size: 32px;
    margin-bottom: var(--spacing-md);
    opacity: 0.6;
  }

  .state-title {
    font-size: 14px;
    font-weight: 600;
    margin-bottom: var(--spacing-xs);
  }

  .state-description {
    font-size: 12px;
    color: var(--fg-secondary);
    max-width: 280px;
  }

  /* Loading spinner */
  .spinner {
    width: 28px;
    height: 28px;
    border: 2px solid var(--border);
    border-top-color: var(--accent);
    border-radius: 50%;
    animation: spin 0.8s linear infinite;
    margin-bottom: var(--spacing-md);
  }

  @keyframes spin { to { transform: rotate(360deg); } }

  .progress-text {
    font-size: 11px;
    color: var(--fg-secondary);
    margin-top: var(--spacing-xs);
  }

  /* Scrollbar */
  ::-webkit-scrollbar { width: 6px; }
  ::-webkit-scrollbar-track { background: transparent; }
  ::-webkit-scrollbar-thumb {
    background: var(--fg-muted);
    border-radius: 3px;
  }
  ::-webkit-scrollbar-thumb:hover { background: var(--fg-secondary); }

  /* Badge */
  .badge {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    min-width: 18px;
    height: 18px;
    padding: 0 5px;
    border-radius: 9px;
    font-size: 10px;
    font-weight: 600;
    background: var(--badge-bg);
    color: var(--badge-fg);
  }

  /* Keyboard focus */
  .finding-item:focus {
    outline: 1px solid var(--accent);
    outline-offset: -1px;
  }

  @media (prefers-reduced-motion: reduce) {
    *, *::before, *::after {
      animation-duration: 0.01ms !important;
      transition-duration: 0.01ms !important;
    }
  }
</style>
</head>
<body>
  <div id="app">
    <!-- Initial empty state -->
    <div id="state-empty" class="state-container">
      ${logoUri ? `<img src="${logoUri}" alt="Flutter QA Workbench" style="width: 80px; height: 80px; border-radius: 16px; margin-bottom: 12px; box-shadow: 0 4px 16px rgba(0,0,0,0.25);" />` : '<div class="state-icon">🛡️</div>'}
      <div class="state-title">QA Workbench</div>
      <div class="state-description">
        Analyze your Flutter project for accessibility issues,
        layout problems, and quality improvements.
      </div>
      <button class="btn btn-primary" style="margin-top: 16px" onclick="startScan()">
        ▶ Run QA Scan
      </button>
    </div>

    <!-- Loading state -->
    <div id="state-loading" class="state-container" style="display: none">
      <div class="spinner"></div>
      <div class="state-title">Analyzing…</div>
      <div class="progress-text" id="progress-text">Scanning Flutter project</div>
      <button class="btn btn-ghost" style="margin-top: 12px" onclick="cancelScan()">
        Cancel
      </button>
    </div>

    <!-- Error state -->
    <div id="state-error" class="state-container" style="display: none">
      <div class="state-icon">⚠️</div>
      <div class="state-title">Scan Failed</div>
      <div class="state-description" id="error-message"></div>
      <button class="btn btn-primary" style="margin-top: 16px" onclick="startScan()">
        Retry
      </button>
    </div>

    <!-- Results state -->
    <div id="state-results" style="display: none">
      <div class="header">
        <div style="display: flex; align-items: center; gap: 8px;">
          ${logoUri ? `<img src="${logoUri}" alt="Logo" style="width: 18px; height: 18px; border-radius: 4px;" />` : ''}
          <span class="header-title">QA Workbench</span>
        </div>
        <div class="header-actions">
          <button class="btn-icon" onclick="startScan()" title="Run Scan" aria-label="Run scan">▶</button>
          <button class="btn-icon" onclick="exportReport()" title="Export" aria-label="Export report">📥</button>
        </div>
      </div>

      <div class="stats-grid" id="stats-grid"></div>

      <div class="scan-info" id="scan-info"></div>

      <div class="toolbar">
        <input
          type="text"
          class="search-input"
          id="search-input"
          placeholder="Search findings…"
          aria-label="Search findings"
          oninput="filterFindings()"
        >
        <div class="filter-row" id="filter-row"></div>
      </div>

      <div class="findings-list" id="findings-list" role="listbox" aria-label="Quality findings"></div>

      <div class="finding-detail" id="finding-detail" role="complementary" aria-label="Finding details"></div>
    </div>
  </div>

<script>
  const vscode = acquireVsCodeApi();
  let findings = [];
  let selectedIndex = -1;
  let activeFilters = { severity: null, category: null };

  // Message handler.
  window.addEventListener('message', (event) => {
    const msg = event.data;
    switch (msg.type) {
      case 'scanStarted':
        showState('loading');
        break;
      case 'scanComplete':
        showResults(msg.payload);
        break;
      case 'scanError':
        showError(msg.payload.message);
        break;
      case 'scanCancelled':
        showState('empty');
        break;
    }
  });

  function showState(state) {
    document.getElementById('state-empty').style.display = state === 'empty' ? 'flex' : 'none';
    document.getElementById('state-loading').style.display = state === 'loading' ? 'flex' : 'none';
    document.getElementById('state-error').style.display = state === 'error' ? 'flex' : 'none';
    document.getElementById('state-results').style.display = state === 'results' ? 'block' : 'none';
  }

  function showError(message) {
    document.getElementById('error-message').textContent = message;
    showState('error');
  }

  function showResults(result) {
    findings = result.findings || [];
    selectedIndex = -1;

    // Stats grid.
    const counts = result.severityCounts || {};
    const total = findings.length;
    const statsHtml =
      '<div class="stat-card ' + (total === 0 ? 'stat-clean' : 'stat-critical') + '">' +
        '<div class="stat-value">' + total + '</div>' +
        '<div class="stat-label">Total Findings</div>' +
      '</div>' +
      '<div class="stat-card stat-critical">' +
        '<div class="stat-value">' + ((counts.critical || 0) + (counts.error || 0)) + '</div>' +
        '<div class="stat-label">Errors</div>' +
      '</div>' +
      '<div class="stat-card stat-warning">' +
        '<div class="stat-value">' + (counts.warning || 0) + '</div>' +
        '<div class="stat-label">Warnings</div>' +
      '</div>' +
      '<div class="stat-card stat-info">' +
        '<div class="stat-value">' + (counts.info || 0) + '</div>' +
        '<div class="stat-label">Info</div>' +
      '</div>';
    document.getElementById('stats-grid').innerHTML = statsHtml;

    // Scan info.
    const duration = result.durationMs || 0;
    const files = result.filesAnalyzed || 0;
    const rules = result.rulesApplied || 0;
    document.getElementById('scan-info').innerHTML =
      '<span>' + files + ' files · ' + rules + ' rules</span>' +
      '<span>' + duration + 'ms' + (result.cancelled ? ' (cancelled)' : '') + '</span>';

    // Filter chips.
    const categories = [...new Set(findings.map(f => f.category))];
    let filterHtml =
      '<button class="filter-chip active" data-severity="all" onclick="toggleFilter(this, \\'severity\\', \\'all\\')">All</button>' +
      '<button class="filter-chip" data-severity="error" onclick="toggleFilter(this, \\'severity\\', \\'error\\')">Errors</button>' +
      '<button class="filter-chip" data-severity="warning" onclick="toggleFilter(this, \\'severity\\', \\'warning\\')">Warnings</button>' +
      '<button class="filter-chip" data-severity="info" onclick="toggleFilter(this, \\'severity\\', \\'info\\')">Info</button>';
    document.getElementById('filter-row').innerHTML = filterHtml;

    renderFindings(findings);
    showState('results');
  }

  function renderFindings(filtered) {
    const list = document.getElementById('findings-list');
    if (filtered.length === 0) {
      list.innerHTML =
        '<div class="state-container">' +
          '<div class="state-icon">✨</div>' +
          '<div class="state-title">' +
            (findings.length === 0 ? 'No Issues Found' : 'No Matching Findings') +
          '</div>' +
          '<div class="state-description">' +
            (findings.length === 0
              ? 'Your Flutter project looks good! All quality checks passed.'
              : 'Try adjusting your search or filters.') +
          '</div>' +
        '</div>';
      document.getElementById('finding-detail').className = 'finding-detail';
      return;
    }

    let html = '';
    filtered.forEach((f, i) => {
      const relPath = f.location?.filePath?.split('/').slice(-2).join('/') || '';
      html +=
        '<div class="finding-item" tabindex="0" role="option" data-index="' + i + '" ' +
             'onclick="selectFinding(' + i + ')" ' +
             'onkeydown="handleFindingKey(event, ' + i + ')" ' +
             'aria-label="' + escapeHtml(f.title) + '">' +
          '<div class="finding-header">' +
            '<div class="severity-dot ' + f.severity + '" aria-label="' + f.severity + '"></div>' +
            '<span class="finding-title">' + escapeHtml(f.title) + '</span>' +
            '<span class="finding-rule">' + escapeHtml(f.ruleId) + '</span>' +
          '</div>' +
          '<div class="finding-location">' + escapeHtml(relPath) + ':' + (f.location?.line || '') + '</div>' +
        '</div>';
    });
    list.innerHTML = html;
  }

  function selectFinding(index) {
    const filtered = getFilteredFindings();
    if (index < 0 || index >= filtered.length) return;

    selectedIndex = index;
    const f = filtered[index];

    // Update selection highlight.
    document.querySelectorAll('.finding-item').forEach((el, i) => {
      el.classList.toggle('selected', i === index);
    });

    // Show detail.
    const detail = document.getElementById('finding-detail');
    let html =
      '<div class="detail-section">' +
        '<div class="detail-label">Description</div>' +
        '<div class="detail-text">' + escapeHtml(f.description) + '</div>' +
      '</div>';

    if (f.evidence) {
      html +=
        '<div class="detail-section">' +
          '<div class="detail-label">Evidence</div>' +
          '<div class="detail-text">' + escapeHtml(f.evidence) + '</div>' +
        '</div>';
    }

    if (f.codeContext) {
      html +=
        '<div class="detail-section">' +
          '<div class="detail-label">Code</div>' +
          '<div class="code-context">' + escapeHtml(f.codeContext) + '</div>' +
        '</div>';
    }

    if (f.recommendation) {
      html +=
        '<div class="detail-section">' +
          '<div class="detail-label">Recommendation</div>' +
          '<div class="recommendation">' + escapeHtml(f.recommendation) + '</div>' +
        '</div>';
    }

    html +=
      '<div class="detail-section">' +
        '<button class="btn btn-primary" onclick="navigateToSource()" aria-label="Open in editor">Open in Editor</button>' +
      '</div>';

    detail.innerHTML = html;
    detail.className = 'finding-detail visible';
  }

  function handleFindingKey(event, index) {
    if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault();
      selectFinding(index);
    } else if (event.key === 'ArrowDown') {
      event.preventDefault();
      const items = document.querySelectorAll('.finding-item');
      if (index + 1 < items.length) items[index + 1].focus();
    } else if (event.key === 'ArrowUp') {
      event.preventDefault();
      const items = document.querySelectorAll('.finding-item');
      if (index - 1 >= 0) items[index - 1].focus();
    }
  }

  function navigateToSource() {
    const filtered = getFilteredFindings();
    if (selectedIndex < 0 || selectedIndex >= filtered.length) return;
    const f = filtered[selectedIndex];
    vscode.postMessage({
      type: 'navigateToFile',
      filePath: f.location.filePath,
      line: f.location.line,
      column: f.location.column,
    });
  }

  function toggleFilter(el, type, value) {
    if (value === 'all') {
      activeFilters[type] = null;
    } else {
      activeFilters[type] = activeFilters[type] === value ? null : value;
    }
    // Update chip active states.
    el.parentElement.querySelectorAll('.filter-chip').forEach(chip => {
      const chipValue = chip.dataset.severity || chip.dataset.category;
      if (chipValue === 'all') {
        chip.classList.toggle('active', activeFilters[type] === null);
      } else {
        chip.classList.toggle('active', activeFilters[type] === chipValue);
      }
    });
    filterFindings();
  }

  function filterFindings() {
    const filtered = getFilteredFindings();
    renderFindings(filtered);
    selectedIndex = -1;
    document.getElementById('finding-detail').className = 'finding-detail';
  }

  function getFilteredFindings() {
    const query = (document.getElementById('search-input')?.value || '').toLowerCase();
    return findings.filter(f => {
      if (activeFilters.severity && f.severity !== activeFilters.severity) return false;
      if (activeFilters.category && f.category !== activeFilters.category) return false;
      if (query) {
        const text = (f.title + ' ' + f.description + ' ' + f.ruleId + ' ' + (f.location?.filePath || '')).toLowerCase();
        if (!text.includes(query)) return false;
      }
      return true;
    });
  }

  function startScan() {
    vscode.postMessage({ type: 'runScan' });
  }

  function cancelScan() {
    vscode.postMessage({ type: 'cancelScan' });
  }

  function exportReport() {
    vscode.postMessage({ type: 'exportJson' });
  }

  function escapeHtml(text) {
    if (!text) return '';
    return text.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  }
</script>
</body>
</html>`;
  }
}
