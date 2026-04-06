import 'package:privacy_gui/page/instant_verify/models/device_score.dart';

enum VerdictPriority { critical, warning, info, allClear }

/// A single actionable finding shown on the Overview tab.
///
/// Only findings with a clear fix path (auto-launchable or concrete instruction)
/// should appear on the customer-facing Overview. Technical findings without
/// a customer action go to agent tabs only.
class VerdictFinding {
  final VerdictPriority priority;

  /// Short headline: "Your internet is slow (12 Mbps)"
  final String headline;

  /// Plain-language explanation + what to do next.
  final String explanation;

  /// Button label for auto-fix, or null if instruction-only.
  final String? actionLabel;

  /// Key identifying which action to trigger. See [VerdictEngine] constants.
  final String? actionKey;

  const VerdictFinding({
    required this.priority,
    required this.headline,
    required this.explanation,
    this.actionLabel,
    this.actionKey,
  });

  bool get hasAutoFix => actionKey != null;
}

/// Full verdict result: ranked findings + check count.
class Verdict {
  final List<VerdictFinding> findings;

  /// Total number of checks run (for "X checks passed" trust indicator).
  final int checksRun;

  const Verdict({required this.findings, this.checksRun = 0});

  VerdictFinding? get primaryFinding =>
      findings.isEmpty ? null : findings.first;

  /// Always-visible findings (up to 2 shown without expand).
  List<VerdictFinding> get visibleFindings => findings.take(2).toList();

  /// Overflow findings shown only when user expands.
  List<VerdictFinding> get hiddenFindings =>
      findings.length > 2 ? findings.skip(2).toList() : [];

  bool get isAllClear =>
      findings.isEmpty ||
      findings.every((f) => f.priority == VerdictPriority.allClear);

  VerdictPriority get overallPriority =>
      findings.isEmpty ? VerdictPriority.allClear : findings.first.priority;

  /// True if speed tests are still pending — verdict is preliminary.
  bool get isPreliminary => false; // set externally via state
}

/// Computes the customer-facing verdict from available diagnostic inputs.
///
/// Rules:
/// - Only findings with a clear fix path are included.
/// - Technical metrics without a customer action (CPU%, memory%, DHCP%) are excluded.
/// - Sorted by severity: critical → warning → info.
class VerdictEngine {
  // Auto-fix action key constants
  static const String actionRestartRouter = 'restart_router';
  static const String actionFirmwareUpdate = 'firmware_update';

  static Verdict compute({
    required bool? gatewayReachable,
    required bool? wanConnected,
    required bool? dnsWorking,
    required double? downloadMbps,
    required int? latencyMs,
    required bool? firmwareUpdateAvailable,
    required String? firmwareVersion,
    required int? uptimeSeconds,
    required List<DeviceScore> deviceScores,
    required double? planSpeedMbps,
  }) {
    final findings = <VerdictFinding>[];
    int checksRun = 0;

    // Check 1: Can we reach the router?
    if (gatewayReachable != null) {
      checksRun++;
      if (!gatewayReachable) {
        findings.add(const VerdictFinding(
          priority: VerdictPriority.critical,
          headline: 'Your router can\'t be reached',
          explanation:
              'Try refreshing the page. If this keeps happening, your router may need a restart.',
          actionLabel: 'Restart Router',
          actionKey: actionRestartRouter,
        ));
        // Can't trust any other checks if gateway is down
        return Verdict(findings: findings, checksRun: checksRun);
      }
    }

    // Check 2: WAN status — distinguish ISP outage from local problem
    if (wanConnected != null) {
      checksRun++;
      if (!wanConnected) {
        // WAN disconnected: ISP-side issue, router restart won't help
        findings.add(const VerdictFinding(
          priority: VerdictPriority.critical,
          headline: 'Your internet service appears down',
          explanation:
              'Your router is working, but your internet service isn\'t connected. '
              'This is not a router problem — please contact your internet provider.',
        ));
      } else if (dnsWorking == false) {
        checksRun++;
        // WAN connected but DNS/internet unreachable: router restart may help
        findings.add(const VerdictFinding(
          priority: VerdictPriority.critical,
          headline: 'Your internet is not working',
          explanation:
              'Your router is on but can\'t reach websites. '
              'Try restarting your router first.',
          actionLabel: 'Restart Router',
          actionKey: actionRestartRouter,
        ));
      } else if (dnsWorking != null) {
        checksRun++;
      }
    }

    // Check 3: Internet speed (only meaningful if WAN is connected)
    if (downloadMbps != null && wanConnected != false) {
      checksRun++;
      final plan = planSpeedMbps;

      if (downloadMbps < 5) {
        findings.add(VerdictFinding(
          priority: VerdictPriority.critical,
          headline:
              'Your internet is very slow (${downloadMbps.toStringAsFixed(0)} Mbps)',
          explanation:
              'Getting about ${downloadMbps.toStringAsFixed(0)} Mbps. '
              'Try restarting your router first. If still slow, restart your modem.',
          actionLabel: 'Restart Router',
          actionKey: actionRestartRouter,
        ));
      } else if (downloadMbps < 25 ||
          (plan != null && downloadMbps < plan * 0.5)) {
        final planText = plan != null
            ? ' (your plan promises ${plan.toStringAsFixed(0)} Mbps)'
            : '';
        findings.add(VerdictFinding(
          priority: VerdictPriority.warning,
          headline:
              'Your internet is slower than expected (${downloadMbps.toStringAsFixed(0)} Mbps$planText)',
          explanation:
              'Getting about ${downloadMbps.toStringAsFixed(0)} Mbps. '
              'Restarting your router often helps with slowdowns.',
          actionLabel: 'Restart Router',
          actionKey: actionRestartRouter,
        ));
      }
    }

    // Check 4: High latency (causes noticeable lag, actionable via modem restart)
    if (latencyMs != null && wanConnected != false) {
      checksRun++;
      if (latencyMs > 100) {
        findings.add(VerdictFinding(
          priority: VerdictPriority.warning,
          headline: 'High lag detected (${latencyMs}ms)',
          explanation:
              'Your connection has high latency, which causes delays in '
              'video calls and online games. Try restarting your modem.',
        ));
      }
    }

    // Check 5: Device WiFi quality
    if (deviceScores.isNotEmpty) {
      checksRun++;
      final issueDevices = deviceScores.where((d) => d.isIssue).toList()
        ..sort((a, b) => a.score.compareTo(b.score));

      if (issueDevices.isNotEmpty) {
        final names = issueDevices
            .take(3)
            .map((d) => d.client.displayNameWithOui)
            .toList();
        final count = issueDevices.length;
        final deviceWord = count == 1 ? 'device' : 'devices';
        final nameText = names.length >= 3
            ? '${names.sublist(0, 2).join(', ')}, and ${count - 2} more'
            : names.join(' and ');

        // Classify: mostly too-far (signal < -75) or mostly interference
        final tooFarCount =
            issueDevices.where((d) => (d.client.signalDecibels ?? 0) < -75).length;

        if (tooFarCount > count / 2) {
          findings.add(VerdictFinding(
            priority: VerdictPriority.warning,
            headline: '$count $deviceWord may be too far from your router',
            explanation:
                '$nameText ${count == 1 ? 'has' : 'have'} a weak WiFi signal. '
                'Moving your router to a more central location could help.',
          ));
        } else {
          findings.add(VerdictFinding(
            priority: VerdictPriority.warning,
            headline: '$count $deviceWord ${count == 1 ? 'has' : 'have'} weak WiFi',
            explanation:
                '$nameText ${count == 1 ? 'has' : 'have'} a weak WiFi connection. '
                'Check for thick walls or obstacles between these devices and your router.',
          ));
        }
      }
    }

    // Check 6: Firmware update available (info — not an emergency)
    if (firmwareUpdateAvailable == true) {
      checksRun++;
      final versionText = firmwareVersion != null ? ' ($firmwareVersion)' : '';
      findings.add(VerdictFinding(
        priority: VerdictPriority.info,
        headline: 'A software update is available$versionText',
        explanation:
            'Keeping your router updated improves performance and security.',
        actionLabel: 'Update Now',
        actionKey: actionFirmwareUpdate,
      ));
    } else if (firmwareUpdateAvailable != null) {
      checksRun++;
    }

    // Check 7: Long uptime (info — restart can help accumulated slowdowns)
    if (uptimeSeconds != null) {
      checksRun++;
      final days = uptimeSeconds ~/ 86400;
      if (days >= 30) {
        findings.add(VerdictFinding(
          priority: VerdictPriority.info,
          headline: 'Your router has been running for $days days',
          explanation:
              'A restart can clear up slowdowns that build up over time.',
          actionLabel: 'Restart Router',
          actionKey: actionRestartRouter,
        ));
      }
    }

    // Sort: critical → warning → info
    findings.sort((a, b) => a.priority.index.compareTo(b.priority.index));

    return Verdict(
      findings: findings,
      checksRun: checksRun > 0 ? checksRun : 8,
    );
  }
}
