import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/instant_test/models/device_score.dart';
import 'package:privacy_gui/page/topology/models/node_ui_model.dart';

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
  static const String actionBridgeModeHelp = 'bridge_mode_help';

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
    /// DNS servers the router is using.
    /// When provided, Check 4 surfaces server addresses + targeted advice.
    List<String>? dnsServers,
    /// IPv6 WAN status — shown alongside DNS failure for context.
    bool? wanIpv6Connected,
    /// WAN connection type (DHCP/PPPoE/Static) — PPPoE may need re-auth.
    String? wanType,
    /// Result of silent public DNS check (Google DoH at 8.8.8.8).
    bool? publicDnsWorking,
    /// Whether configured DNS server IPs respond to ICMP ping from the router.
    bool? configuredDnsReachable,
    required List<DeviceScore> deviceScores,
    required List<DeviceUIModel> clients,
    required List<NodeUIModel> meshNodes,
    required double? planSpeedMbps,
    bool? isWifiScheduleBlocking,
    bool? isInstantPrivacyOn,
    bool? isInstantPauseActive,
    int? cpuLoadPct,
    int? cpuLoadPctStart,
    int? memoryLoadPct,
    int? wifiSnrDb,
    bool? isPmfRequired,
    bool? isBandSteeringMissteer,
    bool? hasEthernetNoLink,
    bool? hasZombieMeshNode,
    int? dhcpPoolUtilizationPct,
    bool? isDeviceInApMode,
    // Three-leg comparison (D-R7): router→internet speed from USP speedTestProvider.
    // If provided and significantly faster than client→internet, surfaces WiFi bottleneck finding.
    double? routerInternetDownloadMbps,
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

    // ── Check 3b: Double-NAT / CGNAT detection — TEMPORARILY DISABLED ────
    // ignore: dead_code
    if (false && wanConnected == true && wanIpAddress != null) {}

    // ── Check 4: Internet reachable (DNS/website access) ─────────────────
    if (dnsWorking != null && wanConnected != false) {
      checksRun++;
      if (!dnsWorking) {
        final ipText = (wanIpAddress != null && wanIpAddress.isNotEmpty)
            ? 'WAN IP assigned ($wanIpAddress)'
            : 'WAN connected';

        final dnsBlock = StringBuffer();
        if (dnsServers != null && dnsServers.isNotEmpty) {
          dnsBlock.write('\n\nDNS servers your router is using:');
          for (final s in dnsServers) {
            dnsBlock.write('\n  • $s  (${_labelDnsServer(s)})');
          }
          final allIsp = dnsServers.every(_isIspOrPrivateDns);
          final hasCustom = dnsServers.any((s) => !_isIspOrPrivateDns(s));
          if (allIsp) {
            dnsBlock.write(
                '\n\nThese are assigned by your ISP. If their DNS servers are down, '
                'websites won\'t load even though your router is connected.');
          } else if (hasCustom) {
            dnsBlock.write(
                '\n\nYou\'re using custom DNS servers. If they\'re unreachable '
                'from your location, try switching back to automatic (ISP) DNS.');
          }
        }

        String wanTypeNote = '';
        if (wanType == 'PPPoE' || wanType == 'PPTP' || wanType == 'L2TP') {
          wanTypeNote = '\n\nYour connection type is $wanType — '
              'if the session dropped, a restart re-establishes it.';
        }

        final pcNote = isInstantPauseActive == true
            ? '\n\nParental controls are active — internet access may be '
              'paused for some devices.'
            : '';

        final ipv6Note = (wanIpv6Connected == false)
            ? '\n\nIPv6 is not connected — this is normal for most home '
              'connections and is not the cause of this issue.'
            : '';

        final String rootCauseContext;
        final String postRestartMsg;
        if (publicDnsWorking == true) {
          if (configuredDnsReachable == true) {
            rootCauseContext =
                '\n\nDiagnosis: DNS servers are online but not responding to '
                'queries — likely a DNS service issue on your ISP\'s side. '
                'Restarting your router clears the DNS cache.';
            postRestartMsg =
                'Since restarting didn\'t fix it, your ISP\'s DNS service is '
                'likely having an issue. Contact your provider and say: '
                '"My router can reach your DNS servers by IP but DNS queries '
                'are failing. It looks like a DNS service outage."';
          } else if (configuredDnsReachable == false) {
            rootCauseContext =
                '\n\nDiagnosis: Cannot reach your ISP\'s DNS servers — there '
                'may be a routing issue between your router and your provider. '
                'Try restarting both your modem and router (modem first, '
                'wait 30 seconds, then the router).';
            postRestartMsg =
                'Since restarting didn\'t fix it, there\'s likely a routing '
                'issue between your modem and ISP. Contact your provider and '
                'say: "My router cannot reach your DNS servers at all. '
                'I\'ve restarted both modem and router."';
          } else {
            rootCauseContext =
                '\n\nYour internet connection is working — only the DNS lookup '
                'service is failing. Restarting your router clears the DNS cache.';
            postRestartMsg =
                'Since restarting didn\'t fix it, your ISP\'s DNS servers may '
                'be having an outage. Contact your provider and say: '
                '"My router is connected but websites won\'t load. '
                'Your DNS servers appear to be down."';
          }
        } else if (publicDnsWorking == false) {
          rootCauseContext =
              '\n\nDiagnosis: Internet appears to be unreachable — not just '
              'DNS. This may be a wider outage from your provider. '
              'Check that all cables are firmly connected, then restart '
              'your modem and router.';
          postRestartMsg = _ispEscalation('websites won\'t load');
        } else {
          rootCauseContext = '';
          postRestartMsg = _ispEscalation('websites won\'t load');
        }

        findings.add(VerdictFinding(
          priority: VerdictPriority.critical,
          headline: 'Websites aren\'t loading',
          explanation:
              'Verified: Router reachable ✓  $ipText ✓  '
              'Website access: not working ✗'
              '$dnsBlock'
              '$rootCauseContext'
              '\n\nPossible causes:'
              '\n  • ISP DNS servers temporarily down'
              '\n  • ISP network issue between router and DNS'
              '\n  • DNS cache on router needs clearing (restart fixes this)'
              '$wanTypeNote'
              '$pcNote'
              '$ipv6Note',
          actionLabel: 'Restart Router',
          actionKey: actionRestartRouter,
          checkNumber: 4,
          postRestartEscalation: postRestartMsg,
        ));
      }
    }

    // ── Check 5: Internet speed ───────────────────────────────────────────
    if (downloadMbps != null && wanConnected != false && dnsWorking != false) {
      checksRun++;
      final plan = planSpeedMbps;

      final hasWeakDevices = deviceScores.any((d) => d.isIssue);
      final weakNote = hasWeakDevices
          ? ' Note: this test runs from your current device — if it has a weak WiFi signal, the reading may be lower than your router\'s actual speed.'
          : '';

      if (hasWeakDevices && downloadMbps < 25) {
        findings.add(VerdictFinding(
          priority: VerdictPriority.warning,
          headline: 'Your device has a weak WiFi connection',
          explanation:
              'This speed test runs from your device — your device has a weak '
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
              'Getting about ${downloadMbps.toStringAsFixed(0)} Mbps — barely enough for video calls.'
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

    // ── Check 5b: Three-leg WiFi bottleneck (D-R7) ───────────────────────
    // router→internet > 2× client→internet → WiFi hop is the bottleneck.
    if (downloadMbps != null &&
        routerInternetDownloadMbps != null &&
        routerInternetDownloadMbps > downloadMbps * 2 &&
        downloadMbps < 50) {
      findings.add(VerdictFinding(
        priority: VerdictPriority.warning,
        headline:
            'Your WiFi is slowing down your connection',
        explanation:
            'Your router gets ${routerInternetDownloadMbps.toStringAsFixed(0)} Mbps from your ISP, '
            'but your device is only seeing ${downloadMbps.toStringAsFixed(0)} Mbps. '
            'The WiFi hop between your device and router is the bottleneck. '
            'Moving closer to your router or connecting with an Ethernet cable will help.',
      ));
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
      final issueDevices = deviceScores.where((d) => d.isIssue).toList()
        ..sort((a, b) => a.score.compareTo(b.score));

      if (issueDevices.isNotEmpty) {
        final count = issueDevices.length;
        final deviceWord = count == 1 ? 'device' : 'devices';
        final names = issueDevices
            .take(3)
            .map((d) => d.device.displayName)
            .toList();
        final nameText = names.length >= 3
            ? '${names.sublist(0, 2).join(', ')}, and ${count - 2} more'
            : names.join(' and ');

        // signalStrength is RSSI dBm; downlinkRate is bits/sec
        final tooFarCount = issueDevices
            .where((d) => (d.device.signalStrength ?? 0) < -75)
            .length;
        final slowRateCount = issueDevices
            .where((d) => ((d.device.downlinkRate ?? 0) / 1000000) < 10)
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
      final wirelessClients = clients.where((c) => c.isWifi).toList();
      if (wirelessClients.length >= 4) {
        checksRun++;
        final twoFourCount =
            wirelessClients.where((c) => (c.band ?? '').contains('2.4')).length;
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
    final childNodes = meshNodes.where((n) => !n.isMaster).toList();
    if (childNodes.isNotEmpty) {
      checksRun++;
      // backhaulSignalStrength is RSSI dBm; < -70 = weak
      final weakNodes = childNodes
          .where((n) =>
              n.backhaulSignalStrength != null &&
              n.backhaulSignalStrength! < -70)
          .toList();
      if (weakNodes.isNotEmpty) {
        final names = weakNodes.map((n) => n.displayName).join(', ');
        final count = weakNodes.length;
        final nodeWord = count == 1 ? 'child node' : 'child nodes';
        findings.add(VerdictFinding(
          priority: VerdictPriority.warning,
          headline:
              '$count $nodeWord ${count == 1 ? 'has' : 'have'} a weak connection to your router',
          explanation:
              '$names ${count == 1 ? 'is' : 'are'} connected wirelessly with a weak signal '
              '(${weakNodes.map((n) => '${n.backhaulSignalStrength} dBm').join(', ')}). '
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

    // ── Check 13: CPU / Memory ────────────────────────────────────────────
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

    // ── Check 16: Band steering mis-steer ────────────────────────────────────
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

    // ── Check 17: Ethernet no-link ────────────────────────────────────────────
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

    // ── Check 18: Zombie mesh node ────────────────────────────────────────────
    if (hasZombieMeshNode != null) {
      checksRun++;
      if (hasZombieMeshNode) {
        findings.add(const VerdictFinding(
          priority: VerdictPriority.warning,
          headline: 'A child node is connected but not working well',
          explanation:
              'One of your child nodes is connected to your router but '
              'its speed is much lower than expected — devices in that area '
              'will be slow even though the node appears connected. '
              'Try restarting your router. If it keeps happening, '
              'move the node closer or connect it with an Ethernet cable.',
          actionLabel: 'Restart Router',
          actionKey: actionRestartRouter,
        ));
      }
    }

    // ── Check 19: DHCP pool near capacity ────────────────────────────────────
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

    // ── Check 10: Firmware update ─────────────────────────────────────────
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

  static bool _isIspOrPrivateDns(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    final a = int.tryParse(parts[0]) ?? -1;
    final b = int.tryParse(parts[1]) ?? -1;
    if (a == 10) return true;
    if (a == 172 && b >= 16 && b <= 31) return true;
    if (a == 192 && b == 168) return true;
    return false;
  }

  static String _labelDnsServer(String ip) {
    switch (ip) {
      case '8.8.8.8': return 'Google Public DNS';
      case '8.8.4.4': return 'Google Public DNS';
      case '1.1.1.1': return 'Cloudflare DNS';
      case '1.0.0.1': return 'Cloudflare DNS';
      case '208.67.222.222': return 'OpenDNS';
      case '208.67.220.220': return 'OpenDNS';
      case '9.9.9.9': return 'Quad9';
      case '149.112.112.112': return 'Quad9';
    }
    return _isIspOrPrivateDns(ip) ? 'assigned by your ISP' : 'custom DNS';
  }

  static String _ispEscalation(String symptom) =>
      'Since restarting didn\'t fix it, the issue is likely '
      'outside your router.\n\n'
      'When you call your internet provider, say:\n'
      '"My router shows it\'s connected but $symptom. '
      'I restarted my router but the problem persists."';
}
