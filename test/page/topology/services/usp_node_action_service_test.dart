import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/topology/services/usp_node_action_service.dart';

class MockUspClient extends Mock implements UspClient {}

void main() {
  const devices = 'Device.WiFi.DataElements.Network.Device.';
  const agent = 'AA:BB:CC:DD:EE:02';

  late MockUspClient mockUsp;
  late UspNodeActionService service;

  setUp(() {
    mockUsp = MockUspClient();
    service = UspNodeActionService(mockUsp);
  });

  void rows(Map<String, String> idByInstance) {
    when(() => mockUsp.get(any(), fresh: any(named: 'fresh'))).thenAnswer(
      (_) async => {
        for (final e in idByInstance.entries) '$devices${e.key}.ID': e.value,
      },
    );
  }

  void operateAnswers() {
    when(() => mockUsp.operate(any())).thenAnswer((_) async => {});
  }

  group('UspNodeActionService - run', () {
    // FWDEV#202: instance numbers change, so {i} is looked up by the AL MAC
    // right before the call, never taken from the last topology read.
    test('looks the instance up by AL MAC on a fresh read', () async {
      rows({'1': 'AA:BB:CC:DD:EE:01', '3': agent});
      operateAnswers();

      await service.run(NodeAction.reboot, agent);

      verify(() => mockUsp.get(['$devices*.ID'], fresh: true)).called(1);
      verify(() => mockUsp.operate('${devices}3.X_LINKSYS_Reboot()')).called(1);
    });

    test('sends the factory reset command for factoryReset', () async {
      rows({'2': agent});
      operateAnswers();

      await service.run(NodeAction.factoryReset, agent);

      verify(() => mockUsp.operate('${devices}2.X_LINKSYS_FactoryReset()'))
          .called(1);
    });

    test('matches the AL MAC whatever its case', () async {
      rows({'4': agent.toLowerCase()});
      operateAnswers();

      await service.run(NodeAction.reboot, agent);

      verify(() => mockUsp.operate('${devices}4.X_LINKSYS_Reboot()')).called(1);
    });

    test('a node no longer listed is not found and nothing is sent', () async {
      rows({'1': 'AA:BB:CC:DD:EE:01'});

      await expectLater(
        service.run(NodeAction.reboot, agent),
        throwsA(isA<ResourceNotFoundError>()),
      );
      verifyNever(() => mockUsp.operate(any()));
    });

    test('maps a refused command to ServiceError', () async {
      rows({'2': agent});
      when(() => mockUsp.operate(any())).thenThrow(
        'Operate failed: Operation error: '
        '${devices}2.X_LINKSYS_Reboot() refused: Command failure (code: 7022)',
      );

      await expectLater(
        service.run(NodeAction.reboot, agent),
        throwsA(
            isA<UspCompleteFailureError>().having((e) => e.code, 'code', 7022)),
      );
    });

    test('maps a failed lookup to ServiceError', () async {
      when(() => mockUsp.get(any(), fresh: any(named: 'fresh')))
          .thenThrow('Get failed: Transport error: Connection refused');

      await expectLater(
        service.run(NodeAction.reboot, agent),
        throwsA(isA<ConnectivityError>()),
      );
    });
  });
}
