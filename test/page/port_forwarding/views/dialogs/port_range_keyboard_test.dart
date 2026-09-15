import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/ipv6_port_service/views/dialogs/ipv6_port_service_rule_dialog.dart';
import 'package:privacy_gui/page/port_forwarding/views/dialogs/port_range_forwarding_dialog.dart';
import 'package:privacy_gui/page/port_forwarding/views/dialogs/port_triggering_dialog.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Pins the numeric keyboard on every `AppRangeInput` port pair in the app
/// (linksys/PrivacyGUI#1537, upstream privacyGUI-UI-kit#90).
///
/// The three port-forwarding pairs regressed in #1536: each box used to be its
/// own `AppTextField` carrying `keyboardType: TextInputType.number`, and
/// migrating the pair onto `AppRangeInput` dropped it because the kit exposed no
/// such parameter. The IPv6 pair never had one. **v3.3.0** added it — the version
/// this repo already pins (`pubspec.yaml`, `resolved-ref`
/// `5e325b536ade05406508b1c03a04cf22a56f7e48`; absent at v3.2.0, present there) —
/// so this needs no kit bump. It defaults to `TextInputType.text`, so every call
/// site must pass it explicitly and nothing in the kit makes a numeric pair
/// numeric for free.
///
/// The assertions read the keyboard off the rendered `TextField`s, not off the
/// `AppRangeInput` widget this test would otherwise be handing the value to.
/// That distinction is the point: the kit's merged branch (`mergeContainers:
/// true`, which `flat` — the app's default style — authors) forwards each
/// parameter to a bare `TextField` BY HAND, and the kit's own source records
/// `enabled` and `inputStyle` having been dropped exactly that way. A test that
/// asserted `AppRangeInput.keyboardType` would pass against a kit that accepts
/// the parameter and forwards nothing.
final _testTheme = AppTheme.create(
  brightness: Brightness.light,
  seedColor: Colors.blue,
  designThemeBuilder: (c) => CustomDesignTheme.fromJson({'style': 'flat'}),
);

/// Pumps [dialog] through the same `showAppDialog` path the pages use and opens
/// it.
Future<void> _pumpAndOpen(WidgetTester tester, Widget dialog) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showAppDialog<void>(
                  context: context,
                  builder: (_) => dialog,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ],
  );

  await tester.pumpWidget(MaterialApp.router(
    theme: _testTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: router,
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

/// Every `TextField` rendered by the [AppRangeInput] at [index], in the order
/// the kit builds them (start, then end).
List<TextField> _rangeFields(WidgetTester tester, int index) {
  final ranges = find.byType(AppRangeInput);
  expect(
    ranges,
    findsAtLeastNWidgets(index + 1),
    reason: 'expected an AppRangeInput at index $index',
  );
  final fields = find
      .descendant(of: ranges.at(index), matching: find.byType(TextField))
      .evaluate()
      .map((e) => e.widget as TextField)
      .toList();
  expect(
    fields.length,
    2,
    reason: 'an AppRangeInput renders exactly two boxes; if this changed, the '
        'keyboard assertion below is reading the wrong widget',
  );
  return fields;
}

void _expectNumericPair(WidgetTester tester, int index, String what) {
  for (final field in _rangeFields(tester, index)) {
    expect(
      field.keyboardType,
      TextInputType.number,
      reason: '$what is a port pair, so it must raise the numeric keyboard '
          '(#1537). The kit defaults to TextInputType.text, so this only '
          'passes if the call site passes keyboardType explicitly.',
    );
  }
}

void main() {
  group('#1537 AppRangeInput port pairs raise the numeric keyboard', () {
    testWidgets('port triggering: both the trigger and forward pairs',
        (tester) async {
      await _pumpAndOpen(tester, const PortTriggeringDialog());

      expect(find.byType(AppRangeInput), findsNWidgets(2));
      _expectNumericPair(tester, 0, 'the trigger port range');
      _expectNumericPair(tester, 1, 'the forwarded port range');
    });

    testWidgets('port range forwarding: the external pair', (tester) async {
      await _pumpAndOpen(
        tester,
        const PortRangeForwardingDialog(deviceOptions: []),
      );

      expect(find.byType(AppRangeInput), findsOneWidget);
      _expectNumericPair(tester, 0, 'the external port range');
    });

    // Never had a numeric keyboard — predates #1536 and is why #1537 covers the
    // project rather than just the two dialogs that regressed.
    testWidgets('ipv6 port service rule: the port pair', (tester) async {
      await _pumpAndOpen(tester, const Ipv6PortServiceRuleDialog());

      expect(find.byType(AppRangeInput), findsOneWidget);
      _expectNumericPair(tester, 0, 'the IPv6 service port range');
    });
  });
}
