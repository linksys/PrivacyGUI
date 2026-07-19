import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/models/usp_ws_message.dart';
import 'package:privacy_gui/core/usp/services/turbo_session_manager.dart';
import 'package:privacy_gui/core/usp/usp_ws_client.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_ws_upload_strategy.dart';

class MockTurboSessionManager extends Mock implements TurboSessionManager {}

class MockUspWsClientWrapper extends Mock implements UspWsClientWrapper {}

void main() {
  late MockTurboSessionManager turboManager;
  late MockUspWsClientWrapper wsClient;

  setUp(() {
    turboManager = MockTurboSessionManager();
    wsClient = MockUspWsClientWrapper();

    when(() => turboManager.start()).thenAnswer((_) async => 'test-session');
    when(() => turboManager.release()).thenAnswer((_) async {});
    when(() => wsClient.onMessage)
        .thenAnswer((_) => const Stream<UspWsMessage>.empty());
    when(
      () => wsClient.sendWebSocketConnect(
        fromId: any(named: 'fromId'),
        toId: any(named: 'toId'),
      ),
    ).thenAnswer((_) async {});
  });

  test('handshake timeout fails preparation and releases all resources',
      () async {
    String? connectedUrl;
    final strategy = FirmwareWsUploadStrategy(
      turboManager: turboManager,
      wsUrl: 'wss://router.test/usp-ws',
      fromId: 'controller::test',
      toId: 'agent::test',
      connect: (url) async {
        connectedUrl = url;
        return wsClient;
      },
      handshakeTimeout: const Duration(milliseconds: 1),
    );

    await expectLater(strategy.prepare(), throwsA(isA<NetworkError>()));

    expect(connectedUrl, 'wss://router.test/usp-ws');
    verify(() => turboManager.start()).called(1);
    verify(
      () => wsClient.sendWebSocketConnect(
        fromId: 'controller::test',
        toId: 'agent::test',
      ),
    ).called(1);
    verify(() => wsClient.dispose()).called(1);
    verify(() => turboManager.release()).called(1);
  });
}
