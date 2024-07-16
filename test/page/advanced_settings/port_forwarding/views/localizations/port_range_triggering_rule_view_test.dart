import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/page/advanced_settings/port_forwarding/_port_forwarding.dart';
import 'package:privacy_gui/route/route_model.dart';

import '../../../../../common/test_responsive_widget.dart';
import '../../../../../common/testable_router.dart';
import '../../port_range_triggering_rule_view_test_mocks.dart';

@GenerateNiceMocks([
  MockSpec<PortRangeTriggeringRuleNotifier>(),
])
void main() {
  late PortRangeTriggeringRuleNotifier mockPortRangeTriggeringRuleNotifier;

  setUp(() {
    mockPortRangeTriggeringRuleNotifier = MockPortRangeTriggeringRuleNotifier();
    when(mockPortRangeTriggeringRuleNotifier.build())
        .thenReturn(const PortRangeTriggeringRuleState());
    when(mockPortRangeTriggeringRuleNotifier.subnetMask)
        .thenReturn('255.255.0.0');
    when(mockPortRangeTriggeringRuleNotifier.ipAddress)
        .thenReturn('192.168.1.1');
  });

  testLocalizations('Port range triggering rule view', (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const PortRangeTriggeringRuleView(),
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 9),
        ),
        locale: locale,
        overrides: [
          portRangeTriggeringRuleProvider
              .overrideWith(() => mockPortRangeTriggeringRuleNotifier)
        ],
      ),
    );
    await tester.pumpAndSettle();
  });
}
