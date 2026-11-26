import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dhcp/views/usp_dhcp_detail_view.dart';
import 'package:privacy_gui/page/dhcp/views/components/usp_dhcp_reservations_detail_card.dart';
import 'package:ui_kit_library/ui_kit.dart' show AppIconButton;

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../../mocks/provider_overrides/mock_dhcp.dart';
import '../../../../mocks/test_data/scenes/dhcp_scene_data.dart';

void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'dhcp_detail',
      view: () => const UspDhcpDetailView(),
      shell: ShellType.custom,
      height: 1600,
      states: {
        'reservations_list': (overrides) => overrides.addAll(
              dhcpDetailOverrides(
                reservationState: dataState(),
                lanInfo: testLanInfo,
                clients: testClients,
              ),
            ),
        'empty': (overrides) => overrides.addAll(
              dhcpDetailOverrides(
                reservationState: emptyState(),
                lanInfo: testLanInfo,
              ),
            ),
        'edit_dirty': (overrides) => overrides.addAll(
              dhcpDetailOverrides(
                reservationState: dirtyState(),
                lanInfo: testLanInfo,
                clients: testClients,
              ),
            ),
      },
      interactions: {
        'dialog_add': Interaction(
          setup: (overrides) => overrides.addAll(
            dhcpDetailOverrides(
              reservationState: dataState(),
              lanInfo: testLanInfo,
              clients: testClients,
            ),
          ),
          steps: (tester) async {
            final addBtn = find.descendant(
              of: find.byType(UspDhcpReservationsDetailCard),
              matching: find.byType(AppIconButton),
            );
            await tester.tap(addBtn.first);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
          },
        ),
        'dialog_edit': Interaction(
          setup: (overrides) => overrides.addAll(
            dhcpDetailOverrides(
              reservationState: dataState(),
              lanInfo: testLanInfo,
              clients: testClients,
            ),
          ),
          steps: (tester) async {
            final buttons = find.descendant(
              of: find.byType(UspDhcpReservationsDetailCard),
              matching: find.byType(AppIconButton),
            );
            // Button order: [0]=add(header), [1]=edit(row1), [2]=delete(row1)
            await tester.tap(buttons.at(1));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
          },
        ),
        'dialog_delete': Interaction(
          setup: (overrides) => overrides.addAll(
            dhcpDetailOverrides(
              reservationState: dataState(),
              lanInfo: testLanInfo,
              clients: testClients,
            ),
          ),
          steps: (tester) async {
            final buttons = find.descendant(
              of: find.byType(UspDhcpReservationsDetailCard),
              matching: find.byType(AppIconButton),
            );
            await tester.tap(buttons.at(2));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
          },
        ),
        'dialog_validation': Interaction(
          setup: (overrides) => overrides.addAll(
            dhcpDetailOverrides(
              reservationState: dataState(),
              lanInfo: testLanInfo,
              clients: testClients,
            ),
          ),
          steps: withSemantics((tester) async {
            final addBtn = find.descendant(
              of: find.byType(UspDhcpReservationsDetailCard),
              matching: find.byType(AppIconButton),
            );
            await tester.tap(addBtn.first);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
            // By identifier (#1870): "the last two fields" became IP and Name
            // once the Name field was added after IP (#1698), so the MAC field
            // stayed empty and `invalid-mac` was validated as an IP address.
            await typeInto(tester, 'dhcp-reservation-mac', 'invalid-mac');
            await typeInto(tester, 'dhcp-reservation-ip', '999.999.999.999');
            // The dialog validates on focus-loss, so IP's error needs one.
            await blurFocus(tester);
            await tester.pump(const Duration(milliseconds: 100));
          }),
        ),
      },
    ),
  );
}
