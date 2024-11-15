import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/route/route_model.dart';

import '../../../../../common/test_responsive_widget.dart';
import '../../../../../common/testable_router.dart';
import '../../../../../test_data/ipv6_port_service_list_test_state.dart';
import '../../../../../mocks/ipv6_port_service_list_notifier_mocks.dart';

void main() {
  late Ipv6PortServiceListNotifier mockIpv6PortServiceListNotifier;

  setUp(() {
    mockIpv6PortServiceListNotifier = MockIpv6PortServiceListNotifier();
    when(mockIpv6PortServiceListNotifier.build()).thenReturn(
        Ipv6PortServiceListState.fromMap(ipv6PortServiceListTestState));
    when(mockIpv6PortServiceListNotifier.fetch())
        .thenAnswer((realInvocation) async {
      return Ipv6PortServiceListState.fromMap(ipv6PortServiceListTestState);
    });
  });
  testLocalizations('IPv6 port service list view - with rules',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const Ipv6PortServiceListView(),
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 9),
        ),
        locale: locale,
        overrides: [
          ipv6PortServiceListProvider
              .overrideWith(() => mockIpv6PortServiceListNotifier)
        ],
      ),
    );
    await tester.pumpAndSettle();
  });

  testLocalizations('IPv6 port service list view - empty',
      (tester, locale) async {
    when(mockIpv6PortServiceListNotifier.build()).thenReturn(
        Ipv6PortServiceListState.fromMap(ipv6PortServiceEmptyListTestState));
    await tester.pumpWidget(
      testableSingleRoute(
        child: const Ipv6PortServiceListView(),
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 9),
        ),
        locale: locale,
        overrides: [
          ipv6PortServiceListProvider
              .overrideWith(() => mockIpv6PortServiceListNotifier)
        ],
      ),
    );
    await tester.pumpAndSettle();
  });
}
