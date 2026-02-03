/// Example: Generate HTML report with AI analysis
///
/// This example demonstrates how to combine standard WCAG reports with AI analysis results,
/// generating a complete HTML report with fix suggestions and priority sorting.

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ui_kit_library/src/foundation/accessibility/accessibility.dart';

/// Generate enhanced HTML report with AI analysis
String generateEnhancedHtmlReport({
  required WcagReport report,
  WcagReport? previousReport,
  bool includeFixSuggestions = true,
}) {
  // Perform AI analysis
  final analysis = report.analyze(
    previousReport: previousReport,
    includeFixSuggestions: includeFixSuggestions,
  );

  // Get standard report JSON data
  final reportJson = report.toJson();
  final chartData = report.toChartData();

  return '''
<!DOCTYPE html>
<html lang="zh-TW">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${_escapeHtml(report.successCriterion)}: ${_escapeHtml(report.title)} - AI Analysis Report</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            line-height: 1.6;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background: #f5f5f5;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            border-radius: 10px;
            margin-bottom: 20px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        .header h1 {
            margin: 0 0 10px 0;
            font-size: 28px;
        }
        .score-container {
            display: flex;
            justify-content: space-around;
            margin-top: 20px;
            gap: 15px;
        }
        .score-card {
            background: rgba(255,255,255,0.2);
            padding: 15px 25px;
            border-radius: 8px;
            text-align: center;
            flex: 1;
        }
        .score-label {
            font-size: 12px;
            opacity: 0.9;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        .score-value {
            font-size: 32px;
            font-weight: bold;
            margin-top: 5px;
        }
        .card {
            background: white;
            padding: 25px;
            border-radius: 10px;
            margin-bottom: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .card h2 {
            margin-top: 0;
            color: #333;
            border-bottom: 2px solid #667eea;
            padding-bottom: 10px;
        }

        /* Styles for AI analysis */
        .analysis-section {
            background: linear-gradient(to right, #f8f9fa, #e9ecef);
            border-left: 4px solid #667eea;
        }
        .health-score {
            font-size: 48px;
            font-weight: bold;
            text-align: center;
            margin: 20px 0;
        }
        .health-good { color: #28a745; }
        .health-warning { color: #ffc107; }
        .health-danger { color: #dc3545; }

        .insight {
            background: white;
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 15px;
            border-left: 4px solid #ccc;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }
        .insight-critical {
            border-left-color: #dc3545;
            background: #fff5f5;
        }
        .insight-high {
            border-left-color: #ff9800;
            background: #fff9f0;
        }
        .insight-medium {
            border-left-color: #ffc107;
            background: #fffef0;
        }
        .insight-low {
            border-left-color: #4caf50;
            background: #f0fff4;
        }

        .insight-header {
            display: flex;
            align-items: center;
            margin-bottom: 10px;
        }
        .insight-emoji {
            font-size: 24px;
            margin-right: 10px;
        }
        .insight-title {
            font-size: 18px;
            font-weight: bold;
            color: #333;
            flex: 1;
        }
        .insight-confidence {
            background: #e9ecef;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 12px;
            color: #666;
        }

        .insight-meta {
            display: flex;
            gap: 15px;
            margin: 10px 0;
            font-size: 14px;
            color: #666;
        }
        .insight-meta-item {
            display: flex;
            align-items: center;
            gap: 5px;
        }

        .insight-description {
            color: #555;
            margin: 15px 0;
            line-height: 1.6;
        }

        .affected-components {
            display: flex;
            flex-wrap: wrap;
            gap: 8px;
            margin: 10px 0;
        }
        .component-badge {
            background: #e3f2fd;
            color: #1976d2;
            padding: 4px 12px;
            border-radius: 16px;
            font-size: 13px;
            font-weight: 500;
        }

        .action-steps {
            background: #f8f9fa;
            border-radius: 8px;
            padding: 15px;
            margin-top: 15px;
        }
        .action-step {
            margin-bottom: 15px;
            padding-left: 10px;
        }
        .action-step-header {
            font-weight: 600;
            color: #333;
            margin-bottom: 5px;
        }
        .action-step-description {
            color: #666;
            margin-bottom: 8px;
        }
        .code-example {
            background: #1e1e1e;
            color: #d4d4d4;
            padding: 12px;
            border-radius: 4px;
            font-family: 'Monaco', 'Menlo', 'Courier New', monospace;
            font-size: 13px;
            overflow-x: auto;
            margin: 8px 0;
            white-space: pre-wrap;
        }
        .action-impact {
            color: #28a745;
            font-size: 13px;
            font-style: italic;
        }

        .regression-alert {
            background: #fff3cd;
            border: 2px solid #ffc107;
            border-radius: 8px;
            padding: 15px;
            margin: 15px 0;
        }
        .regression-alert h3 {
            color: #856404;
            margin-top: 0;
        }

        .chart-container {
            position: relative;
            height: 300px;
            margin: 20px 0;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 15px;
        }
        th {
            background: #f8f9fa;
            padding: 12px;
            text-align: left;
            font-weight: 600;
            color: #333;
            border-bottom: 2px solid #dee2e6;
        }
        td {
            padding: 12px;
            border-bottom: 1px solid #e9ecef;
        }
        tr:hover {
            background: #f8f9fa;
        }

        .severity-critical { color: #dc3545; font-weight: bold; }
        .severity-high { color: #ff9800; font-weight: bold; }
        .severity-medium { color: #ffc107; }
        .severity-low { color: #4caf50; }
    </style>
</head>
<body>
    <!-- Header: Basic Info and Scores -->
    <div class="header">
        <h1>${_escapeHtml(report.successCriterion)}: ${_escapeHtml(report.title)}</h1>
        <div style="opacity: 0.9; margin-bottom: 10px;">
            Version ${report.metadata.version} •
            ${report.metadata.environment} •
            ${report.metadata.timestamp.toString().substring(0, 19)}
        </div>

        <div class="score-container">
            <div class="score-card">
                <div class="score-label">Compliance Rate</div>
                <div class="score-value">
                    ${report.score.statusEmoji} ${report.score.percentage.toStringAsFixed(1)}%
                </div>
            </div>
            <div class="score-card">
                <div class="score-label">Health Score</div>
                <div class="score-value ${_getHealthClass(analysis.healthScore)}">
                    ${_getHealthEmoji(analysis.healthScore)} ${(analysis.healthScore * 100).toStringAsFixed(1)}%
                </div>
            </div>
            <div class="score-card">
                <div class="score-label">Expected Improvement</div>
                <div class="score-value">
                    📈 +${((analysis.expectedImprovement ?? 0) * 100).toStringAsFixed(1)}%
                </div>
            </div>
            <div class="score-card">
                <div class="score-label">Effort Estimation</div>
                <div class="score-value">
                    ⏱️ ${analysis.estimatedEffort?.toStringAsFixed(1) ?? 'N/A'}h
                </div>
            </div>
        </div>
    </div>

    <!-- Regression Warning -->
    ${analysis.regressions.isNotEmpty ? '''
    <div class="regression-alert">
        <h3>🚨 Accessibility Regression Detected!</h3>
        <p>The following components passed in the previous version but failed in the current one:</p>
        <ul>
            ${analysis.regressions.map((r) => '<li><strong>${r.affectedComponents.map((c) => _escapeHtml(c)).join(", ")}</strong> - ${_escapeHtml(r.title)}</li>').join('\n')}
        </ul>
    </div>
    ''' : ''}

    <!-- AI Analysis: Key Insights -->
    <div class="card analysis-section">
        <h2>🧠 AI Analysis: Key Insights</h2>

        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 15px; margin: 20px 0;">
            <div style="text-align: center; padding: 15px; background: white; border-radius: 8px;">
                <div style="font-size: 32px; font-weight: bold; color: #dc3545;">
                    ${analysis.criticalInsights.length}
                </div>
                <div style="color: #666; font-size: 14px;">Critical Issues</div>
            </div>
            <div style="text-align: center; padding: 15px; background: white; border-radius: 8px;">
                <div style="font-size: 32px; font-weight: bold; color: #ff9800;">
                    ${analysis.highInsights.length}
                </div>
                <div style="color: #666; font-size: 14px;">High Priority</div>
            </div>
            <div style="text-align: center; padding: 15px; background: white; border-radius: 8px;">
                <div style="font-size: 32px; font-weight: bold; color: #667eea;">
                    ${analysis.systemicIssues.length}
                </div>
                <div style="color: #666; font-size: 14px;">Systemic</div>
            </div>
            <div style="text-align: center; padding: 15px; background: white; border-radius: 8px;">
                <div style="font-size: 32px; font-weight: bold; color: #4caf50;">
                    ${analysis.totalAffectedComponents}
                </div>
                <div style="color: #666; font-size: 14px;">Affected Components</div>
            </div>
        </div>

        ${analysis.insights.isEmpty ? '''
        <div style="text-align: center; padding: 40px; color: #28a745;">
            <div style="font-size: 48px;">✅</div>
            <div style="font-size: 18px; margin-top: 10px;">No problem patterns detected!</div>
            <div style="color: #666; margin-top: 5px;">All tests comply with WCAG ${report.level.name.toUpperCase()} standards</div>
        </div>
        ''' : analysis.insights.map((insight) => _generateInsightHtml(insight)).join('\n')}
    </div>

    <!-- Standard Compliance Report -->
    <div class="card">
        <h2>📊 Compliance Overview</h2>
        <div class="chart-container">
            <canvas id="complianceChart"></canvas>
        </div>

        <table>
            <tr>
                <th>Test Item</th>
                <th>Value</th>
            </tr>
            <tr>
                <td>Total Validations</td>
                <td><strong>${report.score.total}</strong></td>
            </tr>
            <tr>
                <td>✅ Passed</td>
                <td style="color: #28a745;"><strong>${report.score.passed}</strong></td>
            </tr>
            <tr>
                <td>❌ Failed</td>
                <td style="color: #dc3545;"><strong>${report.score.failed}</strong></td>
            </tr>
            <tr>
                <td>🔴 Critical Failures</td>
                <td style="color: #dc3545;"><strong>${report.criticalFailures.length}</strong></td>
            </tr>
        </table>
    </div>

    <!-- Failed Component Details -->
    ${report.failures.isNotEmpty ? '''
    <div class="card">
        <h2>❌ Failed元件</h2>
        <table>
            <thead>
                <tr>
                    <th>Component Name</th>
                    <th>Issues Description</th>
                    <th>Severity</th>
                </tr>
            </thead>
            <tbody>
                ${report.failures.map((failure) => '''
                <tr>
                    <td><strong>${_escapeHtml(failure.name)}</strong></td>
                    <td>${_escapeHtml(failure.message)}</td>
                    <td class="severity-${failure.severity.name}">
                        ${failure.severity.emoji} ${failure.severity.name.toUpperCase()}
                    </td>
                </tr>
                ''').join('\n')}
            </tbody>
        </table>
    </div>
    ''' : ''}

    <!-- Chart.js Initialization -->
    <script>
        const reportData = ${jsonEncode(reportJson)};
        const chartData = $chartData;

        // Compliance Doughnut Chart
        new Chart(document.getElementById('complianceChart'), {
            type: 'doughnut',
            data: {
                labels: ['Passed', 'Failed'],
                datasets: [{
                    data: [${report.score.passed}, ${report.score.failed}],
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
    </script>
</body>
</html>
''';
}

/// Generate HTML for a single insight
String _generateInsightHtml(Insight insight) {
  final severityClass = 'insight-${insight.severity.name}';

  return '''
<div class="insight $severityClass">
    <div class="insight-header">
        <span class="insight-emoji">${insight.severity.emoji}</span>
        <span class="insight-title">${_escapeHtml(insight.title)}</span>
        <span class="insight-confidence">${(insight.confidence * 100).toStringAsFixed(0)}% Confidence</span>
    </div>

    <div class="insight-meta">
        <div class="insight-meta-item">
            <span>📋</span>
            <span>Type: ${_getInsightTypeName(insight.type)}</span>
        </div>
        <div class="insight-meta-item">
            <span>🔢</span>
            <span>Failure Count: ${insight.failureCount}</span>
        </div>
        <div class="insight-meta-item">
            <span>📌</span>
            <span>SC: ${insight.successCriteria.join(", ")}</span>
        </div>
    </div>

    <div class="insight-description">
        ${_escapeHtml(insight.description)}
    </div>

    <div style="margin: 10px 0;">
        <strong>Affected Components:</strong>
        <div class="affected-components">
            ${insight.affectedComponents.map((c) => '<span class="component-badge">${_escapeHtml(c)}</span>').join('\n')}
        </div>
    </div>

    ${insight.actions.isNotEmpty ? '''
    <div class="action-steps">
        <strong>🛠️ Fix Steps:</strong>
        ${insight.actions.map((action) => '''
        <div class="action-step">
            <div class="action-step-header">
                Step ${action.step}: ${_escapeHtml(action.description)}
            </div>
            ${action.filePath != null ? '<div style="color: #666; font-size: 13px;">📁 File: ${_escapeHtml(action.filePath!)}</div>' : ''}
            ${action.codeExample != null ? '<div class="code-example">${_escapeHtml(action.codeExample!)}</div>' : ''}
            ${action.impact != null ? '<div class="action-impact">✨ ${_escapeHtml(action.impact!)}</div>' : ''}
        </div>
        ''').join('\n')}
    </div>
    ''' : ''}
</div>
''';
}

/// 取得Health Score的 CSS class
String _getHealthClass(double score) {
  if (score >= 0.8) return 'health-good';
  if (score >= 0.5) return 'health-warning';
  return 'health-danger';
}

/// 取得Health Score的 emoji
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

/// Complete usage example
void main() {
  // 1. Create Reporter and collect data
  final reporter = TargetSizeReporter(targetLevel: WcagLevel.aaa);

  reporter.validateComponent(
    componentName: 'LoginButton',
    actualSize: const Size(32, 32),
    severity: Severity.critical,
  );

  reporter.validateComponent(
    componentName: 'CancelButton',
    actualSize: const Size(38, 38),
    severity: Severity.high,
  );

  reporter.validateComponent(
    componentName: 'HelpIcon',
    actualSize: const Size(48, 48),
  );

  // 2. Generate report
  final report = reporter.generate(
    version: 'v2.0.0',
    gitCommitHash: 'abc123',
    environment: 'Demo',
  );

  // 3. Generate enhanced HTML with AI analysis
  final enhancedHtml = generateEnhancedHtmlReport(
    report: report,
    includeFixSuggestions: true,
  );

  // 4. Save report
  final outputDir = Directory('reports/accessibility/enhanced');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  File('${outputDir.path}/enhanced_report.html')
      .writeAsStringSync(enhancedHtml);

  print('✅ Enhanced HTML report generated!');
  print('   Path: ${outputDir.path}/enhanced_report.html');
  print('   Includes: AI analysis、fix suggestions、priority sorting');
}
