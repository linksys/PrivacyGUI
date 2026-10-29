import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/page/_shared/models/lan_info_ui_model.dart';
import 'package:privacy_gui/page/dashboard/providers/pdf_report_provider.dart';
import 'package:privacy_gui/page/ipv6_port_service/services/usp_ipv6_port_service_service.dart';
import 'package:privacy_gui/page/local_network/providers/lan_data_provider.dart';
import 'package:privacy_gui/page/static_routing/providers/usp_static_routing_notifier.dart';
import 'package:privacy_gui/page/static_routing/services/usp_static_routing_service.dart';

import '../../../mocks/test_data/scenes/ipv6_port_service_scene_data.dart';
import '../../../mocks/test_data/scenes/static_routing_scene_data.dart';
import '../../../util/dashboard/kitchen_sink_overrides.dart';

class _MockStaticRoutingService extends Mock
    implements UspStaticRoutingService {}

class _MockIpv6PortServiceService extends Mock
    implements UspIpv6PortServiceService {}

void main() {
  late _MockStaticRoutingService routing;
  late _MockIpv6PortServiceService ipv6;

  setUp(() {
    routing = _MockStaticRoutingService();
    ipv6 = _MockIpv6PortServiceService();
    when(() => routing.fetch()).thenAnswer((_) async => const [route1]);
    when(() => ipv6.fetch()).thenAnswer((_) async => testRules);
  });

  /// Every source the report reads, so none starts a real USP fetch.
  ProviderContainer containerWithSources() {
    final c = ProviderContainer(overrides: [
      ...kitchenSinkOverrides(),
      uspMutationLockProvider.overrideWithValue(UspMutationLock()),
      uspStaticRoutingServiceProvider.overrideWithValue(routing),
      uspIpv6PortServiceServiceProvider.overrideWithValue(ipv6),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('PdfReport.snapshot', () {
    test('a second export reads the data as it is now, not as it was',
        () async {
      final container = containerWithSources();
      await container.read(lanDataProvider.future);
      final report = container.read(pdfReportProvider);

      expect((await report.snapshot()).lanInfo?.ipAddress, '192.168.1.1');

      container.read(lanDataProvider.notifier).state = const AsyncData(
        LanData(
          model: LanInfoUIModel(
            ipAddress: '10.0.0.1',
            subnetMask: '255.255.255.0',
            dhcpEnabled: true,
            minAddress: '10.0.0.100',
            maxAddress: '10.0.0.200',
          ),
        ),
      );

      expect((await report.snapshot()).lanInfo?.ipAddress, '10.0.0.1');
    });

    // Nothing on the dashboard holds these two page notifiers, so each starts
    // empty and fetches in a microtask. Reading their state on the spot printed
    // the empty list, and the PDF skips an empty section: neither ever printed.
    test('static routes and IPv6 rules are read from the router, not skipped',
        () async {
      final container = containerWithSources();

      final data = await container.read(pdfReportProvider).snapshot();

      expect(data.staticRoutes, const [route1]);
      expect(data.ipv6PortRules, testRules);
      verify(() => routing.fetch()).called(1);
      verify(() => ipv6.fetch()).called(1);
    });

    // The mascot can export from any route, including over an open Static
    // Routing page. Reading the router must not reset that page's edits.
    test('an export leaves an open page\'s unsaved edits alone', () async {
      final container = containerWithSources();
      container.listen(uspStaticRoutingProvider, (_, __) {});
      // The page's own first load (build() schedules it) lands before the edit.
      await pumpEventQueue();
      container.read(uspStaticRoutingProvider.notifier).addRoute(route2);
      expect(
          container.read(uspStaticRoutingProvider.notifier).isDirty(), isTrue);

      await container.read(pdfReportProvider).snapshot();
      await pumpEventQueue();

      expect(
          container.read(uspStaticRoutingProvider.notifier).isDirty(), isTrue);
      expect(
          container
              .read(uspStaticRoutingProvider)
              .settings
              .current
              .routes
              .map((r) => r.name),
          contains(route2.name));
    });

    test('a section the router cannot read is left out, not the report',
        () async {
      when(() => routing.fetch())
          .thenThrow(const NetworkError(detail: 'unreachable'));
      final container = containerWithSources();

      final data = await container.read(pdfReportProvider).snapshot();

      expect(data.staticRoutes, isNull);
      expect(data.ipv6PortRules, testRules);
      expect(data.lanInfo, isNotNull,
          reason: 'the rest of the report is built');
    });
  });
}
