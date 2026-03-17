import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/transforms.g.dart';
import 'package:privacy_gui/usp_page/dashboard/models/network_health_helpers.dart';
import 'package:privacy_gui/usp_page/dashboard/models/pdf_report_data.dart';
import 'package:privacy_gui/usp_page/dashboard/models/traffic_analysis_state.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_dashboard_state.dart';
import 'package:privacy_gui/usp_page/dmz/models/dmz_ui_model.dart';
import 'package:privacy_gui/usp_page/firewall/models/firewall_ui_model.dart';

/// Generates a comprehensive multi-page PDF report of router information.
///
/// Reads from [PdfReportData] which aggregates dashboard state, polling
/// providers (traffic/device analytics/system monitor), and optional
/// feature provider data (firewall, DMZ, static routing, etc.).
class UspPdfService {
  UspPdfService._();

  static Future<void> generatePdf(PdfReportData data) async {
    try {
      // Load Noto Sans + Symbols fallback for full Unicode support
      final baseFont = await PdfGoogleFonts.notoSansRegular();
      final boldFont = await PdfGoogleFonts.notoSansBold();
      final symbolFont = await PdfGoogleFonts.notoSansSymbols2Regular();

      final doc = pw.Document(
        theme: pw.ThemeData.withFont(
          base: baseFont,
          bold: boldFont,
          fontFallback: [symbolFont],
        ),
      );
      final state = data.dashboard;

      // Page 1: Device Info + System + Network Health + WAN + LAN
      doc.addPage(_createPage([
        ..._buildDeviceInfo(state),
        ..._buildSystemStatus(state, data),
        ..._buildNetworkHealth(data),
        ..._buildWanStatus(state),
        ..._buildLanNetwork(state),
      ]));

      // Page 2: WiFi
      doc.addPage(_createPage(_buildWifi(state)));

      // Page 3: Devices + DHCP Leases + Device Analytics
      doc.addPage(_createPage([
        ..._buildDevices(state),
        ..._buildDhcpClients(state),
        ..._buildDeviceAnalytics(data),
      ]));

      // Page 4: Services + Safe Browsing
      doc.addPage(_createPage([
        ..._buildTimeSettings(state),
        ..._buildEthernetPorts(state),
        ..._buildDhcpReservations(state),
        ..._buildSafeBrowsing(data),
      ]));

      // Page 5: Traffic + Mesh + Firewall + DMZ
      doc.addPage(_createPage([
        ..._buildTrafficSnapshot(data),
        ..._buildMeshTopology(state),
        ..._buildFirewallSettings(data.firewallSettings),
        ..._buildDmzSettings(data.dmzSettings),
      ]));

      // Page 6: Port Rules + Routing
      doc.addPage(_createPage([
        ..._buildPortForwarding(state),
        ..._buildPortTriggering(state),
        ..._buildIpv6PortService(data),
        ..._buildStaticRouting(data),
      ]));

      // Page 7: USP Traffic Log
      final uspLog = _buildUspTrafficLog([symbolFont]);
      if (uspLog.isNotEmpty) {
        doc.addPage(_createPage(uspLog));
      }

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) => doc.save(),
      );
    } catch (e) {
      logger.e('[USP][Dashboard][PDF]Print error', error: e);
    }
  }

  // ---------------------------------------------------------------------------
  // Page template
  // ---------------------------------------------------------------------------

  static pw.Page _createPage(List<pw.Widget> children) {
    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      header: (pw.Context ctx) {
        return pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Router Information Report',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              textScaleFactor: 2.0,
            ),
            pw.Text(
              DateTime.now().toString().substring(0, 19),
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        );
      },
      build: (pw.Context ctx) => children,
    );
  }

  // ===========================================================================
  // Page 1: Device Info + System + Health + WAN + LAN
  // ===========================================================================

  static List<pw.Widget> _buildDeviceInfo(UspDashboardState state) {
    final info = state.systemInfoModel;
    return [
      _sectionTitle('Device Information'),
      _keyValue('Manufacturer', info.manufacturer),
      _keyValue('Model', info.modelName),
      _keyValue('Serial Number', info.serialNumber),
      _keyValue('Hardware Version', info.hardwareVersion),
      _keyValue('Firmware Version', info.softwareVersion),
      if (info.firmwareImages.isNotEmpty) ...[
        pw.SizedBox(height: 4),
        ...info.firmwareImages.map((img) {
          final label = img.name.isNotEmpty ? img.name : img.instancePath;
          final status = [
            if (img.isActive) 'Active',
            if (img.isBootTarget) 'Boot',
          ].join(', ');
          return _keyValue(
            '  $label',
            '${img.version}${status.isNotEmpty ? ' ($status)' : ''}',
          );
        }),
      ],
      pw.SizedBox(height: 12),
    ];
  }

  static List<pw.Widget> _buildSystemStatus(
      UspDashboardState state, PdfReportData data) {
    final info = state.systemInfoModel;
    final latest = data.systemMonitor.latest;
    final history = data.systemMonitor.history;
    return [
      _sectionTitle('System Status'),
      _keyValue('Uptime', info.formattedUptime),
      _keyValue('CPU Usage', '${latest?.cpuPercent ?? info.cpuPercent}%'),
      _keyValue(
          'Memory',
          '${info.formattedUsedMemory} / ${info.formattedTotalMemory} '
              '(${latest?.memoryPercent ?? info.memoryPercent}%)'),
      if (history.length > 1)
        _keyValue('Monitor Samples', '${history.length} snapshots'),
      // CPU/Memory history line chart
      if (history.length >= 2) ...[
        pw.SizedBox(height: 8),
        pw.SizedBox(
          height: 120,
          child: pw.Chart(
            grid: pw.CartesianGrid(
              xAxis: pw.FixedAxis(
                List.generate(history.length, (i) => i),
                format: (v) {
                  final idx = v.toInt();
                  if (idx % 10 == 0 && idx < history.length) return '$idx';
                  return '';
                },
                textStyle: const pw.TextStyle(fontSize: 7),
              ),
              yAxis: pw.FixedAxis(
                [0, 25, 50, 75, 100],
                format: (v) => '${v.toInt()}%',
                divisions: true,
                divisionsColor: PdfColors.grey300,
                textStyle: const pw.TextStyle(fontSize: 7),
              ),
            ),
            datasets: [
              pw.LineDataSet(
                data: [
                  for (int i = 0; i < history.length; i++)
                    pw.PointChartValue(
                        i.toDouble(), history[i].cpuPercent.toDouble()),
                ],
                legend: 'CPU',
                color: _chartBlue,
                lineColor: _chartBlue,
                lineWidth: 1.5,
                drawPoints: false,
                drawSurface: true,
                surfaceOpacity: 0.1,
                isCurved: true,
              ),
              pw.LineDataSet(
                data: [
                  for (int i = 0; i < history.length; i++)
                    pw.PointChartValue(
                        i.toDouble(), history[i].memoryPercent.toDouble()),
                ],
                legend: 'Memory',
                color: _chartOrange,
                lineColor: _chartOrange,
                lineWidth: 1.5,
                drawPoints: false,
                drawSurface: true,
                surfaceOpacity: 0.1,
                isCurved: true,
              ),
            ],
            overlay: pw.ChartLegend(
              position: pw.Alignment.topRight,
              textStyle: const pw.TextStyle(fontSize: 7),
            ),
          ),
        ),
      ],
      pw.SizedBox(height: 12),
    ];
  }

  static List<pw.Widget> _buildNetworkHealth(PdfReportData data) {
    final latest = data.trafficAnalysis.latest;
    if (latest == null) return [];
    final wan = latest.interfaces[TrafficInterface.wan];
    if (wan == null) return [];

    final score = NetworkHealthHelpers.computeHealthScore(wan);
    final tier = NetworkHealthHelpers.tierFromScore(score);
    final lossPercent = NetworkHealthHelpers.computeLossPercent(wan);
    final faultRate =
        NetworkHealthHelpers.formatFaultRate(wan.totalFaultsPerSec);

    return [
      _sectionTitle('Network Health'),
      _keyValue('Health Score', '$score / 100'),
      _keyValue('Tier', NetworkHealthHelpers.tierLabel(tier)),
      _keyValue('Packet Loss', '${lossPercent.toStringAsFixed(3)}%'),
      _keyValue('Fault Rate', faultRate),
      pw.SizedBox(height: 12),
    ];
  }

  static List<pw.Widget> _buildWanStatus(UspDashboardState state) {
    final wan = state.wanStatusModel;
    return [
      _sectionTitle('WAN Status'),
      _keyValue('Status', wan.isUp ? 'Up' : 'Down'),
      _keyValue('IP Address', wan.ipAddress),
      _keyValue('Subnet Mask', wan.subnetMask),
      if (wan.gateway.isNotEmpty) _keyValue('Gateway', wan.gateway),
      _keyValue('Addressing Type', wan.addressingType),
      _keyValue('MTU', '${wan.mtu}'),
      if (wan.ipv6Enabled) ...[
        _keyValue('IPv6', 'Enabled'),
        if (wan.ipv6Addresses.isNotEmpty)
          _keyValue('IPv6 Addresses', wan.ipv6Addresses.join(', ')),
      ],
      pw.SizedBox(height: 12),
    ];
  }

  static List<pw.Widget> _buildLanNetwork(UspDashboardState state) {
    final lan = state.lanInfoModel;
    return [
      _sectionTitle('LAN Network'),
      _keyValue('IP Address', lan.ipAddress),
      _keyValue('Subnet Mask', lan.subnetMask),
      _keyValue('DHCP', lan.dhcpEnabled ? 'Enabled' : 'Disabled'),
      if (lan.dhcpEnabled) _keyValue('DHCP Range', lan.dhcpRange),
      if (lan.dnsServers.isNotEmpty) _keyValue('DNS Servers', lan.dnsServers),
      if (lan.ipv6Enabled) ...[
        _keyValue('IPv6', 'Enabled'),
        if (lan.ipv6Addresses.isNotEmpty)
          _keyValue('IPv6 Addresses', lan.ipv6Addresses.join(', ')),
      ],
      pw.SizedBox(height: 12),
    ];
  }

  // ===========================================================================
  // Page 2: WiFi
  // ===========================================================================

  static List<pw.Widget> _buildWifi(UspDashboardState state) {
    final radios = state.wifiRadioModels;
    final widgets = <pw.Widget>[_sectionTitle('WiFi Configuration')];

    for (final radio in radios) {
      widgets.addAll([
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '${radio.band} Radio',
                style:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
              ),
              pw.SizedBox(height: 4),
              _keyValue('Status', radio.enable ? 'Enabled' : 'Disabled'),
              _keyValue('Channel', radio.channelDisplay),
              _keyValue('Bandwidth', radio.channelBandwidth),
              _keyValue('TX Power', radio.txPowerDisplay),
              _keyValue('Max Bit Rate', '${radio.maxBitRate} Mbps'),
              if (radio.supportedStandards.isNotEmpty)
                _keyValue('Standards', radio.supportedStandards),
              if (radio.accessPoints.isNotEmpty) ...[
                pw.SizedBox(height: 6),
                pw.Text('Access Points:',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.SizedBox(height: 2),
                ...radio.accessPoints.map((ap) => pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 12, bottom: 2),
                      child: pw.Text(
                        '${ap.ssidName} — ${ap.enable ? "On" : "Off"} — ${ap.securityMode}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    )),
              ],
            ],
          ),
        ),
      ]);
    }

    return widgets;
  }

  // ===========================================================================
  // Page 3: Devices + DHCP Leases + Analytics
  // ===========================================================================

  static List<pw.Widget> _buildDevices(UspDashboardState state) {
    final devices = state.deviceModels;
    final online = devices.where((d) => d.isActive).toList();
    final offline = devices.where((d) => !d.isActive).toList();

    final widgets = <pw.Widget>[
      _sectionTitle('Connected Devices (${online.length} online / '
          '${devices.length} total)'),
      pw.SizedBox(height: 8),
    ];

    if (online.isNotEmpty) {
      widgets.add(_deviceTable(online, isOnline: true));
    }

    if (offline.isNotEmpty) {
      widgets.addAll([
        pw.SizedBox(height: 12),
        pw.Text('Offline Devices',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
        pw.SizedBox(height: 4),
        _deviceTable(offline, isOnline: false),
      ]);
    }

    return widgets;
  }

  static pw.Widget _deviceTable(
    List<dynamic> devices, {
    required bool isOnline,
  }) {
    final headers = isOnline
        ? ['Name', 'MAC', 'IP', 'Type', 'Signal', 'Band']
        : ['Name', 'MAC', 'IP'];

    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      headers: headers,
      data: devices.map((d) {
        if (isOnline) {
          return [
            d.displayName,
            d.mac,
            d.ip,
            d.isWifi ? 'WiFi' : 'Ethernet',
            d.signalStrength != null ? '${d.signalStrength} dBm' : '—',
            d.band ?? '—',
          ];
        }
        return [d.displayName, d.mac, d.ip];
      }).toList(),
    );
  }

  static List<pw.Widget> _buildDhcpClients(UspDashboardState state) {
    final clients = state.dhcpClientModels;
    if (clients.isEmpty) return [];
    return [
      pw.SizedBox(height: 12),
      _sectionTitle('DHCP Active Leases (${clients.length})'),
      pw.SizedBox(height: 4),
      pw.TableHelper.fromTextArray(
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
        cellStyle: const pw.TextStyle(fontSize: 8),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
        headers: ['Name', 'MAC', 'IP', 'Active', 'Lease'],
        data: clients
            .map((c) => [
                  c.displayName,
                  c.mac,
                  c.ip,
                  c.active ? 'Yes' : 'No',
                  c.leaseTimeFormatted.isNotEmpty ? c.leaseTimeFormatted : '—',
                ])
            .toList(),
      ),
      pw.SizedBox(height: 12),
    ];
  }

  static List<pw.Widget> _buildDeviceAnalytics(PdfReportData data) {
    final current = data.deviceAnalytics.current;
    if (current == null) return [];

    final widgets = <pw.Widget>[
      _sectionTitle('Device Analytics'),
      _keyValue('Total Devices', '${current.totalCount}'),
      _keyValue('Online', '${current.onlineCount}'),
      _keyValue('Offline', '${current.offlineCount}'),
      _keyValue('WiFi', '${current.wifiCount}'),
      _keyValue('Wired', '${current.wiredCount}'),
    ];

    // --- WiFi/Wired pie chart ---
    final totalOnline = current.wifiCount + current.wiredCount;
    if (totalOnline > 0) {
      widgets.addAll([
        pw.SizedBox(height: 8),
        pw.Text('Connection Type Distribution',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        pw.SizedBox(height: 4),
        pw.SizedBox(
          height: 150,
          child: pw.Chart(
            grid: pw.PieGrid(),
            datasets: [
              pw.PieDataSet(
                value: current.wifiCount,
                legend: 'WiFi (${current.wifiCount})',
                color: _chartBlue,
                legendPosition: pw.PieLegendPosition.outside,
                legendStyle: const pw.TextStyle(fontSize: 8),
              ),
              pw.PieDataSet(
                value: current.wiredCount,
                legend: 'Wired (${current.wiredCount})',
                color: _chartTeal,
                legendPosition: pw.PieLegendPosition.outside,
                legendStyle: const pw.TextStyle(fontSize: 8),
              ),
            ],
          ),
        ),
      ]);
    }

    // --- Band Distribution bar chart ---
    // Need at least 2 bands for a valid x-axis range (single-entry axis
    // produces NaN in coordinate transform: (0-0)/(0-0)), and at least
    // one non-zero count so bars are visible.
    if (current.bandDistribution.length >= 2) {
      final bands = current.bandDistribution.entries.toList();
      final maxCount =
          bands.map((e) => e.value).reduce((a, b) => a > b ? a : b);

      if (maxCount > 0) {
        final yTicks = _niceYSteps(maxCount.toDouble(), steps: 4);

        widgets.addAll([
          pw.SizedBox(height: 8),
          pw.Text('Band Distribution',
              style:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.SizedBox(height: 4),
          pw.SizedBox(
            height: 100,
            child: pw.Chart(
              grid: pw.CartesianGrid(
                xAxis: pw.FixedAxis.fromStrings(
                  bands.map((e) => e.key).toList(),
                  textStyle: const pw.TextStyle(fontSize: 7),
                ),
                yAxis: pw.FixedAxis(
                  yTicks,
                  format: (v) => v.toInt().toString(),
                  divisions: true,
                  divisionsColor: PdfColors.grey300,
                  textStyle: const pw.TextStyle(fontSize: 7),
                ),
              ),
              datasets: [
                pw.BarDataSet(
                  data: [
                    for (int i = 0; i < bands.length; i++)
                      pw.PointChartValue(
                          i.toDouble(), bands[i].value.toDouble()),
                  ],
                  color: _chartBlue,
                  width: 20,
                  buildValue: (context, value) => pw.Text(
                    value.y.toInt().toString(),
                    style: const pw.TextStyle(fontSize: 7),
                  ),
                ),
              ],
            ),
          ),
        ]);
      }
    }

    // Signal quality (text)
    if (current.bandSignalQuality.isNotEmpty) {
      widgets.addAll([
        pw.SizedBox(height: 4),
        pw.Text('Signal Quality by Band:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        pw.SizedBox(height: 2),
        ...current.bandSignalQuality.entries.map(
          (e) =>
              _keyValue('  ${e.key}', '${(e.value * 100).toStringAsFixed(0)}%'),
        ),
      ]);
    }

    if (data.deviceAnalytics.hourlyHistory.isNotEmpty) {
      widgets.add(_keyValue('History',
          '${data.deviceAnalytics.hourlyHistory.length} hourly samples'));
    }
    widgets.add(pw.SizedBox(height: 12));
    return widgets;
  }

  // ===========================================================================
  // Page 4: Services + Safe Browsing
  // ===========================================================================

  static List<pw.Widget> _buildTimeSettings(UspDashboardState state) {
    final time = state.timeSettingsModel;
    return [
      _sectionTitle('Time Settings'),
      _keyValue('NTP', time.enable ? 'Enabled' : 'Disabled'),
      _keyValue('Status', time.isSynchronized ? 'Synchronized' : time.status),
      _keyValue('Local Time', time.formattedDateTime),
      _keyValue('Timezone', time.localTimeZone),
      if (time.ntpServer1.isNotEmpty)
        _keyValue('NTP Server 1', time.ntpServer1),
      if (time.ntpServer2.isNotEmpty)
        _keyValue('NTP Server 2', time.ntpServer2),
      pw.SizedBox(height: 12),
    ];
  }

  static List<pw.Widget> _buildEthernetPorts(UspDashboardState state) {
    final ports = state.ethernetPortModels;
    if (ports.isEmpty) return [];
    return [
      _sectionTitle('Ethernet Ports'),
      pw.SizedBox(height: 4),
      pw.TableHelper.fromTextArray(
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        cellStyle: const pw.TextStyle(fontSize: 9),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
        headers: ['Port', 'Type', 'Status', 'Speed'],
        data: ports
            .map((p) => [
                  p.label,
                  p.isWan ? 'WAN' : 'LAN',
                  p.isUp ? 'Up' : 'Down',
                  p.speedLabel,
                ])
            .toList(),
      ),
      pw.SizedBox(height: 12),
    ];
  }

  static List<pw.Widget> _buildDhcpReservations(UspDashboardState state) {
    final reservations = state.dhcpReservationModels;
    if (reservations.isEmpty) return [];
    return [
      _sectionTitle('DHCP Reservations'),
      pw.SizedBox(height: 4),
      pw.TableHelper.fromTextArray(
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        cellStyle: const pw.TextStyle(fontSize: 9),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
        headers: ['MAC', 'IP', 'Enabled'],
        data: reservations
            .map((r) => [r.mac, r.ip, r.enable ? 'Yes' : 'No'])
            .toList(),
      ),
      pw.SizedBox(height: 12),
    ];
  }

  static List<pw.Widget> _buildSafeBrowsing(PdfReportData data) {
    final sb = data.safeBrowsing;
    if (sb == null) return [];
    return [
      _sectionTitle('Safe Browsing'),
      _keyValue('Status', sb.isEnabled ? 'Enabled' : 'Disabled'),
      _keyValue('Mode', sb.type.name),
      if (sb.currentDnsServers.isNotEmpty)
        _keyValue('DNS Servers', sb.currentDnsServers),
      pw.SizedBox(height: 12),
    ];
  }

  // ===========================================================================
  // Page 5: Traffic + Mesh + Firewall + DMZ
  // ===========================================================================

  static List<pw.Widget> _buildTrafficSnapshot(PdfReportData data) {
    final latest = data.trafficAnalysis.latest;
    if (latest == null) return [];
    final history = data.trafficAnalysis.history;

    final widgets = <pw.Widget>[
      _sectionTitle('Traffic Snapshot'),
    ];

    // --- Traffic Trend line chart (WAN upload/download over time) ---
    if (history.length >= 2) {
      // Compute Y-axis max from all WAN data points
      double safeD(double v) => v.isNaN || v.isInfinite ? 0 : v;
      double maxBps = 0;
      for (final snap in history) {
        final wan = snap.interfaces[TrafficInterface.wan];
        if (wan == null) continue;
        final up = safeD(wan.uploadBytesPerSec);
        final down = safeD(wan.downloadBytesPerSec);
        if (up > maxBps) maxBps = up;
        if (down > maxBps) maxBps = down;
      }
      final yTicks = _niceYSteps(maxBps);

      widgets.addAll([
        pw.Text('WAN Traffic Trend',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        pw.SizedBox(height: 4),
        pw.SizedBox(
          height: 150,
          child: pw.Chart(
            grid: pw.CartesianGrid(
              xAxis: pw.FixedAxis(
                List.generate(history.length, (i) => i),
                format: (v) {
                  final idx = v.toInt();
                  if (idx % 10 == 0 && idx < history.length) return '$idx';
                  return '';
                },
                textStyle: const pw.TextStyle(fontSize: 7),
              ),
              yAxis: pw.FixedAxis(
                yTicks,
                format: (v) => _formatSpeedLabel(v),
                divisions: true,
                divisionsColor: PdfColors.grey300,
                textStyle: const pw.TextStyle(fontSize: 7),
              ),
            ),
            datasets: [
              pw.LineDataSet(
                data: [
                  for (int i = 0; i < history.length; i++)
                    pw.PointChartValue(
                      i.toDouble(),
                      safeD(history[i]
                              .interfaces[TrafficInterface.wan]
                              ?.uploadBytesPerSec ??
                          0),
                    ),
                ],
                legend: 'Upload',
                color: _chartBlue,
                lineColor: _chartBlue,
                lineWidth: 1.5,
                drawPoints: false,
                drawSurface: true,
                surfaceOpacity: 0.1,
                isCurved: true,
              ),
              pw.LineDataSet(
                data: [
                  for (int i = 0; i < history.length; i++)
                    pw.PointChartValue(
                      i.toDouble(),
                      safeD(history[i]
                              .interfaces[TrafficInterface.wan]
                              ?.downloadBytesPerSec ??
                          0),
                    ),
                ],
                legend: 'Download',
                color: _chartTeal,
                lineColor: _chartTeal,
                lineWidth: 1.5,
                drawPoints: false,
                drawSurface: true,
                surfaceOpacity: 0.1,
                isCurved: true,
              ),
            ],
            overlay: pw.ChartLegend(
              position: pw.Alignment.topRight,
              textStyle: const pw.TextStyle(fontSize: 7),
            ),
          ),
        ),
        pw.SizedBox(height: 8),
      ]);

      // --- WAN vs LAN bar chart ---
      final wan = latest.interfaces[TrafficInterface.wan];
      final lan = latest.interfaces[TrafficInterface.lan];
      if (wan != null && lan != null) {
        // Guard against NaN values (first poll before baseline is set)
        double safeVal(double v) => v.isNaN || v.isInfinite ? 0 : v;
        final wanUp = safeVal(wan.uploadBytesPerSec);
        final wanDown = safeVal(wan.downloadBytesPerSec);
        final lanUp = safeVal(lan.uploadBytesPerSec);
        final lanDown = safeVal(lan.downloadBytesPerSec);
        final barMax =
            [wanUp, wanDown, lanUp, lanDown].reduce((a, b) => a > b ? a : b);

        // Skip chart when all values are zero — bar surface drawing
        // can produce NaN in coordinate transform.
        if (barMax > 0) {
          final barYTicks = _niceYSteps(barMax);
          widgets.addAll([
            pw.Text('WAN vs LAN Throughput',
                style:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            pw.SizedBox(height: 4),
            pw.SizedBox(
              height: 120,
              child: pw.Chart(
                grid: pw.CartesianGrid(
                  xAxis: pw.FixedAxis.fromStrings(
                    ['Upload', 'Download'],
                    textStyle: const pw.TextStyle(fontSize: 8),
                  ),
                  yAxis: pw.FixedAxis(
                    barYTicks,
                    format: (v) => _formatSpeedLabel(v),
                    divisions: true,
                    divisionsColor: PdfColors.grey300,
                    textStyle: const pw.TextStyle(fontSize: 7),
                  ),
                ),
                datasets: [
                  pw.BarDataSet(
                    data: [
                      pw.PointChartValue(0, wanUp),
                      pw.PointChartValue(1, wanDown),
                    ],
                    legend: 'WAN',
                    color: _chartBlue,
                    width: 15,
                    offset: -8,
                  ),
                  pw.BarDataSet(
                    data: [
                      pw.PointChartValue(0, lanUp),
                      pw.PointChartValue(1, lanDown),
                    ],
                    legend: 'LAN',
                    color: _chartTeal,
                    width: 15,
                    offset: 8,
                  ),
                ],
                overlay: pw.ChartLegend(
                  position: pw.Alignment.topRight,
                  textStyle: const pw.TextStyle(fontSize: 7),
                ),
              ),
            ),
            pw.SizedBox(height: 8),
          ]);
        }
      }
    }

    // --- Per-interface key-value details ---
    for (final iface in TrafficInterface.values) {
      final snap = latest.interfaces[iface];
      if (snap == null) continue;
      final label = iface == TrafficInterface.wan ? 'WAN' : 'LAN';
      widgets.addAll([
        pw.SizedBox(height: 4),
        pw.Text('$label Interface:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        pw.SizedBox(height: 2),
        _keyValue(
            '  Upload', Transforms.formatSpeed(snap.uploadBytesPerSec / 1024)),
        _keyValue('  Download',
            Transforms.formatSpeed(snap.downloadBytesPerSec / 1024)),
        _keyValue('  Packets/s', snap.totalPacketsPerSec.toStringAsFixed(0)),
        _keyValue('  Total Sent', Transforms.formatBytes(snap.totalBytesSent)),
        _keyValue('  Total Received',
            Transforms.formatBytes(snap.totalBytesReceived)),
        if (snap.totalErrorsPerSec > 0)
          _keyValue('  Errors/s', snap.totalErrorsPerSec.toStringAsFixed(2)),
        if (snap.totalDiscardsPerSec > 0)
          _keyValue(
              '  Discards/s', snap.totalDiscardsPerSec.toStringAsFixed(2)),
      ]);
    }

    widgets.add(pw.SizedBox(height: 12));
    return widgets;
  }

  static List<pw.Widget> _buildMeshTopology(UspDashboardState state) {
    final nodes = state.nodeModels;
    if (nodes.isEmpty) return [];
    return [
      _sectionTitle('Mesh Topology (${nodes.length} nodes)'),
      pw.SizedBox(height: 4),
      pw.TableHelper.fromTextArray(
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        cellStyle: const pw.TextStyle(fontSize: 9),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
        headers: ['Name', 'Role', 'Model', 'Firmware', 'Devices'],
        data: nodes
            .map((n) => [
                  n.displayName,
                  n.roleLabel,
                  n.model,
                  n.softwareVersion,
                  '${n.connectedDeviceCount}',
                ])
            .toList(),
      ),
      pw.SizedBox(height: 12),
    ];
  }

  static List<pw.Widget> _buildFirewallSettings(FirewallUIModel fw) {
    return [
      _sectionTitle('Firewall Settings'),
      _keyValue('IPv4 SPI Firewall', fw.isIPv4FirewallEnabled ? 'On' : 'Off'),
      _keyValue('IPv6 SPI Firewall', fw.isIPv6FirewallEnabled ? 'On' : 'Off'),
      _keyValue('IPSec Passthrough', fw.blockIPSec ? 'Blocked' : 'Allowed'),
      _keyValue('PPTP Passthrough', fw.blockPPTP ? 'Blocked' : 'Allowed'),
      _keyValue('L2TP Passthrough', fw.blockL2TP ? 'Blocked' : 'Allowed'),
      _keyValue(
          'ICMP Ping (WAN)', fw.blockAnonymousRequests ? 'Blocked' : 'Allowed'),
      _keyValue('Multicast (IGMP)', fw.blockMulticast ? 'Blocked' : 'Allowed'),
      _keyValue('IDENT (TCP 113)', fw.blockIDENT ? 'Blocked' : 'Allowed'),
      pw.SizedBox(height: 12),
    ];
  }

  static List<pw.Widget> _buildDmzSettings(DmzUIModel dmz) {
    return [
      _sectionTitle('DMZ'),
      _keyValue('Status', dmz.isEnabled ? 'Enabled' : 'Disabled'),
      if (dmz.isEnabled) ...[
        _keyValue('Destination IP', dmz.destIp),
        _keyValue('Source',
            dmz.sourceType == DmzSourceType.any ? 'Any' : dmz.sourcePrefix),
      ],
      pw.SizedBox(height: 12),
    ];
  }

  // ===========================================================================
  // Page 6: Port Rules + Routing
  // ===========================================================================

  static List<pw.Widget> _buildPortForwarding(UspDashboardState state) {
    final rules = state.portForwardingRuleModels;
    if (rules.isEmpty) return [];
    return [
      _sectionTitle('Port Forwarding Rules (${rules.length})'),
      pw.SizedBox(height: 4),
      pw.TableHelper.fromTextArray(
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        cellStyle: const pw.TextStyle(fontSize: 9),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
        headers: ['Name', 'Ext Port', 'Int Port', 'Client', 'Protocol', 'On'],
        data: rules
            .map((r) => [
                  r.displayName,
                  r.portRangeDisplay,
                  '${r.internalPort}',
                  r.internalClient,
                  r.protocol,
                  r.enabled ? 'Yes' : 'No',
                ])
            .toList(),
      ),
      pw.SizedBox(height: 12),
    ];
  }

  static List<pw.Widget> _buildPortTriggering(UspDashboardState state) {
    final rules = state.portTriggeringRuleModels;
    if (rules.isEmpty) return [];
    return [
      _sectionTitle('Port Triggering Rules (${rules.length})'),
      pw.SizedBox(height: 4),
      pw.TableHelper.fromTextArray(
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        cellStyle: const pw.TextStyle(fontSize: 9),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
        headers: ['Name', 'Trigger', 'Protocol', 'Forward', 'On'],
        data: rules
            .map((r) => [
                  r.displayName,
                  r.triggerPortDisplay,
                  r.triggerProtocol,
                  r.forwardPortDisplay,
                  r.enabled ? 'Yes' : 'No',
                ])
            .toList(),
      ),
      pw.SizedBox(height: 12),
    ];
  }

  static List<pw.Widget> _buildIpv6PortService(PdfReportData data) {
    final rules = data.ipv6PortRules;
    if (rules == null || rules.isEmpty) return [];
    return [
      _sectionTitle('IPv6 Port Service Rules (${rules.length})'),
      pw.SizedBox(height: 4),
      pw.TableHelper.fromTextArray(
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        cellStyle: const pw.TextStyle(fontSize: 9),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
        headers: ['Name', 'IPv6 Address', 'Protocol', 'Port', 'On'],
        data: rules
            .map((r) => [
                  r.description.isNotEmpty ? r.description : '(unnamed)',
                  r.ipv6Address,
                  r.protocol,
                  r.portDisplay,
                  r.enabled ? 'Yes' : 'No',
                ])
            .toList(),
      ),
      pw.SizedBox(height: 12),
    ];
  }

  static List<pw.Widget> _buildStaticRouting(PdfReportData data) {
    final routes = data.staticRoutes;
    if (routes == null || routes.isEmpty) return [];
    return [
      _sectionTitle('Static Routes (${routes.length})'),
      pw.SizedBox(height: 4),
      pw.TableHelper.fromTextArray(
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        cellStyle: const pw.TextStyle(fontSize: 9),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
        headers: ['Name', 'Destination', 'Mask', 'Gateway', 'Interface', 'On'],
        data: routes
            .map((r) => [
                  r.name.isNotEmpty ? r.name : '(unnamed)',
                  r.destIpAddress,
                  r.destSubnetMask,
                  r.gatewayIpAddress.isNotEmpty ? r.gatewayIpAddress : '—',
                  r.interfaceName,
                  r.enabled ? 'Yes' : 'No',
                ])
            .toList(),
      ),
      pw.SizedBox(height: 12),
    ];
  }

  // ===========================================================================
  // USP Traffic Log
  // ===========================================================================

  static List<pw.Widget> _buildUspTrafficLog(List<pw.Font> fontFallback) {
    final log = getWebLogByTag(tag: 'UspService');
    if (log.trim().isEmpty) return [];
    final style = pw.TextStyle(fontSize: 7, fontFallback: fontFallback);
    final lines = log.split('\n');
    return [
      _sectionTitle('USP Traffic Log'),
      ...lines.map((line) => pw.Text(line, style: style)),
      pw.SizedBox(height: 12),
    ];
  }

  // ===========================================================================
  // Shared helpers
  // ===========================================================================

  static pw.Widget _sectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
      ),
    );
  }

  static pw.Widget _keyValue(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text(label,
                style:
                    const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Chart helpers
  // ===========================================================================

  /// Format bytes/sec for chart Y-axis labels.
  static String _formatSpeedLabel(num bytesPerSec) {
    final v = bytesPerSec.toDouble();
    if (v < 1024) return '${v.toInt()} B/s';
    if (v < 1024 * 1024) return '${(v / 1024).toStringAsFixed(1)} KB/s';
    if (v < 1024 * 1024 * 1024) {
      return '${(v / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
    return '${(v / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB/s';
  }

  /// Compute nice Y-axis tick values for a given max, returning [steps+1]
  /// evenly spaced values from 0 to a rounded-up ceiling.
  static List<num> _niceYSteps(double maxVal, {int steps = 4}) {
    if (maxVal.isNaN || maxVal.isInfinite || maxVal <= 0) {
      return List.generate(steps + 1, (i) => i);
    }
    // Round up to a "nice" number
    final magnitude = maxVal.abs();
    final exp = magnitude.toStringAsFixed(0).length - 1;
    final base = _pow10(exp).toDouble();
    final niceMax = (maxVal / base).ceil() * base;
    final interval = niceMax / steps;
    return List.generate(steps + 1, (i) => (i * interval).roundToDouble());
  }

  static int _pow10(int exp) {
    int result = 1;
    for (int i = 0; i < exp; i++) {
      result *= 10;
    }
    return result;
  }

  /// Predefined chart colors for multi-series charts.
  static const _chartBlue = PdfColors.blue;
  static const _chartTeal = PdfColors.teal;
  static const _chartOrange = PdfColors.orange;
}
