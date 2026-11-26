import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/models/firmware_update_settings.dart';
import 'package:privacy_gui/core/jnap/models/firmware_update_status.dart';
import 'package:privacy_gui/core/jnap/models/firmware_update_status_nodes.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_state.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../common/di.dart';
import '../../../common/recording_polling.dart';
import '../../../common/router_boundary.dart';
import '../../../mocks/jnap_service_supported_mocks.dart';

JNAPSuccess _ok(Map<String, dynamic> output) =>
    JNAPSuccess(result: 'OK', output: output);

String _isoMinutesAgo(int minutes) => DateTime.now()
    .toUtc()
    .subtract(Duration(minutes: minutes))
    .toIso8601String();

/// `GetFirmwareUpdateStatus` output for the router alone.
Map<String, dynamic> _status({
  String? checkedAt,
  bool update = false,
  int? progress,
  String? failure,
}) =>
    {
      'lastSuccessfulCheckTime': checkedAt ?? _isoMinutesAgo(60),
      if (update)
        'availableUpdate': {
          'firmwareVersion': '1.3.2',
          'firmwareDate': '2026-11-01T00:00:00Z',
          'description': 'Fixes',
        },
      if (progress != null)
        'pendingOperation': {
          'operation': 'Installing',
          'progressPercent': progress,
        },
      if (failure != null) 'lastOperationFailure': failure,
    };

/// One node's entry in `GetNodesFirmwareUpdateStatus` output.
Map<String, dynamic> _nodeStatus(String deviceUUID,
        {bool update = false, int? progress}) =>
    {
      'deviceUUID': deviceUUID,
      ..._status(update: update, progress: progress),
    };

const _settingsOutput = <String, dynamic>{
  'updatePolicy': 'AutomaticallyCheckAndInstall',
  'autoUpdateWindow': {'startMinute': 120, 'durationMinutes': 180},
};

void main() {
  mockDependencyRegister();
  final services = serviceHelper as MockServiceHelper;

  late RouterBoundary router;
  late RecordingPolling polling;
  late ProviderContainer container;
  late List<List<JNAPResult>> scheduledAnswers;
  late List<JNAPAction> scheduledActions;

  FirmwareUpdateNotifier notifier() =>
      container.read(firmwareUpdateProvider.notifier);
  FirmwareUpdateState page() => container.read(firmwareUpdateProvider);

  /// Starts the app, logged in with full access, with [pollData] as the last
  /// poll.
  void start(Map<JNAPAction, JNAPResult> pollData) {
    polling = RecordingPolling(pollData);
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(router.repo),
      pollingProvider.overrideWith(() => polling),
      accessPolicyProvider.overrideWithValue(AccessPolicy.full),
    ]);
  }

  /// Lets an update that is following the router's status run to its end.
  Future<void> settle() async {
    for (var i = 0; i < 20; i++) {
      await pumpEventQueue();
    }
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    when(services.isSupportNodeFirmwareUpdate()).thenReturn(false);
    router = RouterBoundary()
      ..holds(JNAPAction.getFirmwareUpdateSettings, _settingsOutput)
      // Both start a check or an install; neither answers with anything.
      ..holds(JNAPAction.updateFirmwareNow, const {})
      ..holds(JNAPAction.nodesUpdateFirmwareNow, const {});
    scheduledAnswers = [];
    scheduledActions = [];
    // The status checks, as RouterRepository.scheduledCommand runs them: each
    // answer is yielded, then checked against the stop condition, and the
    // caller is told at the end whether the retries ran out.
    when(router.repo.scheduledCommand(
      action: anyNamed('action'),
      retryDelayInMilliSec: anyNamed('retryDelayInMilliSec'),
      maxRetry: anyNamed('maxRetry'),
      firstDelayInMilliSec: anyNamed('firstDelayInMilliSec'),
      data: anyNamed('data'),
      condition: anyNamed('condition'),
      onCompleted: anyNamed('onCompleted'),
      requestTimeoutOverride: anyNamed('requestTimeoutOverride'),
      auth: anyNamed('auth'),
      logoutGeneration: anyNamed('logoutGeneration'),
    )).thenAnswer((invocation) {
      final named = invocation.namedArguments;
      scheduledActions.add(named[#action] as JNAPAction);
      final answers = scheduledAnswers.isEmpty
          ? <JNAPResult>[]
          : scheduledAnswers.removeAt(0);
      final maxRetry = named[#maxRetry] as int;
      final condition = named[#condition] as bool Function(JNAPResult)?;
      final onCompleted = named[#onCompleted] as Function(bool)?;
      Stream<JNAPResult> run() async* {
        var exceeded = true;
        for (final (index, answer) in answers.indexed) {
          if (maxRetry != -1 && index >= maxRetry) break;
          yield answer;
          if (condition?.call(answer) ?? false) {
            exceeded = false;
            break;
          }
        }
        onCompleted?.call(exceeded);
      }

      return run();
    });
  });

  tearDown(() {
    container.dispose();
    reset(services);
  });

  group('build', () {
    test('reads the update policy and the status from the last poll', () {
      start({
        JNAPAction.getFirmwareUpdateSettings: _ok(_settingsOutput),
        JNAPAction.getFirmwareUpdateStatus: _ok(_status(update: true)),
      });

      expect(page().settings.updatePolicy,
          FirmwareUpdateSettings.firmwareUpdatePolicyAuto);
      expect(page().settings.autoUpdateWindow.startMinute, 120);
      expect(
          page().nodesStatus!.single.availableUpdate?.firmwareVersion, '1.3.2');
      expect(notifier().getAvailableUpdateNumber(), 1);
    });

    test('assumes automatic updates in a four-hour window before a poll', () {
      start({});

      expect(page().settings.updatePolicy,
          FirmwareUpdateSettings.firmwareUpdatePolicyAuto);
      expect(
          page().settings.autoUpdateWindow, FirmwareAutoUpdateWindow.simple());
      expect(page().nodesStatus, isEmpty);
    });

    test('reads every node on a router that updates its nodes', () {
      when(services.isSupportNodeFirmwareUpdate()).thenReturn(true);
      start({
        JNAPAction.getNodesFirmwareUpdateStatus: _ok({
          'firmwareUpdateStatus': [
            _nodeStatus('master-uuid', update: true),
            _nodeStatus('child-uuid'),
          ],
        }),
      });

      expect(
          page().nodesStatus!.map(
              (status) => (status as NodesFirmwareUpdateStatus).deviceUUID),
          ['master-uuid', 'child-uuid']);
      expect(notifier().getAvailableUpdateNumber(), 1);
    });

    test('keeps showing every node while a child is still rebooting', () {
      when(services.isSupportNodeFirmwareUpdate()).thenReturn(true);
      start({
        // Only the master answers right after the update.
        JNAPAction.getNodesFirmwareUpdateStatus: _ok({
          'firmwareUpdateStatus': [_nodeStatus('master-uuid')],
        }),
      });
      container.read(firmwareUpdateCandidateProvider.notifier).state = [
        for (final uuid in ['master-uuid', 'child-uuid'])
          (
            null,
            NodesFirmwareUpdateStatus.fromMap(_nodeStatus(uuid, update: true))
          ),
      ];

      final shown = page().nodesStatus!;
      expect(shown.map((s) => (s as NodesFirmwareUpdateStatus).deviceUUID),
          ['master-uuid', 'child-uuid']);
      expect(shown.every((status) => status.availableUpdate == null), isTrue);
      expect(page().isWaitingChildrenAfterUpdating, isTrue);
    });

    test('flags a failed update check', () {
      start({
        JNAPAction.getFirmwareUpdateStatus:
            _ok(_status(failure: 'CheckFailed')),
      });

      expect(notifier().isFailedCheckFirmwareUpdate(), isTrue);
    });
  });

  group('setFirmwareUpdatePolicy', () {
    setUp(() => start({
          JNAPAction.getFirmwareUpdateSettings: _ok(_settingsOutput),
        }));

    test('writes the new policy with the window the router holds', () async {
      await notifier().setFirmwareUpdatePolicy(
          FirmwareUpdateSettings.firmwareUpdatePolicyManual);

      expect(router.payloadsOf(JNAPAction.setFirmwareUpdateSettings).single, {
        'updatePolicy': 'Manual',
        'autoUpdateWindow': {'startMinute': 120, 'durationMinutes': 180},
      });
    });

    test('reads the settings back, then shows the new policy', () async {
      await notifier().setFirmwareUpdatePolicy(
          FirmwareUpdateSettings.firmwareUpdatePolicyManual);

      expect(router.actions, [
        JNAPAction.setFirmwareUpdateSettings,
        JNAPAction.getFirmwareUpdateSettings,
      ]);
      expect(page().settings.updatePolicy, 'Manual');
    });

    test('reports a write the router refuses, keeping the policy', () async {
      router.refuses(JNAPAction.setFirmwareUpdateSettings);

      await expectLater(
          notifier().setFirmwareUpdatePolicy(
              FirmwareUpdateSettings.firmwareUpdatePolicyManual),
          throwsA(isA<JNAPError>()));

      expect(router.actions, [JNAPAction.setFirmwareUpdateSettings]);
      expect(page().settings.updatePolicy,
          FirmwareUpdateSettings.firmwareUpdatePolicyAuto);
    });
  });

  group('checking for updates', () {
    test('asks the router to check, then shows what it found', () async {
      start({});
      scheduledAnswers = [
        [_ok(_status(update: true))],
      ];

      await notifier().fetchAvailableFirmwareUpdates();

      expect(router.payloadsOf(JNAPAction.updateFirmwareNow).single,
          {'onlyCheck': true});
      expect(scheduledActions, [JNAPAction.getFirmwareUpdateStatus]);
      expect(notifier().getAvailableUpdateNumber(), 1);
    });

    test('asks every node on a router that updates its nodes', () async {
      when(services.isSupportNodeFirmwareUpdate()).thenReturn(true);
      start({});
      scheduledAnswers = [
        [
          _ok({
            'firmwareUpdateStatus': [_nodeStatus('master-uuid', update: true)],
          }),
        ],
      ];

      await notifier().fetchAvailableFirmwareUpdates();

      expect(router.payloadsOf(JNAPAction.nodesUpdateFirmwareNow).single,
          {'onlyCheck': true});
      expect(scheduledActions, [JNAPAction.getNodesFirmwareUpdateStatus]);
      expect(page().nodesStatus!.single, isA<NodesFirmwareUpdateStatus>());
    });

    test('shows no updates when the router refuses to check', () async {
      start({JNAPAction.getFirmwareUpdateStatus: _ok(_status(update: true))});
      router.refuses(JNAPAction.updateFirmwareNow);

      await notifier().fetchAvailableFirmwareUpdates();

      expect(scheduledActions, isEmpty);
      expect(page().nodesStatus, isEmpty);
    });

    test('shows no updates when the check gets no answer', () async {
      start({JNAPAction.getFirmwareUpdateStatus: _ok(_status(update: true))});
      scheduledAnswers = [
        [const JNAPError(result: 'ErrorUnknown')],
      ];

      await notifier().fetchAvailableFirmwareUpdates();

      expect(page().nodesStatus, isEmpty);
    });

    test('skips a check made in the last five minutes unless forced', () async {
      start({
        JNAPAction.getFirmwareUpdateStatus:
            _ok(_status(checkedAt: _isoMinutesAgo(1))),
      });

      final skipped = await notifier().fetchFirmwareUpdateStream().toList();

      expect(skipped, [<FirmwareUpdateStatus>[]]);
      expect(router.actions, isEmpty);
    });

    test('checks again once five minutes have passed', () async {
      start({
        JNAPAction.getFirmwareUpdateStatus:
            _ok(_status(checkedAt: _isoMinutesAgo(10))),
      });
      scheduledAnswers = [
        [_ok(_status())],
      ];

      await notifier().fetchFirmwareUpdateStream().toList();

      expect(router.actions, [JNAPAction.updateFirmwareNow]);
    });
  });

  group('updateFirmware', () {
    test('installs, follows the progress, and finishes once nothing is pending',
        () async {
      start({JNAPAction.getFirmwareUpdateStatus: _ok(_status(update: true))});
      scheduledAnswers = [
        // The install.
        [
          _ok(_status(update: true, progress: 40)),
          _ok(_status(update: true, progress: 90)),
          _ok(_status()),
        ],
        // The check that follows it.
        [_ok(_status())],
      ];

      await notifier().updateFirmware();

      expect(router.payloadsOf(JNAPAction.updateFirmwareNow).first,
          {'onlyCheck': false});
      expect(page().isUpdating, isTrue);
      expect(polling.stopped, 1);

      await settle();

      expect(page().isUpdating, isFalse);
      expect(page().isRetryMaxReached, isFalse);
      expect(notifier().getAvailableUpdateNumber(), 0);
      expect(router.payloadsOf(JNAPAction.updateFirmwareNow).last,
          {'onlyCheck': true});
      expect(polling.forced, 1);
      expect(polling.started, 1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(pFWUpdated), isTrue);
    });

    test('keeps the router status from before the install as candidates',
        () async {
      start({JNAPAction.getFirmwareUpdateStatus: _ok(_status(update: true))});
      scheduledAnswers = [
        [_ok(_status())],
        [_ok(_status())],
      ];

      await notifier().updateFirmware();

      final candidates = container.read(firmwareUpdateCandidateProvider)!;
      expect(candidates.single.$2.availableUpdate?.firmwareVersion, '1.3.2');
      await settle();
    });

    test('installs on every node on a router that updates its nodes', () async {
      when(services.isSupportNodeFirmwareUpdate()).thenReturn(true);
      start({
        JNAPAction.getNodesFirmwareUpdateStatus: _ok({
          'firmwareUpdateStatus': [_nodeStatus('master-uuid', update: true)],
        }),
      });
      final done = _ok({
        'firmwareUpdateStatus': [_nodeStatus('master-uuid')],
      });
      scheduledAnswers = [
        [done],
        [done],
      ];

      await notifier().updateFirmware();
      await settle();

      expect(router.payloadsOf(JNAPAction.nodesUpdateFirmwareNow).first,
          {'onlyCheck': false});
      expect(scheduledActions.first, JNAPAction.getNodesFirmwareUpdateStatus);
      expect(page().isUpdating, isFalse);
    });

    test('stops and says so when the router never reports the install done',
        () async {
      start({JNAPAction.getFirmwareUpdateStatus: _ok(_status(update: true))});
      scheduledAnswers = [
        [
          for (var i = 0; i < 60; i++) _ok(_status(update: true, progress: 50)),
        ],
      ];

      await notifier().updateFirmware();
      await settle();

      expect(page().isRetryMaxReached, isTrue);
      expect(page().isUpdating, isFalse);
      expect(polling.started, 0);
    });

    // A read-only login is refused before anything is sent:
    // firmware_update_access_test covers that.

    test('reports an install the router refuses, and keeps polling', () async {
      start({JNAPAction.getFirmwareUpdateStatus: _ok(_status(update: true))});
      router.refuses(JNAPAction.updateFirmwareNow);

      await expectLater(notifier().updateFirmware(), throwsA(isA<JNAPError>()));

      expect(polling.stopped, 0);
      expect(scheduledActions, isEmpty);
    });

    test('rides out the status reads that fail while the router restarts',
        () async {
      start({JNAPAction.getFirmwareUpdateStatus: _ok(_status(update: true))});
      scheduledAnswers = [
        [
          _ok(_status(update: true, progress: 90)),
          // The router is rebooting into the new firmware.
          const JNAPError(result: 'ClientException'),
          _ok(_status()),
        ],
        [_ok(_status())],
      ];

      await notifier().updateFirmware();
      await settle();

      expect(page().isUpdating, isFalse);
      expect(page().isRetryMaxReached, isFalse);
      expect(polling.started, 1);
    });

    test('leaves the update page once the router refuses the install',
        () async {
      start({JNAPAction.getFirmwareUpdateStatus: _ok(_status(update: true))});
      router.refuses(JNAPAction.updateFirmwareNow);

      await notifier().updateFirmware().catchError((_) {});

      expect(page().isUpdating, isFalse);
      // Nothing was installed, so there are no nodes to wait for.
      expect(container.read(firmwareUpdateCandidateProvider), isNull);
      expect(page().nodesStatus!.single.availableUpdate, isNotNull);
    });
  });

  group('getIDStatusRecords', () {
    test('pairs a node status with no device it can find with none', () {
      when(services.isSupportNodeFirmwareUpdate()).thenReturn(true);
      start({
        JNAPAction.getNodesFirmwareUpdateStatus: _ok({
          'firmwareUpdateStatus': [_nodeStatus('unknown-uuid')],
        }),
      });

      final records = notifier().getIDStatusRecords();

      expect(records.single.$1, isNull);
      expect((records.single.$2 as NodesFirmwareUpdateStatus).deviceUUID,
          'unknown-uuid');
    });
  });

  group('isRecordConsistent', () {
    NodesFirmwareUpdateStatus node(String uuid) =>
        NodesFirmwareUpdateStatus.fromMap(_nodeStatus(uuid));

    test('holds when every recorded node is back', () {
      start({});

      expect(
          notifier().isRecordConsistent(
              [node('a'), node('b')], [node('a'), node('b')]),
          isTrue);
      expect(notifier().isRecordConsistent([node('a')], [node('a'), node('b')]),
          isFalse);
    });

    test('holds for a router alone when it answers once', () {
      start({});
      final status = FirmwareUpdateStatus.fromMap(_status());

      expect(notifier().isRecordConsistent([status], [status]), isTrue);
      expect(notifier().isRecordConsistent([], [status]), isFalse);
    });
  });
}
