import 'package:flutter/material.dart';
import 'package:privacy_gui/page/cs_diagnostic/models/diagnostic_client.dart';
import 'package:privacy_gui/page/cs_diagnostic/providers/cs_diagnostic_state.dart';

/// Shows flow-specific analysis when a complaint chip is selected on the agent dashboard.
class FlowAnalysisView extends StatelessWidget {
  final int complaintIndex;
  final CsDiagnosticState state;

  const FlowAnalysisView({
    super.key,
    required this.complaintIndex,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: switch (complaintIndex) {
        0 => _slowInternet(context),
        1 => _slowDevice(context),
        2 => _drops(context),
        3 => _cantConnect(context),
        4 => _deadSpots(context),
        5 => _offline(context),
        _ => const SizedBox.shrink(),
      },
    );
  }

  // ── Flow 1: Slow Internet ──────────────────────────────────────────
  Widget _slowInternet(BuildContext context) {
    final issues = <_Finding>[];

    // Router identity — model and firmware first
    final model = state.deviceInfo?['description'] ?? state.deviceInfo?['modelNumber'];
    final fw = state.deviceInfo?['firmwareVersion'];
    if (model != null || fw != null) {
      issues.add(_Finding(
        severity: _Severity.info,
        title: '${model ?? "Unknown"} — FW ${fw ?? "Unknown"}',
        detail: 'Uptime: ${_formatUptime(state.routerUptimeSeconds)}',
        action: 'Note model and firmware for reference.',
      ));
    }

    // WAN status
    if (!state.wanConnected) {
      issues.add(const _Finding(
        severity: _Severity.critical,
        title: 'WAN link is down',
        detail: 'No internet connectivity detected.',
        action: 'Verify modem power and cable. If modem is online, escalate to ISP.',
      ));
    } else {
      final wanConn = state.wanStatus?['wanConnection'] as Map<String, dynamic>?;
      final wanIp = wanConn?['ipAddress'] as String? ?? state.wanStatus?['wanIPAddress'] as String?;
      issues.add(_Finding(
        severity: _Severity.ok,
        title: 'WAN is connected${wanIp != null ? ' ($wanIp)' : ''}',
        detail: 'Internet uplink is active.',
        action: 'WAN is not the bottleneck. Check device-side factors below.',
      ));
    }

    // Router CPU/memory load
    final cpuLoad = state.routerHealth?['cpuLoad'] as int?;
    final memLoad = state.routerHealth?['memoryLoad'] as int?;
    if (cpuLoad != null && cpuLoad > 80) {
      issues.add(_Finding(
        severity: _Severity.warning,
        title: 'Router CPU load is $cpuLoad%',
        detail: 'High CPU can throttle wireless throughput and cause packet drops.',
        action: 'Reboot router. If persistent, check for excessive clients or firmware update.',
      ));
    }
    if (memLoad != null && memLoad > 80) {
      issues.add(_Finding(
        severity: _Severity.warning,
        title: 'Router memory usage is $memLoad%',
        detail: 'High memory can cause instability and slow packet forwarding.',
        action: 'Reboot may temporarily resolve. Check connected device count.',
      ));
    }

    // Recent reboot
    if (state.routerUptimeSeconds > 0 && state.routerUptimeSeconds < 3600) {
      issues.add(const _Finding(
        severity: _Severity.warning,
        title: 'Router rebooted recently',
        detail: 'Uptime is under 1 hour. Router may be crash-looping or was just restarted.',
        action: 'Check firmware version. If repeated reboots, escalate to engineering.',
      ));
    }

    // DHCP pressure
    if (state.dhcpUtilization > 0.8) {
      issues.add(_Finding(
        severity: _Severity.warning,
        title: 'DHCP pool is ${(state.dhcpUtilization * 100).toInt()}% full',
        detail: '${state.dhcpLeasesCount} of ${state.dhcpPoolLimit} addresses in use.',
        action: 'Consider expanding DHCP pool or reducing lease time.',
      ));
    }

    // Band distribution
    final on24 = state.clients.where((c) => c.band == '2.4GHz').length;
    final on5 = state.clients.where((c) => c.band == '5GHz').length;
    final on6 = state.clients.where((c) => c.band == '6GHz').length;
    if (state.clients.isNotEmpty) {
      final bandCongested = on24 > on5 * 2 && on24 > 5;
      issues.add(_Finding(
        severity: bandCongested ? _Severity.warning : _Severity.ok,
        title: 'Band distribution: $on24 on 2.4G, $on5 on 5G${on6 > 0 ? ', $on6 on 6G' : ''}',
        detail: bandCongested
            ? '2.4 GHz is congested and slower. Many devices could use 5 GHz.'
            : 'Band distribution looks reasonable.',
        action: bandCongested
            ? 'Check if band steering is enabled.'
            : 'No band steering changes needed.',
      ));
    }

    // High bandwidth users
    final highBw = state.clients.where((c) =>
        c.isWireless && c.txRateMbps != null && c.txRateMbps! > 500).toList();
    if (highBw.length > 3) {
      issues.add(_Finding(
        severity: _Severity.info,
        title: '${highBw.length} high-bandwidth clients active (>500 Mbps)',
        detail: 'Multiple devices negotiating high rates. Heavy simultaneous usage possible.',
        action: 'Ask if multiple people are streaming or downloading simultaneously.',
      ));
    }

    // Mesh backhaul bottleneck
    if (state.backhaulInfo != null) {
      final nodes = state.backhaulInfo!['backhaulDevices'] as List? ?? [];
      final slowBackhaul = nodes.where((n) => (n['speedMbps'] as int? ?? 0) < 100).toList();
      if (slowBackhaul.isNotEmpty) {
        issues.add(_Finding(
          severity: _Severity.warning,
          title: '${slowBackhaul.length} mesh node(s) with weak backhaul (<100 Mbps)',
          detail: 'Nodes cannot forward traffic faster than their backhaul speed.',
          action: 'Move node closer to main router or use wired backhaul if available.',
        ));
      }
    }

    // Channel info — congestion indicator
    if (state.channelInfo != null) {
      final channels = state.channelInfo!['selectedChannels'] as List? ?? [];
      for (final ch in channels) {
        final band = ch['radioID'] as String? ?? '?';
        final channel = ch['channel'];
        if (channel != null && band.contains('2.4')) {
          // Channels 1, 6, 11 are non-overlapping; others cause interference
          final chNum = channel is int ? channel : int.tryParse('$channel') ?? 0;
          if (chNum != 1 && chNum != 6 && chNum != 11 && chNum > 0) {
            issues.add(_Finding(
              severity: _Severity.warning,
              title: '2.4 GHz on channel $chNum (overlapping)',
              detail: 'Only channels 1, 6, 11 are non-overlapping. Channel $chNum causes co-channel interference.',
              action: 'Switch to channel 1, 6, or 11 — or set to Auto.',
            ));
          }
        }
      }
    }

    // Wireless schedule — WiFi may be throttled at certain times
    if (state.wirelessScheduleEnabled) {
      issues.add(const _Finding(
        severity: _Severity.warning,
        title: 'Wireless scheduler is active',
        detail: 'WiFi may be turned off or restricted at certain times of day.',
        action: 'Check schedule settings. Ask if slowness happens at consistent times.',
      ));
    }

    // Firmware update available
    if (state.firmwareUpdateAvailable) {
      issues.add(_Finding(
        severity: _Severity.info,
        title: 'Firmware update available: ${state.availableFirmwareVersion ?? "newer version"}',
        detail: 'Firmware updates often include performance improvements and bug fixes.',
        action: 'Recommend updating firmware after resolving the immediate issue.',
      ));
    }

    // Talking point
    issues.add(const _Finding(
      severity: _Severity.ask,
      title: 'Ask the customer',
      detail: 'Is it slow on all devices or just one? Wired or wireless? When did it start?',
      action: 'If only one device, switch to "Slow Device" tab. If all devices, run a speed test.',
    ));

    return _buildFindings(context, 'Slow Internet', 'Why is my internet slow?', issues);
  }

  // ── Flow 2: Slow Device ────────────────────────────────────────────
  Widget _slowDevice(BuildContext context) {
    final issues = <_Finding>[];

    // Very weak signal devices
    final veryWeak = state.clients
        .where((c) => c.isWireless && c.signalDecibels != null && c.signalDecibels! < -80)
        .toList();
    if (veryWeak.isNotEmpty) {
      issues.add(_Finding(
        severity: _Severity.critical,
        title: '${veryWeak.length} device(s) with very weak signal (<-80 dBm)',
        detail: veryWeak.map((c) => '${c.displayNameWithOui}: ${c.signalDecibels} dBm').join('\n'),
        action: 'Too far from router or behind obstructions. Recommend mesh node.',
      ));
    }

    // Weak signal devices
    final weak = state.clients
        .where((c) => c.isWireless && c.signalDecibels != null &&
            c.signalDecibels! >= -80 && c.signalDecibels! < -70)
        .toList();
    if (weak.isNotEmpty) {
      issues.add(_Finding(
        severity: _Severity.warning,
        title: '${weak.length} device(s) with marginal signal (-70 to -80 dBm)',
        detail: weak.map((c) => '${c.displayNameWithOui}: ${c.signalDecibels} dBm').join('\n'),
        action: 'Suggest moving device closer or adding a mesh node.',
      ));
    }

    // Low TX rate
    final lowRate = state.clients
        .where((c) => c.isWireless && c.txRateMbps != null && c.txRateMbps! < 30)
        .toList();
    if (lowRate.isNotEmpty) {
      issues.add(_Finding(
        severity: _Severity.warning,
        title: '${lowRate.length} device(s) with very low TX rate (<30 Mbps)',
        detail: lowRate.map((c) => '${c.displayNameWithOui}: ${c.txRateMbps} Mbps TX / ${c.rxRateMbps ?? "?"} Mbps RX').join('\n'),
        action: 'Poor link quality. Check if device supports 5 GHz.',
      ));
    }

    // RX/TX asymmetry — indicates receive path issues
    final asymmetric = state.clients.where((c) =>
        c.isWireless &&
        c.txRateMbps != null && c.rxRateMbps != null &&
        c.txRateMbps! > 200 && c.rxRateMbps! < c.txRateMbps! ~/ 2).toList();
    if (asymmetric.isNotEmpty) {
      issues.add(_Finding(
        severity: _Severity.warning,
        title: '${asymmetric.length} device(s) with TX/RX rate imbalance',
        detail: asymmetric.map((c) => '${c.displayNameWithOui}: TX ${c.txRateMbps} / RX ${c.rxRateMbps} Mbps').join('\n'),
        action: 'Download slower than upload suggests interference on receive path or obstruction.',
      ));
    }

    // 2.4 GHz congestion
    final on24 = state.clients.where((c) => c.band == '2.4GHz').length;
    final on5 = state.clients.where((c) => c.band == '5GHz').length;
    if (on24 > on5 * 2 && on24 > 5) {
      issues.add(_Finding(
        severity: _Severity.info,
        title: 'Most devices on 2.4 GHz ($on24 vs $on5 on 5 GHz)',
        detail: '2.4 GHz is more congested and slower.',
        action: 'Check if band steering is enabled. Ensure shared SSID for auto band selection.',
      ));
    }

    // Per-device summary
    final wireless = state.clients.where((c) => c.isWireless).toList();
    if (wireless.isNotEmpty) {
      final avgSignal = wireless
          .where((c) => c.signalDecibels != null)
          .map((c) => c.signalDecibels!)
          .fold<int>(0, (a, b) => a + b) /
          wireless.where((c) => c.signalDecibels != null).length;
      issues.add(_Finding(
        severity: _Severity.info,
        title: 'Network overview: ${wireless.length} wireless devices, avg signal ${avgSignal.round()} dBm',
        detail: 'Good: ≥-65 dBm | Fair: -65 to -75 | Weak: -75 to -85 | Very Weak: <-85',
        action: 'Ask which specific device is slow. Check signal and band for that device above.',
      ));
    }

    if (issues.isEmpty) {
      issues.add(const _Finding(
        severity: _Severity.ok,
        title: 'All devices have acceptable signal',
        detail: 'No devices flagged for weak signal or low throughput.',
        action: 'Ask which specific device is slow. It may not be connected, or the issue may be app-specific.',
      ));
    }

    // Talking point
    issues.add(const _Finding(
      severity: _Severity.ask,
      title: 'Ask the customer',
      detail: 'Which device is slow? Is it WiFi or wired? How old is the device? Has it worked well before?',
      action: 'Older devices on 2.4 GHz only will always be slower. Confirm device supports 5 GHz.',
    ));

    return _buildFindings(context, 'Slow Device', 'One device is slow but others are fine', issues);
  }

  // ── Flow 3: Connectivity Drops ─────────────────────────────────────
  Widget _drops(BuildContext context) {
    final issues = <_Finding>[];

    // Router stability
    if (state.routerUptimeSeconds > 0 && state.routerUptimeSeconds < 7200) {
      issues.add(_Finding(
        severity: _Severity.critical,
        title: 'Router uptime is only ${_formatUptime(state.routerUptimeSeconds)}',
        detail: 'The router was recently restarted or crashed.',
        action: 'Check event logs for crash reasons. If repeated, check firmware version and escalate.',
      ));
    } else if (state.routerUptimeSeconds >= 7200) {
      issues.add(_Finding(
        severity: _Severity.ok,
        title: 'Router stable — uptime ${_formatUptime(state.routerUptimeSeconds)}',
        detail: 'Router has not rebooted recently.',
        action: 'Drops are likely not caused by router restarts.',
      ));
    }

    // WAN status
    if (!state.wanConnected) {
      issues.add(const _Finding(
        severity: _Severity.critical,
        title: 'WAN is currently disconnected',
        detail: 'Customer may be experiencing an active outage.',
        action: 'Check modem status. Ask how often drops occur and duration.',
      ));
    }

    // Marginal signal devices (prone to drops)
    final marginal = state.clients.where((c) =>
        c.isWireless && c.signalDecibels != null &&
        c.signalDecibels! >= -80 && c.signalDecibels! < -70).toList();
    if (marginal.isNotEmpty) {
      issues.add(_Finding(
        severity: _Severity.warning,
        title: '${marginal.length} device(s) in marginal signal range (-70 to -80 dBm)',
        detail: marginal.map((c) => '${c.displayNameWithOui}: ${c.signalDecibels} dBm').join('\n'),
        action: 'Marginal signal = intermittent drops. Mesh node recommended for these devices.',
      ));
    }

    // Very weak (definitely dropping)
    final veryWeak = state.clients.where((c) =>
        c.isWireless && c.signalDecibels != null && c.signalDecibels! < -80).toList();
    if (veryWeak.isNotEmpty) {
      issues.add(_Finding(
        severity: _Severity.critical,
        title: '${veryWeak.length} device(s) with very weak signal (<-80 dBm)',
        detail: veryWeak.map((c) => '${c.displayNameWithOui}: ${c.signalDecibels} dBm').join('\n'),
        action: 'These devices will experience frequent disconnections. Mesh node needed.',
      ));
    }

    // DFS channel warning — radar events cause brief drops
    if (state.channelInfo != null) {
      final channels = state.channelInfo!['selectedChannels'] as List? ?? [];
      for (final ch in channels) {
        final band = ch['radioID'] as String? ?? '';
        final channel = ch['channel'];
        if (channel != null && band.contains('5')) {
          final chNum = channel is int ? channel : int.tryParse('$channel') ?? 0;
          if (chNum >= 52 && chNum <= 144) {
            issues.add(_Finding(
              severity: _Severity.info,
              title: '5 GHz on DFS channel $chNum',
              detail: 'DFS channels require radar detection. When radar is detected, the router switches channels, briefly interrupting connections.',
              action: 'If drops are brief (30-60s) and infrequent, DFS radar may be the cause. Switch to non-DFS channel (36-48 or 149-165).',
            ));
          }
        }
      }
    }

    // Memory pressure — early warning before crash
    final memLoad = state.routerHealth?['memoryLoad'] as int?;
    if (memLoad != null && memLoad > 75) {
      issues.add(_Finding(
        severity: _Severity.warning,
        title: 'Router memory load is $memLoad%',
        detail: 'Memory fragmentation or leaks can cause intermittent crashes and drops.',
        action: 'Note current uptime. If uptime keeps resetting, memory leak confirmed. Schedule off-hours reboot.',
      ));
    }

    // DHCP exhaustion
    if (state.dhcpUtilization > 0.9) {
      issues.add(const _Finding(
        severity: _Severity.warning,
        title: 'DHCP pool nearly exhausted',
        detail: 'When the pool is full, devices lose their IP and appear to "drop".',
        action: 'Reduce lease time or expand pool. Check for rogue devices.',
      ));
    }

    // Wireless schedule — may cause scheduled outages
    if (state.wirelessScheduleEnabled) {
      issues.add(const _Finding(
        severity: _Severity.warning,
        title: 'Wireless scheduler is active',
        detail: 'WiFi turns off at scheduled times. Customer may perceive this as "drops".',
        action: 'Review schedule. Ask if drops happen at consistent times every day.',
      ));
    }

    // Firmware update — stability fixes
    if (state.firmwareUpdateAvailable) {
      issues.add(_Finding(
        severity: _Severity.info,
        title: 'Firmware update available: ${state.availableFirmwareVersion ?? "newer version"}',
        detail: 'Updates may include stability fixes for disconnection issues.',
        action: 'Recommend firmware update.',
      ));
    }

    // Talking point
    issues.add(const _Finding(
      severity: _Severity.ask,
      title: 'Ask the customer',
      detail: 'How often do drops happen? All devices or just one? Does it happen at certain times of day?',
      action: 'Time-of-day pattern → ISP congestion or wireless scheduler. Single device → signal issue. All devices → WAN or router.',
    ));

    return _buildFindings(context, 'Connectivity Drops', 'My internet keeps cutting out', issues);
  }

  // ── Flow 4: Can't Connect ─────────────────────────────────────────
  Widget _cantConnect(BuildContext context) {
    final issues = <_Finding>[];

    // DHCP capacity
    if (state.dhcpUtilization > 0.9) {
      issues.add(_Finding(
        severity: _Severity.critical,
        title: 'DHCP pool is ${(state.dhcpUtilization * 100).toInt()}% full',
        detail: 'New devices may not get an IP address.',
        action: 'Check for unknown devices in lease table. Expand pool or reduce lease time.',
      ));
    } else if (state.dhcpUtilization > 0.8 && state.guestNetworkEnabled) {
      issues.add(_Finding(
        severity: _Severity.warning,
        title: 'DHCP ${(state.dhcpUtilization * 100).toInt()}% used — guest network active',
        detail: 'Guest network may share the DHCP pool. Guest devices consuming addresses can block new main devices.',
        action: 'Check if guest pool is separate. If shared, reduce guest lease time or expand main pool.',
      ));
    } else {
      issues.add(_Finding(
        severity: _Severity.ok,
        title: 'DHCP pool has capacity (${(state.dhcpUtilization * 100).toInt()}% used)',
        detail: '${state.dhcpLeasesCount} of ${state.dhcpPoolLimit} addresses in use.',
        action: 'DHCP is not blocking new connections.',
      ));
    }

    // Device count
    if (state.clients.length > 30) {
      issues.add(_Finding(
        severity: _Severity.warning,
        title: '${state.clients.length} devices already connected',
        detail: 'High device count can cause association failures.',
        action: 'Review device list with customer. Remove unused or unknown devices.',
      ));
    } else {
      issues.add(_Finding(
        severity: _Severity.ok,
        title: '${state.clients.length} devices connected',
        detail: 'Device count is within normal range for a consumer router.',
        action: 'Not a capacity issue.',
      ));
    }

    // 2.4 GHz band loading
    final on24 = state.clients.where((c) => c.band == '2.4GHz').length;
    if (on24 > 15) {
      issues.add(_Finding(
        severity: _Severity.warning,
        title: '$on24 devices on 2.4 GHz',
        detail: '2.4 GHz has lower client capacity. Band may be overloaded.',
        action: 'Enable band steering to push capable devices to 5 GHz.',
      ));
    }

    // MAC filter — device may be blocked
    final macMode = state.macFilterMode;
    if (macMode != null) {
      issues.add(_Finding(
        severity: _Severity.warning,
        title: 'MAC filter is active ($macMode mode)',
        detail: macMode == 'Allow'
            ? 'Only whitelisted MAC addresses can connect. New devices will be blocked unless added.'
            : 'Blacklisted MAC addresses are blocked. Check if the customer\'s device is on the deny list.',
        action: macMode == 'Allow'
            ? 'Ask for the device\'s MAC address and add it to the allow list.'
            : 'Check deny list for the device\'s MAC address.',
      ));
    } else {
      issues.add(const _Finding(
        severity: _Severity.ok,
        title: 'MAC filter is disabled',
        detail: 'No MAC-based access restrictions in place.',
        action: 'MAC filtering is not blocking connections.',
      ));
    }

    // Security mode — WPA3 incompatibility
    final secMode = state.securityMode;
    if (secMode != null && secMode.contains('WPA3')) {
      issues.add(const _Finding(
        severity: _Severity.warning,
        title: 'Security mode is WPA3',
        detail: 'Older devices (pre-2019) may not support WPA3 and will fail to connect.',
        action: 'If the failing device is older, switch to WPA2/WPA3 mixed mode.',
      ));
    }

    // Parental controls — device may be restricted
    if (state.parentalControlsEnabled) {
      issues.add(const _Finding(
        severity: _Severity.info,
        title: 'Parental controls are active',
        detail: 'Parental controls can block device access entirely or restrict certain sites/times.',
        action: 'Check if the device is in a restricted group. Temporarily disable to test.',
      ));
    }

    // WAN status matters here too
    if (!state.wanConnected) {
      issues.add(const _Finding(
        severity: _Severity.warning,
        title: 'WAN is down — device may connect to WiFi but have no internet',
        detail: 'Customer may say "can\'t connect" when they mean "no internet after connecting".',
        action: 'Clarify: can they see the WiFi network? Can they join it? Or is there no internet after joining?',
      ));
    }

    // Guided troubleshooting
    issues.add(const _Finding(
      severity: _Severity.ask,
      title: 'Guided troubleshooting steps',
      detail: '1. Correct password?\n2. Toggle WiFi off/on on device\n3. Restart the device\n4. Forget network, rejoin\n5. Try 2.4 GHz if 5 GHz fails (range issue)',
      action: 'Walk customer through each step. If still failing after step 5, factory reset may be needed.',
    ));

    return _buildFindings(context, "Can't Connect", "A device won't connect to WiFi", issues);
  }

  // ── Flow 5: Dead Spots / Weak Signal ───────────────────────────────
  Widget _deadSpots(BuildContext context) {
    final issues = <_Finding>[];

    // Signal distribution breakdown
    final bySignal = <String, List<DiagnosticClient>>{
      'Critical (<-80 dBm)': [],
      'Weak (-75 to -80 dBm)': [],
      'Marginal (-65 to -75 dBm)': [],
      'Good (≥-65 dBm)': [],
    };

    for (final c in state.clients.where((c) => c.isWireless && c.signalDecibels != null)) {
      final s = c.signalDecibels!;
      if (s < -80) {
        bySignal['Critical (<-80 dBm)']!.add(c);
      } else if (s < -75) {
        bySignal['Weak (-75 to -80 dBm)']!.add(c);
      } else if (s < -65) {
        bySignal['Marginal (-65 to -75 dBm)']!.add(c);
      } else {
        bySignal['Good (≥-65 dBm)']!.add(c);
      }
    }

    for (final entry in bySignal.entries) {
      if (entry.value.isNotEmpty) {
        final severity = entry.key.startsWith('Critical')
            ? _Severity.critical
            : entry.key.startsWith('Weak')
                ? _Severity.warning
                : entry.key.startsWith('Marginal')
                    ? _Severity.info
                    : _Severity.ok;
        issues.add(_Finding(
          severity: severity,
          title: '${entry.value.length} device(s) — ${entry.key}',
          detail: entry.value.map((c) =>
              '${c.displayNameWithOui} (${c.signalDecibels} dBm, ${c.band})').join('\n'),
          action: severity == _Severity.critical
              ? 'Needs a mesh node nearby. Signal is unusable for streaming.'
              : severity == _Severity.warning
                  ? 'Consider mesh node placement to improve coverage.'
                  : severity == _Severity.info
                      ? 'Monitor — marginal signal may degrade with interference.'
                      : 'Good signal. No action needed.',
        ));
      }
    }

    // Coverage quality score
    final allWireless = state.clients.where((c) => c.isWireless).length;
    final goodSignal = state.clients.where((c) =>
        c.isWireless && c.signalDecibels != null && c.signalDecibels! >= -65).length;
    if (allWireless > 0) {
      final pct = (goodSignal / allWireless * 100).toInt();
      issues.add(_Finding(
        severity: pct >= 80 ? _Severity.ok : pct >= 60 ? _Severity.warning : _Severity.critical,
        title: 'Coverage score: $pct% of devices have good signal',
        detail: '$goodSignal of $allWireless wireless devices at -65 dBm or better.',
        action: pct < 60
            ? 'Significant coverage gaps. Mesh system evaluation recommended.'
            : pct < 80
                ? 'Some weak areas. Targeted mesh node may help.'
                : 'Good overall coverage.',
      ));
    }

    // Mesh recommendation
    final needsMesh = state.clients.where((c) =>
        c.isWireless && c.signalDecibels != null && c.signalDecibels! < -75).length;
    if (needsMesh > 0) {
      issues.add(_Finding(
        severity: _Severity.info,
        title: 'Mesh recommendation: $needsMesh device(s) would benefit from a mesh node',
        detail: 'Devices below -75 dBm are in coverage gap areas.',
        action: 'Ask where these devices are used. Recommend mesh node placement between router and weak area.',
      ));
    }

    // Backhaul info — mesh node health
    if (state.backhaulInfo != null) {
      final devices = state.backhaulInfo!['backhaulDevices'] as List? ?? [];
      if (devices.isNotEmpty) {
        for (final node in devices) {
          final id = node['deviceID'] as String? ?? 'Unknown node';
          final connType = node['connectionType'] as String? ?? '?';
          final speed = node['speedMbps'] as int? ?? 0;
          final severity = speed < 200 ? _Severity.warning : _Severity.ok;
          issues.add(_Finding(
            severity: severity,
            title: 'Mesh node: $id ($connType backhaul, $speed Mbps)',
            detail: speed < 200
                ? 'Backhaul is slow — clients connected to this node will be limited.'
                : 'Backhaul link is healthy.',
            action: speed < 200
                ? 'Move node closer to router, or use wired backhaul if possible.'
                : 'Node backhaul is adequate.',
          ));
        }
      }
    }

    // Band steering check
    if (state.radioInfo != null && !state.bandSteeringEnabled) {
      issues.add(const _Finding(
        severity: _Severity.info,
        title: 'Band steering is disabled',
        detail: 'Devices may stick on 2.4 GHz even when 5 GHz would provide better coverage from the router.',
        action: 'Enable band steering to let the router guide devices to the best band.',
      ));
    }

    if (issues.isEmpty) {
      issues.add(const _Finding(
        severity: _Severity.ok,
        title: 'All devices have good signal',
        detail: 'No dead spots detected based on currently connected devices.',
        action: 'If customer reports dead spots in specific rooms, have them connect from that location and re-check.',
      ));
    }

    return _buildFindings(context, 'Dead Spots / Signal', 'WiFi is weak in parts of my home', issues);
  }

  // ── Flow 6: Router Offline ─────────────────────────────────────────
  Widget _offline(BuildContext context) {
    final issues = <_Finding>[];

    // WAN status — primary concern
    if (!state.wanConnected) {
      issues.add(const _Finding(
        severity: _Severity.critical,
        title: 'WAN is currently disconnected',
        detail: 'The router cannot reach the internet.',
        action: 'Check modem power and Ethernet from modem to router WAN port. Reboot modem first, then router.',
      ));
    } else {
      issues.add(const _Finding(
        severity: _Severity.ok,
        title: 'WAN is connected right now',
        detail: 'The router has internet access at this moment.',
        action: 'If intermittent offline, ask for timing pattern. Check ISP for maintenance windows.',
      ));
    }

    // Recent restart
    if (state.routerUptimeSeconds > 0 && state.routerUptimeSeconds < 1800) {
      issues.add(_Finding(
        severity: _Severity.warning,
        title: 'Router was recently restarted (${_formatUptime(state.routerUptimeSeconds)} ago)',
        detail: 'May indicate crash, power outage, or manual reboot.',
        action: 'Ask: did you reboot it, or did it restart on its own?',
      ));
    } else if (state.routerUptimeSeconds >= 1800) {
      issues.add(_Finding(
        severity: _Severity.ok,
        title: 'Router has been up for ${_formatUptime(state.routerUptimeSeconds)}',
        detail: 'No recent restarts detected.',
        action: 'Router stability is not the issue.',
      ));
    }

    // Firmware info (no update suggestion when offline)
    final fwVersion = state.deviceInfo?['firmwareVersion'] as String?;
    if (fwVersion != null) {
      issues.add(_Finding(
        severity: _Severity.info,
        title: 'Firmware: $fwVersion',
        detail: 'Note firmware version for reference.',
        action: 'Check release notes for known stability fixes.',
      ));
    }

    // CPU/Memory stress
    final cpuLoad = state.routerHealth?['cpuLoad'] as int?;
    final memLoad = state.routerHealth?['memoryLoad'] as int?;
    if (cpuLoad != null && cpuLoad > 90) {
      issues.add(_Finding(
        severity: _Severity.warning,
        title: 'CPU load is very high: $cpuLoad%',
        detail: 'High CPU can cause the router to become unresponsive or crash.',
        action: 'Check for excessive connected devices or malware activity.',
      ));
    }
    if (memLoad != null && memLoad > 90) {
      issues.add(_Finding(
        severity: _Severity.warning,
        title: 'Memory usage is very high: $memLoad%',
        detail: 'Memory exhaustion can cause router instability.',
        action: 'Reboot may temporarily resolve. If recurring, reduce connected devices or check for firmware update.',
      ));
    }

    // Firmware update
    if (state.firmwareUpdateAvailable) {
      issues.add(_Finding(
        severity: _Severity.info,
        title: 'Firmware update available: ${state.availableFirmwareVersion ?? "newer version"}',
        detail: 'Updates may include stability and crash fixes.',
        action: 'Recommend updating firmware after restoring connectivity.',
      ));
    }

    // Ethernet port status
    if (state.ethernetPorts != null) {
      final ports = state.ethernetPorts!['connections'] as List? ?? [];
      final wanPort = ports.where((p) => p['portName'] == 'WAN' || p['portType'] == 'WAN').toList();
      if (wanPort.isNotEmpty) {
        final status = wanPort.first['linkState'] as String? ?? 'unknown';
        if (status != 'Up' && status != 'up') {
          issues.add(_Finding(
            severity: _Severity.critical,
            title: 'WAN Ethernet port link is $status',
            detail: 'Physical connection between modem and router may be disconnected.',
            action: 'Check Ethernet cable from modem to WAN port. Try a different cable.',
          ));
        }
      }
    }

    // Guided steps
    issues.add(const _Finding(
      severity: _Severity.ask,
      title: 'Troubleshooting steps',
      detail: '1. Is the modem online? (check modem lights)\n2. Is Ethernet cable from modem to router WAN port secure?\n3. Reboot modem, wait 2 min, then reboot router\n4. Check if ISP has outage in the area',
      action: 'Walk through each step with customer. If modem is online but router has no WAN, may need factory reset.',
    ));

    return _buildFindings(context, 'Router Offline', 'My router appears offline or keeps rebooting', issues);
  }

  // ── Shared builders ────────────────────────────────────────────────

  Widget _buildFindings(BuildContext context, String title, String subtitle, List<_Finding> findings) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 700;
        final header = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 12),
          ],
        );

        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [header, ...findings.map((f) => _findingCard(context, f))],
          );
        }

        // Two-column layout: findings left, summary right
        final actionable = findings.where((f) => f.severity != _Severity.ok && f.severity != _Severity.info && f.severity != _Severity.ask).toList();
        final other = findings.where((f) => f.severity == _Severity.ok || f.severity == _Severity.info || f.severity == _Severity.ask).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (actionable.isNotEmpty) ...[
                        Text('Action Items', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red.shade700)),
                        const SizedBox(height: 4),
                        ...actionable.map((f) => _findingCard(context, f)),
                      ],
                      if (other.isNotEmpty) ...[
                        if (actionable.isNotEmpty) const SizedBox(height: 8),
                        ...other.map((f) => _findingCard(context, f)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _buildQuickRef(context),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Quick-reference sidebar shown on wide screens
  Widget _buildQuickRef(BuildContext context) {
    final model = state.deviceInfo?['description'] ?? state.deviceInfo?['modelNumber'] ?? 'Unknown';
    final fw = state.deviceInfo?['firmwareVersion'] ?? 'Unknown';
    final cpuLoad = state.routerHealth?['cpuLoad'] as int?;
    final memLoad = state.routerHealth?['memoryLoad'] as int?;
    final on24 = state.clients.where((c) => c.band == '2.4GHz').length;
    final on5 = state.clients.where((c) => c.band == '5GHz').length;
    final wired = state.clients.where((c) => !c.isWireless).length;

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Reference', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
            const Divider(height: 16),
            _refRow('Model', '$model'),
            _refRow('Firmware', '$fw'),
            _refRow('Uptime', _formatUptime(state.routerUptimeSeconds)),
            _refRow('WAN', state.wanConnected ? 'Connected' : 'DOWN'),
            if (cpuLoad != null) _refRow('CPU', '$cpuLoad%'),
            if (memLoad != null) _refRow('Memory', '$memLoad%'),
            _refRow('Devices', '${state.clients.length} (2.4G: $on24, 5G: $on5, Wired: $wired)'),
            _refRow('DHCP', '${state.dhcpLeasesCount}/${state.dhcpPoolLimit} (${(state.dhcpUtilization * 100).toInt()}%)'),
            if (state.bandSteeringEnabled) _refRow('Band Steer', 'Enabled'),
            if (state.guestNetworkEnabled) _refRow('Guest Net', 'Enabled'),
            if (state.firmwareUpdateAvailable) _refRow('FW Update', 'Available'),
          ],
        ),
      ),
    );
  }

  Widget _refRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _findingCard(BuildContext context, _Finding finding) {
    final (icon, color) = switch (finding.severity) {
      _Severity.critical => (Icons.error, Colors.red.shade700),
      _Severity.warning => (Icons.warning_amber, Colors.orange.shade800),
      _Severity.ask => (Icons.chat_bubble_outline, Colors.deepPurple),
      _Severity.info => (Icons.info_outline, Colors.blueGrey),
      _Severity.ok => (Icons.check_circle, Colors.green.shade700),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(finding.title,
                      style: TextStyle(fontWeight: FontWeight.w600, color: color)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Text(finding.detail,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.arrow_forward, size: 14,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(finding.action,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.primary,
                        )),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatUptime(int seconds) {
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${seconds ~/ 60}m';
    if (seconds < 86400) return '${seconds ~/ 3600}h ${(seconds % 3600) ~/ 60}m';
    return '${seconds ~/ 86400}d ${(seconds % 86400) ~/ 3600}h';
  }
}

enum _Severity { critical, warning, info, ask, ok }

class _Finding {
  final _Severity severity;
  final String title;
  final String detail;
  final String action;

  const _Finding({
    required this.severity,
    required this.title,
    required this.detail,
    required this.action,
  });
}
