import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_dashboard_state.dart';

/// Generates a multi-page PDF report of essential router information.
///
/// Follows the same pattern as [InstantVerifyPdfService] but reads from
/// [UspDashboardState] UI models instead of JNAP providers.
class UspPdfService {
  UspPdfService._();

  static Future<void> generatePdf(UspDashboardState state) async {
    try {
      final doc = pw.Document();

      doc.addPage(_createPage([
        ..._buildDeviceInfo(state),
        ..._buildSystemStatus(state),
        ..._buildWanStatus(state),
        ..._buildLanNetwork(state),
      ]));

      doc.addPage(_createPage(_buildWifi(state)));

      doc.addPage(_createPage(_buildDevices(state)));

      doc.addPage(_createPage(_buildServices(state)));

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) => doc.save(),
      );
    } catch (e) {
      logger.e('[UspPdfService] Print error', error: e);
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

  // ---------------------------------------------------------------------------
  // Section builders
  // ---------------------------------------------------------------------------

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

  static List<pw.Widget> _buildSystemStatus(UspDashboardState state) {
    final info = state.systemInfoModel;
    return [
      _sectionTitle('System Status'),
      _keyValue('Uptime', info.formattedUptime),
      _keyValue('CPU Usage', '${info.cpuPercent}%'),
      _keyValue('Memory',
          '${info.formattedUsedMemory} / ${info.formattedTotalMemory} (${info.memoryPercent}%)'),
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

  static List<pw.Widget> _buildServices(UspDashboardState state) {
    return [
      ..._buildTimeSettings(state),
      ..._buildEthernetPorts(state),
      ..._buildDhcpReservations(state),
      ..._buildPortForwarding(state),
    ];
  }

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

  static List<pw.Widget> _buildPortForwarding(UspDashboardState state) {
    final rules = state.portForwardingRuleModels;
    if (rules.isEmpty) return [];
    return [
      _sectionTitle('Port Forwarding Rules'),
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

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

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
}
