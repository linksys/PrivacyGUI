import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/administration/services/usp_upnp_data_service.dart';

class MockUspClient extends Mock implements UspClient {}

const _upnpEnable = 'Device.UPnP.Device.Enable';
const _upnpIgd = 'Device.UPnP.Device.UPnPIGD';

void main() {
  late MockUspClient mockUsp;
  late UspUpnpDataService svc;

  setUp(() {
    mockUsp = MockUspClient();
    svc = UspUpnpDataService(mockUsp);
  });

  void answerGet(Map<String, dynamic> data) {
    when(() => mockUsp.get(any())).thenAnswer((_) async => data);
  }

  test('reads UPnP as on when Device.UPnP.Device.Enable is 1', () async {
    answerGet({_upnpEnable: '1', _upnpIgd: '1'});

    expect(await svc.fetchEnabled(), isTrue);
  });

  test('reads UPnP as off when Device.UPnP.Device.Enable is 0', () async {
    answerGet({_upnpEnable: '0', _upnpIgd: '0'});

    expect(await svc.fetchEnabled(), isFalse);
  });

  test('a failed read is a ServiceError, not UPnP off', () async {
    // The WASM client answers a failed GET with an empty data map.
    answerGet({});

    expect(svc.fetchEnabled(), throwsA(isA<ServiceError>()));
  });
}
