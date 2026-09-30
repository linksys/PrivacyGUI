// Baseline for DHCP Server's "Save changes?" prompt in the default build.
//
// Opening DHCP Reservations with unsaved edits offers to save them from a
// dialog, which calls the page's save directly rather than through its Save
// bar. A read-only build has to account for that second path. These tests pin
// that in the default build the prompt appears only when there are edits, that
// Save runs the page's save, and that Cancel does not.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/providers/read_only/read_only_mode_provider.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/_local_network_settings.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import '../../../../common/di.dart';
import '../../../../common/testable_router.dart';
import '../../../../mocks/local_network_settings_notifier_mocks.dart';
import '../../../../test_data/local_network_settings_state.dart';

void main() {
  late MockLocalNetworkSettingsNotifier mockNotifier;

  mockDependencyRegister();

  setUp(() {
    mockNotifier = MockLocalNetworkSettingsNotifier();
    when(mockNotifier.build()).thenReturn(
        LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsState));
  });

  Future<void> pump(
    WidgetTester tester, {
    required bool edited,
    required Future<void> Function() onSave,
    bool readOnly = false,
  }) async {
    await tester.pumpWidget(testableSingleRoute(
      overrides: [
        readOnlyModeProvider.overrideWithValue(readOnly),
        localNetworkSettingProvider.overrideWith(() => mockNotifier),
      ],
      extraRoutes: [
        GoRoute(
          name: RoutePath.dhcpReservation,
          path: '/${RoutePath.dhcpReservation}',
          builder: (context, state) => const Text('reservations page'),
        ),
      ],
      child: Scaffold(
        body: SingleChildScrollView(
          child: DHCPServerView(isEdited: () => edited, onSaveSettings: onSave),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> openReservations(WidgetTester tester) async {
    final entry = find.text('DHCP Reservations');
    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await tester.pumpAndSettle();
  }

  testWidgets('with edits, Save runs the page save', (tester) async {
    var saves = 0;
    await pump(tester, edited: true, onSave: () async => saves++);

    await openReservations(tester);
    expect(find.text('Save Changes?'), findsOneWidget);
    await tester.tap(find.widgetWithText(AppTextButton, 'Save'));
    await tester.pumpAndSettle();
    expect(saves, 1);
  });

  testWidgets('with edits, Cancel saves nothing', (tester) async {
    var saves = 0;
    await pump(tester, edited: true, onSave: () async => saves++);

    await openReservations(tester);
    await tester.tap(find.widgetWithText(AppTextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(saves, 0);
  });

  testWidgets('without edits, it goes straight to reservations',
      (tester) async {
    var saves = 0;
    await pump(tester, edited: false, onSave: () async => saves++);

    await openReservations(tester);
    expect(find.text('Save Changes?'), findsNothing);
    expect(find.text('reservations page'), findsOneWidget);
    expect(saves, 0);
  });

  testWidgets('a read-only build goes straight on without offering to save',
      (tester) async {
    var saves = 0;
    await pump(tester,
        edited: true, onSave: () async => saves++, readOnly: true);

    await openReservations(tester);
    expect(find.text('Save Changes?'), findsNothing);
    expect(find.text('reservations page'), findsOneWidget);
    expect(saves, 0);
  });
}
