import 'package:privacy_gui/page/instant_verify/models/diagnostic_client.dart';
import 'package:privacy_gui/page/instant_verify/models/device_score.dart';
import 'package:privacy_gui/page/instant_verify/models/mesh_node_info.dart';

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

  /// Which check number produced this finding (for post-restart escalation D-26).
  final int? checkNumber;

  /// ISP escalation text to show after a failed restart attempt (D-26).
  final String? postRestartEscalation;

  const VerdictFinding({
    required this.priority,
    required this.headline,
    required this.explanation,
    this.actionLabel,
    this.actionKey,
    this.checkNumber,
    this.postRestartEscalation,
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

  bool get isPreliminary => false;
}

/// Computes the customer-facing verdict from available diagnostic inputs.
///
/// Diagnostic chain order (most → least severe):
/// 1. Router reachable (gateway ping to 192.168.1.1)
/// 2. WAN status — connected/disconnected
/// 3. WAN IP assigned — modem DHCP worked
/// 4. Internet reachable (DNS check)
/// 5. Internet speed
/// 6. Latency
/// 7. Device WiFi quality (signal + data rate combined)
/// 8. 2.4 GHz band overcrowding
/// 9. Firmware update available
/// 10. Long uptime
class VerdictEngine {
  static const String actionRestartRouter = 'restart_router';
  static const String actionFirmwareUpdate = 'firmware_update';

  static Verdict compute({
    required bool? gatewayReachable,
    required bool? wanConnected,
    required String? wanIpAddress,
    required bool? dnsWorking,
    required double? downloadMbps,
    required int? latencyMs,
    required bool? firmwareUpdateAvailable,
    required String? firmwareVersion,
    required int? uptimeSeconds,
    required List<DeviceScore> deviceScores,
    required List<DiagnosticClient> clients,
    required List<MeshNodeInfo> meshNodes,
    required double? planSpeedMbps,
    bool? isWifiScheduleBlocking,
    bool? isInstantPrivacyOn,
    bool? isInstantPauseActive,
    int? cpuLoadPct,
    int? memoryLoadPct,
    int? wifiSnrDb,
    bool? isPmfRequired,
    // New checks (items 28, 30, 38, 43)
    bool? isBandSteeringMissteer,    // 5GHz-capable device stuck on 2.4 GHz with steering on
    bool? hasEthernetNoLink,         // Wired device with no physical link detected
    bool? hasZombieMeshNode,         // Node with good RSSI but degraded throughput
    int? dhcpPoolUtilizationPct,     // 0-100, percentage of DHCP pool used
  }) {
    final findings = <VerdictFinding>[];
    int checksRun = 0;

    // ── Check 1: Router reachable (ping 192.168.1.1) ─────────────────────
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
          checkNumber: 1,
          postRestartEscalation: 'Your router may not be responding. Contact Linksys support.',
        ));
        return Verdict(findings: findings, checksRun: checksRun);
      }
    }

    // ── Check 2: WAN connection ───────────────────────────────────────────
    if (wanConnected != null) {
      checksRun++;
      if (!wanConnected) {
        findings.add(const VerdictFinding(
          priority: VerdictPriority.critical,
          headline: 'No internet connection detected',
          explanation:
              'Check that:\n'
              '• Your modem is powered on (look for the WAN or Internet light)\n'
              '• The cable from your modem to your router\'s WAN/Internet port is firmly plugged in\n\n'
              'If cables look fine, your internet service may be down — contact your provider.',
        ));
        return Verdict(findings: findings, checksRun: checksRun);
      }
    }

    // ── Check 3: WAN IP assigned (ISP DHCP) ──────────────────────────────
    if (wanConnected == true && wanIpAddress != null) {
      checksRun++;
      final hasIp = wanIpAddress.isNotEmpty;
      if (!hasIp) {
        findings.add(VerdictFinding(
          priority: VerdictPriority.critical,
          headline: 'Your router connected but didn\'t get an address',
          explanation:
              'The router line is active but your internet provider didn\'t assign an '
              'IP address. This usually means the modem needs a restart. '
              'Unplug your modem (the box from your ISP), wait 30 seconds, plug it back in, '
              'then restart the router.',
          actionLabel: 'Restart Router',
          actionKey: actionRestartRouter,
          checkNumber: 3,
          postRestartEscalation: _ispEscalation(
            'my router shows it\'s connected but didn\'t get an IP address',
          ),
        ));
        return Verdict(findings: findings, checksRun: checksRun);
      }
    }

    // ── Check 3b: Double-NAT / CGNAT detection ───────────────────────────────
    if (wanConnected == true && wanIpAddress != null && wanIpAddress.isNotEmpty) {
      final parts = wanIpAddress.split('.');
      if (parts.length == 4) {
        final first = int.tryParse(parts[0]) ?? 0;
        final second = int.tryParse(parts[1]) ?? 0;
        final isCgnat = first == 100 && second >= 64 && second <= 127;
        final isDoubleNat = first == 10 ||
            (first == 192 && second == 168) ||
            (first == 172 && second >= 16 && second <= 31);
        if (isCgnat) {
          findings.add(const VerdictFinding(
            priority: VerdictPriority.info,
            headline: 'Your ISP is using a shared IP address (CGNAT)',
            explanation: 'Carrier-Grade NAT is active. Port forwarding and some online games won\'t work. Contact your ISP if you need a dedicated public IP address.',
          ));
        } else if (isDoubleNat) {
          findings.add(const VerdictFinding(
            priority: VerdictPriority.info,
            headline: 'Your router may be behind another router (double-NAT)',
            explanation: 'Your WAN address is private — your Linksys router is connected behind another router or modem/router combo. Port forwarding won\'t work. Put the upstream device into bridge mode to fix this.',
          ));
        }
      }
    }

    // ── Check 4: Internet reachable (DNS/website access) ─────────────────
    if (dnsWorking != null && wanConnected != false) {
      checksRun++;
      if (!dnsWorking) {
        // We know: WAN connected ✓, router IP ✓, router LAN reachable ✓
        // Gateway (ISP side) reachability: we can't browser-ping the ISP gateway,
        // but we can tell the customer what we verified.
        final ipText = (wanIpAddress != null && wanIpAddress.isNotEmpty)
            ? 'WAN IP assigned ($wanIpAddress)'
            : 'WAN connected';
        findings.add(VerdictFinding(
          priority: VerdictPriority.critical,
          headline: 'Your internet isn\'t working',
          explanation:
              'Verified: Router reachable \u2713  $ipText \u2713  Websites: not loading \u2717\n\n'
              'Your router is connected but can\'t reach websites. '
              'Try restarting your router. If it keeps happening, '
              'the problem may be with your provider\'s network.',
          actionLabel: 'Restart Router',
          actionKey: actionRestartRouter,
          checkNumber: 4,
          postRestartEscalation: _ispEscalation(
            'websites won\'t load',
          ),
        ));
      }
    }

    // ── Check 5: Internet speed ───────────────────────────────────────────
    if (downloadMbps != null && wanConnected != false && dnsWorking != false) {
      checksRun++;
      final plan = planSpeedMbps;

      // Check if weak WiFi on connected devices might explain the slow speed
      final hasWeakDevices = deviceScores.any((d) => d.isIssue);
      final weakNote = hasWeakDevices
          ? ' Note: this test runs from your current device — if it has a weak WiFi signal, the reading may be lower than your router\'s actual speed.'
          : '';

      // Weak-WiFi elevation (PRD v0.7 D-8): if test device has weak WiFi,
      // elevate that as primary finding ahead of speed
      if (hasWeakDevices && downloadMbps < 25) {
        findings.add(VerdictFinding(
          priority: VerdictPriority.warning,
          headline: 'Your device has a weak WiFi connection',
          explanation:
              'This speed test runs from your device \u2014 your device has a weak '
              'WiFi connection, which may be making the reading look lower than '
              'your actual internet speed.\n\n'
              'Fix your device\'s signal first, then run again.',
          checkNumber: 7,
        ));
      }

      if (downloadMbps < 5) {
        findings.add(VerdictFinding(
          priority: VerdictPriority.critical,
          headline:
              'Your internet is very slow (${downloadMbps.toStringAsFixed(0)} Mbps)',
          explanation:
              'Getting about ${downloadMbps.toStringAsFixed(0)} Mbps \u2014 barely enough for video calls.'
              '${hasWeakDevices ? '' : ' '}$weakNote '
              'Speed can vary based on time of day, how many devices are active, '
              'and your distance from the router.',
          actionLabel: 'Restart Router',
          actionKey: actionRestartRouter,
          checkNumber: 5,
          postRestartEscalation: _ispEscalation(
            'my speed is only ${downloadMbps.toStringAsFixed(0)} Mbps',
          ),
        ));
      } else if (downloadMbps < 25 ||
          (plan != null && downloadMbps < plan * 0.5)) {
        final planText = plan != null
            ? ' (your plan is ${plan.toStringAsFixed(0)} Mbps)'
            : '';
        findings.add(VerdictFinding(
          priority: VerdictPriority.warning,
          headline:
              'Your internet is slower than expected (${downloadMbps.toStringAsFixed(0)} Mbps$planText)',
          explanation:
              'Getting about ${downloadMbps.toStringAsFixed(0)} Mbps.$weakNote '
              'Speed can vary based on time of day, how many devices are active, '
              'and your distance from the router.',
          actionLabel: 'Restart Router',
          actionKey: actionRestartRouter,
          checkNumber: 6,
          postRestartEscalation: _ispEscalation(
            'my internet is slower than what I\'m paying for. '
            'My speed test shows ${downloadMbps.toStringAsFixed(0)} Mbps',
          ),
        ));
      }
    }

    // ── Check 6: Latency ─────────────────────────────────────────────────
    if (latencyMs != null && wanConnected != false && dnsWorking != false) {
      checksRun++;
      if (latencyMs > 100) {
        findings.add(VerdictFinding(
          priority: VerdictPriority.warning,
          headline: 'High lag detected (${latencyMs}ms)',
          explanation:
              'High latency causes delays in video calls and online games. '
              'Try restarting your modem. If it persists, contact your provider.',
        ));
      }
    }

    // ── Check 7: Device WiFi quality (signal + data rate combined) ────────
    if (deviceScores.isNotEmpty) {
      checksRun++;
      // isFlagged already combines: signal < -75 dBm OR tx/rx rate < 10 Mbps
      final issueDevices = deviceScores.where((d) => d.isIssue).toList()
        ..sort((a, b) => a.score.compareTo(b.score));

      if (issueDevices.isNotEmpty) {
        final count = issueDevices.length;
        final deviceWord = count == 1 ? 'device' : 'devices';
        final names = issueDevices
            .take(3)
            .map((d) => d.client.displayNameWithOui)
            .toList();
        final nameText = names.length >= 3
            ? '${names.sublist(0, 2).join(', ')}, and ${count - 2} more'
            : names.join(' and ');

        final tooFarCount = issueDevices
            .where((d) => (d.client.signalDecibels ?? 0) < -75)
            .length;
        final slowRateCount = issueDevices
            .where((d) =>
                (d.client.txRateMbps ?? 0) < 10 ||
                (d.client.rxRateMbps ?? 0) < 10)
            .length;

        String advice;
        if (tooFarCount > count / 2) {
          advice =
              '$nameText ${count == 1 ? 'has' : 'have'} a weak signal. '
              'Moving your router to a more central location could help.';
        } else if (slowRateCount > count / 2) {
          advice =
              '$nameText ${count == 1 ? 'is' : 'are'} getting very slow WiFi speeds. '
              'Check for thick walls or interference between these devices and your router. '
              'Moving them closer often helps.';
        } else {
          advice =
              '$nameText ${count == 1 ? 'has' : 'have'} a weak WiFi connection. '
              'Check for walls, metal objects, or appliances between them and your router.';
        }

        findings.add(VerdictFinding(
          priority: VerdictPriority.warning,
          headline: '$count $deviceWord with weak WiFi',
          explanation: advice,
        ));
      }
    }

    // ── Check 8: 2.4 GHz band overcrowding ───────────────────────────────
    if (clients.isNotEmpty) {
      final wirelessClients = clients.where((c) => c.isWireless).toList();
      if (wirelessClients.length >= 4) {
        checksRun++;
        final twoFourCount =
            wirelessClients.where((c) => c.band.contains('2.4')).length;
        final ratio = twoFourCount / wirelessClients.length;
        if (ratio >= 0.6 && twoFourCount >= 4) {
          findings.add(VerdictFinding(
            priority: VerdictPriority.info,
            headline:
                '$twoFourCount of ${wirelessClients.length} devices are on the slower 2.4 GHz band',
            explanation:
                'The 2.4 GHz band is more congested and slower than 5 GHz. '
                'On your devices, go to WiFi settings and connect to the 5 GHz network '
                '(same name, same password — your phone will prefer it if it\'s in range).',
          ));
        }
      }
    }

    // ── Check 9: Mesh backhaul health ────────────────────────────────────
    if (meshNodes.length > 1) {
      checksRun++;
      final weakNodes = meshNodes.where((n) => n.hasWeakBackhaul).toList();
      if (weakNodes.isNotEmpty) {
        final names = weakNodes.map((n) => n.name).join(', ');
        final count = weakNodes.length;
        final nodeWord = count == 1 ? 'satellite node' : 'satellite nodes';
        findings.add(VerdictFinding(
          priority: VerdictPriority.warning,
          headline:
              '$count $nodeWord ${count == 1 ? 'has' : 'have'} a weak connection to your router',
          explanation:
              '$names ${count == 1 ? 'is' : 'are'} connected wirelessly with a weak signal '
              '(${weakNodes.map((n) => '${n.backhaulRssi} dBm').join(', ')}). '
              'Moving ${count == 1 ? 'it' : 'them'} closer to your main router, '
              'or connecting via Ethernet, will improve network reliability.',
        ));
      }
    }

    // ── Check 12: WiFi access restrictions ───────────────────────────────────
    if (isWifiScheduleBlocking != null) checksRun++;
    if (isWifiScheduleBlocking == true) {
      findings.add(const VerdictFinding(
        priority: VerdictPriority.info,
        headline: 'Your WiFi schedule may be blocking connections',
        explanation: 'Your router has a WiFi schedule that turns off wireless access during certain hours. If your WiFi isn\'t working at a specific time, check your schedule settings.',
      ));
    }
    if (isInstantPrivacyOn != null) checksRun++;
    if (isInstantPrivacyOn == true) {
      findings.add(const VerdictFinding(
        priority: VerdictPriority.warning,
        headline: 'Instant Privacy is blocking new devices',
        explanation: 'Instant Privacy is on — new devices can\'t connect until it\'s turned off. Go to your router settings to disable Instant Privacy.',
      ));
    }
    if (isInstantPauseActive != null) checksRun++;
    if (isInstantPauseActive == true) {
      findings.add(const VerdictFinding(
        priority: VerdictPriority.warning,
        headline: 'Internet access is paused',
        explanation: 'A parental control pause is active. This blocks internet access for some devices. Check your parental control settings.',
      ));
    }

    // ── Check 13: CPU / Memory ────────────────────────────────────────────────
    if (cpuLoadPct != null || memoryLoadPct != null) checksRun++;
    if (cpuLoadPct != null && cpuLoadPct > 80) {
      findings.add(VerdictFinding(
        priority: VerdictPriority.warning,
        headline: 'Your router is under high load ($cpuLoadPct% CPU)',
        explanation: 'An overloaded processor can drop packets and slow all devices. A restart usually clears this.',
        actionLabel: 'Restart Router',
        actionKey: actionRestartRouter,
      ));
    }
    if (memoryLoadPct != null && memoryLoadPct > 85) {
      findings.add(VerdictFinding(
        priority: VerdictPriority.warning,
        headline: 'Your router\'s memory is nearly full ($memoryLoadPct%)',
        explanation: 'Low memory causes slowdowns and dropped connections. A restart will clear it.',
        actionLabel: 'Restart Router',
        actionKey: actionRestartRouter,
      ));
    }

    // ── Check 14: Channel interference (SNR) ─────────────────────────────────
    if (wifiSnrDb != null) {
      checksRun++;
      if (wifiSnrDb < 20) {
        findings.add(const VerdictFinding(
          priority: VerdictPriority.info,
          headline: 'WiFi interference from nearby networks',
          explanation: 'Your 5 GHz radio is experiencing interference, likely from neighboring WiFi networks. This is common in apartments and dense buildings. Contact Linksys support about adjusting your WiFi channel.',
        ));
      }
    }

    // ── Check 15: WPA3 PMF Required (breaks IoT devices) ─────────────────────
    if (isPmfRequired != null) {
      checksRun++;
      if (isPmfRequired) {
        findings.add(const VerdictFinding(
          priority: VerdictPriority.warning,
          headline: 'WiFi security setting may block smart home devices',
          explanation: 'Your router has strict Protected Management Frames (PMF) enabled. Some smart home devices (Ring, Nest, smart bulbs) can\'t connect with this setting. Switch to WPA2/WPA3 compatibility mode in your WiFi Security settings.',
        ));
      }
    }

    // ── Check 16: Band steering mis-steer (item 28) ──────────────────────────
    if (isBandSteeringMissteer != null) {
      checksRun++;
      if (isBandSteeringMissteer) {
        findings.add(const VerdictFinding(
          priority: VerdictPriority.warning,
          headline: 'A device is stuck on the slower 2.4 GHz band',
          explanation:
              'Your router has automatic band selection on, but one or more '
              '5 GHz-capable devices are on the slower 2.4 GHz band. '
              'Moving the device closer to your router, or forgetting and '
              'reconnecting, usually fixes this.',
        ));
      }
    }

    // ── Check 17: Ethernet no-link (item 30) ─────────────────────────────────
    if (hasEthernetNoLink != null) {
      checksRun++;
      if (hasEthernetNoLink) {
        findings.add(const VerdictFinding(
          priority: VerdictPriority.warning,
          headline: 'A wired device has no network link',
          explanation:
              'One or more devices are plugged in via Ethernet cable but '
              'the port shows no connection. Check that the cable is firmly '
              'plugged in at both ends. Try a different cable or port.',
        ));
      }
    }

    // ── Check 18: Zombie mesh node (item 38) ─────────────────────────────────
    if (hasZombieMeshNode != null) {
      checksRun++;
      if (hasZombieMeshNode) {
        findings.add(const VerdictFinding(
          priority: VerdictPriority.warning,
          headline: 'A satellite node is connected but not working well',
          explanation:
              'One of your satellite nodes is connected to your router but '
              'its speed is much lower than expected — devices in that area '
              'will be slow even though the node appears connected. '
              'Try restarting your router. If it keeps happening, '
              'move the node closer or connect it with an Ethernet cable.',
          actionLabel: 'Restart Router',
          actionKey: actionRestartRouter,
        ));
      }
    }

    // ── Check 19: DHCP pool near capacity (item 43) ────────────────────────
    if (dhcpPoolUtilizationPct != null) {
      checksRun++;
      if (dhcpPoolUtilizationPct >= 90) {
        findings.add(VerdictFinding(
          priority: VerdictPriority.warning,
          headline:
              'Your network address pool is almost full ($dhcpPoolUtilizationPct% used)',
          explanation:
              'Your router can only support a limited number of devices. '
              'When the pool is full, new devices will fail to connect '
              'even with the correct password. Contact Linksys support '
              'to increase the pool size.',
        ));
      }
    }

    // ── Check 10: Firmware update ──────────────────────────────────────────
    if (firmwareUpdateAvailable == true) {
      checksRun++;
      final versionText =
          firmwareVersion != null ? ' ($firmwareVersion)' : '';
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

    // ── Check 11: Long uptime ─────────────────────────────────────────────
    if (uptimeSeconds != null) {
      checksRun++;
      final days = uptimeSeconds ~/ 86400;
      if (days >= 30) {
        findings.add(VerdictFinding(
          priority: VerdictPriority.info,
          headline: 'Your router has been running for $days days without a restart',
          explanation:
              'A restart can clear up slowdowns that build up over time. '
              'Once a month is a good habit.',
          actionLabel: 'Restart Router',
          actionKey: actionRestartRouter,
        ));
      }
    }

    findings.sort((a, b) => a.priority.index.compareTo(b.priority.index));

    return Verdict(
      findings: findings,
      checksRun: checksRun > 0 ? checksRun : 8,
    );
  }

  /// Generates ISP escalation text (PRD v0.7 D-26, D-31, D-32).
  static String _ispEscalation(String symptom) =>
      'Since restarting didn\'t fix it, the issue is likely '
      'outside your router.\n\n'
      'When you call your internet provider, say:\n'
      '"My router shows it\'s connected but $symptom. '
      'I restarted my router but the problem persists."';
}
