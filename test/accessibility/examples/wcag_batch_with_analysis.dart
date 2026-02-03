/// 增強版批量報告生成器 - 整合AI analysis到 full.html
///
/// 此檔案提供一個完整的批量報告生成器，將AI analysis結果整合到
/// full.html 中，包括：
/// - 跨 SC 的整體AI analysis
/// - 每個 SC 的詳細洞察
/// - priority sorting的fix suggestions
/// - Systemic和回歸檢測

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ui_kit_library/src/foundation/accessibility/accessibility.dart';

/// 為 WcagBatchResult 生成包含AI analysis的完整 HTML 報告
String generateFullHtmlWithAnalysis({
  required WcagBatchResult batch,
  WcagBatchResult? previousBatch,
  bool includeFixSuggestions = true,
}) {
  // 執行整體AI analysis（跨所有 SC）
  final engine = WcagAnalysisEngine();
  final overallAnalysis = engine.analyzeMultiple(
    batch.reports,
    includeFixSuggestions: includeFixSuggestions,
  );

  // 為每個 SC 執行個別分析
  final individualAnalyses = <String, AnalysisResult>{};
  for (final report in batch.reports) {
    WcagReport? previousReport;
    if (previousBatch != null) {
      // 找出對應的前一版本報告
      final reportType = report.successCriterion;
      previousReport = previousBatch.reports.cast<WcagReport?>().firstWhere(
            (r) => r?.successCriterion == reportType,
            orElse: () => null,
          );
    }

    individualAnalyses[report.successCriterion] = report.analyze(
      previousReport: previousReport,
      includeFixSuggestions: includeFixSuggestions,
    );
  }

  final buffer = StringBuffer();

  buffer.writeln('<!DOCTYPE html>');
  buffer.writeln('<html lang="zh-TW">');
  buffer.writeln('<head>');
  buffer.writeln('  <meta charset="UTF-8">');
  buffer.writeln(
      '  <meta name="viewport" content="width=device-width, initial-scale=1.0">');
  buffer.writeln(
      '  <title>WCAG 完整Compliance報告（含AI analysis）- v${batch.metadata.version}</title>');
  buffer.writeln(
      '  <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>');
  buffer.writeln('  <style>');
  buffer.writeln(_getEnhancedStyles());
  buffer.writeln('  </style>');
  buffer.writeln('</head>');
  buffer.writeln('<body>');

  // === 頁首導航 ===
  buffer.writeln('  <div class="header">');
  buffer.writeln('    <div class="container">');
  buffer.writeln(
      '      <h1>${batch.statusEmoji} WCAG 完整Compliance報告（含AI analysis）</h1>');
  buffer.writeln('      <div class="header-subtitle">');
  buffer.writeln(
      '        Version ${batch.metadata.version} • ${batch.metadata.environment} • ${batch.metadata.timestamp.toString().substring(0, 19)}');
  buffer.writeln('      </div>');
  buffer.writeln('      <div class="nav-links">');
  buffer.writeln('        <a href="#overview">📊 總覽</a>');
  buffer.writeln('        <a href="#analysis">🧠 AI analysis</a>');
  for (final report in batch.reports) {
    final scId =
        report.successCriterion.replaceAll(' ', '_').replaceAll('.', '_');
    buffer.writeln('        <a href="#$scId">${report.successCriterion}</a>');
  }
  buffer.writeln('      </div>');
  buffer.writeln('    </div>');
  buffer.writeln('  </div>');

  buffer.writeln('  <div class="container">');

  // === 總覽區塊 ===
  buffer.writeln('    <section id="overview" class="section">');
  buffer.writeln('      <h2>📊 整體總覽</h2>');

  // 關鍵指標卡片
  buffer.writeln('      <div class="metrics-grid">');

  buffer.writeln('        <div class="metric-card">');
  buffer.writeln('          <div class="metric-icon">📈</div>');
  buffer.writeln(
      '          <div class="metric-value">${batch.overallCompliance.toStringAsFixed(1)}%</div>');
  buffer.writeln('          <div class="metric-label">整體Compliance性</div>');
  buffer.writeln('        </div>');

  buffer.writeln(
      '        <div class="metric-card ${_getHealthCardClass(overallAnalysis.healthScore)}">');
  buffer.writeln(
      '          <div class="metric-icon">${_getHealthEmoji(overallAnalysis.healthScore)}</div>');
  buffer.writeln(
      '          <div class="metric-value">${(overallAnalysis.healthScore * 100).toStringAsFixed(1)}%</div>');
  buffer.writeln('          <div class="metric-label">Health Score</div>');
  buffer.writeln('        </div>');

  buffer.writeln(
      '        <div class="metric-card ${overallAnalysis.criticalInsights.isNotEmpty ? 'critical' : ''}">');
  buffer.writeln('          <div class="metric-icon">🔴</div>');
  buffer.writeln(
      '          <div class="metric-value">${overallAnalysis.criticalInsights.length}</div>');
  buffer.writeln('          <div class="metric-label">Critical Issues</div>');
  buffer.writeln('        </div>');

  buffer.writeln('        <div class="metric-card">');
  buffer.writeln('          <div class="metric-icon">⏱️</div>');
  buffer.writeln(
      '          <div class="metric-value">${overallAnalysis.estimatedEffort?.toStringAsFixed(1) ?? 'N/A'}h</div>');
  buffer.writeln('          <div class="metric-label">Effort Estimation</div>');
  buffer.writeln('        </div>');

  buffer.writeln('        <div class="metric-card success">');
  buffer.writeln('          <div class="metric-icon">📈</div>');
  buffer.writeln(
      '          <div class="metric-value">+${((overallAnalysis.expectedImprovement ?? 0) * 100).toStringAsFixed(1)}%</div>');
  buffer.writeln(
      '          <div class="metric-label">Expected Improvement</div>');
  buffer.writeln('        </div>');

  buffer.writeln('        <div class="metric-card">');
  buffer.writeln('          <div class="metric-icon">🎯</div>');
  buffer.writeln(
      '          <div class="metric-value">${overallAnalysis.totalAffectedComponents}</div>');
  buffer
      .writeln('          <div class="metric-label">Affected Components</div>');
  buffer.writeln('        </div>');

  buffer.writeln('      </div>');

  // 元數據資訊
  buffer.writeln('      <div class="metadata-card">');
  buffer.writeln('        <h3>報告資訊</h3>');
  buffer.writeln('        <div class="metadata-grid">');
  buffer.writeln(
      '          <div><strong>Git Commit:</strong> ${batch.metadata.gitCommitHash}</div>');
  buffer.writeln(
      '          <div><strong>Success Criteria:</strong> ${batch.reportCount}</div>');
  buffer.writeln(
      '          <div><strong>Total Validations:</strong> ${batch.totalValidations}</div>');
  buffer.writeln(
      '          <div><strong>Passed:</strong> ${batch.totalPassed}</div>');
  buffer.writeln(
      '          <div><strong>Failed:</strong> ${batch.totalFailures}</div>');
  buffer.writeln(
      '          <div><strong>Critical Failures:</strong> ${batch.totalCriticalFailures}</div>');
  buffer.writeln('        </div>');
  buffer.writeln('      </div>');

  // 圖表區域
  buffer.writeln('      <div class="charts-row">');
  buffer.writeln('        <div class="chart-card">');
  buffer.writeln('          <h3>Compliance性分布</h3>');
  buffer.writeln('          <div class="chart-container">');
  buffer.writeln('            <canvas id="overallChart"></canvas>');
  buffer.writeln('          </div>');
  buffer.writeln('        </div>');
  buffer.writeln('        <div class="chart-card">');
  buffer.writeln('          <h3>各 SC Compliance Rate</h3>');
  buffer.writeln('          <div class="chart-container">');
  buffer.writeln('            <canvas id="complianceChart"></canvas>');
  buffer.writeln('          </div>');
  buffer.writeln('        </div>');
  buffer.writeln('      </div>');

  // SC 總覽表格
  buffer.writeln('      <h3>Success Criteria 詳情</h3>');
  buffer.writeln('      <table class="sc-table">');
  buffer.writeln('        <thead>');
  buffer.writeln('          <tr>');
  buffer.writeln('            <th>SC</th>');
  buffer.writeln('            <th>標題</th>');
  buffer.writeln('            <th>等級</th>');
  buffer.writeln('            <th>Compliance性</th>');
  buffer.writeln('            <th>Health Score</th>');
  buffer.writeln('            <th>關鍵問題</th>');
  buffer.writeln('            <th>操作</th>');
  buffer.writeln('          </tr>');
  buffer.writeln('        </thead>');
  buffer.writeln('        <tbody>');
  for (final report in batch.reports) {
    final scId =
        report.successCriterion.replaceAll(' ', '_').replaceAll('.', '_');
    final analysis = individualAnalyses[report.successCriterion]!;
    buffer.writeln('          <tr>');
    buffer.writeln(
        '            <td><strong>${report.successCriterion}</strong></td>');
    buffer.writeln('            <td>${report.title}</td>');
    buffer.writeln(
        '            <td><span class="level-badge level-${report.level.name}">${report.level.label}</span></td>');
    buffer.writeln(
        '            <td>${report.score.statusEmoji} ${report.score.percentage.toStringAsFixed(1)}%</td>');
    buffer.writeln(
        '            <td>${_getHealthEmoji(analysis.healthScore)} ${(analysis.healthScore * 100).toStringAsFixed(1)}%</td>');
    buffer.writeln(
        '            <td>${analysis.criticalInsights.length > 0 ? '🔴 ${analysis.criticalInsights.length}' : '✅'}</td>');
    buffer.writeln(
        '            <td><a href="#$scId" class="btn-link">查看詳情 →</a></td>');
    buffer.writeln('          </tr>');
  }
  buffer.writeln('        </tbody>');
  buffer.writeln('      </table>');

  buffer.writeln('    </section>');

  // === AI analysis區塊 ===
  buffer
      .writeln('    <section id="analysis" class="section analysis-section">');
  buffer.writeln('      <h2>🧠 AI analysis：整體洞察</h2>');

  // Regression Warning
  if (overallAnalysis.regressions.isNotEmpty) {
    buffer.writeln('      <div class="alert alert-danger">');
    buffer.writeln('        <h3>🚨 Accessibility Regression Detected!</h3>');
    buffer.writeln(
        '        <p>The following components passed in the previous version but failed in the current one:</p>');
    buffer.writeln('        <ul>');
    for (final regression in overallAnalysis.regressions) {
      buffer.writeln('          <li>');
      buffer.writeln('            <strong>${regression.title}</strong><br>');
      buffer.writeln(
          '            <span class="text-muted">受影響：${regression.affectedComponents.join(", ")}</span>');
      buffer.writeln('          </li>');
    }
    buffer.writeln('        </ul>');
    buffer.writeln('      </div>');
  }

  // Systemic
  if (overallAnalysis.systemicIssues.isNotEmpty) {
    buffer.writeln('      <div class="alert alert-warning">');
    buffer.writeln('        <h3>⚠️ Systemic</h3>');
    buffer.writeln('        <p>以下元件在多個 Success Criteria 或情境中Failed：</p>');
    buffer.writeln('        <ul>');
    for (final systemic in overallAnalysis.systemicIssues) {
      buffer.writeln('          <li>');
      buffer.writeln(
          '            <strong>${systemic.title}</strong> (Failure Count: ${systemic.failureCount})<br>');
      buffer.writeln(
          '            <span class="text-muted">${systemic.description}</span>');
      buffer.writeln('          </li>');
    }
    buffer.writeln('        </ul>');
    buffer.writeln('      </div>');
  }

  // priority sorting的洞察
  buffer.writeln('      <h3>💡 優先修復順序（跨所有 SC）</h3>');
  buffer.writeln(
      '      <p class="section-subtitle">根據Severity、影響範圍和 WCAG 等級自動排序</p>');

  if (overallAnalysis.insights.isEmpty) {
    buffer.writeln('      <div class="success-message">');
    buffer.writeln('        <div style="font-size: 64px;">✅</div>');
    buffer.writeln('        <h3>沒有發現問題模式！</h3>');
    buffer.writeln('        <p>All tests comply with WCAG 標準。</p>');
    buffer.writeln('      </div>');
  } else {
    for (var i = 0; i < overallAnalysis.insights.length; i++) {
      final insight = overallAnalysis.insights[i];
      buffer.write(_generateInsightCard(insight, i + 1));
    }
  }

  buffer.writeln('    </section>');

  // === 各 SC 詳細報告 ===
  for (final report in batch.reports) {
    final scId =
        report.successCriterion.replaceAll(' ', '_').replaceAll('.', '_');
    final analysis = individualAnalyses[report.successCriterion]!;

    buffer.writeln('    <section id="$scId" class="section sc-section">');

    // SC 標題
    buffer.writeln('      <div class="sc-header">');
    buffer.writeln('        <div>');
    buffer.writeln(
        '          <h2>${report.successCriterion} - ${report.title}</h2>');
    buffer.writeln('          <div class="sc-meta">');
    buffer.writeln(
        '            <span class="level-badge level-${report.level.name}">${report.level.label}</span>');
    buffer.writeln(
        '            <span>Compliance性: ${report.score.statusEmoji} ${report.score.percentage.toStringAsFixed(1)}%</span>');
    buffer.writeln(
        '            <span>Health Score: ${_getHealthEmoji(analysis.healthScore)} ${(analysis.healthScore * 100).toStringAsFixed(1)}%</span>');
    buffer.writeln('          </div>');
    buffer.writeln('        </div>');
    buffer.writeln('        <a href="#overview" class="back-link">↑ 返回總覽</a>');
    buffer.writeln('      </div>');

    // SC 統計卡片
    buffer.writeln('      <div class="sc-stats-grid">');
    buffer.writeln('        <div class="stat-card">');
    buffer.writeln(
        '          <div class="stat-value">${report.score.passed}/${report.score.total}</div>');
    buffer.writeln('          <div class="stat-label">Passed測試</div>');
    buffer.writeln('        </div>');
    buffer.writeln(
        '        <div class="stat-card ${report.criticalFailures.isNotEmpty ? 'critical' : ''}">');
    buffer.writeln(
        '          <div class="stat-value">${report.criticalFailures.length}</div>');
    buffer.writeln('          <div class="stat-label">Critical Failures</div>');
    buffer.writeln('        </div>');
    buffer.writeln('        <div class="stat-card">');
    buffer.writeln(
        '          <div class="stat-value">${analysis.insights.length}</div>');
    buffer.writeln('          <div class="stat-label">發現洞察</div>');
    buffer.writeln('        </div>');
    buffer.writeln('        <div class="stat-card">');
    buffer.writeln(
        '          <div class="stat-value">${analysis.estimatedEffort?.toStringAsFixed(1) ?? 'N/A'}h</div>');
    buffer.writeln('          <div class="stat-label">修復工作量</div>');
    buffer.writeln('        </div>');
    buffer.writeln('      </div>');

    // SC 特定的AI analysis
    if (analysis.insights.isNotEmpty) {
      buffer.writeln('      <div class="sc-analysis">');
      buffer.writeln('        <h3>🧠 此 SC 的AI analysis</h3>');
      for (var i = 0; i < analysis.insights.length; i++) {
        buffer.write(
            _generateInsightCard(analysis.insights[i], i + 1, compact: true));
      }
      buffer.writeln('      </div>');
    }

    // 測試結果表格
    if (report.results.isNotEmpty) {
      buffer.writeln('      <h3>📋 測試結果</h3>');
      buffer.writeln('      <table class="results-table">');
      buffer.writeln('        <thead>');
      buffer.writeln('          <tr>');
      buffer.writeln('            <th>元件</th>');
      buffer.writeln('            <th>狀態</th>');
      buffer.writeln('            <th>嚴重性</th>');
      buffer.writeln('            <th>說明</th>');
      buffer.writeln('          </tr>');
      buffer.writeln('        </thead>');
      buffer.writeln('        <tbody>');
      for (final result in report.results) {
        final rowClass = result.isCompliant ? 'row-pass' : 'row-fail';
        buffer.writeln('          <tr class="$rowClass">');
        buffer.writeln('            <td><strong>${result.name}</strong></td>');
        buffer.writeln(
            '            <td>${result.isCompliant ? "✅ Passed" : "❌ Failed"}</td>');
        buffer.writeln(
            '            <td><span class="severity-badge severity-${result.severity.name}">${result.severity.emoji} ${result.severity.name.toUpperCase()}</span></td>');
        buffer.writeln('            <td>${result.message}</td>');
        buffer.writeln('          </tr>');
      }
      buffer.writeln('        </tbody>');
      buffer.writeln('      </table>');
    }

    buffer.writeln('    </section>');
  }

  buffer.writeln('  </div>');

  // === JavaScript ===
  buffer.writeln('  <script>');
  buffer.writeln(_generateChartScript(batch));
  buffer.writeln('  </script>');

  buffer.writeln('</body>');
  buffer.writeln('</html>');

  return buffer.toString();
}

/// 生成洞察卡片 HTML
String _generateInsightCard(Insight insight, int priority,
    {bool compact = false}) {
  final severityClass = 'insight-${insight.severity.name}';

  return '''
      <div class="insight-card $severityClass">
        <div class="insight-header">
          <div class="insight-priority">
            <span class="priority-badge">優先級 $priority</span>
          </div>
          <div class="insight-title-group">
            <span class="insight-emoji">${insight.severity.emoji}</span>
            <h4 class="insight-title">${insight.title}</h4>
          </div>
          <div class="insight-meta">
            <span class="confidence-badge">${(insight.confidence * 100).toStringAsFixed(0)}% Confidence</span>
            <span class="type-badge">${_getInsightTypeName(insight.type)}</span>
          </div>
        </div>

        <div class="insight-body">
          <div class="insight-description">${insight.description}</div>

          <div class="insight-details">
            <div class="detail-item">
              <span class="detail-icon">📌</span>
              <span class="detail-label">Success Criteria:</span>
              <span class="detail-value">${insight.successCriteria.join(", ")}</span>
            </div>
            <div class="detail-item">
              <span class="detail-icon">🔢</span>
              <span class="detail-label">Failed次數:</span>
              <span class="detail-value">${insight.failureCount}</span>
            </div>
          </div>

          <div class="affected-components">
            <strong>Affected Components:</strong>
            <div class="component-badges">
              ${insight.affectedComponents.map((c) => '<span class="component-badge">$c</span>').join('\n')}
            </div>
          </div>

          ${!compact && insight.actions.isNotEmpty ? '''
          <div class="action-steps">
            <h5>🛠️ Fix Steps:</h5>
            ${insight.actions.map((action) => '''
            <div class="action-step">
              <div class="action-step-header">
                <span class="step-number">${action.step}</span>
                <span class="step-description">${action.description}</span>
              </div>
              ${action.filePath != null ? '<div class="action-file">📁 ${action.filePath}</div>' : ''}
              ${action.codeExample != null ? '<pre class="code-example">${_escapeHtml(action.codeExample!)}</pre>' : ''}
              ${action.impact != null ? '<div class="action-impact">✨ ${action.impact}</div>' : ''}
            </div>
            ''').join('\n')}
          </div>
          ''' : ''}
        </div>
      </div>
''';
}

/// 生成圖表 JavaScript
String _generateChartScript(WcagBatchResult batch) {
  return '''
    // 整體Compliance Doughnut Chart
    new Chart(document.getElementById('overallChart'), {
      type: 'doughnut',
      data: {
        labels: ['Passed', 'Failed'],
        datasets: [{
          data: [${batch.totalPassed}, ${batch.totalFailures}],
          backgroundColor: ['#28a745', '#dc3545'],
          borderWidth: 0
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'bottom',
            labels: {
              font: { size: 14 },
              padding: 15
            }
          }
        }
      }
    });

    // 各 SC Compliance Rate長條圖
    new Chart(document.getElementById('complianceChart'), {
      type: 'bar',
      data: {
        labels: [${batch.reports.map((r) => '"${r.successCriterion}"').join(', ')}],
        datasets: [{
          label: 'Compliance Rate (%)',
          data: [${batch.reports.map((r) => r.score.percentage).join(', ')}],
          backgroundColor: [${batch.reports.map((r) => _getBarColor(r.score.percentage)).join(', ')}],
          borderWidth: 0
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: {
            beginAtZero: true,
            max: 100,
            ticks: {
              callback: function(value) {
                return value + '%';
              }
            }
          }
        },
        plugins: {
          legend: {
            display: false
          }
        }
      }
    });
  ''';
}

/// 取得長條圖顏色
String _getBarColor(double percentage) {
  if (percentage >= 95) return "'#28a745'";
  if (percentage >= 80) return "'#ffc107'";
  return "'#dc3545'";
}

/// 取得Health Score的卡片 class
String _getHealthCardClass(double score) {
  if (score >= 0.8) return 'success';
  if (score >= 0.5) return 'warning';
  return 'critical';
}

/// Get health score emoji
String _getHealthEmoji(double score) {
  if (score >= 0.9) return '🟢';
  if (score >= 0.7) return '🟡';
  if (score >= 0.5) return '🟠';
  return '🔴';
}

/// Get insight type name
String _getInsightTypeName(InsightType type) {
  return switch (type) {
    InsightType.systemic => 'Systemic',
    InsightType.common => 'Common',
    InsightType.regression => 'Regression',
    InsightType.priority => 'Priority',
    InsightType.suggestion => 'Suggestion',
  };
}

/// HTML Escape
String _escapeHtml(String text) {
  return text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}

/// 增強版樣式
String _getEnhancedStyles() {
  return '''
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }

    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
      line-height: 1.6;
      color: #333;
      background: #f5f7fa;
    }

    .header {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      padding: 30px 0;
      box-shadow: 0 4px 6px rgba(0,0,0,0.1);
      position: sticky;
      top: 0;
      z-index: 1000;
    }

    .header h1 {
      margin: 0 0 10px 0;
      font-size: 28px;
    }

    .header-subtitle {
      opacity: 0.9;
      margin-bottom: 15px;
      font-size: 14px;
    }

    .nav-links {
      display: flex;
      gap: 15px;
      flex-wrap: wrap;
    }

    .nav-links a {
      color: white;
      text-decoration: none;
      padding: 8px 16px;
      background: rgba(255,255,255,0.2);
      border-radius: 20px;
      font-size: 13px;
      transition: all 0.3s;
    }

    .nav-links a:hover {
      background: rgba(255,255,255,0.3);
      transform: translateY(-2px);
    }

    .container {
      max-width: 1400px;
      margin: 0 auto;
      padding: 30px 20px;
    }

    .section {
      background: white;
      padding: 30px;
      border-radius: 10px;
      margin-bottom: 30px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }

    .section h2 {
      margin: 0 0 20px 0;
      color: #333;
      font-size: 24px;
      border-bottom: 3px solid #667eea;
      padding-bottom: 10px;
    }

    .section h3 {
      margin: 25px 0 15px 0;
      color: #555;
      font-size: 18px;
    }

    .section-subtitle {
      color: #666;
      font-size: 14px;
      margin: -10px 0 20px 0;
    }

    /* 指標卡片 */
    .metrics-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 20px;
      margin-bottom: 30px;
    }

    .metric-card {
      background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
      padding: 25px;
      border-radius: 10px;
      text-align: center;
      transition: transform 0.3s;
    }

    .metric-card:hover {
      transform: translateY(-5px);
    }

    .metric-card.success {
      background: linear-gradient(135deg, #d4fc79 0%, #96e6a1 100%);
    }

    .metric-card.warning {
      background: linear-gradient(135deg, #ffeaa7 0%, #fdcb6e 100%);
    }

    .metric-card.critical {
      background: linear-gradient(135deg, #ff7979 0%, #ff6b6b 100%);
      color: white;
    }

    .metric-icon {
      font-size: 32px;
      margin-bottom: 10px;
    }

    .metric-value {
      font-size: 36px;
      font-weight: bold;
      margin-bottom: 5px;
    }

    .metric-label {
      font-size: 14px;
      opacity: 0.8;
    }

    /* 元數據卡片 */
    .metadata-card {
      background: #f8f9fa;
      padding: 20px;
      border-radius: 8px;
      margin-bottom: 30px;
    }

    .metadata-card h3 {
      margin: 0 0 15px 0;
      font-size: 16px;
    }

    .metadata-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
      gap: 10px;
      font-size: 14px;
    }

    /* 圖表 */
    .charts-row {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
      gap: 20px;
      margin: 30px 0;
    }

    .chart-card {
      background: #f8f9fa;
      padding: 20px;
      border-radius: 8px;
    }

    .chart-card h3 {
      margin: 0 0 15px 0;
      font-size: 16px;
    }

    .chart-container {
      position: relative;
      height: 300px;
    }

    /* 表格 */
    .sc-table, .results-table {
      width: 100%;
      border-collapse: collapse;
      margin-top: 15px;
    }

    .sc-table th, .results-table th {
      background: #667eea;
      color: white;
      padding: 12px;
      text-align: left;
      font-weight: 600;
      font-size: 14px;
    }

    .sc-table td, .results-table td {
      padding: 12px;
      border-bottom: 1px solid #e9ecef;
      font-size: 14px;
    }

    .sc-table tr:hover, .results-table tr:hover {
      background: #f8f9fa;
    }

    .row-pass {
      background: #f0fff4;
    }

    .row-fail {
      background: #fff5f5;
    }

    /* 徽章 */
    .level-badge {
      display: inline-block;
      padding: 4px 12px;
      border-radius: 12px;
      font-size: 12px;
      font-weight: 600;
    }

    .level-badge.level-a {
      background: #e3f2fd;
      color: #1976d2;
    }

    .level-badge.level-aa {
      background: #f3e5f5;
      color: #7b1fa2;
    }

    .level-badge.level-aaa {
      background: #fff3e0;
      color: #e65100;
    }

    .severity-badge {
      display: inline-block;
      padding: 4px 8px;
      border-radius: 4px;
      font-size: 12px;
      font-weight: 600;
    }

    .severity-badge.severity-critical {
      background: #ffebee;
      color: #c62828;
    }

    .severity-badge.severity-high {
      background: #fff3e0;
      color: #e65100;
    }

    .severity-badge.severity-medium {
      background: #fff9c4;
      color: #f57f17;
    }

    .severity-badge.severity-low {
      background: #e8f5e9;
      color: #2e7d32;
    }

    /* 按鈕 */
    .btn-link {
      color: #667eea;
      text-decoration: none;
      font-weight: 600;
      transition: all 0.3s;
    }

    .btn-link:hover {
      color: #764ba2;
      text-decoration: underline;
    }

    /* Warning框 */
    .alert {
      padding: 20px;
      border-radius: 8px;
      margin-bottom: 20px;
    }

    .alert h3 {
      margin: 0 0 10px 0;
      font-size: 18px;
    }

    .alert ul {
      margin: 10px 0 0 20px;
    }

    .alert li {
      margin-bottom: 8px;
    }

    .alert-danger {
      background: #fff5f5;
      border-left: 4px solid #dc3545;
    }

    .alert-warning {
      background: #fff9f0;
      border-left: 4px solid #ff9800;
    }

    .text-muted {
      color: #666;
      font-size: 13px;
    }

    .success-message {
      text-align: center;
      padding: 60px 20px;
      color: #28a745;
    }

    /* AI analysis區塊 */
    .analysis-section {
      background: linear-gradient(to right, #f8f9fa, #e9ecef);
    }

    /* 洞察卡片 */
    .insight-card {
      background: white;
      border-radius: 10px;
      padding: 25px;
      margin-bottom: 20px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
      border-left: 4px solid #ccc;
      transition: all 0.3s;
    }

    .insight-card:hover {
      box-shadow: 0 4px 12px rgba(0,0,0,0.15);
      transform: translateX(5px);
    }

    .insight-card.insight-critical {
      border-left-color: #dc3545;
      background: linear-gradient(to right, #fff5f5, white);
    }

    .insight-card.insight-high {
      border-left-color: #ff9800;
      background: linear-gradient(to right, #fff9f0, white);
    }

    .insight-card.insight-medium {
      border-left-color: #ffc107;
      background: linear-gradient(to right, #fffef0, white);
    }

    .insight-card.insight-low {
      border-left-color: #4caf50;
      background: linear-gradient(to right, #f0fff4, white);
    }

    .insight-header {
      display: flex;
      align-items: flex-start;
      gap: 15px;
      margin-bottom: 15px;
      flex-wrap: wrap;
    }

    .insight-priority {
      flex-shrink: 0;
    }

    .priority-badge {
      background: #667eea;
      color: white;
      padding: 6px 12px;
      border-radius: 16px;
      font-size: 12px;
      font-weight: 600;
    }

    .insight-title-group {
      flex: 1;
      display: flex;
      align-items: center;
      gap: 10px;
    }

    .insight-emoji {
      font-size: 28px;
    }

    .insight-title {
      margin: 0;
      font-size: 18px;
      color: #333;
    }

    .insight-meta {
      display: flex;
      gap: 10px;
      flex-wrap: wrap;
    }

    .confidence-badge, .type-badge {
      background: #e9ecef;
      padding: 4px 10px;
      border-radius: 12px;
      font-size: 12px;
      color: #666;
    }

    .insight-body {
      margin-top: 15px;
    }

    .insight-description {
      color: #555;
      line-height: 1.7;
      margin-bottom: 15px;
    }

    .insight-details {
      display: flex;
      gap: 20px;
      flex-wrap: wrap;
      margin: 15px 0;
      padding: 12px;
      background: #f8f9fa;
      border-radius: 6px;
    }

    .detail-item {
      display: flex;
      align-items: center;
      gap: 6px;
      font-size: 13px;
    }

    .detail-icon {
      font-size: 16px;
    }

    .detail-label {
      color: #666;
    }

    .detail-value {
      font-weight: 600;
      color: #333;
    }

    .affected-components {
      margin: 15px 0;
    }

    .component-badges {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
      margin-top: 8px;
    }

    .component-badge {
      background: #e3f2fd;
      color: #1976d2;
      padding: 6px 14px;
      border-radius: 16px;
      font-size: 13px;
      font-weight: 500;
    }

    /* 修復Step */
    .action-steps {
      background: #f8f9fa;
      border-radius: 8px;
      padding: 20px;
      margin-top: 20px;
    }

    .action-steps h5 {
      margin: 0 0 15px 0;
      color: #333;
      font-size: 16px;
    }

    .action-step {
      margin-bottom: 20px;
      padding-bottom: 20px;
      border-bottom: 1px solid #e9ecef;
    }

    .action-step:last-child {
      border-bottom: none;
      margin-bottom: 0;
      padding-bottom: 0;
    }

    .action-step-header {
      display: flex;
      gap: 10px;
      align-items: flex-start;
      margin-bottom: 10px;
    }

    .step-number {
      background: #667eea;
      color: white;
      width: 28px;
      height: 28px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: 600;
      font-size: 14px;
      flex-shrink: 0;
    }

    .step-description {
      flex: 1;
      font-weight: 600;
      color: #333;
      line-height: 1.8;
    }

    .action-file {
      color: #666;
      font-size: 13px;
      margin: 8px 0;
      padding-left: 38px;
    }

    .code-example {
      background: #1e1e1e;
      color: #d4d4d4;
      padding: 15px;
      border-radius: 6px;
      font-family: 'Monaco', 'Menlo', 'Courier New', monospace;
      font-size: 13px;
      overflow-x: auto;
      margin: 10px 0;
      margin-left: 38px;
      white-space: pre-wrap;
      line-height: 1.5;
    }

    .action-impact {
      color: #28a745;
      font-size: 13px;
      font-style: italic;
      margin-top: 8px;
      padding-left: 38px;
    }

    /* SC 區塊 */
    .sc-section {
      border-left: 4px solid #667eea;
    }

    .sc-header {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      margin-bottom: 20px;
      flex-wrap: wrap;
      gap: 15px;
    }

    .sc-meta {
      display: flex;
      gap: 15px;
      flex-wrap: wrap;
      margin-top: 8px;
      font-size: 14px;
      color: #666;
    }

    .back-link {
      color: #667eea;
      text-decoration: none;
      font-weight: 600;
      padding: 8px 16px;
      background: #f8f9fa;
      border-radius: 6px;
      transition: all 0.3s;
    }

    .back-link:hover {
      background: #e9ecef;
      transform: translateY(-2px);
    }

    .sc-stats-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
      gap: 15px;
      margin-bottom: 30px;
    }

    .stat-card {
      background: #f8f9fa;
      padding: 20px;
      border-radius: 8px;
      text-align: center;
    }

    .stat-card.critical {
      background: #ffebee;
      color: #c62828;
    }

    .stat-value {
      font-size: 28px;
      font-weight: bold;
      margin-bottom: 5px;
    }

    .stat-label {
      font-size: 13px;
      color: #666;
    }

    .sc-analysis {
      background: #f8f9fa;
      padding: 20px;
      border-radius: 8px;
      margin: 20px 0;
    }

    /* 響應式設計 */
    @media (max-width: 768px) {
      .header h1 {
        font-size: 22px;
      }

      .metrics-grid {
        grid-template-columns: 1fr;
      }

      .charts-row {
        grid-template-columns: 1fr;
      }

      .sc-header {
        flex-direction: column;
      }

      .insight-header {
        flex-direction: column;
      }
    }

    /* 平滑滾動 */
    html {
      scroll-behavior: smooth;
    }
  ''';
}

/// Complete usage example
void main() {
  // 1. 建立批量執行器並收集資料
  final runner = WcagBatchRunner();

  // Target Size
  final targetSizeReporter = TargetSizeReporter(targetLevel: WcagLevel.aaa);
  targetSizeReporter.validateComponent(
    componentName: 'LoginButton',
    actualSize: const Size(32, 32),
    severity: Severity.critical,
  );
  targetSizeReporter.validateComponent(
    componentName: 'CancelButton',
    actualSize: const Size(48, 48),
  );
  runner.addTargetSizeReporter(targetSizeReporter);

  // Semantics
  final semanticsReporter = SemanticsReporter(targetLevel: WcagLevel.a);
  semanticsReporter.validateComponent(
    componentName: 'IconButton',
    hasLabel: false,
    hasRole: true,
    exposesValue: true,
    severity: Severity.critical,
  );
  runner.addSemanticsReporter(semanticsReporter);

  // Focus Order
  final focusOrderReporter = FocusOrderReporter(targetLevel: WcagLevel.a);
  focusOrderReporter.validateComponent(
    componentName: 'LoginForm_Username',
    expectedIndex: 0,
    actualIndex: 0,
  );
  runner.addFocusOrderReporter(focusOrderReporter);

  // 2. 生成批量報告
  final batch = runner.generateBatch(
    version: 'v2.0.0',
    gitCommitHash: 'abc123',
    environment: 'Demo',
  );

  // 3. 生成增強版 full.html（含AI analysis）
  final enhancedFullHtml = generateFullHtmlWithAnalysis(
    batch: batch,
    includeFixSuggestions: true,
  );

  // 4. Save report
  final outputDir = Directory('reports/accessibility/enhanced_batch');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  File('${outputDir.path}/full_with_analysis.html')
      .writeAsStringSync(enhancedFullHtml);

  print('✅ 增強版 full.html 已生成！');
  print('   Path: ${outputDir.path}/full_with_analysis.html');
  print('');
  print('📊 報告內容：');
  print('   • 整體Compliance性總覽');
  print('   • 整體Health Score和指標');
  print('   • 跨所有 SC 的AI analysis');
  print('   • priority sorting的fix suggestions');
  print('   • Systemic和回歸檢測');
  print('   • 每個 SC 的詳細報告和分析');
  print('   • 互動式圖表和導航');
}
