import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_state.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/login/auto_parent/views/auto_parent_first_login_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/route_model.dart';

import '../../../../common/config.dart';
import '../../../../common/di.dart';
import '../../../../common/recording_polling.dart';
import '../../../../common/router_boundary.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../common/testable_router.dart';

/// The firmware update as the first login meets it: one update is available.
/// An install goes as the real provider takes it. `isUpdating` turns on;
/// then either the router refuses the install, which turns `isUpdating` off
/// and rethrows, or it accepts it, and `isUpdating` turns off once
/// [finishInstall] says the router is done.
class _FirmwareStub extends FirmwareUpdateNotifier {
  _FirmwareStub({required this.refuse});

  final bool refuse;

  @override
  FirmwareUpdateState build() => FirmwareUpdateState.empty();

  @override
  Future fetchAvailableFirmwareUpdates() async {}

  @override
  bool isFailedCheckFirmwareUpdate() => false;

  @override
  int getAvailableUpdateNumber() => 1;

  @override
  Future updateFirmware() async {
    state = state.copyWith(isUpdating: true);
    if (refuse) {
      state = state.copyWith(isUpdating: false);
      throw const JNAPError(result: 'ErrorUnknown');
    }
  }

  void finishInstall() => state = state.copyWith(isUpdating: false);
}

void main() {
  mockDependencyRegister();

  late RouterBoundary router;
  late ProviderContainer container;
  late _FirmwareStub firmware;

  Future<void> openFirstLogin(WidgetTester tester,
      {required bool refuse}) async {
    router = RouterBoundary()
      ..holds(JNAPAction.getInternetConnectionStatus,
          {'connectionStatus': 'InternetConnected'})
      ..holds(JNAPAction.getFirmwareUpdateSettings, {
        'updatePolicy': 'AutomaticallyCheckAndInstall',
        'autoUpdateWindow': {'startMinute': 0, 'durationMinutes': 240},
      });
    firmware = _FirmwareStub(refuse: refuse);
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(router.repo),
      pollingProvider.overrideWith(() => RecordingPolling()),
      firmwareUpdateProvider.overrideWith(() => firmware),
    ]);
    addTearDown(container.dispose);
    await tester.setScreenSize(device1440w);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(testableRouter(
      provider: container,
      locale: const Locale('en'),
      router: GoRouter(initialLocation: '/', routes: [
        LinksysRoute(
          path: '/',
          builder: (_, __) => const AutoParentFirstLoginView(),
        ),
        LinksysRoute(
          path: '/dashboard',
          name: RouteNamed.dashboardHome,
          builder: (_, __) => const Text('dashboard'),
        ),
      ]),
    ));
  }

  testWidgets(
      'a refused install ends the first login once, as a failed check, '
      'without acknowledging auto-configuration', (tester) async {
    await openFirstLogin(tester, refuse: true);
    await tester.pumpAndSettle();

    expect(find.text('dashboard'), findsOneWidget);
    expect(router.actions,
        isNot(contains(JNAPAction.setUserAcknowledgedAutoConfiguration)));
    // The update policy is set once: the first login finished once.
    expect(
        router.payloadsOf(JNAPAction.setFirmwareUpdateSettings), hasLength(1));
  });

  testWidgets(
      'an accepted install ends the first login once the router is done, '
      'and acknowledges auto-configuration', (tester) async {
    await openFirstLogin(tester, refuse: false);
    await tester.pump();
    await tester.pump();
    expect(find.text('dashboard'), findsNothing);

    firmware.finishInstall();
    await tester.pumpAndSettle();

    expect(find.text('dashboard'), findsOneWidget);
    expect(router.payloadsOf(JNAPAction.setUserAcknowledgedAutoConfiguration),
        hasLength(1));
    expect(
        router.payloadsOf(JNAPAction.setFirmwareUpdateSettings), hasLength(1));
  });
}
