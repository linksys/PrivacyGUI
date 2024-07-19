import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';

import '../../../../../common/test_responsive_widget.dart';
import '../../../../../common/testable_router.dart';
import '../../ipv6_port_service_rule_view_test_mocks.dart';

@GenerateNiceMocks([
  MockSpec<Ipv6PortServiceRuleNotifier>(),
])
void main() {
  late Ipv6PortServiceRuleNotifier mockIpv6PortServiceRuleNotifier;

  setUp(() {
    mockIpv6PortServiceRuleNotifier = MockIpv6PortServiceRuleNotifier();
    when(mockIpv6PortServiceRuleNotifier.build())
        .thenReturn(const Ipv6PortServiceRuleState());
  });
  testLocalizations('IPv6 port service rule view', (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const Ipv6PortServiceRuleView(),
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 9),
        ),
        locale: locale,
        overrides: [
          ipv6PortServiceRuleProvider
              .overrideWith(() => mockIpv6PortServiceRuleNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();
  });
  testLocalizations('IPv6 port service rule view - edit protocal',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const Ipv6PortServiceRuleView(),
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 9),
        ),
        locale: locale,
        overrides: [
          ipv6PortServiceRuleProvider
              .overrideWith(() => mockIpv6PortServiceRuleNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();
    final editFinder = find.byIcon(LinksysIcons.edit);
    await tester.scrollUntilVisible(editFinder, 10,
        scrollable: find
            .descendant(
                of: find.byType(StyledAppPageView),
                matching: find.byType(Scrollable))
            .last);
    await tester.pumpAndSettle();
    await tester.tap(editFinder);
    await tester.pumpAndSettle();
  });
}
