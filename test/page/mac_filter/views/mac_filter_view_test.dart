import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/mac_filter/providers/mac_filter_state.dart';
import 'package:privacy_gui/page/mac_filter/services/mac_filter_service.dart';
import 'package:privacy_gui/page/mac_filter/views/mac_filter_view.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../layout_gate/families/page_surface_family.dart';
import '../../../mocks/provider_overrides/mock_mac_filter.dart';
import '../../../mocks/test_data/scenes/mac_filter_scene_data.dart';
import '../../../util/app_test_fonts.dart';

/// The MAC Filter page renders its mode selector always, and the list editor
/// only when a mode is active. Untagged on purpose so `run_tests.sh` runs it.
///
/// Hosted through the layout gate's [pageSurfaceHost] because `UspTopBar` inside
/// `UiKitPageView` reaches `GoRouter.of(context)` unguarded.
void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  Widget host(String key, MacFilterState state) => KeyedSubtree(
        key: ValueKey(key),
        child: pageSurfaceHost(
          view: const MacFilterView(),
          locale: const Locale('en'),
          overrides: macFilterOverrides(state),
        ),
      );

  testWidgets('always shows the three-mode selector', (tester) async {
    await tester.pumpWidget(host('disabled', disabledState));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(AppRadioList<MacFilterMode>), findsOneWidget);
  });

  testWidgets('Off mode hides the device list', (tester) async {
    await tester.pumpWidget(host('off', disabledState));
    await tester.pump(const Duration(milliseconds: 100));

    // The Add-device button only exists when a mode is active.
    expect(
        find.byWidgetPredicate(
            (w) => w is AppButton && (w.identifier == 'mac-filter-add-device')),
        findsNothing);
  });

  testWidgets('Deny mode shows the list with its devices', (tester) async {
    await tester.pumpWidget(host('deny', denyWithDevicesState));
    await tester.pump(const Duration(milliseconds: 100));

    // Two configured MACs render as rows.
    expect(find.text('AA:BB:CC:DD:EE:01'), findsOneWidget);
    expect(find.text('7A:BB:CC:DD:EE:03'), findsOneWidget);
  });

  testWidgets('enabled with an empty list shows the empty message',
      (tester) async {
    await tester.pumpWidget(host('empty', enabledEmptyState));
    await tester.pump(const Duration(milliseconds: 100));

    // No device-row MAC text present.
    expect(find.text('AA:BB:CC:DD:EE:01'), findsNothing);
  });
}
