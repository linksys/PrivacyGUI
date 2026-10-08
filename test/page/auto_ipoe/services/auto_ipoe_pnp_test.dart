import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/instant_setup/services/pnp_service.dart';

import '../../../mocks/test_data/auto_ipoe_test_data.dart';

class MockPnpClient extends Mock implements UspClient {}

void main() {
  test(
    'PnP accepts verified native tunnel without physical WAN IPv4',
    () async {
      final client = MockPnpClient();
      final wire = AutoIPoETestData.wire();
      wire['Device.X_LINKSYS_AutoIPoE.Status'] = jsonEncode(
        AutoIPoETestData.snapshot(
          requestId: AutoIPoETestData.id,
          exitCode: 0,
          verified: true,
        ).runtime.toMap(),
      );
      when(() => client.get(any(), fresh: true)).thenAnswer((_) async => wire);
      expect(await PnpService(client).checkInternetConnected(), true);
      verify(() => client.get(any(), fresh: true)).called(1);
    },
  );
  test(
    'PnP never promotes accepted Apply or unverified native tunnel',
    () async {
      final client = MockPnpClient();
      when(() => client.get(any(), fresh: true))
          .thenAnswer((_) async => AutoIPoETestData.wire());
      expect(await PnpService(client).checkInternetConnected(), false);
    },
  );
}
