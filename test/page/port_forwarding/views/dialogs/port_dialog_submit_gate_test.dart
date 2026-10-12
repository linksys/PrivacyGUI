import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/dashboard/views/dialogs/port_forwarding_dialog.dart';
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
  // The single-port dialog is opened from the Single Port tab and from the
  // dashboard card. The same FWDEV#204 rules apply, because FW 2.0.3 drops a
  // refused field on Add and still creates the rule (fwdev204_run2.log A-B).
  group('single port forwarding dialog', () {
    const lan = (ip: '192.168.1.1', mask: '255.255.255.0');
    const taken = PortForwardingRuleUIModel(
      description: 'Web',
      externalPort: 8080,
      internalPort: 80,
      internalClient: '192.168.1.60',
      protocol: 'UDP',
      enabled: false,
    );

    Future<void> fillValid(WidgetTester tester) async {
      await _type(tester, 'pf-single-description', 'Camera');
      await _type(tester, 'pf-single-external-port', '8080');
      await _type(tester, 'pf-single-internal-port', '80');
      await _type(tester, 'pf-single-internal-ip', '192.168.1.50');
      await _blur(tester, 'Add Port Forwarding');
    }

    Future<_Outcome<PortForwardingDialogResult>> open(WidgetTester tester) =>
        _pumpAndOpen<PortForwardingDialogResult>(
          tester,
          PortForwardingDialog(
            otherRules: const [taken],
            lanIp: lan.ip,
            lanSubnetMask: lan.mask,
          ),
        );

    Future<void> pick(WidgetTester tester, String protocol) async {
      await tester.ensureVisible(find.text(protocol));
      await tester.pumpAndSettle();
      await tester.tap(find.text(protocol));
      await tester.pumpAndSettle();
    }

    testWidgets(
        'a port another rule holds on a shared protocol is not '
        'submitted, and the error follows the protocol', (tester) async {
      final outcome = await open(tester);
      await fillValid(tester);
      expect(_errorTextOf(tester, 'pf-single-external-port'), isNull,
          reason: 'TCP does not collide with the UDP rule');

      await pick(tester, 'Both');
      expect(_errorTextOf(tester, 'pf-single-external-port'),
          startsWith('The rules cannot be created'));
      await tester.tap(find.bySemanticsIdentifier('pf-single-submit'));
      await tester.pumpAndSettle();
      expect(outcome.closed, isFalse);

      await pick(tester, 'TCP');
      expect(_errorTextOf(tester, 'pf-single-external-port'), isNull);
    }, variant: _onDesktop);

    testWidgets('a destination that is not a LAN host is not submitted',
        (tester) async {
      final outcome = await open(tester);
      await fillValid(tester);
      await tester.tap(_field('pf-single-internal-ip'));
      await _type(tester, 'pf-single-internal-ip', '192.168.1.1');
      await _blur(tester, 'Add Port Forwarding');

      await tester.tap(find.bySemanticsIdentifier('pf-single-submit'));
      await tester.pumpAndSettle();

      expect(outcome.closed, isFalse);
      expect(
          _errorTextOf(tester, 'pf-single-internal-ip'), 'Invalid IP address');
    }, variant: _onDesktop);

    testWidgets('a description over 32 bytes is not submitted', (tester) async {
      final outcome = await open(tester);
      await fillValid(tester);
      await tester.tap(_field('pf-single-description'));
      await _type(tester, 'pf-single-description', '網' * 11);
      await _blur(tester, 'Add Port Forwarding');

      await tester.tap(find.bySemanticsIdentifier('pf-single-submit'));
      await tester.pumpAndSettle();

      expect(outcome.closed, isFalse);
      expect(_errorTextOf(tester, 'pf-single-description'),
          'Must be 32 characters or less');
    }, variant: _onDesktop);

    testWidgets('a valid form submits what was typed', (tester) async {
      final outcome = await open(tester);
      await fillValid(tester);

      await tester.tap(find.bySemanticsIdentifier('pf-single-submit'));
      await tester.pumpAndSettle();

      expect(outcome.closed, isTrue);
      expect(outcome.result!.externalPort, 8080);
      expect(outcome.result!.internalClient, '192.168.1.50');
    }, variant: _onDesktop);
  });

  group('port range forwarding dialog', () {
    Future<void> fillValid(WidgetTester tester) async {
      await _type(tester, 'pf-range-external-port-start', '3000');
      await _type(tester, 'pf-range-external-port-end', '3010');
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
      await tester.tap(_field('pf-range-external-port-end'));
      await _type(tester, 'pf-range-external-port-end', '99999');
      // Still focused, so no error text yet: showing it mid-edit is what
      // rebuilds the field and drops focus. Only the gate has moved.
      expect(
        tester
            .widget<AppRangeInput>(find.byType(AppRangeInput).first)
            .errorText,
        isNull,
      );
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
      expect(r.internalClient, '192.168.1.50');
    }, variant: _onDesktop);

    // FWDEV#204: "Range rules: send InternalPort = ExternalPort (ports are
    // kept, as on 1.0)", and 1.x's range rule has no internal port at all
    // (#1080). FW 2.0.3 stores any value without checking it.
    testWidgets('has no internal port field, and forwards the start port',
        (tester) async {
      final outcome = await _pumpAndOpen<PortRangeForwardingDialogResult>(
        tester,
        const PortRangeForwardingDialog(),
      );

      expect(
          find.bySemanticsIdentifier('pf-range-internal-port'), findsNothing);

      await fillValid(tester);
      await tester.tap(find.bySemanticsIdentifier('pf-range-submit'));
      await tester.pumpAndSettle();

      expect(outcome.result!.internalPort, 3000);
    }, variant: _onDesktop);

    // FW 2.0.3 does not refuse a range over an existing single port: it stores
    // both rules, enabled and overlapping (fwdev204_run2.log B2). So the
    // dialog is the only place this can be stopped.
    testWidgets('a range overlapping another rule is not submitted',
        (tester) async {
      final outcome = await _pumpAndOpen<PortRangeForwardingDialogResult>(
        tester,
        const PortRangeForwardingDialog(
          otherRules: [
            PortForwardingRuleUIModel(
              description: 'Web',
              externalPort: 3005,
              internalPort: 80,
              internalClient: '192.168.1.60',
              protocol: 'Both',
              enabled: false,
            ),
          ],
        ),
      );
      await fillValid(tester);

      await tester.tap(find.bySemanticsIdentifier('pf-range-submit'));
      await tester.pumpAndSettle();

      expect(outcome.closed, isFalse);
      expect(
        tester
            .widget<AppRangeInput>(find.byType(AppRangeInput).first)
            .errorText,
        startsWith('The rules cannot be created'),
      );
    }, variant: _onDesktop);

    testWidgets(
        'switching the protocol onto a taken one shows the overlap, and back '
        'clears it', (tester) async {
      final outcome = await _pumpAndOpen<PortRangeForwardingDialogResult>(
        tester,
        const PortRangeForwardingDialog(
          otherRules: [
            PortForwardingRuleUIModel(
              description: 'Game',
              externalPort: 3005,
              internalPort: 3005,
              internalClient: '192.168.1.60',
              protocol: 'UDP',
              enabled: true,
            ),
          ],
        ),
      );
      await fillValid(tester);
      String? rangeError() => tester
          .widget<AppRangeInput>(find.byType(AppRangeInput).first)
          .errorText;
      expect(rangeError(), isNull, reason: 'TCP does not collide with UDP');

      // The error text makes the dialog taller, so scroll each segment into view
      // first, as a user would.
      Future<void> pick(String protocol) async {
        await tester.ensureVisible(find.text(protocol));
        await tester.pumpAndSettle();
        await tester.tap(find.text(protocol));
        await tester.pumpAndSettle();
      }

      await pick('UDP');
      expect(rangeError(), startsWith('The rules cannot be created'));

      await pick('TCP');
      expect(rangeError(), isNull);
      await tester.tap(find.bySemanticsIdentifier('pf-range-submit'));
      await tester.pumpAndSettle();
      expect(outcome.closed, isTrue);
    }, variant: _onDesktop);

    // FW 2.0.3 drops a destination that is not a LAN host and still creates
    // the rule, enabled, forwarding to nothing (fwdev204_run2.log A2-A4).
    for (final (ip, why) in const [
      ('192.168.1.1', 'the router itself'),
      ('10.9.9.9', 'outside the LAN subnet'),
      ('192.168.1.255', 'the broadcast address'),
      ('192.168.1.0', 'the network address'),
    ]) {
      testWidgets('a destination that is $why is not submitted',
          (tester) async {
        final outcome = await _pumpAndOpen<PortRangeForwardingDialogResult>(
          tester,
          const PortRangeForwardingDialog(
            lanIp: '192.168.1.1',
            lanSubnetMask: '255.255.255.0',
          ),
        );
        await fillValid(tester);
        await tester.tap(_field('pf-range-internal-ip'));
        await _type(tester, 'pf-range-internal-ip', ip);
        await _blur(tester, 'Add Port Range Forwarding');

        await tester.tap(find.bySemanticsIdentifier('pf-range-submit'));
        await tester.pumpAndSettle();

        expect(outcome.closed, isFalse);
        expect(
            _errorTextOf(tester, 'pf-range-internal-ip'), 'Invalid IP address');
      }, variant: _onDesktop);
    }

    // FW counts the description in bytes. Eleven CJK characters are 33 bytes,
    // which FW clears on Add while saving the rule (fwdev204_run2.log A1).
    testWidgets('a description over 32 bytes is not submitted', (tester) async {
      final outcome = await _pumpAndOpen<PortRangeForwardingDialogResult>(
        tester,
        const PortRangeForwardingDialog(),
      );
      await fillValid(tester);
      await tester.tap(_field('pf-range-description'));
      await _type(tester, 'pf-range-description', '網' * 11);
      await _blur(tester, 'Add Port Range Forwarding');

      await tester.tap(find.bySemanticsIdentifier('pf-range-submit'));
      await tester.pumpAndSettle();

      expect(outcome.closed, isFalse);
      expect(_errorTextOf(tester, 'pf-range-description'), 'Max 32 characters');
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

    // FWDEV#204: "1.0 used TCP+UDP for both, so send Both to match it", and
    // its trigger overlap check does not compare protocols. 1.x's trigger rule
    // has no protocol at all (#1080).
    testWidgets('has no protocol choice, and sends Both for both ranges',
        (tester) async {
      final outcome = await _pumpAndOpen<PortTriggeringDialogResult>(
        tester,
        const PortTriggeringDialog(),
      );

      expect(find.byType(SegmentedButton<String>), findsNothing);

      await fillValid(tester);
      await tester.tap(find.bySemanticsIdentifier('port-triggering-submit'));
      await tester.pumpAndSettle();

      expect(outcome.result!.triggerProtocol, 'Both');
      expect(outcome.result!.forwardProtocol, 'Both');
    }, variant: _onDesktop);

    testWidgets('a trigger range overlapping another rule\'s is not submitted',
        (tester) async {
      final outcome = await _pumpAndOpen<PortTriggeringDialogResult>(
        tester,
        const PortTriggeringDialog(
          otherRules: [
            PortTriggeringRuleUIModel(
              enabled: false,
              description: 'Chat',
              triggerPort: 90,
              triggerPortEndRange: 110,
              triggerProtocol: 'Both',
              forwardRules: [
                PortTriggerForwardRuleUIModel(
                  forwardPort: 5000,
                  forwardProtocol: 'Both',
                ),
              ],
            ),
          ],
        ),
      );
      await fillValid(tester);

      await tester.tap(find.bySemanticsIdentifier('port-triggering-submit'));
      await tester.pumpAndSettle();

      expect(outcome.closed, isFalse);
      expect(
        tester
            .widget<AppRangeInput>(find.byType(AppRangeInput).first)
            .errorText,
        startsWith('The rules cannot be created'),
      );
    }, variant: _onDesktop);

    testWidgets(
        'a forwarded range overlapping another rule\'s is not submitted',
        (tester) async {
      final outcome = await _pumpAndOpen<PortTriggeringDialogResult>(
        tester,
        const PortTriggeringDialog(
          otherRules: [
            PortTriggeringRuleUIModel(
              enabled: true,
              description: 'Chat',
              triggerPort: 9000,
              triggerProtocol: 'Both',
              forwardRules: [
                PortTriggerForwardRuleUIModel(
                  forwardPort: 190,
                  forwardPortEndRange: 210,
                  forwardProtocol: 'Both',
                ),
              ],
            ),
          ],
        ),
      );
      await fillValid(tester);

      await tester.tap(find.bySemanticsIdentifier('port-triggering-submit'));
      await tester.pumpAndSettle();

      expect(outcome.closed, isFalse);
      expect(
        tester.widget<AppRangeInput>(find.byType(AppRangeInput).last).errorText,
        startsWith('The rules cannot be created'),
      );
    }, variant: _onDesktop);

    testWidgets('a description over 32 bytes is not submitted', (tester) async {
      final outcome = await _pumpAndOpen<PortTriggeringDialogResult>(
        tester,
        const PortTriggeringDialog(),
      );
      await fillValid(tester);
      await tester.tap(_field('pf-trigger-description'));
      await _type(tester, 'pf-trigger-description', '網' * 11);
      await _blur(tester, 'Add Port Range Triggering');

      await tester.tap(find.bySemanticsIdentifier('port-triggering-submit'));
      await tester.pumpAndSettle();

      expect(outcome.closed, isFalse);
      expect(
          _errorTextOf(tester, 'pf-trigger-description'), 'Max 32 characters');
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
      // 1.x keeps no protocol for a trigger, so a stored UDP is saved as Both.
      expect(r.triggerProtocol, 'Both');
      expect(r.forwardProtocol, 'Both');
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
