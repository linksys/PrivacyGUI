import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/health_check/views/speed_test_external.dart';

import '../../../../common/di.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../common/testable_router.dart';

void main() {
  mockDependencyRegister();
  ServiceHelper mockServiceHelper = getIt.get<ServiceHelper>();

  setUp(() {});

  testLocalizations('SpeedtestExternal - init', (tester, locale) async {
    final widget = testableSingleRoute(
      overrides: [],
      locale: locale,
      child: const SpeedTestExternalView(),
    );
    await tester.pumpWidget(widget);
  });
}
