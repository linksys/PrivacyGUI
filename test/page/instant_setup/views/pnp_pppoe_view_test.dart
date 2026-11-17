@Tags(['ui'])
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_pppoe_view.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../mocks/provider_overrides/mock_common.dart';
import '../../../mocks/provider_overrides/mock_pnp.dart';
import '../../../mocks/test_data/scenes/pnp_scene_data.dart';

final _testTheme = AppTheme.create(
  brightness: Brightness.light,
  seedColor: Colors.blue,
  designThemeBuilder: (c) => CustomDesignTheme.fromJson({'style': 'flat'}),
);

/// The PPPoE step prefilled from a router with VLAN 201 on.
Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [...commonOverrides(), ...pnpOverrides(pnpNoInternetState)],
    child: MaterialApp.router(
      theme: _testTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: GoRouter(
        initialLocation: '/pppoe',
        routes: [
          GoRoute(path: '/pppoe', builder: (_, __) => const PnpPppoeView()),
        ],
      ),
    ),
  ));
  await tester.pumpAndSettle();
  expect(find.byType(PnpPppoeView), findsOneWidget);
}

Finder get _vlanId => find.byWidgetPredicate(
    (w) => w is AppTextField && w.identifier == 'pnp-pppoe-vlan-id');

Future<void> _typeVlanId(WidgetTester tester, String text) async {
  await tester.enterText(
      find.descendant(of: _vlanId, matching: find.byType(EditableText)), text);
  await tester.pumpAndSettle();
}

bool _canSave(WidgetTester tester) =>
    tester.widget<AppButton>(find.widgetWithText(AppButton, 'Save')).onTap !=
    null;

void main() {
  group('VLAN ID (issue #1754)', () {
    testWidgets('with VLAN on, Save waits for an ID of 3 to 4094',
        (tester) async {
      await _pump(tester);
      expect(_canSave(tester), isTrue, reason: 'the router ID 201');

      await _typeVlanId(tester, '2');
      expect(_canSave(tester), isFalse);
      expect(tester.widget<AppTextField>(_vlanId).errorText,
          'Must be between 3 and 4094');

      await _typeVlanId(tester, '');
      expect(_canSave(tester), isFalse, reason: 'the ID is required');

      await _typeVlanId(tester, '4094');
      expect(_canSave(tester), isTrue);
      expect(tester.widget<AppTextField>(_vlanId).errorText, isNull);
    });

    testWidgets('an empty ID shows no error, only holds Save', (tester) async {
      await _pump(tester);
      await _typeVlanId(tester, '');
      expect(tester.widget<AppTextField>(_vlanId).errorText, isNull);
    });

    testWidgets('the error shows as text', (tester) async {
      await _pump(tester);
      expect(tester.widget<AppTextField>(_vlanId).errorDisplayMode,
          AppErrorDisplayMode.text,
          reason: 'on web a tooltip opening on focus drops the focus, so '
              'nothing could be typed into a field in error (PR #1826)');
    });

    testWidgets('with VLAN removed, the ID is not checked', (tester) async {
      await _pump(tester);
      await _typeVlanId(tester, '2');

      await tester.tap(find.text('Remove VLAN ID'));
      await tester.pumpAndSettle();

      expect(_vlanId, findsNothing);
      expect(_canSave(tester), isTrue);
    });
  });
}
