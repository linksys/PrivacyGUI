import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/ipv6_port_service/providers/ipv6_port_service_data_provider.dart';
import 'package:privacy_gui/page/ipv6_port_service/services/usp_ipv6_port_service_service.dart';

import '../../../mocks/test_data/ipv6_port_service_test_data.dart';

class MockUspIpv6PortServiceService extends Mock
    implements UspIpv6PortServiceService {}

void main() {
  late MockUspIpv6PortServiceService svc;

  setUp(() {
    svc = MockUspIpv6PortServiceService();
  });

  ProviderContainer containerWith(MockUspIpv6PortServiceService svc) {
    final container = ProviderContainer(overrides: [
      uspIpv6PortServiceServiceProvider.overrideWithValue(svc),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  test('holds the rules the IPv6 Port Service page lists', () async {
    final rules = [
      Ipv6PortServiceTestData.createRule(),
      Ipv6PortServiceTestData.createRule(enabled: false),
    ];
    when(() => svc.fetch()).thenAnswer((_) async => rules);

    final container = containerWith(svc);

    expect(await container.read(ipv6PortServiceDataProvider.future), rules);
  });

  test('a failed read is an error, not "no rules"', () async {
    when(() => svc.fetch()).thenAnswer((_) async => throw const TimeoutError());
    final container = containerWith(svc);
    container.listen(ipv6PortServiceDataProvider, (_, __) {});

    await expectLater(
      container.read(ipv6PortServiceDataProvider.future),
      throwsA(isA<TimeoutError>()),
    );
    expect(container.read(ipv6PortServiceDataProvider).valueOrNull, isNull);
  });
}
