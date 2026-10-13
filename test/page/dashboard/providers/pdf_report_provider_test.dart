import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/lan_info_ui_model.dart';
import 'package:privacy_gui/page/dashboard/providers/pdf_report_provider.dart';
import 'package:privacy_gui/page/local_network/providers/lan_data_provider.dart';

import '../../../mocks/provider_overrides/mock_ipv6_port_service.dart';
import '../../../mocks/provider_overrides/mock_static_routing.dart';
import '../../../util/dashboard/kitchen_sink_overrides.dart';

void main() {
  group('PdfReport.snapshot', () {
    test('a second export reads the data as it is now, not as it was',
        () async {
      // Every source the report reads, so none starts a real USP fetch.
      final container = ProviderContainer(overrides: [
        ...kitchenSinkOverrides(),
        ...staticRoutingOverrides(),
        ...ipv6PortServiceOverrides(),
      ]);
      addTearDown(container.dispose);
      await container.read(lanDataProvider.future);
      final report = container.read(pdfReportProvider);

      expect(report.snapshot().lanInfo?.ipAddress, '192.168.1.1');

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

      expect(report.snapshot().lanInfo?.ipAddress, '10.0.0.1');
    });
  });
}
