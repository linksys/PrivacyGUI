import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/administration/providers/upnp_data_provider.dart';
import 'package:privacy_gui/page/administration/services/usp_upnp_data_service.dart';

class MockUspUpnpDataService extends Mock implements UspUpnpDataService {}

void main() {
  late MockUspUpnpDataService svc;

  setUp(() {
    svc = MockUspUpnpDataService();
  });

  ProviderContainer containerWith(MockUspUpnpDataService svc) {
    final container = ProviderContainer(overrides: [
      uspUpnpDataServiceProvider.overrideWithValue(svc),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  test('holds whether UPnP is on, as the router reports it', () async {
    when(() => svc.fetchEnabled()).thenAnswer((_) async => false);

    final container = containerWith(svc);

    expect(await container.read(upnpDataProvider.future), isFalse);
  });

  test('a failed read is an error, not UPnP off', () async {
    when(() => svc.fetchEnabled())
        .thenAnswer((_) async => throw const TimeoutError());
    final container = containerWith(svc);
    container.listen(upnpDataProvider, (_, __) {});

    await expectLater(
      container.read(upnpDataProvider.future),
      throwsA(isA<TimeoutError>()),
    );
    expect(container.read(upnpDataProvider).valueOrNull, isNull);
  });
}
