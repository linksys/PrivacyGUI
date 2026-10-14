import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/page/instant_device/providers/client_block_provider.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';
import 'package:privacy_gui/page/instant_device/views/client_block_button.dart';

import '../../../common/config.dart';
import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';

const _client = DeviceListItem(
    deviceId: 'phone',
    name: 'Phone',
    macAddress: '02:00:00:00:00:01',
    isOnline: true);

class _Blocks extends ClientBlockService {
  _Blocks(super.ref);
  final calls = <String>[];
  ClientBlockOutcome outcome = ClientBlockOutcome.disconnectRequested;
  Object? error;
  Future<void> Function()? beforeComplete;

  @override
  Future<ClientBlockOutcome> block(String deviceId) async {
    calls.add(deviceId);
    await beforeComplete?.call();
    if (error != null) throw error!;
    return outcome;
  }
}

void main() {
  mockDependencyRegister();
  late _Blocks blocks;
  late ValueNotifier<bool> visible;

  Future<void> pump(WidgetTester tester,
      {bool writable = true,
      bool mobile = false,
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
        clientBlockProvider.overrideWith((ref) => blocks = _Blocks(ref)),
      ],
      child: Scaffold(
          body: ValueListenableBuilder<bool>(
        valueListenable: visible,
        builder: (_, show, __) => show
            ? ClientBlockButton(device: client)
            : const Text('Client left the list'),
      )),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> confirm(WidgetTester tester) async {
    await tester.tap(find.text('Block'));
    await tester.pumpAndSettle();
    expect(find.text('Block: Phone'), findsOneWidget);
    expect(find.textContaining('then disconnect it now'), findsOneWidget);
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.tap(find.descendant(
        of: find.byType(AlertDialog), matching: find.text('Block')));
    await tester.pumpAndSettle();
  }

  for (final mobile in [false, true]) {
    testWidgets(
        'confirmation blocks only the selected live client (${mobile ? 'mobile' : 'desktop'})',
        (tester) async {
      await pump(tester, mobile: mobile);
      await confirm(tester);
      await submit(tester);
      expect(blocks.calls, ['phone']);
      expect(find.text('WiFi block saved. A disconnect was requested.'),
          findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    });
  }

  testWidgets('cancelling never starts blocking', (tester) async {
    await pump(tester);
    await confirm(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('read-only login cannot open the confirmation', (tester) async {
    await pump(tester, writable: false);
    await tester.tap(find.text('Block'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('wired clients do not get WiFi blocking', (tester) async {
    await pump(tester, client: _client.copyWith(isWired: true));
    expect(find.text('Block'), findsNothing);
  });

  testWidgets('lack of deauth support is explained before confirmation',
      (tester) async {
    await pump(tester);
    when(serviceHelper.isSupportClientDeauth()).thenReturn(false);
    await tester.tap(find.text('Block'));
    await tester.pumpAndSettle();
    expect(find.textContaining('does not support immediate disconnection'),
        findsOneWidget);
  });

  testWidgets('a saved block with failed deauth reports partial success',
      (tester) async {
    await pump(tester);
    await confirm(tester);
    final container = ProviderScope.containerOf(
        tester.element(find.byType(ClientBlockButton)));
    container.read(clientBlockProvider);
    blocks.outcome = ClientBlockOutcome.disconnectFailed;
    await submit(tester);
    expect(
        find.textContaining('block saved, but the disconnect request failed'),
        findsOneWidget);
  });

  testWidgets('feedback survives the client disappearing during refresh',
      (tester) async {
    await pump(tester);
    await confirm(tester);
    final container = ProviderScope.containerOf(
        tester.element(find.byType(ClientBlockButton)));
    container.read(clientBlockProvider);
    blocks.beforeComplete = () async {
      visible.value = false;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    };
    await submit(tester);
    expect(find.byType(ClientBlockButton), findsNothing);
    expect(find.text('WiFi block saved. A disconnect was requested.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('self-block refusal is shown without a success message',
      (tester) async {
    await pump(tester);
    await confirm(tester);
    final container = ProviderScope.containerOf(
        tester.element(find.byType(ClientBlockButton)));
    container.read(clientBlockProvider);
    blocks.error =
        const ClientBlockException(ClientBlockFailure.protectedDevice);
    await submit(tester);
    expect(
        find.text(
            'Your current device and mesh connections cannot be blocked.'),
        findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('WiFi block saved'), findsNothing);
  });

  testWidgets('readback uncertainty is reported without claiming a saved block',
      (tester) async {
    await pump(tester);
    await confirm(tester);
    final container = ProviderScope.containerOf(
        tester.element(find.byType(ClientBlockButton)));
    container.read(clientBlockProvider);
    blocks.outcome = ClientBlockOutcome.unverified;
    await submit(tester);
    expect(
        find.textContaining('The block could not be verified'), findsOneWidget);
    expect(find.textContaining('WiFi block saved'), findsNothing);
  });
}
