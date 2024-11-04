import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';

import '../../../../../common/test_responsive_widget.dart';
import '../../../../../common/testable_router.dart';
import '../../../../../test_data/firewall_settings_test_state.dart';
import '../../../../../mocks/firewall_notifier_mocks.dart';

void main() {
  late FirewallNotifier mockFirewallNotifier;

  setUp(() {
    mockFirewallNotifier = MockFirewallNotifier();
    when(mockFirewallNotifier.build())
        .thenReturn(FirewallState.fromMap(firewallSettingsTestState));
    when(mockFirewallNotifier.fetch()).thenAnswer((realInvocation) async {
      await Future.delayed(const Duration(seconds: 1));
      return FirewallState.fromMap(firewallSettingsTestState);
    });
  });
  testLocalizations('Firewall settings view', (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const FirewallView(),
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 9),
        ),
        locale: locale,
        overrides: [
          firewallProvider.overrideWith(() => mockFirewallNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();
  });

  testLocalizations('Firewall settings view - scroll down', (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const FirewallView(),
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 9),
        ),
        locale: locale,
        overrides: [
          firewallProvider.overrideWith(() => mockFirewallNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byType(AppCard).last, 10,
            scrollable: find
                .descendant(
                    of: find.byType(StyledAppPageView),
                    matching: find.byType(Scrollable))
                .last);
        await tester.pumpAndSettle();
  });
}
