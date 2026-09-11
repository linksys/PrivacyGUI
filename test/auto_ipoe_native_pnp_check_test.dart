import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_issue.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_models.dart';
import 'package:privacy_gui/page/auto_ipoe/service/auto_ipoe_internet_settings_bridge.dart';
import 'package:privacy_gui/page/auto_ipoe/service/auto_ipoe_service.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/isp_settings/pnp_ipoe_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'common/di.dart';
import 'common/testable_router.dart';
import 'mocks/pnp_notifier_mocks.dart' as mocks;
import 'test_data/device_info_test_data.dart';

class _Service extends Fake implements AutoIPoEService {
  @override
  Future<AutoIPoECapabilities> getCapabilities() async =>
      const AutoIPoECapabilities.init();
}

class _Bridge extends Fake implements AutoIPoEInternetSettingsBridge {
  final completion = Completer<void>();

  @override
  Future<AutoIPoELog> waitForPnpIPoESetupCompletion({
    int maxRetry = 80,
    Duration retryDelay = const Duration(seconds: 3),
    AutoIPoEMode? expectedMode,
    bool useStructuredProgress = false,
    AutoIPoEProgressCallback? onProgress,
    AutoIPoEReconciliationProgressCallback? onReconciliationProgress,
  }) async {
    await completion.future;
    onProgress?.call(
      const AutoIPoEStatus.init().copyWith(
        terminalResultSupported: true,
        connectivityVerified: true,
      ),
      const AutoIPoELog.init(),
    );
    return const AutoIPoELog.init();
  }
}

void main() {
  mockDependencyRegister();

  for (final connected in [true, false]) {
    testWidgets(
        'native ICC ${connected ? 'success' : 'failure'} after verified Auto-IPoE',
        (tester) async {
      final bridge = _Bridge();
      final nativeCheck = Completer<void>();
      final pnp = mocks.MockPnpNotifier();
      when(pnp.build()).thenReturn(PnpState(
        deviceInfo:
            NodeDeviceInfo.fromJson(jsonDecode(testDeviceInfo)['output']),
      ));
      when(pnp.checkInternetConnection(30))
          .thenAnswer((_) => nativeCheck.future);
      final router = GoRouter(initialLocation: '/ipoe', routes: [
        LinksysRoute(path: '/ipoe', builder: (_, __) => const PnpIpoeView()),
        GoRoute(
          name: RouteNamed.pnpIspSaveSettings,
          path: '/save',
          builder: (context, _) => TextButton(
            onPressed: () => context.pop(const AutoIPoEIssue(
              category: AutoIPoEIssueCategory.retryable,
              code: 'ApplyAccepted',
              retryable: true,
              recoveryAction: AutoIPoERecoveryAction.continueChecking,
            )),
            child: const Text('Accept apply'),
          ),
        ),
        GoRoute(
            name: RouteNamed.pnp,
            path: '/pnp',
            builder: (_, __) => const Text('Native PnP')),
        GoRoute(
            name: RouteNamed.pnpNoInternetConnection,
            path: '/offline',
            builder: (_, __) => const Text('Native offline')),
      ]);
      await tester.pumpWidget(testableRouter(
        router: router,
        locale: const Locale('en'),
        overrides: [
          autoIPoEServiceProvider.overrideWithValue(_Service()),
          autoIPoEInternetSettingsBridgeProvider.overrideWithValue(bridge),
          pnpProvider.overrideWith(() => pnp),
        ],
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Accept apply'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      verifyNever(pnp.checkInternetConnection(30));

      bridge.completion.complete();
      await tester.pump();
      verify(pnp.checkInternetConnection(30)).called(1);
      expect(router.routeInformationProvider.value.uri.path, '/ipoe');

      if (connected) {
        nativeCheck.complete();
      } else {
        nativeCheck.completeError(ExceptionNoInternetConnection());
      }
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path,
          connected ? '/pnp' : '/offline');
      expect(router.routeInformationProvider.value.uri.query, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
    });
  }
}
