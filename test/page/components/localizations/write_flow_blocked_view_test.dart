import 'package:privacy_gui/page/components/views/write_flow_blocked_view.dart';

import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';

void main() {
  mockDependencyRegister();

  testLocalizations('Write flow blocked view', (tester, locale) async {
    await tester.pumpWidget(testableSingleRoute(
      locale: locale,
      child: const WriteFlowBlockedView(),
    ));
  });
}
