import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/dashboard/views/prepare_dashboard_view.dart';
import 'package:privacy_gui/providers/connectivity/_connectivity.dart';

import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../mocks/connectivity_notifier_mocks.dart';

void main() {
  late MockConnectivityNotifier mockConnectivityNotifier;

  mockDependencyRegister();

  setUp(() {
    mockConnectivityNotifier = MockConnectivityNotifier();
    when(mockConnectivityNotifier.build()).thenReturn(const ConnectivityState(
        hasInternet: true, connectivityInfo: ConnectivityInfo()));
    // The page first waits for connectivity to update. This one never
    // finishes, so the page stays on its spinner.
    when(mockConnectivityNotifier.forceUpdate())
        .thenAnswer((_) => Completer<ConnectivityState>().future);
  });

  testLocalizations('Prepare dashboard view', (tester, locale) async {
    await tester.pumpWidget(testableSingleRoute(
      overrides: [
        connectivityProvider.overrideWith(() => mockConnectivityNotifier),
      ],
      locale: locale,
      child: const PrepareDashboardView(),
    ));
  });
}
