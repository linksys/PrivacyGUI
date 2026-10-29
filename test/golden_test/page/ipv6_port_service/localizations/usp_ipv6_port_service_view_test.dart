import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/ipv6_port_service/models/ipv6_port_service_status.dart';
import 'package:privacy_gui/page/ipv6_port_service/views/usp_ipv6_port_service_view.dart';
import 'package:ui_kit_library/ui_kit.dart' show AppIconButton;

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../../mocks/provider_overrides/mock_ipv6_port_service.dart';
import '../../../../mocks/test_data/scenes/ipv6_port_service_scene_data.dart';

void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'ipv6_port_service',
      view: () => const UspIpv6PortServiceView(),
      shell: ShellType.custom,
      height: 1200,
      states: {
        'rules_list': (overrides) => overrides.addAll(
              ipv6PortServiceOverrides(dataState()),
            ),
        'empty': (overrides) => overrides.addAll(
              ipv6PortServiceOverrides(emptyState()),
            ),
        'edit_dirty': (overrides) => overrides.addAll(
              ipv6PortServiceOverrides(dirtyState()),
            ),
      },
      interactions: {
        'dialog_add': Interaction(
          setup: (overrides) => overrides.addAll(
            ipv6PortServiceOverrides(dataState()),
          ),
          steps: (tester) async {
            final addBtn = find.byType(AppIconButton);
            await tester.tap(addBtn.first);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
          },
        ),
        'dialog_edit': Interaction(
          setup: (overrides) => overrides.addAll(
            ipv6PortServiceOverrides(dataState()),
          ),
          steps: (tester) async {
            final buttons = find.byType(AppIconButton);
            // Button order: [0]=add(header), then per rule card: [1]=edit(rule1), [2]=delete(rule1), ...
            await tester.tap(buttons.at(1));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
          },
        ),
        // By identifier, and each field left for the next, so the dialog's
        // focus-loss validation runs on every one: the earlier version typed
        // by position into the last field and never left it.
        'dialog_validation': Interaction(
          setup: (overrides) => overrides.addAll(
            ipv6PortServiceOverrides(dataState()),
          ),
          steps: withSemantics((tester) async {
            await tapAdd(tester, 'ipv6-rule-add');
            await typeInto(tester, 'ipv6-rule-description', 'x' * 65);
            await typeInto(tester, 'ipv6-rule-address', 'invalid-ipv6');
            await typeInto(tester, 'ipv6-rule-start-port', '99999');
            await typeInto(tester, 'ipv6-rule-end-port', '0');
            await leaveFields(tester);
          }),
        ),
        // --- FWDEV#204's checks (#1687) ---
        // 80 TCP to 2001:db8::1 is the scene's Web Server.
        'dialog_overlap': Interaction(
          setup: (overrides) => overrides.addAll(
            ipv6PortServiceOverrides(dataState()),
          ),
          steps: withSemantics((tester) async {
            await tapAdd(tester, 'ipv6-rule-add');
            await typeInto(tester, 'ipv6-rule-description', 'Web 2');
            await typeInto(tester, 'ipv6-rule-address', '2001:db8::1');
            await typeInto(tester, 'ipv6-rule-start-port', '80');
            await typeInto(tester, 'ipv6-rule-end-port', '80');
            await leaveFields(tester);
          }),
        ),
        // The two name errors below show as a red name field: AppTextField
        // puts its message in a tooltip on the error icon (the kit's default
        // `AppErrorDisplayMode.toolTip`), so no frame shows the text. Every
        // other field is filled valid so the name is the only red.
        // RULE_IDENT is a firewall rule the page hides.
        'dialog_name_in_use': Interaction(
          setup: (overrides) => overrides.addAll(
            ipv6PortServiceOverrides(dataState().copyWith(
              status: const Ipv6PortServiceStatus(
                  hiddenRuleDescriptions: {'RULE_IDENT'}),
            )),
          ),
          steps: withSemantics((tester) async {
            await tapAdd(tester, 'ipv6-rule-add');
            await typeInto(tester, 'ipv6-rule-description', 'RULE_IDENT');
            await fillValidRest(tester);
          }),
        ),
        // 22 CJK characters: 66 bytes, so the counter reads 66/64 in the
        // error colour, above the length error.
        'dialog_name_too_long': Interaction(
          setup: (overrides) => overrides.addAll(
            ipv6PortServiceOverrides(dataState()),
          ),
          steps: withSemantics((tester) async {
            await tapAdd(tester, 'ipv6-rule-add');
            await typeInto(tester, 'ipv6-rule-description', '規' * 22);
            await fillValidRest(tester);
          }),
        ),
        // The list at its 15-rule limit: Add disabled, reason shown.
        'full': Interaction(
          setup: (overrides) =>
              overrides.addAll(ipv6PortServiceOverrides(fullState)),
          steps: (tester) async {},
        ),
      },
    ),
  );
}

/// Fills the address and a port no rule uses, so the name is the only error.
Future<void> fillValidRest(WidgetTester tester) async {
  await typeInto(tester, 'ipv6-rule-address', '2001:db8::5');
  await typeInto(tester, 'ipv6-rule-start-port', '7000');
  await typeInto(tester, 'ipv6-rule-end-port', '7000');
  await leaveFields(tester);
}

/// Takes focus off the last field, so it validates too, and dismisses the
/// text-selection toolbar a tap into a filled field opens.
Future<void> leaveFields(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}
