import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/local_network/providers/lan_data_provider.dart';
import 'package:privacy_gui/page/static_routing/views/usp_static_routing_view.dart';
import 'package:ui_kit_library/ui_kit.dart'
    show AppIconButton, AppIpv4TextField;

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../../mocks/provider_overrides/mock_dashboard_cards.dart'
    show FixedLanDataNotifier;
import '../../../../mocks/provider_overrides/mock_static_routing.dart';
import '../../../../mocks/test_data/scenes/cards_scene_data.dart'
    show testLanData;
import '../../../../mocks/test_data/scenes/static_routing_scene_data.dart';

/// The page with a readable LAN, which the dialog cases need.
///
/// Add and Edit await `lanDataProvider` before they open the dialog (the
/// gateway is checked against the LAN subnet), and [staticRoutingOverrides]
/// leaves it out on purpose. Without it, both buttons show "The service is not
/// ready yet" and no dialog opens (#1870).
List<Override> _dialogOverrides() => [
      ...staticRoutingOverrides(dataState([route1, route2])),
      lanDataProvider.overrideWith(() => FixedLanDataNotifier(testLanData)),
    ];

/// Types [address] into the four octet boxes of the IPv4 field [identifier].
///
/// [typeInto] expects one box per field; an [AppIpv4TextField] holds four, and
/// each takes digits only.
Future<void> _typeIpv4(
    WidgetTester tester, String identifier, String address) async {
  final boxes = find.descendant(
    of: find.byWidgetPredicate(
        (w) => w is AppIpv4TextField && w.identifier == identifier),
    matching: find.byType(EditableText),
  );
  await tester.ensureVisible(boxes.first);
  final octets = address.split('.');
  for (var i = 0; i < 4; i++) {
    await tester.tap(boxes.at(i));
    await tester.pump();
    tester.testTextInput.enterText(octets[i]);
    await tester.pump();
  }
}

void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'static_routing',
      view: () => const UspStaticRoutingView(),
      shell: ShellType.custom,
      states: {
        'routes_list': (overrides) => overrides.addAll(
              staticRoutingOverrides(dataState([route1, route2])),
            ),
        'empty': (overrides) => overrides.addAll(
              staticRoutingOverrides(emptyState()),
            ),
        'edit_dirty': (overrides) => overrides.addAll(
              staticRoutingOverrides(dirtyState()),
            ),
        // #1100: a router with the NAT / Dynamic routing switch.
        'nat_dynamic_routing': (overrides) => overrides.addAll(
              staticRoutingOverrides(
                  dataState([route1, route2], ripEnabled: true)),
            ),
        // #1100: at FWDEV#213's 20 routes, Add is disabled and says why.
        'full': (overrides) => overrides.addAll(
              staticRoutingOverrides(fullState),
            ),
      },
      interactions: {
        'dialog_add': Interaction(
          setup: (overrides) => overrides.addAll(_dialogOverrides()),
          steps: (tester) async {
            final addBtn = find.descendant(
              of: find.byType(UspStaticRoutingView),
              matching: find.byType(AppIconButton),
            );
            await tester.tap(addBtn.first);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
          },
        ),
        'dialog_edit': Interaction(
          setup: (overrides) => overrides.addAll(_dialogOverrides()),
          steps: (tester) async {
            final buttons = find.descendant(
              of: find.byType(UspStaticRoutingView),
              matching: find.byType(AppIconButton),
            );
            // [0]=add, [1]=edit(row1), [2]=delete(row1), ...
            await tester.tap(buttons.at(1));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
          },
        ),
        'dialog_validation': Interaction(
          setup: (overrides) => overrides.addAll(_dialogOverrides()),
          steps: withSemantics((tester) async {
            final addBtn = find.descendant(
              of: find.byType(UspStaticRoutingView),
              matching: find.byType(AppIconButton),
            );
            await tester.tap(addBtn.first);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
            // By identifier, not position (#1870): the three addresses are
            // four boxes each, so "the last four fields" was the gateway alone.
            // Each value breaks a different rule of the dialog's own checks.
            // Name — over 32 chars
            await typeInto(tester, 'static-route-name', 'x' * 33);
            // Destination — reserved (127/8)
            await _typeIpv4(tester, 'static-route-dest-ip', '127.20.0.0');
            // Subnet mask — not contiguous
            await _typeIpv4(tester, 'static-route-subnet-mask', '255.0.255.0');
            // Gateway — outside the LAN subnet, for the default LAN interface
            await _typeIpv4(tester, 'static-route-gateway', '10.0.0.1');
            // The dialog validates on focus-loss, so the gateway needs one.
            await blurFocus(tester);
            await tester.pump(const Duration(milliseconds: 100));
          }),
        ),
      },
    ),
  );
}
