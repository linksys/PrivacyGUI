import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:async';

import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_provider.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_state.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/page/components/styled/remote_assistance/remote_assistance_dialog.dart';

import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacygui_widgets/theme/_theme.dart';

import '../../../../common/theme_data.dart';

/// The generated `MockPollingNotifier` overrides only the `paused` setter, so
/// reading the getter returns null and fails its bool cast before mockito can
/// stub it. Extending the real notifier keeps `paused` working and only stubs out
/// the two things that would reach the network.
class _FakePollingNotifier extends PollingNotifier {
  @override
  FutureOr<CoreTransactionData> build() =>
      const CoreTransactionData(lastUpdate: 0, isReady: false, data: {});

  @override
  void checkAndStartPolling([bool force = false]) {}
}

/// Lets the test move the session between statuses without a cloud service, and
/// keeps the passive dialog from opening a real stream.
class _TestRemoteClientNotifier extends RemoteClientNotifier {
  _TestRemoteClientNotifier(this._initial);

  final RemoteClientState _initial;

  @override
  RemoteClientState build() => _initial;

  @override
  void startSessionInfoStream() {}

  void emit(RemoteClientState next) => state = next;
}

void main() {
  /// `testableWidget` wraps only `home` in [CustomResponsive], and a dialog is a
  /// separate route, so widgets inside one cannot reach the `CustomTheme` it
  /// provides. Production puts it in `MaterialApp.builder` (app.dart), which does
  /// cover routes, so this mirrors that rather than the shared harness.
  Widget harness({
    required List<Override> overrides,
    required Widget child,
  }) =>
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          theme: mockLightThemeData,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, routeChild) =>
              CustomResponsive(child: routeChild ?? const SizedBox.shrink()),
          home: Scaffold(body: child),
        ),
      );

  /// [WidgetTester.pumpAndSettle] cannot be used here: the ACTIVE state renders
  /// [RemoteAssistanceAnimation], which loops, so there is never a frame with
  /// nothing scheduled. Pump a fixed span instead - enough for the dialog route
  /// transition and any provider listener to run.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// The dialog content is a fixed 400x400 box, which does not fit the default
  /// 800x600 test surface once the title and actions are added.
  void useLargeSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1400, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  GRASessionInfo sessionWith(GRASessionStatus status) => GRASessionInfo(
        id: 'session-1',
        serialNumber: 'TEST123',
        modelNumber: 'LN16-EU',
        status: status,
        expiredIn: 2547,
        createdAt: 1748315872000,
        statusChangedAt: 1748315989000,
        currentTime: 1748316924838,
      );

  // #1559: nothing on the client side reacted to a session leaving ACTIVE, so
  // the dialog sat there as though the session were still running.
  testWidgets('leaving ACTIVE closes the dialog and says the session ended',
      (tester) async {
    final notifier = _TestRemoteClientNotifier(
        RemoteClientState(sessionInfo: sessionWith(GRASessionStatus.active)));
    final polling = _FakePollingNotifier();
    useLargeSurface(tester);

    await tester.pumpWidget(harness(
      overrides: [
        remoteClientProvider.overrideWith(() => notifier),
        pollingProvider.overrideWith(() => polling),
      ],
      child: Consumer(
        builder: (context, ref, child) => TextButton(
          onPressed: () =>
              showRemoteAssistanceDialog(context, ref, isPassive: true),
          child: const Text('open'),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await settle(tester);
    expect(find.text('Close'), findsOneWidget, reason: 'dialog should be open');

    // The Guardian ends the session, or a new one replaces it. Every exit from
    // ACTIVE observed in the field went to INITIATE, never to INVALID.
    notifier.emit(
        RemoteClientState(sessionInfo: sessionWith(GRASessionStatus.initiate)));
    await settle(tester);

    expect(find.text('Close'), findsNothing,
        reason: 'the dialog should have closed itself');
    expect(find.text('Session expired'), findsOneWidget,
        reason: 'the user should be told, not left guessing');
  });

  testWidgets('a session that stays ACTIVE leaves the dialog alone',
      (tester) async {
    final notifier = _TestRemoteClientNotifier(
        RemoteClientState(sessionInfo: sessionWith(GRASessionStatus.active)));
    final polling = _FakePollingNotifier();
    useLargeSurface(tester);

    await tester.pumpWidget(harness(
      overrides: [
        remoteClientProvider.overrideWith(() => notifier),
        pollingProvider.overrideWith(() => polling),
      ],
      child: Consumer(
        builder: (context, ref, child) => TextButton(
          onPressed: () =>
              showRemoteAssistanceDialog(context, ref, isPassive: true),
          child: const Text('open'),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await settle(tester);

    // A fresh countdown value is a state change that must not be mistaken for
    // the session ending.
    notifier.emit(RemoteClientState(
        sessionInfo: sessionWith(GRASessionStatus.active),
        expiredCountdown: 2500));
    await settle(tester);

    expect(find.text('Close'), findsOneWidget);
    expect(find.text('Session expired'), findsNothing);
  });
}
