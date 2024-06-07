import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/page/pnp/data/pnp_exception.dart';
import 'package:privacy_gui/page/pnp/data/pnp_provider.dart';
import 'package:privacy_gui/page/pnp/troubleshooter/providers/pnp_troubleshooter_provider.dart';
import 'package:privacy_gui/page/pnp/troubleshooter/views/pnp_no_internet_connection_view.dart';
import '../../../../common/mock_firebase_messaging.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../common/testable_router.dart';
import '../../../../test_data/device_info_test_data.dart';
import '../../pnp_admin_view_test_mocks.dart' as Mock;
import 'package:privacy_gui/page/pnp/data/pnp_state.dart';

import '../../pnp_no_internet_connection_view_test_mocks.dart';

@GenerateNiceMocks([MockSpec<PnpTroubleshooterNotifier>()])
void main() async {
  late Mock.MockPnpNotifier mockPnpNotifier;
  late MockPnpTroubleshooterNotifier mockPnpTroubleshooterNotifier;

  setupFirebaseMessagingMocks();
  await Firebase.initializeApp();

  setUp(() {
    mockPnpNotifier = Mock.MockPnpNotifier();
    mockPnpTroubleshooterNotifier = MockPnpTroubleshooterNotifier();

    when(mockPnpNotifier.build()).thenReturn(PnpState(
        deviceInfo:
            NodeDeviceInfo.fromJson(jsonDecode(testDeviceInfo)['output']),
        isUnconfigured: true));
    when(mockPnpNotifier.checkAdminPassword(null)).thenAnswer((_) {
      throw ExceptionInvalidAdminPassword();
    });
  });

  testLocalizations('pnp no internet connection view - no ssid ',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const PnpNoInternetConnectionView(),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
    );
    await tester.pumpAndSettle();
  });

  testLocalizations('pnp no internet connection view - with ssid',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const PnpNoInternetConnectionView(
          args: {'ssid': 'AwesomeSSID'},
        ),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
    );
    await tester.pumpAndSettle();
  });

  testLocalizations('pnp no internet connection view - need help',
      (tester, locale) async {
    when(mockPnpTroubleshooterNotifier.build())
        .thenReturn(PnpTroubleshooterState(hasResetModem: true));
    await tester.pumpWidget(
      testableSingleRoute(
        child: const PnpNoInternetConnectionView(
          args: {'ssid': 'AwesomeSSID'},
        ),
        locale: locale,
        overrides: [
          pnpProvider.overrideWith(() => mockPnpNotifier),
          pnpTroubleshooterProvider
              .overrideWith(() => mockPnpTroubleshooterNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();
  });
}
