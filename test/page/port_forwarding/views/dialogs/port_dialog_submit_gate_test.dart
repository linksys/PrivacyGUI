import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_triggering_rule_ui_model.dart';
import 'package:privacy_gui/page/port_forwarding/views/dialogs/port_range_forwarding_dialog.dart';
import 'package:privacy_gui/page/port_forwarding/views/dialogs/port_triggering_dialog.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// The submit gate of the two Port Forwarding page dialogs (linksys/PrivacyGUI#1543).
///
/// Each dialog is opened through `showAppDialog`, the path its tab uses, and is
/// judged only by what it pops: nothing while it stays open, the result once it
/// closes.
///
/// What these tests reproduce is the stale gate letting a bad value through —
/// both dialogs close with `99999` before the fix. They do not reproduce the
/// browser-only half of #1543, where the button went disabled mid-press and the
/// release dismissed the dialog: that needs the release build's semantics
/// overlay, which a widget test does not have. Asserting the dialog stayed open
/// catches both.
///
/// Every test runs as macOS ([_onDesktop]), the desktop target the bug was
/// measured on, so a tap outside a field unfocuses it as it does there. The
/// gate tests fail on the old code under the default Android target too, so
/// this is fidelity rather than what makes them work.
final _onDesktop = TargetPlatformVariant.only(TargetPlatform.macOS);

final _testTheme = AppTheme.create(
  brightness: Brightness.light,
  seedColor: Colors.blue,
  designThemeBuilder: (c) => CustomDesignTheme.fromJson({'style': 'flat'}),
);

/// What the dialog popped with. [closed] is false while it is still open.
class _Outcome<T> {
  bool closed = false;
  T? result;
}

Future<_Outcome<T>> _pumpAndOpen<T>(WidgetTester tester, Widget dialog) async {
  final outcome = _Outcome<T>();
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () async {
                  outcome.result = await showAppDialog<T>(
                    context: context,
                    builder: (_) => dialog,
                  );
                  outcome.closed = true;
                },
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
  return outcome;
}

/// The editable field carrying [identifier].
Finder _field(String identifier) => find.descendant(
      of: find.bySemanticsIdentifier(identifier),
      matching: find.byType(EditableText),
    );

/// The error the field carrying [identifier] has been handed to show.
String? _errorTextOf(WidgetTester tester, String identifier) => tester
    .widget<AppTextField>(find.ancestor(
      of: find.bySemanticsIdentifier(identifier),
      matching: find.byType(AppTextField),
    ))
    .errorText;

Future<void> _type(WidgetTester tester, String identifier, String text) async {
  await tester.enterText(_field(identifier), text);
  await tester.pump();
}

/// Leaves the field that has focus the way a click elsewhere would. It taps the
/// title, which is inert, so the click cannot land on a control and change the
/// form the way a tap at the dialog's centre could.
Future<void> _blur(WidgetTester tester, String title) async {
  await tester.tap(find.text(title));
  await tester.pump();
}

void main() {
  group('port range forwarding dialog', () {
    Future<void> fillValid(WidgetTester tester) async {
      await _type(tester, 'pf-range-external-port-start', '3000');
      await _type(tester, 'pf-range-external-port-end', '3010');
      await _type(tester, 'pf-range-internal-port', '3000');
      await _type(tester, 'pf-range-internal-ip', '192.168.1.50');
      await _blur(tester, 'Add Port Range Forwarding');
    }

    testWidgets(
        'an out-of-range port typed into a field that still has focus is not '
        'submitted', (tester) async {
      final outcome = await _pumpAndOpen<PortRangeForwardingDialogResult>(
        tester,
        const PortRangeForwardingDialog(),
      );
      await fillValid(tester);

      // Retype one box and press Add without leaving it first.
      await tester.tap(_field('pf-range-internal-port'));
      await _type(tester, 'pf-range-internal-port', '99999');
      // Still focused, so no error text yet: showing it mid-edit is what
      // rebuilds the field and drops focus. Only the gate has moved.
      expect(_errorTextOf(tester, 'pf-range-internal-port'), isNull);
      await tester.tap(find.bySemanticsIdentifier('pf-range-submit'));
      await tester.pumpAndSettle();

      expect(outcome.closed, isFalse,
          reason: '99999 is not a port, so Add must not close the dialog');
    }, variant: _onDesktop);

    testWidgets('a valid form submits what was typed', (tester) async {
      final outcome = await _pumpAndOpen<PortRangeForwardingDialogResult>(
        tester,
        const PortRangeForwardingDialog(),
      );
      await fillValid(tester);

      await tester.tap(find.bySemanticsIdentifier('pf-range-submit'));
      await tester.pumpAndSettle();

      expect(outcome.closed, isTrue);
      final r = outcome.result!;
      expect(r.externalPortStart, 3000);
      expect(r.externalPortEnd, 3010);
      expect(r.internalPort, 3000);
      expect(r.internalClient, '192.168.1.50');
    }, variant: _onDesktop);

    testWidgets(
        'editing only the description of a stored rule saves, and keeps its '
        'ports', (tester) async {
      final outcome = await _pumpAndOpen<PortRangeForwardingDialogResult>(
        tester,
        const PortRangeForwardingDialog(
          rule: PortForwardingRuleUIModel(
            instancePath: 'Device.NAT.PortMapping.1.',
            description: 'Game',
            externalPort: 3074,
            externalPortEndRange: 3080,
            internalPort: 3074,
            internalClient: '192.168.1.50',
            protocol: 'UDP',
            enabled: true,
          ),
        ),
      );

      await tester.tap(_field('pf-range-description'));
      await _type(tester, 'pf-range-description', 'Game console');
      await _blur(tester, 'Edit Port Range Forwarding');
      await tester.tap(find.bySemanticsIdentifier('pf-range-submit'));
      await tester.pumpAndSettle();

      expect(outcome.closed, isTrue);
      final r = outcome.result!;
      expect(r.description, 'Game console');
      expect(r.externalPortStart, 3074);
      expect(r.externalPortEnd, 3080);
      expect(r.internalPort, 3074);
      expect(r.protocol, 'UDP');
    }, variant: _onDesktop);

    testWidgets(
        'editing a stored rule that is already invalid shows why on open, '
        'before any field is touched', (tester) async {
      // The router accepts what this dialog refuses (a description over 32
      // characters), so such a rule can come back from the device. With a live
      // gate, Save is disabled from the first frame; the reason has to be on
      // screen from the first frame too, not after a blur nobody has made.
      await _pumpAndOpen<PortRangeForwardingDialogResult>(
        tester,
        PortRangeForwardingDialog(
          rule: PortForwardingRuleUIModel(
            instancePath: 'Device.NAT.PortMapping.1.',
            description: 'x' * 33,
            externalPort: 3000,
            externalPortEndRange: 3010,
            internalPort: 3000,
            internalClient: '192.168.1.50',
            protocol: 'TCP',
            enabled: true,
          ),
        ),
      );

      // A field shows its error as a hover tooltip, so the text is not in the
      // tree to find; the field's `errorText` is what decides whether it shows.
      expect(_errorTextOf(tester, 'pf-range-description'), 'Max 32 characters');
    }, variant: _onDesktop);
  });

  group('port triggering dialog', () {
    // Only the two start ports are required here, so this is the form where a
    // bad value is easiest to reach with Add already enabled.
    Future<void> fillValid(WidgetTester tester) async {
      await _type(tester, 'pf-trigger-trigger-port-start', '100');
      await _type(tester, 'pf-trigger-forward-port-start', '200');
      await _blur(tester, 'Add Port Range Triggering');
    }

    testWidgets(
        'an out-of-range port typed into a field that still has focus is not '
        'submitted', (tester) async {
      final outcome = await _pumpAndOpen<PortTriggeringDialogResult>(
        tester,
        const PortTriggeringDialog(),
      );
      await fillValid(tester);

      await tester.tap(_field('pf-trigger-trigger-port-start'));
      await _type(tester, 'pf-trigger-trigger-port-start', '99999');
      // Same as the range dialog: no error text while the box is focused. The
      // pair's one error slot is on the range input, not on either box.
      expect(
        tester
            .widget<AppRangeInput>(find.byType(AppRangeInput).first)
            .errorText,
        isNull,
      );
      await tester.tap(find.bySemanticsIdentifier('port-triggering-submit'));
      await tester.pumpAndSettle();

      expect(outcome.closed, isFalse,
          reason: '99999 is not a port, so Add must not close the dialog');
    }, variant: _onDesktop);

    testWidgets('a valid form submits what was typed', (tester) async {
      final outcome = await _pumpAndOpen<PortTriggeringDialogResult>(
        tester,
        const PortTriggeringDialog(),
      );
      await fillValid(tester);

      await tester.tap(find.bySemanticsIdentifier('port-triggering-submit'));
      await tester.pumpAndSettle();

      expect(outcome.closed, isTrue);
      final r = outcome.result!;
      expect(r.triggerPort, 100);
      expect(r.forwardPort, 200);
      // An empty end box means a single port, which the model stores as 0.
      expect(r.triggerPortEndRange, 0);
      expect(r.forwardPortEndRange, 0);
    }, variant: _onDesktop);

    testWidgets(
        'editing only the description of a stored rule saves, and keeps its '
        'ports', (tester) async {
      final outcome = await _pumpAndOpen<PortTriggeringDialogResult>(
        tester,
        const PortTriggeringDialog(
          rule: PortTriggeringRuleUIModel(
            instancePath: 'Device.NAT.PortTrigger.1.',
            enabled: true,
            description: 'Game',
            triggerPort: 6112,
            triggerProtocol: 'TCP',
            forwardRules: [
              PortTriggerForwardRuleUIModel(
                forwardPort: 6113,
                forwardPortEndRange: 6119,
                forwardProtocol: 'UDP',
              ),
            ],
          ),
        ),
      );

      await tester.tap(_field('pf-trigger-description'));
      await _type(tester, 'pf-trigger-description', 'Game console');
      await _blur(tester, 'Edit Port Range Triggering');
      await tester.tap(find.bySemanticsIdentifier('port-triggering-submit'));
      await tester.pumpAndSettle();

      expect(outcome.closed, isTrue);
      final r = outcome.result!;
      expect(r.description, 'Game console');
      expect(r.triggerPort, 6112);
      expect(r.triggerPortEndRange, 0);
      expect(r.forwardPort, 6113);
      expect(r.forwardPortEndRange, 6119);
      expect(r.forwardProtocol, 'UDP');
    }, variant: _onDesktop);

    testWidgets(
        'a stored rule whose end port equals its start port is a single port, '
        'and saves without the end box being cleared', (tester) async {
      // The model reads `end == start` as a single port, the same as `end == 0`
      // (`triggerPortDisplay`, `portDisplay`). Prefilling that end into the box
      // made the validator's `end > start` check reject a rule that is fine.
      final outcome = await _pumpAndOpen<PortTriggeringDialogResult>(
        tester,
        const PortTriggeringDialog(
          rule: PortTriggeringRuleUIModel(
            instancePath: 'Device.NAT.PortTrigger.1.',
            enabled: true,
            description: 'Game',
            triggerPort: 6112,
            triggerPortEndRange: 6112,
            triggerProtocol: 'TCP',
            forwardRules: [
              PortTriggerForwardRuleUIModel(
                forwardPort: 6113,
                forwardPortEndRange: 6113,
                forwardProtocol: 'TCP',
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.bySemanticsIdentifier('port-triggering-submit'));
      await tester.pumpAndSettle();

      expect(outcome.closed, isTrue);
      final r = outcome.result!;
      expect(r.triggerPort, 6112);
      expect(r.forwardPort, 6113);
      // Saved back in the single-port form the dialog writes for an empty box.
      expect(r.triggerPortEndRange, 0);
      expect(r.forwardPortEndRange, 0);
    }, variant: _onDesktop);

    testWidgets(
        'a stored end port below the start is still shown, so the broken rule '
        'is flagged rather than saved as a single port', (tester) async {
      final outcome = await _pumpAndOpen<PortTriggeringDialogResult>(
        tester,
        const PortTriggeringDialog(
          rule: PortTriggeringRuleUIModel(
            instancePath: 'Device.NAT.PortTrigger.1.',
            enabled: true,
            description: 'Game',
            triggerPort: 6112,
            triggerPortEndRange: 6100,
            triggerProtocol: 'TCP',
            forwardRules: [
              PortTriggerForwardRuleUIModel(
                forwardPort: 6113,
                forwardProtocol: 'TCP',
              ),
            ],
          ),
        ),
      );

      expect(
        tester
            .widget<AppRangeInput>(find.byType(AppRangeInput).first)
            .errorText,
        'Must be greater than start port',
      );
      await tester.tap(find.bySemanticsIdentifier('port-triggering-submit'));
      await tester.pumpAndSettle();
      expect(outcome.closed, isFalse);
    }, variant: _onDesktop);

    testWidgets(
        'editing a stored rule that is already invalid shows why on open, '
        'before any field is touched', (tester) async {
      await _pumpAndOpen<PortTriggeringDialogResult>(
        tester,
        PortTriggeringDialog(
          rule: PortTriggeringRuleUIModel(
            instancePath: 'Device.NAT.PortTrigger.1.',
            enabled: true,
            description: 'x' * 33,
            triggerPort: 100,
            triggerProtocol: 'TCP',
            forwardRules: const [
              PortTriggerForwardRuleUIModel(
                forwardPort: 200,
                forwardProtocol: 'TCP',
              ),
            ],
          ),
        ),
      );

      expect(
          _errorTextOf(tester, 'pf-trigger-description'), 'Max 32 characters');
    }, variant: _onDesktop);
  });
}
