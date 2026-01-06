import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:privacy_gui/core/jnap/models/back_haul_info.dart';
import 'package:privacy_gui/core/jnap/models/wan_status.dart';
import 'package:privacy_gui/core/data/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/data/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/utils/wifi.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/health_check/_health_check.dart';
import 'package:privacy_gui/page/instant_topology/_instant_topology.dart';
import 'package:privacy_gui/page/instant_topology/views/model/tree_view_node.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_provider.dart';
import 'package:privacy_gui/utils.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Service responsible for generating PDF reports for Instant Verify
class InstantVerifyPdfService {
  /// Generate and print a comprehensive network status PDF report
  static Future<void> generatePdf(BuildContext context, WidgetRef ref) async {
    final topologyState = ref.read(instantTopologyProvider);
    final nodeList = [
      ...topologyState.root.toFlatList(),
      // ...topologyState.offlineRoot.toFlatList()
    ]..removeWhere((element) =>
        element is OnlineTopologyNode || element is OfflineTopologyNode);
    final nodeMap = nodeList.foldIndexed(
        <int, List<AppTreeNode<TopologyModel>>>{}, (index, previous, element) {
      final id = (index ~/ 5) + 1;
      final list = previous[id] ?? [];
      list.add(element);
      previous[id] = list;
      return previous;
    });

    try {
      final doc = pw.Document();

      // Create Info Page
      doc.addPage(_createPage(context, _buildInfo(context, ref)));
      // Create Node Pages
      for (int i = 0; i < nodeMap.entries.length; i++) {
        final list = nodeMap.entries.toList()[i];
        doc.addPage(
          _createPage(context, _buildNodes(context, list.key, list.value)),
        );
      }
      // Create external device list pages
      doc.addPage(_createPage(context, _createDeviceList(context, ref)));

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) => doc.save(),
      );
    } catch (e) {
      logger.e('Print page error', error: e);
    }
  }

  static List<pw.Widget> _buildInfo(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.read(dashboardManagerProvider);
    final deviceManagerState = ref.read(deviceManagerProvider);
    final devicesState = ref.read(deviceManagerProvider);
    final healthCheckState = ref.read(healthCheckProvider);
    final systemConnectivityState = ref.read(instantVerifyProvider);

    final uptime = DateFormatUtils.formatDuration(
        Duration(seconds: dashboardState.uptimes), context);
    final master = devicesState.masterDevice;
    final guestWiFi =
        systemConnectivityState.guestRadioSettings.radios.firstOrNull;
    final isSupportHealthCheck =
        ref.watch(healthCheckProvider).isSpeedTestModuleSupported;
    final cpuLoad = dashboardState.cpuLoad;
    final memoryLoad = dashboardState.memoryLoad;
    return [
      //
      pw.Text(loc(context).deviceInfo),
      pw.Text(
          '${loc(context).systemTestDateFormat(DateTime.now())} ${loc(context).systemTestDateTime(DateTime.now())}'),
      pw.Text('${loc(context).uptime}: $uptime'),
      pw.Text('${loc(context).model}: ${master.modelNumber ?? '--'}'),
      pw.Text('${loc(context).sku}: ${dashboardState.skuModelNumber ?? '--'}'),
      pw.Text(
          '${loc(context).serialNumber}: ${master.unit.serialNumber ?? '--'}'),
      pw.Text('${loc(context).macAddress}: ${master.getMacAddress()}'),
      pw.Text(
          '${loc(context).firmwareVersion}: ${master.unit.firmwareVersion ?? '--'}'),
      if (cpuLoad != null)
        pw.Text(
            'CPU Utilization: ${((double.tryParse(cpuLoad.padLeft(2, '0')) ?? 0) * 100).toStringAsFixed(2)}%'),
      if (memoryLoad != null)
        pw.Text(
            'Memory Utilization: ${((double.tryParse(memoryLoad.padLeft(2, '0')) ?? 0) * 100).toStringAsFixed(2)}%'),
      pw.Divider(height: AppSpacing.lg),
      //
      pw.Text(loc(context).connectivity),
      // pw.Text('${loc(context).selfTest}... Passed'),
      pw.Text(
          '${loc(context).internet}... ${systemConnectivityState.wanConnection != null ? 'Passed' : 'Failed'}'),
      ...systemConnectivityState.radioInfo.radios.map(
        (e) => pw.Text(
            '${e.band} | ${e.ssid}... ${e.isEnabled ? 'Enabled' : 'Disabled'}'),
      ),
      if (guestWiFi != null)
        pw.Text(
            'Guest | ${guestWiFi.guestSSID}... ${systemConnectivityState.guestRadioSettings.isGuestNetworkEnabled ? 'Enabled' : 'Disabled'}'),
      pw.Text(
          '${loc(context).wanIPAddress}: ${systemConnectivityState.wanConnection?.ipAddress ?? '--'}'),
      pw.Text(
          '${loc(context).gateway}: ${systemConnectivityState.wanConnection?.gateway ?? '--'}'),
      pw.Text(
          '${loc(context).connectionType}: ${systemConnectivityState.wanConnection?.wanType ?? '--'}'),
      pw.Text(
          '${loc(context).dns} 1: ${systemConnectivityState.wanConnection?.dnsServer1 ?? '--'}'),
      pw.Text(
          '${loc(context).dns} 2: ${systemConnectivityState.wanConnection?.dnsServer2 ?? '--'}'),
      pw.Text(
          '${loc(context).dns} 3: ${systemConnectivityState.wanConnection?.dnsServer3 ?? '--'}'),
      pw.Divider(height: AppSpacing.lg),
      if (isSupportHealthCheck) ...[
        pw.Text(loc(context).speedTest),
        pw.Text(healthCheckState.result?.toString() ?? ''),
        pw.Divider(height: AppSpacing.lg),
      ],
      ..._createBackhaulInfoData(devicesState.backhaulInfoData),

      ..._createWANStatus(deviceManagerState.wanStatus),
    ];
  }

  static List<pw.Widget> _createDeviceList(
      BuildContext context, WidgetRef ref) {
    final deviceManagerState = ref.watch(deviceManagerProvider);
    final externalDeviceList = deviceManagerState.externalDevices;
    return externalDeviceList.isEmpty
        ? []
        : [
            pw.Text('Device list'),
            pw.Text('Online'),
            ...externalDeviceList.where((e) => e.isOnline()).map(
                  (e) => pw.Container(
                    padding: pw.EdgeInsets.all(AppSpacing.sm),
                    decoration: pw.BoxDecoration(border: pw.Border.all()),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(e.getDeviceLocation()),
                        pw.Text(
                            'Connection Type: ${e.getConnectionType().name}'),
                        pw.Text('Signal Decibels: ${e.signalDecibels ?? '--'}'),
                        pw.Text('Connections'),
                        ...e.connections.map((conn) {
                          return pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('['),
                                pw.Text(
                                    'IP Address: ${conn.ipAddress ?? '--'}'),
                                pw.Text(
                                    'IPv6 Address: ${conn.ipv6Address ?? '--'}'),
                                pw.Text('MAC Address: ${conn.macAddress}'),
                                pw.Text(
                                    'Parent Device ID: ${conn.parentDeviceID ?? '--'}'),
                                pw.Text('Is Guest: ${conn.isGuest ?? '--'}'),
                                pw.Text(']'),
                              ]);
                        }),
                        if (e.knownInterfaces != null) ...[
                          pw.Text('Known Interfaces'),
                          ...e.knownInterfaces!.map((interface) {
                            return pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text('['),
                                  pw.Text('Band: ${interface.band ?? '--'}'),
                                  pw.Text(
                                      'Interface Type: ${interface.interfaceType}'),
                                  pw.Text(
                                      'MAC Address: ${interface.macAddress}'),
                                  pw.Text(']'),
                                ]);
                          }),
                        ],
                      ],
                    ),
                  ),
                ),
            pw.SizedBox(height: AppSpacing.sm),
            pw.Text('Offline'),
            ...externalDeviceList.where((e) => !e.isOnline()).map(
                  (e) => pw.Container(
                    padding: pw.EdgeInsets.all(AppSpacing.sm),
                    decoration: pw.BoxDecoration(border: pw.Border.all()),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(e.getDeviceLocation()),
                        pw.Text(
                            'Connection Type: ${e.getConnectionType().name}'),
                        pw.Text('Signal Decibels: ${e.signalDecibels ?? '--'}'),
                        pw.Text('Connections'),
                        ...e.connections.map((conn) {
                          return pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('['),
                                pw.Text(
                                    'IP Address: ${conn.ipAddress ?? '--'}'),
                                pw.Text(
                                    'IPv6 Address: ${conn.ipv6Address ?? '--'}'),
                                pw.Text('MAC Address: ${conn.macAddress}'),
                                pw.Text(
                                    'Parent Device ID: ${conn.parentDeviceID ?? '--'}'),
                                pw.Text('Is Guest: ${conn.isGuest ?? '--'}'),
                                pw.Text(']'),
                              ]);
                        }),
                        if (e.knownInterfaces != null) ...[
                          pw.Text('Known Interfaces'),
                          ...e.knownInterfaces!.map((interface) {
                            return pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text('['),
                                  pw.Text('Band: ${interface.band ?? '--'}'),
                                  pw.Text(
                                      'Interface Type: ${interface.interfaceType}'),
                                  pw.Text(
                                      'MAC Address: ${interface.macAddress}'),
                                  pw.Text(']'),
                                ]);
                          }),
                        ],
                      ],
                    ),
                  ),
                ),
          ];
  }

  static List<pw.Widget> _createBackhaulInfoData(List<BackHaulInfoData> data) {
    return data.isEmpty
        ? []
        : [
            pw.Text('Backhaul info'),
            ...data.map((b) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Device UUID: ${b.deviceUUID}'),
                  pw.Text('IP Address: ${b.ipAddress}'),
                  pw.Text('Connection Type: ${b.connectionType}'),
                  pw.Text('Parent IP Address: ${b.parentIPAddress}'),
                  pw.Text('Speed Mbps: ${b.speedMbps}'),
                  if (b.wirelessConnectionInfo != null)
                    pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Wireless Connection Info'),
                          pw.Text(
                              'Radio ID: ${b.wirelessConnectionInfo?.radioID}'),
                          pw.Text(
                              'Channel: ${b.wirelessConnectionInfo?.channel}'),
                          pw.Text(
                              'Ap BSSID: ${b.wirelessConnectionInfo?.apBSSID}'),
                          pw.Text(
                              'Ap RSSI: ${b.wirelessConnectionInfo?.apRSSI}'),
                          pw.Text(
                              'Station BSSID: ${b.wirelessConnectionInfo?.stationBSSID}'),
                          pw.Text(
                              'Station RSSI: ${b.wirelessConnectionInfo?.stationRSSI}'),
                          pw.Text(
                              'tx rate: ${b.wirelessConnectionInfo?.txRate}'),
                          pw.Text(
                              'rx rate: ${b.wirelessConnectionInfo?.rxRate}'),
                          if (b.wirelessConnectionInfo?.isMultiLinkOperation !=
                              null)
                            pw.Text(
                                'Is Multi Link Operation: ${b.wirelessConnectionInfo?.isMultiLinkOperation}'),
                          pw.Divider(height: AppSpacing.xs),
                        ]),
                ],
              );
            }),
          ];
  }

  static List<pw.Widget> _createWANStatus(RouterWANStatus? wanStatus) {
    return wanStatus == null
        ? []
        : [
            pw.Text('WAN status'),
            pw.Text('MAC Address: ${wanStatus.macAddress}'),
            pw.Text('Detected WAN type: ${wanStatus.detectedWANType}'),
            pw.Text('IPv4'),
            pw.Text('\tWAN Status: ${wanStatus.wanStatus}'),
            pw.Text('\tWAN Type: ${wanStatus.wanConnection?.wanType ?? '--'}'),
            pw.Text('\tAddress: ${wanStatus.wanConnection?.ipAddress ?? '--'}'),
            pw.Text('\tGateway: ${wanStatus.wanConnection?.gateway ?? '--'}'),
            pw.Text(
                '\tSubmasks: ${wanStatus.wanConnection?.networkPrefixLength != null ? NetworkUtils.prefixLengthToSubnetMask(wanStatus.wanConnection!.networkPrefixLength) : '--'}'),
            pw.Text(
                '\tDNS server1: ${wanStatus.wanConnection?.dnsServer1 ?? '--'}'),
            pw.Text(
                '\tDNS server2: ${wanStatus.wanConnection?.dnsServer2 ?? '--'}'),
            pw.Text(
                '\tDNS server3: ${wanStatus.wanConnection?.dnsServer3 ?? '--'}'),
            pw.Text('\tmtu: ${wanStatus.wanConnection?.mtu ?? '--'}'),
            pw.Text(
                '\tDHCP Lease Minutes: ${wanStatus.wanConnection?.dhcpLeaseMinutes ?? '--'}'),
            pw.Text('IPv6'),
            pw.Text('\tWAN Status: ${wanStatus.wanIPv6Status}'),
            pw.Text(
                '\tWAN Type: ${wanStatus.wanIPv6Connection?.wanType ?? '--'}'),
            pw.Text(
                '\tIP Address: ${wanStatus.wanIPv6Connection?.networkInfo?.ipAddress ?? '--'}'),
            pw.Text(
                '\tGateway: ${wanStatus.wanIPv6Connection?.networkInfo?.gateway ?? '--'}'),
            pw.Text(
                '\tDNS server1: ${wanStatus.wanIPv6Connection?.networkInfo?.dnsServer1 ?? '--'}'),
            pw.Text(
                '\tDNS server2: ${wanStatus.wanIPv6Connection?.networkInfo?.dnsServer2 ?? '--'}'),
            pw.Text(
                '\tDNS server3: ${wanStatus.wanIPv6Connection?.networkInfo?.dnsServer3 ?? '--'}'),
            pw.Text(
                '\tDHCP Lease Minutes: ${wanStatus.wanIPv6Connection?.networkInfo?.dhcpLeaseMinutes ?? '--'}'),
            pw.Divider(height: AppSpacing.lg),
          ];
  }

  static List<pw.Widget> _buildNodes(BuildContext context, int index,
      List<AppTreeNode<TopologyModel>> nodeList) {
    return nodeList.isEmpty
        ? []
        : [
            pw.Text('${loc(context).instantTopology}... $index'),
            ...nodeList.map((node) {
              return pw.Row(children: [
                pw.SizedBox(width: 16.0 * node.level()),
                pw.Container(
                  constraints: const pw.BoxConstraints(
                    minWidth: 180,
                    maxWidth: 400,
                    // minHeight: 264,
                  ),
                  decoration: pw.BoxDecoration(
                    // color: PdfColor.fromInt(Colors.amber.value),
                    border: pw.Border.all(),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(AppSpacing.lg),
                        child: pw.Row(
                          mainAxisSize: pw.MainAxisSize.min,
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Expanded(
                              child: pw.Column(
                                mainAxisAlignment: pw.MainAxisAlignment.start,
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    node.data.location,
                                    maxLines: 1,
                                  ),
                                  // const AppGap.medium(),
                                  pw.SizedBox(height: AppSpacing.sm),
                                  pw.Column(
                                    mainAxisSize: pw.MainAxisSize.min,
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    children: [
                                      _buildNodeContent(
                                        context,
                                        node,
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ]);
            }),
          ];
  }

  static pw.Widget _buildNodeContent(
    BuildContext context,
    AppTreeNode<TopologyModel> node,
  ) {
    final signalLevel = getWifiSignalLevel(node.data.signalStrength);
    return pw.Table(
      border: const pw.TableBorder(),
      columnWidths: const {
        0: pw.FlexColumnWidth(1),
        1: pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(children: [
          pw.Text('${loc(context).model}:'),
          pw.Text(node.data.model),
        ]),
        pw.TableRow(children: [
          pw.Text('${loc(context).serialNo}:'),
          pw.Text(node.data.serialNumber),
        ]),
        pw.TableRow(children: [
          pw.Text('${loc(context).fwVersion}:'),
          pw.Wrap(
            crossAxisAlignment: pw.WrapCrossAlignment.center,
            children: [
              pw.Text(node.data.fwVersion),
            ],
          ),
        ]),
        pw.TableRow(children: [
          pw.Text('${loc(context).connection}:'),
          pw.Text(!node.data.isOnline
              ? '--'
              : node.data.isWiredConnection
                  ? loc(context).wired
                  : loc(context).wireless),
        ]),
        if (!(node.data.isMaster || node.data.isWiredConnection))
          pw.TableRow(children: [
            pw.Text('${loc(context).meshHealth}:'),
            pw.Text(
              node.data.isOnline
                  ? '${signalLevel.resolveLabel(context)}(${node.data.signalStrength})'
                  : loc(context).offline,
            ),
          ]),
        pw.TableRow(children: [
          pw.Text('${loc(context).ipAddress}:'),
          pw.Text(node.data.isOnline ? node.data.ipAddress : '--'),
        ]),
        pw.TableRow(children: [
          pw.Text('${loc(context).upstream}:'),
          pw.Text(node.parent?.data.location ?? '--'),
        ]),
      ],
    );
  }

  static pw.Page _createPage(BuildContext context, List<pw.Widget> children) {
    return pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
        header: (pw.Context pwContext) {
          return pw.Text(loc(context).appTitle,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
              ),
              textScaleFactor: 2.0);
        },
        build: (pw.Context pwContext) {
          return children;
        });
  }
}
