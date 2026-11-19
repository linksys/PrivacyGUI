import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dashboard/views/prepare_dashboard_view.dart';
import 'package:privacy_gui/providers/connectivity/_connectivity.dart';

import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';

/// Connectivity that never finishes its update, so the page stays on its
/// spinner: the first thing it does is wait for one.
class _Updating extends ConnectivityNotifier {
  @override
  ConnectivityState build() => const ConnectivityState(
      hasInternet: true, connectivityInfo: ConnectivityInfo());

  @override
  Future<ConnectivityState> forceUpdate() =>
      Completer<ConnectivityState>().future;
}

void main() {
  mockDependencyRegister();

  testLocalizations('Prepare dashboard view', (tester, locale) async {
    await tester.pumpWidget(testableSingleRoute(
      overrides: [connectivityProvider.overrideWith(_Updating.new)],
      locale: locale,
      child: const PrepareDashboardView(),
    ));
  });
}
