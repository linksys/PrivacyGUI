import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dhcp/views/usp_dhcp_detail_view.dart';
import 'package:privacy_gui/page/dhcp/views/components/usp_dhcp_reservations_detail_card.dart';
import 'package:ui_kit_library/ui_kit.dart' show AppIconButton;

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../golden_framework/mocks/mock_dhcp.dart';
import '../fixtures/dhcp_test_data.dart';

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
          steps: (tester) async {
            final addBtn = find.descendant(
              of: find.byType(UspDhcpReservationsDetailCard),
              matching: find.byType(AppIconButton),
            );
            await tester.tap(addBtn.first);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
            final fields = find.byType(EditableText);
            final count = fields.evaluate().length;
            if (count < 2) return;
            final baseIndex = count - 2;
            await tester.tap(fields.at(baseIndex));
            await tester.pump();
            tester.testTextInput.enterText('invalid-mac');
            await tester.pump();
            await tester.tap(fields.at(baseIndex + 1));
            await tester.pump();
            tester.testTextInput.enterText('999.999.999.999');
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 100));
          },
        ),
      },
    ),
  );
}
