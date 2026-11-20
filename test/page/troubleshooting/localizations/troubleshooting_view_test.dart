import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/troubleshooting/_troubleshooting.dart';

import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../mocks/troubleshooting_notifier_mocks.dart';

void main() {
  late MockTroubleshootingNotifier mockTroubleshootingNotifier;

  mockDependencyRegister();

  setUp(() {
    mockTroubleshootingNotifier = MockTroubleshootingNotifier();
    when(mockTroubleshootingNotifier.build()).thenReturn(
        const TroubleshootingState(deviceStatusList: [], dhcpClientList: []));
    when(mockTroubleshootingNotifier.fetch(force: anyNamed('force')))
        .thenAnswer((_) async {});
    when(mockTroubleshootingNotifier.ping(
            host: anyNamed('host'), pingCount: anyNamed('pingCount')))
        .thenAnswer((_) async {});
    when(mockTroubleshootingNotifier.getPingStatus())
        .thenAnswer((_) => const Stream.empty());
  });

  for (final (name, page) in const [
    ('Troubleshooting view', TroubleshootingView()),
    ('Troubleshooting ping view', TroubleshootingPingView()),
  ]) {
    testLocalizations(name, (tester, locale) async {
      await tester.pumpWidget(testableSingleRoute(
        overrides: [
          troubleshootingProvider
              .overrideWith(() => mockTroubleshootingNotifier),
        ],
        locale: locale,
        child: page,
      ));
    });
  }
}
