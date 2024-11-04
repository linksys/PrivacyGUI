import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/page/advanced_settings/port_forwarding/_port_forwarding.dart';
import 'package:privacy_gui/route/route_model.dart';

import '../../../../../common/test_responsive_widget.dart';
import '../../../../../common/testable_router.dart';
import '../../../../../mocks/port_range_forwarding_rule_notifier_mocks.dart';

void main() {
  late PortRangeForwardingRuleNotifier mockPortRangeForwardingRuleNotifier;

  setUp(() {
    mockPortRangeForwardingRuleNotifier =
        MockPortRangeForwardingRuleNotifier();
    when(mockPortRangeForwardingRuleNotifier.build())
        .thenReturn(const PortRangeForwardingRuleState());
    when(mockPortRangeForwardingRuleNotifier.subnetMask)
        .thenReturn('255.255.0.0');
    when(mockPortRangeForwardingRuleNotifier.ipAddress)
        .thenReturn('192.168.1.1');
  });

  testLocalizations('Port range forwarding rule view', (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const PortRangeForwardingRuleView(),
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 9),
        ),
        locale: locale,
        overrides: [
          portRangeForwardingRuleProvider
              .overrideWith(() => mockPortRangeForwardingRuleNotifier)
        ],
      ),
    );
    await tester.pumpAndSettle();
  });
}
