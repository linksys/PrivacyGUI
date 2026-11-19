import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/ping_status.dart';
import 'package:privacy_gui/page/troubleshooting/_troubleshooting.dart';

import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';

/// The real notifier with the router taken out: the pages fetch on entry.
class _FakeTroubleshooting extends TroubleshootingNotifier {
  @override
  TroubleshootingState build() =>
      const TroubleshootingState(deviceStatusList: [], dhcpClientList: []);

  @override
  Future fetch({bool force = false}) async {}

  @override
  Future ping({required String host, required int? pingCount}) async {}

  @override
  Stream<PingStatus> getPingStatus() => const Stream.empty();
}

void main() {
  mockDependencyRegister();

  for (final (name, page) in const [
    ('Troubleshooting view', TroubleshootingView()),
    ('Troubleshooting ping view', TroubleshootingPingView()),
  ]) {
    testLocalizations(name, (tester, locale) async {
      await tester.pumpWidget(testableSingleRoute(
        overrides: [
          troubleshootingProvider.overrideWith(_FakeTroubleshooting.new),
        ],
        locale: locale,
        child: page,
      ));
    });
  }
}
