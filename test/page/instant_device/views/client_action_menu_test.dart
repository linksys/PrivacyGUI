import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/page/instant_device/providers/client_removal_provider.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';
import 'package:privacy_gui/page/instant_device/views/client_action_menu.dart';

import '../../../common/config.dart';
import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';

const _client = DeviceListItem(
    deviceId: 'phone',
    name: 'Phone',
    macAddress: '02:00:00:00:00:01',
    isOnline: true);

class _Removals extends ClientRemovalService {
  _Removals(super.ref);
  final calls = <String>[];
  final restores = <String>[];
  bool restoreVerified = true;
  ClientRemovalOutcome outcome = ClientRemovalOutcome.disconnectRequested;
  Object? error;
  Future<void> Function()? beforeComplete;

  @override
  Future<ClientRemovalOutcome> remove(String deviceId) async {
    calls.add(deviceId);
    await beforeComplete?.call();
    if (error != null) throw error!;
    return outcome;
  }

  @override
  Future<bool> restore(String mac) async {
    restores.add(mac);
    await beforeComplete?.call();
    if (error != null) throw error!;
    return restoreVerified;
  }
}

void main() {
  mockDependencyRegister();
  late _Removals removals;
  late ValueNotifier<bool> visible;

  Future<void> pump(WidgetTester tester,
      {bool writable = true,
      bool mobile = false,
      bool restricted = false,
      DeviceListItem client = _client}) async {
    await tester.setScreenSize(mobile ? device480w : device1440w);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    when(serviceHelper.isSupportClientDeauth()).thenReturn(true);
    visible = ValueNotifier(true);
    addTearDown(visible.dispose);
    await tester.pumpWidget(testableSingleRoute(
      locale: const Locale('en'),
      overrides: [
        accessPolicyProvider
            .overrideWithValue(AccessPolicy(canWrite: writable)),
        clientRemovalProvider.overrideWith((ref) => removals = _Removals(ref)),
      ],
      child: Scaffold(
          body: ValueListenableBuilder<bool>(
        valueListenable: visible,
        builder: (_, show, __) => show
            ? ClientActionMenu(device: client, restricted: restricted)
            : const Text('Client left the list'),
      )),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> confirm(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Device actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(find.text('Remove: Phone'), findsOneWidget);
    expect(find.textContaining('then disconnect it now'), findsOneWidget);
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.tap(find.descendant(
        of: find.byType(AlertDialog), matching: find.text('Remove')));
    await tester.pumpAndSettle();
  }

  for (final mobile in [false, true]) {
    testWidgets(
        'confirmation removes only the selected live client (${mobile ? 'mobile' : 'desktop'})',
        (tester) async {
      await pump(tester, mobile: mobile);
      await confirm(tester);
      await submit(tester);
      expect(removals.calls, ['phone']);
      expect(find.text('WiFi access removed. A disconnect was requested.'),
          findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    });
  }

  testWidgets('cancelling never starts removal', (tester) async {
    await pump(tester);
    await confirm(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('read-only login cannot open the confirmation', (tester) async {
    await pump(tester, writable: false);
    await tester.tap(find.byTooltip('Device actions'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Remove'), findsNothing);
  });

  testWidgets('wired clients do not get WiFi removal', (tester) async {
    await pump(tester, client: _client.copyWith(isWired: true));
    expect(find.text('Remove'), findsNothing);
  });

  testWidgets('lack of deauth support is explained before confirmation',
      (tester) async {
    await pump(tester);
    when(serviceHelper.isSupportClientDeauth()).thenReturn(false);
    await tester.tap(find.byTooltip('Device actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(find.textContaining('does not support immediate disconnection'),
        findsOneWidget);
  });

  testWidgets('removed access with failed deauth reports partial success',
      (tester) async {
    await pump(tester);
    await confirm(tester);
    final container = ProviderScope.containerOf(
        tester.element(find.byType(ClientActionMenu)));
    container.read(clientRemovalProvider);
    removals.outcome = ClientRemovalOutcome.disconnectFailed;
    await submit(tester);
    expect(
        find.textContaining(
            'access removed, but the disconnect request failed'),
        findsOneWidget);
  });

  testWidgets('feedback survives the client disappearing during refresh',
      (tester) async {
    await pump(tester);
    await confirm(tester);
    final container = ProviderScope.containerOf(
        tester.element(find.byType(ClientActionMenu)));
    container.read(clientRemovalProvider);
    removals.beforeComplete = () async {
      visible.value = false;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    };
    await submit(tester);
    expect(find.byType(ClientActionMenu), findsNothing);
    expect(find.text('WiFi access removed. A disconnect was requested.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('self-removal refusal is shown without a success message',
      (tester) async {
    await pump(tester);
    await confirm(tester);
    final container = ProviderScope.containerOf(
        tester.element(find.byType(ClientActionMenu)));
    container.read(clientRemovalProvider);
    removals.error =
        const ClientRemovalException(ClientRemovalFailure.protectedDevice);
    await submit(tester);
    expect(
        find.text(
            'Your current device and mesh connections cannot be removed.'),
        findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('WiFi access removed'), findsNothing);
  });

  testWidgets(
      'readback uncertainty is reported without claiming removed access',
      (tester) async {
    await pump(tester);
    await confirm(tester);
    final container = ProviderScope.containerOf(
        tester.element(find.byType(ClientActionMenu)));
    container.read(clientRemovalProvider);
    removals.outcome = ClientRemovalOutcome.unverified;
    await submit(tester);
    expect(find.textContaining('The removal could not be verified'),
        findsOneWidget);
    expect(find.textContaining('WiFi access removed'), findsNothing);
  });

  testWidgets('menu offers no traffic Block action', (tester) async {
    await pump(tester);
    await tester.tap(find.byTooltip('Device actions'));
    await tester.pumpAndSettle();
    expect(find.text('Remove'), findsOneWidget);
    expect(find.text('Block'), findsNothing);
    expect(find.textContaining('Coming soon'), findsNothing);
  });

  for (final verified in [true, false]) {
    testWidgets(
        'restore reports verification $verified after the row disappears',
        (tester) async {
      await pump(tester,
          restricted: true, client: _client.copyWith(isOnline: false));
      await tester.tap(find.byTooltip('Device actions'));
      await tester.pumpAndSettle();
      expect(find.text('Remove'), findsNothing);
      await tester.tap(find.text('Restore access'));
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
          tester.element(find.byType(ClientActionMenu)));
      container.read(clientRemovalProvider);
      removals.restoreVerified = verified;
      removals.beforeComplete = () async {
        visible.value = false;
        await Future<void>.delayed(const Duration(milliseconds: 100));
      };
      await tester.tap(find.descendant(
          of: find.byType(AlertDialog), matching: find.text('Restore access')));
      await tester.pumpAndSettle();
      expect(removals.restores, [_client.macAddress]);
      expect(
          find.text(verified
              ? 'WiFi access restored. The device can reconnect.'
              : 'Restored access could not be verified. Refresh the access rules before retrying.'),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
