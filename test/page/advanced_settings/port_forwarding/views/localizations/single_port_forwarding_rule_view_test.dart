import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/route/route_model.dart';

import '../../../../../common/test_responsive_widget.dart';
import '../../../../../common/testable_router.dart';
import '../../../../../mocks/single_port_forwarding_rule_notifier_mocks.dart';

void main() {
  late SinglePortForwardingRuleNotifier mockSinglePortForwardingRuleNotifier;

  setUp(() {
    mockSinglePortForwardingRuleNotifier =
        MockSinglePortForwardingRuleNotifier();
    when(mockSinglePortForwardingRuleNotifier.build())
        .thenReturn(const SinglePortForwardingRuleState());
    when(mockSinglePortForwardingRuleNotifier.subnetMask)
        .thenReturn('255.255.0.0');
    when(mockSinglePortForwardingRuleNotifier.ipAddress)
        .thenReturn('192.168.1.1');
  });

  testLocalizations('Single port forwarding rule view', (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const SinglePortForwardingRuleView(),
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 9),
        ),
        locale: locale,
        overrides: [
          singlePortForwardingRuleProvider
              .overrideWith(() => mockSinglePortForwardingRuleNotifier)
        ],
      ),
    );
    await tester.pumpAndSettle();
  });
}
