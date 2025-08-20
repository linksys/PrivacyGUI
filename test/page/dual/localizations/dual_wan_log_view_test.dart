import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dual/dual_wan_log_view.dart';
import 'package:privacy_gui/page/dual/models/log.dart';
import 'package:privacy_gui/page/dual/models/log_level.dart';
import 'package:privacy_gui/page/dual/models/log_type.dart';
import 'package:privacy_gui/page/dual/providers/dual_wan_filtered_logs_provider.dart';
import 'package:privacy_gui/page/dual/providers/dual_wan_log_state.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:get_it/get_it.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';

import '../../../common/config.dart';
import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';

var mockLogs = [
  DualWANLog(
    level: DualWANLogLevel.warning,
    message: 'Primary WAN connection lost, switching to Secondary WAN',
    source: 'Dual-WAN Manager',
    timestamp: DateTime(2024, 1, 15, 14, 32, 15).millisecondsSinceEpoch,
    type: DualWANLogType.failover,
  ),
  DualWANLog(
    level: DualWANLogLevel.info,
    message: 'Secondary WAN connection established successfully',
    source: 'Dual-WAN Manager',
    timestamp: DateTime(2024, 1, 15, 14, 32, 16).millisecondsSinceEpoch,
    type: DualWANLogType.failover,
  ),
  DualWANLog(
    level: DualWANLogLevel.info,
    message:
        'Speed test completed - Primary WAN: 900Mbps, Secondary WAN: 100Mbps',
    source: 'Speed Test Service',
    timestamp: DateTime(2024, 1, 15, 14, 32, 47).millisecondsSinceEpoch,
    type: DualWANLogType.speed,
  ),
  DualWANLog(
    level: DualWANLogLevel.info,
    message:
        'Primary WAN connection restored, maintaining existing sessions on Secondary WAN',
    source: 'Dual-WAN Manager',
    timestamp: DateTime(2024, 1, 15, 14, 33, 18).millisecondsSinceEpoch,
    type: DualWANLogType.failover,
  ),
  DualWANLog(
    level: DualWANLogLevel.info,
    message: 'WAN uptime report - Primary: 99.8%, Secondary: 98.5%',
    source: 'Uptime Monitor',
    timestamp: DateTime(2024, 1, 15, 14, 34, 19).millisecondsSinceEpoch,
    type: DualWANLogType.uptime,
  ),
  DualWANLog(
    level: DualWANLogLevel.info,
    message:
        'Throughput monitoring - Primary WAN: 45.2 Mbps avg, Secondary WAN: 23.1 Mbps avg',
    source: 'Throughput Monitor',
    timestamp: DateTime(2024, 1, 15, 14, 35, 20).millisecondsSinceEpoch,
    type: DualWANLogType.throughput,
  ),
  DualWANLog(
    level: DualWANLogLevel.error,
    message: 'Failed to establish connection on Secondary WAN - DNS resolution timeout',
    source: 'Dual-WAN Manager',
    timestamp: DateTime(2024, 1, 15, 14, 36, 19).millisecondsSinceEpoch,
    type: DualWANLogType.failover,
  ),
  DualWANLog(
    level: DualWANLogLevel.info,
    message: 'Secondary WAN connection retry successful',
    source: 'Dual-WAN Manager',
    timestamp: DateTime(2024, 1, 15, 14, 36, 20).millisecondsSinceEpoch,
    type: DualWANLogType.failover,
  ),
];

void main() {
  final screenList = [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 1480)).toList(),
    ...responsiveDesktopScreens.map((e) => e.copyWith(height: 940)).toList()
  ];
  mockDependencyRegister();
  ServiceHelper mockServiceHelper = GetIt.I<ServiceHelper>();

  setUp(() {});

  Widget testableWidget(Locale locale, DualWANLogState Function(Ref<DualWANLogState>) create) => testableSingleRoute(
        config: LinksysRouteConfig(column: ColumnGrid(column: 12)),
        overrides: [
          dualWANFilteredLogsProvider
              .overrideWith(create),
        ],
        locale: locale,
        child: const DualWANLogView(),
      );

  testLocalizations('Dual WAN Log View - all logs', (tester, locale) async {
    final widget = testableWidget(locale, (ref) => DualWANLogState(logs: mockLogs));

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
    print(mockLogs.map((e) => e.toMap()));
  }, screens: screenList);
  // testLocalizations('Dual WAN Settings View - failover',
  //     (tester, locale) async {
  //   final widget = testableWidget(locale);

  //   await tester.pumpWidget(widget);
  //   await tester.pumpAndSettle();
  // }, screens: screenList);
}
