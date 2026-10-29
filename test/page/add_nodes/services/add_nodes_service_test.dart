import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/add_nodes/models/add_nodes_ui_models.dart';
import 'package:privacy_gui/page/add_nodes/services/add_nodes_service.dart';

import '../../../mocks/test_data/ble_onboarding_test_data.dart';
import '../../../mocks/test_data/data_elements_test_data.dart';

class MockUspClient extends Mock implements UspClient {}

const _start = 'Device.X_LINKSYS_BLEOnboarding.Start()';
const _stop = 'Device.X_LINKSYS_BLEOnboarding.Stop()';

void main() {
  late MockUspClient usp;
  late AddNodesService service;

  setUp(() {
    usp = MockUspClient();
    service = AddNodesService(usp);
  });

  void stubOperate(String command, Map<String, dynamic> output) {
    when(() => usp.operate(command, args: any(named: 'args')))
        .thenAnswer((_) async => output);
  }

  void stubGet(Map<String, dynamic> response) {
    when(() => usp.get(any())).thenAnswer((_) async => response);
  }

  group('AddNodesService - start', () {
    for (final entry in {
      'Started': OnboardingStartResult.started,
      'Busy': OnboardingStartResult.busy,
      'UnsupportedRole': OnboardingStartResult.unsupportedRole,
      'BackendUnavailable': OnboardingStartResult.backendUnavailable,
    }.entries) {
      test('returns ${entry.value.name} for a Result of ${entry.key}',
          () async {
        stubOperate(_start, BleOnboardingTestData.operateOutput(entry.key));

        expect(await service.start(), entry.value);
      });
    }

    test('sends no MACAddresses argument, which onboards every node in range',
        () async {
      stubOperate(_start, BleOnboardingTestData.operateOutput('Started'));

      await service.start();

      // An empty list is a different request — onboard none — and the firmware
      // tells the two apart by whether the argument is there at all.
      verify(() => usp.operate(_start, args: <String, String>{})).called(1);
    });

    test('a response with no Result is an error, never a start', () async {
      // A fault in a synchronous bbfdm operate reaches the client as a success
      // with empty output (dm_reflector.c).
      stubOperate(_start, BleOnboardingTestData.operateOutput(null));

      await expectLater(service.start(), throwsA(isA<UnexpectedError>()));
    });

    test('a Result of Error is an error', () async {
      stubOperate(_start, BleOnboardingTestData.operateOutput('Error'));

      await expectLater(service.start(), throwsA(isA<UnexpectedError>()));
    });

    test('an error carries no firmware text for the page to show', () async {
      stubOperate(_start, BleOnboardingTestData.operateOutput('Error'));

      final error = await service
          .start()
          .then<Object?>((_) => null, onError: (Object e) => e);

      // UnexpectedError is the one type the page shows `detail` for.
      expect((error as UnexpectedError).detail, isNull);
    });

    test('a refused Operate is mapped to a ServiceError', () async {
      when(() => usp.operate(_start, args: any(named: 'args')))
          .thenThrow('Operate failed: Transport error: Connection refused');

      await expectLater(service.start(), throwsA(isA<ConnectivityError>()));
    });

    test('a ServiceError from below is passed through unchanged', () async {
      when(() => usp.operate(_start, args: any(named: 'args')))
          .thenThrow(const NetworkError());

      await expectLater(service.start(), throwsA(isA<NetworkError>()));
    });
  });

  group('AddNodesService - stop', () {
    test('returns when the router answers Success', () async {
      stubOperate(_stop, BleOnboardingTestData.operateOutput('Success'));

      await service.stop();

      verify(() => usp.operate(_stop, args: any(named: 'args'))).called(1);
    });

    test('a response with no Result is an error', () async {
      stubOperate(_stop, BleOnboardingTestData.operateOutput(null));

      await expectLater(service.stop(), throwsA(isA<UnexpectedError>()));
    });

    test('a Result other than Success is an error', () async {
      stubOperate(_stop, BleOnboardingTestData.operateOutput('Error'));

      await expectLater(service.stop(), throwsA(isA<UnexpectedError>()));
    });

    test('a refused Operate is mapped to a ServiceError', () async {
      when(() => usp.operate(_stop, args: any(named: 'args')))
          .thenThrow('Operate failed: Transport error: Connection refused');

      await expectLater(service.stop(), throwsA(isA<ConnectivityError>()));
    });
  });

  group('AddNodesService - fetchSession', () {
    test('an idle router that never ran a session', () async {
      stubGet(BleOnboardingTestData.sessionResponse());

      final session = await service.fetchSession();

      expect(session.status, OnboardingSessionStatus.idle);
      expect(session.result, OnboardingSessionResult.none);
      expect(session.session, 0);
      expect(session.nodes, isEmpty);
      expect(session.isRunning, isFalse);
      expect(session.isUnavailable, isFalse);
    });

    test('a session that onboarded a node', () async {
      stubGet(BleOnboardingTestData.onboardedSessionResponse());

      final session = await service.fetchSession();

      expect(session.status, OnboardingSessionStatus.complete);
      expect(session.result, OnboardingSessionResult.success);
      expect(session.session, 1450);
      expect(session.devicesFound, 1);
      expect(session.devicesOnboarded, 1);
      expect(session.nodes, [
        const AddNodesNodeUIModel(
          bleMacAddress: BleOnboardingTestData.nodeBleMac,
          status: OnboardingNodeStatus.onboarded,
          modelNumber: 'M60',
          rssi: -40,
          alMacAddress: BleOnboardingTestData.nodeAlMac,
        ),
      ]);
    });

    test('reads every session status', () async {
      for (final entry in {
        'Idle': OnboardingSessionStatus.idle,
        'Scanning': OnboardingSessionStatus.scanning,
        'Onboarding': OnboardingSessionStatus.onboarding,
        'Complete': OnboardingSessionStatus.complete,
      }.entries) {
        stubGet(BleOnboardingTestData.sessionResponse(status: entry.key));

        expect((await service.fetchSession()).status, entry.value,
            reason: entry.key);
      }
    });

    test('reads every documented session result', () async {
      for (final entry in {
        'None': OnboardingSessionResult.none,
        'Started': OnboardingSessionResult.started,
        'Success': OnboardingSessionResult.success,
        'Partial': OnboardingSessionResult.partial,
        'Failed': OnboardingSessionResult.failed,
        'TimedOut': OnboardingSessionResult.timedOut,
        'NoDevicesFound': OnboardingSessionResult.noDevicesFound,
        'TargetNotFound': OnboardingSessionResult.targetNotFound,
        'NoTargetRequested': OnboardingSessionResult.noTargetRequested,
        'Cancelled': OnboardingSessionResult.cancelled,
        'Scanned': OnboardingSessionResult.scanned,
        'Busy': OnboardingSessionResult.busy,
        'UnsupportedRole': OnboardingSessionResult.unsupportedRole,
        'BackendUnavailable': OnboardingSessionResult.backendUnavailable,
        'Error': OnboardingSessionResult.error,
      }.entries) {
        stubGet(BleOnboardingTestData.sessionResponse(result: entry.key));

        expect((await service.fetchSession()).result, entry.value,
            reason: entry.key);
      }
    });

    test('reads every node status', () async {
      for (final entry in {
        'Pending': OnboardingNodeStatus.pending,
        'NotTargeted': OnboardingNodeStatus.notTargeted,
        'Connecting': OnboardingNodeStatus.connecting,
        'Onboarding': OnboardingNodeStatus.onboarding,
        'Onboarded': OnboardingNodeStatus.onboarded,
        'FailedConnect': OnboardingNodeStatus.failedConnect,
        'FailedRegistrar': OnboardingNodeStatus.failedRegistrar,
        'FailedWPS': OnboardingNodeStatus.failedWps,
        'LostConnection': OnboardingNodeStatus.lostConnection,
        'Cancelled': OnboardingNodeStatus.cancelled,
        'Unknown': OnboardingNodeStatus.unknown,
      }.entries) {
        stubGet(BleOnboardingTestData.sessionResponse(
            nodes: [BleOnboardingTestData.nodeRow(status: entry.key)]));

        expect((await service.fetchSession()).nodes.single.status, entry.value,
            reason: entry.key);
      }
    });

    test('a value outside the documented sets reads as the safe default',
        () async {
      stubGet(BleOnboardingTestData.sessionResponse(
        status: 'Pairing',
        result: 'Exploded',
        nodes: [BleOnboardingTestData.nodeRow(status: 'Wandering')],
      ));

      final session = await service.fetchSession();

      // The reflector's own defaults: Idle, Error and Unknown.
      expect(session.status, OnboardingSessionStatus.idle);
      expect(session.result, OnboardingSessionResult.error);
      expect(session.nodes.single.status, OnboardingNodeStatus.unknown);
    });

    test('a node before the controller connects has no model and no AL MAC',
        () async {
      stubGet(BleOnboardingTestData.sessionResponse(
          nodes: [BleOnboardingTestData.nodeRow()]));

      final node = (await service.fetchSession()).nodes.single;

      expect(node.modelNumber, isNull);
      expect(node.alMacAddress, isNull);
    });

    test('a required leaf missing from the response is a ServiceError',
        () async {
      // The mapping on its own: the 9998 the generated parser throws, handed
      // to the service as a string. The notifier only catches ServiceError, so
      // it has to arrive as one, with its code kept.
      when(() => usp.get(any())).thenThrow(
          'Get failed: Validation error: Required fields missing from response: '
          'Device.X_LINKSYS_BLEOnboarding.Device.1.Status (code: 9998)');

      await expectLater(
          service.fetchSession(),
          throwsA(
              isA<InvalidInputError>().having((e) => e.code, 'code', 9998)));
    });

    test('a node row the router sent without its Status fails the read',
        () async {
      // The generated parser itself, on usp-codegen 0.19.0: an absent required
      // leaf in a child row fails the fetch rather than reading ''.
      final row = BleOnboardingTestData.nodeRow()
        ..remove('Device.X_LINKSYS_BLEOnboarding.Device.1.Status');
      stubGet(BleOnboardingTestData.sessionResponse(nodes: [row]));

      await expectLater(
          service.fetchSession(),
          throwsA(
              isA<InvalidInputError>().having((e) => e.code, 'code', 9998)));
    });

    test('an empty model and AL MAC are present, not missing', () async {
      // What the firmware sends before it has connected to a node: the leaves
      // are there with '' values. Only an absent key is a 9998.
      stubGet(BleOnboardingTestData.sessionResponse(nodes: [
        BleOnboardingTestData.nodeRow(modelNumber: '', alMacAddress: '')
      ]));

      expect((await service.fetchSession()).nodes, hasLength(1));
    });

    test('an RSSI of 0 is no reading, not the strongest signal', () async {
      stubGet(BleOnboardingTestData.sessionResponse(
          nodes: [BleOnboardingTestData.nodeRow(rssi: '0')]));

      expect((await service.fetchSession()).nodes.single.rssi, isNull);
    });

    test('a running session is running, whatever its result reads', () async {
      stubGet(BleOnboardingTestData.sessionResponse(
          status: 'Scanning', result: 'Busy'));

      final session = await service.fetchSession();

      // A second request refused mid-session writes Busy over Started.
      expect(session.isRunning, isTrue);
      expect(session.isUnavailable, isFalse);
    });

    test('an idle router that cannot run a session is unavailable', () async {
      for (final result in ['BackendUnavailable', 'UnsupportedRole']) {
        stubGet(BleOnboardingTestData.sessionResponse(result: result));

        expect((await service.fetchSession()).isUnavailable, isTrue,
            reason: result);
      }
    });

    test('a failed read is mapped to a ServiceError', () async {
      when(() => usp.get(any()))
          .thenThrow('Get failed: Transport error: Connection refused');

      await expectLater(
          service.fetchSession(), throwsA(isA<ConnectivityError>()));
    });

    test('firmware without the object is ResourceNotFoundError', () async {
      when(() => usp.get(any()))
          .thenThrow('Get failed: Protocol error: CheckPathProperties: Path '
              '(Device.X_LINKSYS_BLEOnboarding.Status) does not exist in the '
              'schema (code: 7026)');

      await expectLater(
          service.fetchSession(), throwsA(isA<ResourceNotFoundError>()));
    });
  });

  group('AddNodesService - fetchJoinedNodes', () {
    const controller = 'aa:bb:cc:00:00:00';
    const joining = BleOnboardingTestData.nodeAlMac;
    const joiningKey = 'AABBCC000002';

    Map<String, dynamic> network(List<Map<String, dynamic>> rows) => {
          for (final row in rows) ...row,
        };

    test('a node listed with its parent set has joined', () async {
      stubGet(network([
        DataElementsTestData.nodeRows(instance: '1', id: controller),
        DataElementsTestData.nodeRows(
            instance: '2',
            id: joining,
            linkType: 'Wi-Fi',
            parentDeviceId: controller),
      ]));

      expect(await service.fetchJoinedNodes([joining]), {joiningKey});
    });

    test('a node listed with no backhaul yet has not joined', () async {
      // Its first seconds after the session, before the controller's next
      // Topology Response (2.0.3.26100921).
      stubGet(network([
        DataElementsTestData.nodeRows(instance: '1', id: controller),
        DataElementsTestData.nodeRows(instance: '2', id: joining),
      ]));

      expect(await service.fetchJoinedNodes([joining]), isEmpty);
    });

    test('a node not listed yet has not joined', () async {
      stubGet(network([
        DataElementsTestData.nodeRows(instance: '1', id: controller),
      ]));

      expect(await service.fetchJoinedNodes([joining]), isEmpty);
    });

    test('matches whatever the two sides spell a MAC with', () async {
      stubGet(network([
        DataElementsTestData.nodeRows(
            instance: '2',
            id: 'AA-BB-CC-00-00-02',
            linkType: 'Ethernet',
            parentDeviceId: controller),
      ]));

      expect(
          await service.fetchJoinedNodes(['aa:bb:cc:00:00:02']), {joiningKey});
    });

    test('asks nothing of the router when there is nothing to look for',
        () async {
      expect(await service.fetchJoinedNodes(const []), isEmpty);

      verifyNever(() => usp.get(any()));
    });

    test('a failed read is mapped to a ServiceError', () async {
      when(() => usp.get(any()))
          .thenThrow('Get failed: Transport error: Connection refused');

      await expectLater(service.fetchJoinedNodes([joining]),
          throwsA(isA<ConnectivityError>()));
    });

    test('a required leaf missing from DataElements is a ServiceError',
        () async {
      // usp-codegen 0.19.0 checks DataElementsNetwork's child rows too (five
      // leaves). The mapping on its own, as for fetchSession.
      when(() => usp.get(any())).thenThrow(
          'Get failed: Validation error: Required fields missing from response: '
          'Device.WiFi.DataElements.Network.Device.1.Radio.1.BSS.1.STA.1.'
          'MACAddress (code: 9998)');

      await expectLater(
          service.fetchJoinedNodes([joining]),
          throwsA(
              isA<InvalidInputError>().having((e) => e.code, 'code', 9998)));
    });
  });
}
