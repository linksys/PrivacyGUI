import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/cloud/linksys_device_cloud_service.dart';
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_provider.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_state.dart';
import 'package:privacy_gui/core/jnap/models/device.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';

import '../../../common/config.dart';
import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';

class _FakeAuth extends AuthNotifier {
  _FakeAuth(this.loginType);
  final LoginType loginType;

  @override
  Future<AuthState> build() async => AuthState(loginType: loginType);
}

/// Stands in for polling: the test sets [state] to model a poll landing.
class _FakeDeviceManager extends DeviceManagerNotifier {
  _FakeDeviceManager(this.initial);
  final DeviceManagerState initial;

  @override
  DeviceManagerState build() => initial;
}

class _FakeDashboardHome extends DashboardHomeNotifier {
  @override
  DashboardHomeState build() => const DashboardHomeState();
}

/// The cloud, with a round trip of [latency] and a count of each read.
class _FakeCloud implements DeviceCloudService {
  _FakeCloud();

  static const latency = Duration(milliseconds: 200);

  List<GRASessionInfo> Function() sessions = () => const [];
  GRASessionInfo Function(String id) info =
      (id) => throw StateError('no session $id');
  int sessionsCalls = 0;
  int infoCalls = 0;

  @override
  Future<List<GRASessionInfo>> getSessions(
      {required LinksysDevice master}) async {
    sessionsCalls++;
    await Future.delayed(latency);
    return sessions();
  }

  @override
  Future<GRASessionInfo> getSessionInfo(
      {required LinksysDevice master, required String sessionId}) async {
    infoCalls++;
    await Future.delayed(latency);
    return info(sessionId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

GRASessionInfo _session(String id, GRASessionStatus status,
        {int expiredIn = 2547, int currentTime = 1748316924838}) =>
    GRASessionInfo(
      id: id,
      serialNumber: 'TEST123',
      modelNumber: 'LN16-EU',
      status: status,
      expiredIn: expiredIn,
      createdAt: 1748315872000,
      statusChangedAt: 1748315989000,
      currentTime: currentTime,
    );

const _withMaster = DeviceManagerState(
  deviceList: [
    LinksysDevice(
      connections: [],
      properties: [],
      unit: RawDeviceUnit(serialNumber: 'TEST123'),
      deviceID: 'device-uuid-1',
      maxAllowedProperties: 10,
      model: RawDeviceModel(deviceType: 'Infrastructure'),
      isAuthority: true,
      lastChangeRevision: 1,
      nodeType: 'Master',
      knownInterfaces: [
        RawDeviceKnownInterface(
          macAddress: 'AA:BB:CC:DD:EE:FF',
          interfaceType: 'Wireless',
        ),
      ],
    ),
  ],
);

const _endedNotice = 'Session ended. It may have expired or been closed.';

void main() {
  mockDependencyRegister();

  late ProviderContainer container;
  late _FakeCloud cloud;
  late _FakeDeviceManager deviceManager;

  Future<void> pumpTopBar(
    WidgetTester tester, {
    LoginType loginType = LoginType.remote,
    DeviceManagerState devices = _withMaster,
  }) async {
    await tester.setScreenSize(device1440w);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    cloud = _FakeCloud();
    deviceManager = _FakeDeviceManager(devices);
    container = ProviderContainer(overrides: [
      authProvider.overrideWith(() => _FakeAuth(loginType)),
      deviceManagerProvider.overrideWith(() => deviceManager),
      dashboardHomeProvider.overrideWith(_FakeDashboardHome.new),
      deviceCloudServiceProvider.overrideWithValue(cloud),
    ]);
    addTearDown(container.dispose);
    await container.read(authProvider.future);
  }

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(testableSingleRoute(
      provider: container,
      locale: const Locale('en'),
      child:
          StyledAppPageView(child: (context, constraints) => const SizedBox()),
    ));
  }

  /// Plays out [duration] of wall time a frame at a time, so a rebuild that
  /// triggers a request that triggers a rebuild gets every chance to repeat.
  Future<void> run(WidgetTester tester, Duration duration) async {
    final frames = duration.inMilliseconds ~/ 16;
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  /// Ends tracking and runs out the fake clock, so neither the provider's 1 Hz
  /// countdown nor the stream's 30 s sleep outlives the test.
  Future<void> drain(WidgetTester tester) async {
    container.read(remoteClientProvider.notifier).markSessionExpired();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 31));
    await tester.pump(const Duration(seconds: 31));
  }

  Future<void> startLiveSession(WidgetTester tester, {String id = 's1'}) async {
    cloud.sessions = () => [_session(id, GRASessionStatus.active)];
    cloud.info = (sid) => _session(sid, GRASessionStatus.active);
    await mount(tester);
    await run(tester, const Duration(seconds: 1));
    expect(find.textContaining('Session expires in'), findsOneWidget,
        reason: 'precondition: the session is being tracked');
  }

  // #1637: once a session ended, every rebuild of the top bar called
  // initiateRemoteAssistanceCA again, and that call's own state writes rebuilt
  // the top bar - one sessions read per cloud round trip, indefinitely.
  group('after a session ends', () {
    testWidgets('the cloud refusing a request does not set off a storm',
        (tester) async {
      await pumpTopBar(tester);
      await startLiveSession(tester);
      cloud.sessions = () => const [];
      cloud.sessionsCalls = 0;

      container.read(remoteClientProvider.notifier).markSessionExpired();
      await run(tester, const Duration(seconds: 5));

      expect(cloud.sessionsCalls, lessThanOrEqualTo(2),
          reason: 'was one read per round trip, ~23 in 5 s');
      expect(find.text(_endedNotice), findsOneWidget,
          reason: 'the session-ended notice still shows, once');
      await drain(tester);
    });

    testWidgets('a session the cloud still lists as ended does not either',
        (tester) async {
      await pumpTopBar(tester);
      await startLiveSession(tester);
      var now = 1748316924838;
      cloud.info =
          (sid) => _session(sid, GRASessionStatus.invalid, currentTime: now++);
      cloud.sessions = () => [cloud.info('s1')];

      // The stream's next read sees the session as ended and finishes.
      await tester.pump(const Duration(seconds: 31));
      await tester.pump();
      cloud.sessionsCalls = 0;
      cloud.infoCalls = 0;
      await run(tester, const Duration(seconds: 5));

      expect(cloud.sessionsCalls, lessThanOrEqualTo(1));
      expect(cloud.infoCalls, lessThanOrEqualTo(1));
      expect(find.text(_endedNotice), findsOneWidget);
      await drain(tester);
    });
  });

  // What the build()-time call provides, pinned so the fix keeps it.
  group('kept from the build-time call', () {
    // P1: the dashboard's top bar is up before the first poll lands.
    testWidgets('starts tracking once the device list arrives', (tester) async {
      await pumpTopBar(tester, devices: const DeviceManagerState());
      cloud.sessions = () => [_session('s1', GRASessionStatus.active)];
      cloud.info = (sid) => _session(sid, GRASessionStatus.active);
      await mount(tester);
      await run(tester, const Duration(seconds: 1));
      expect(cloud.sessionsCalls, 0, reason: 'no master device to ask with');

      deviceManager.state = _withMaster;
      await run(tester, const Duration(seconds: 1));

      expect(cloud.sessionsCalls, 1);
      expect(find.textContaining('Session expires in'), findsOneWidget);
      await drain(tester);
    });

    // P2: the client's own session shares the provider and must not reach
    // the Guardian's session-ended dialog.
    testWidgets('a local login neither tracks nor shows the dialog',
        (tester) async {
      await pumpTopBar(tester, loginType: LoginType.local);
      await mount(tester);
      final notifier = container.read(remoteClientProvider.notifier);
      notifier.state = RemoteClientState(
          sessionInfo: _session('s1', GRASessionStatus.active));
      await tester.pump();
      notifier.state = RemoteClientState(
          sessionInfo: _session('s1', GRASessionStatus.invalid));
      await run(tester, const Duration(seconds: 1));

      expect(cloud.sessionsCalls, 0);
      expect(find.text(_endedNotice), findsNothing);
    });

    // P3: a failed attempt is retried when the next poll lands, and does not
    // retry itself in the meantime.
    testWidgets('a failed attempt is retried on the next poll', (tester) async {
      await pumpTopBar(tester);
      var first = true;
      cloud.sessions = () {
        if (first) {
          first = false;
          throw Exception('cloud unreachable');
        }
        return [_session('s1', GRASessionStatus.active)];
      };
      cloud.info = (sid) => _session(sid, GRASessionStatus.active);
      // The call is not awaited, so its throw escapes as an uncaught error.
      // That is today's behaviour and not what is under test, so it is caught
      // here rather than left to fail the test.
      final uncaught = <Object>[];
      await runZonedGuarded(() async {
        await mount(tester);
        await run(tester, const Duration(seconds: 3));
      }, (error, _) => uncaught.add(error));
      expect(uncaught, [isA<Exception>()]);
      expect(cloud.sessionsCalls, 1, reason: 'a throw must not feed itself');

      deviceManager.state = _withMaster.copyWith(lastUpdateTime: 1);
      await run(tester, const Duration(seconds: 1));

      expect(cloud.sessionsCalls, 2);
      expect(find.textContaining('Session expires in'), findsOneWidget);
      await drain(tester);
    });

    // The list read writes state before the detail read can fail. That write
    // used to rebuild the bar and retry at frame rate; it no longer changes the
    // line, so the retry waits for the next poll like any other failed attempt.
    testWidgets('a failed detail read is retried on the next poll, not sooner',
        (tester) async {
      await pumpTopBar(tester);
      cloud.sessions = () => [_session('s1', GRASessionStatus.active)];
      var first = true;
      cloud.info = (sid) {
        if (first) {
          first = false;
          throw Exception('detail read failed');
        }
        return _session(sid, GRASessionStatus.active);
      };
      final uncaught = <Object>[];
      await runZonedGuarded(() async {
        await mount(tester);
        await run(tester, const Duration(seconds: 3));
      }, (error, _) => uncaught.add(error));
      expect(uncaught, [isA<Exception>()]);
      expect(cloud.sessionsCalls, 1);
      expect(cloud.infoCalls, 1);

      deviceManager.state = _withMaster.copyWith(lastUpdateTime: 1);
      await run(tester, const Duration(seconds: 1));

      expect(cloud.sessionsCalls, 2);
      expect(find.textContaining('Session expires in'), findsOneWidget);
      await drain(tester);
    });

    // P4: logout leaves this notifier as it was, so whatever stops the storm
    // must not stop the next session from being picked up.
    testWidgets('a new session is picked up after one has ended',
        (tester) async {
      await pumpTopBar(tester);
      await startLiveSession(tester);
      cloud.sessions = () => const [];
      container.read(remoteClientProvider.notifier).markSessionExpired();
      await run(tester, const Duration(seconds: 2));

      cloud.sessions = () => [_session('s2', GRASessionStatus.active)];
      cloud.info = (sid) => _session(sid, GRASessionStatus.active);
      deviceManager.state = _withMaster.copyWith(lastUpdateTime: 1);
      await run(tester, const Duration(seconds: 1));

      expect(container.read(remoteClientProvider).sessionInfo?.id, 's2');
      await drain(tester);
    });

    // The 1 Hz countdown keeps redrawing the line without asking the cloud.
    testWidgets('the countdown ticks without extra requests', (tester) async {
      await pumpTopBar(tester);
      await startLiveSession(tester);
      final before = cloud.sessionsCalls;
      final first =
          tester.widget<Text>(find.textContaining('Session expires in')).data;

      await run(tester, const Duration(seconds: 2));

      expect(
          tester.widget<Text>(find.textContaining('Session expires in')).data,
          isNot(first));
      expect(cloud.sessionsCalls, before);
      await drain(tester);
    });
  });
}
