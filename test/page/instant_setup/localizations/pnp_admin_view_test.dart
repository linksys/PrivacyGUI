import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/models/auto_master_status.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import '../../../common/di.dart';
import '../../../mocks/pnp_notifier_mocks.dart' as Mock;
import 'package:privacy_gui/page/instant_setup/data/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/pnp_admin_view.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../test_data/device_info_test_data.dart';

/// A stub destination for `RouteNamed.localLoginPassword` so redirect-to-login
/// paths can navigate inside the single-route test harness (which otherwise
/// only knows the '/' route and throws "unknown route name").
LinksysRoute _loginStubRoute() => LinksysRoute(
      name: RouteNamed.localLoginPassword,
      path: RoutePath.localLoginPassword,
      config: const LinksysRouteConfig(noNaviRail: true),
      builder: (context, state) => const SizedBox.shrink(key: Key('loginStub')),
    );

void main() async {
  late Mock.MockPnpNotifier mockPnpNotifier;

  mockDependencyRegister();
  ServiceHelper mockServiceHelper = getIt.get<ServiceHelper>();

  setUp(() {
    mockPnpNotifier = Mock.MockPnpNotifier();
  });

  testLocalizations('Instant Setup - PnP: Checking unconfigured router',
      (tester, locale) async {
    when(mockPnpNotifier.build()).thenReturn(
      PnpState(
        deviceInfo: NodeDeviceInfo.fromJson(
          jsonDecode(testDeviceInfo)['output'],
        ),
      ),
    );
    when(mockPnpNotifier.fetchDeviceInfo()).thenAnswer((_) async {});
    when(mockPnpNotifier.checkRouterConfigured()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 2));
    });

    await tester.pumpWidget(
      testableSingleRoute(
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true),
          noNaviRail: true,
        ),
        child: const PnpAdminView(),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
    );
    await tester.pump(const Duration(seconds: 1));
  });

  testLocalizations('Instant Setup - PnP: Router is unconfigured',
      (tester, locale) async {
    when(mockPnpNotifier.build()).thenReturn(
      PnpState(
        deviceInfo: NodeDeviceInfo.fromJson(
          jsonDecode(testDeviceInfo)['output'],
        ),
        isUnconfigured: true,
      ),
    );
    when(mockPnpNotifier.fetchDeviceInfo()).thenAnswer((_) async {});
    when(mockPnpNotifier.checkRouterConfigured()).thenAnswer((_) async {
      throw ExceptionRouterUnconfigured();
    });

    await tester.pumpWidget(
      testableSingleRoute(
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true),
          noNaviRail: true,
        ),
        child: const PnpAdminView(),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
    );
    await tester.runAsync(() async {
      final context = tester.element(find.byType(PnpAdminView));
      await precacheImage(
          CustomTheme.of(context).images.devices.routerLn12, context);
      await tester.pumpAndSettle();
    });
  });

  testLocalizations('Instant Setup - PnP: Checking internet connection',
      (tester, locale) async {
    when(mockPnpNotifier.build()).thenReturn(
      PnpState(
        deviceInfo: NodeDeviceInfo.fromJson(
          jsonDecode(testDeviceInfo)['output'],
        ),
      ),
    );
    when(mockPnpNotifier.fetchDeviceInfo()).thenAnswer((_) async {});
    when(mockPnpNotifier.checkRouterConfigured()).thenAnswer((_) async {});
    when(mockPnpNotifier.checkInternetConnection()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 2));
    });

    await tester.pumpWidget(
      testableSingleRoute(
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true),
          noNaviRail: true,
        ),
        child: const PnpAdminView(),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
    );
    await tester.pump(const Duration(seconds: 1));
  });

  testLocalizations('Instant Setup - PnP: Internet is connected',
      (tester, locale) async {
    when(mockPnpNotifier.build()).thenReturn(
      PnpState(
        deviceInfo: NodeDeviceInfo.fromJson(
          jsonDecode(testDeviceInfo)['output'],
        ),
      ),
    );
    when(mockPnpNotifier.fetchDeviceInfo()).thenAnswer((_) async {});
    when(mockPnpNotifier.checkRouterConfigured()).thenAnswer((_) async {});
    when(mockPnpNotifier.checkInternetConnection()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
    });

    await tester.pumpWidget(
      testableSingleRoute(
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true),
          noNaviRail: true,
        ),
        child: const PnpAdminView(),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
    );
    await tester.pump(const Duration(seconds: 2));
  });

  testLocalizations('Instant Setup - PnP: Password input required',
      (tester, locale) async {
    when(mockPnpNotifier.build()).thenReturn(
      PnpState(
        deviceInfo: NodeDeviceInfo.fromJson(
          jsonDecode(testDeviceInfo)['output'],
        ),
        isUnconfigured: false,
      ),
    );
    when(mockPnpNotifier.fetchDeviceInfo()).thenAnswer((_) async {});
    when(mockPnpNotifier.checkRouterConfigured()).thenAnswer((_) async {
      throw ExceptionRouterUnconfigured();
    });

    await tester.pumpWidget(
      testableSingleRoute(
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true),
          noNaviRail: true,
        ),
        child: const PnpAdminView(),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
    );
    await tester.pump(const Duration(seconds: 1));
  });

  testLocalizations('Instant Setup - PnP: Tap Where is it',
      (tester, locale) async {
    when(mockPnpNotifier.build()).thenReturn(
      PnpState(
        deviceInfo: NodeDeviceInfo.fromJson(
          jsonDecode(testDeviceInfo)['output'],
        ),
        isUnconfigured: false,
      ),
    );
    when(mockPnpNotifier.fetchDeviceInfo()).thenAnswer((_) async {});
    when(mockPnpNotifier.checkRouterConfigured()).thenAnswer((_) async {
      throw ExceptionRouterUnconfigured();
    });

    await tester.pumpWidget(
      testableSingleRoute(
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true),
          noNaviRail: true,
        ),
        child: const PnpAdminView(),
        locale: locale,
        overrides: [
          pnpProvider.overrideWith(() => mockPnpNotifier),
        ],
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    final btnFinder = find.byType(TextButton);
    await tester.tap(btnFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('Instant Setup - PnP: Auto Master running',
      (tester, locale) async {
    when(mockPnpNotifier.build()).thenReturn(
      PnpState(
        deviceInfo: NodeDeviceInfo.fromJson(
          jsonDecode(testDeviceInfo)['output'],
        ),
      ),
    );
    when(mockPnpNotifier.fetchDeviceInfo()).thenAnswer((_) async {});
    when(mockPnpNotifier.checkRouterConfigured()).thenAnswer((_) async {});
    when(mockPnpNotifier.checkAdminPassword(any)).thenAnswer((_) async {});
    when(mockPnpNotifier.checkAutoMasterStatus()).thenAnswer((_) async {
      return AutoMasterStatus.running;
    });
    when(mockPnpNotifier.pollAutoMasterStatus()).thenAnswer((_) {
      return Stream.fromFuture(Future.delayed(
          const Duration(seconds: 5), () => AutoMasterStatus.running));
    });

    await tester.pumpWidget(
      testableSingleRoute(
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true),
          noNaviRail: true,
        ),
        child: const PnpAdminView(),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
    );
    await tester.pump(const Duration(seconds: 2));
  });

  testLocalizations('Instant Setup - PnP: Auto Master connection error',
      (tester, locale) async {
    when(mockPnpNotifier.build()).thenReturn(
      PnpState(
        deviceInfo: NodeDeviceInfo.fromJson(
          jsonDecode(testDeviceInfo)['output'],
        ),
      ),
    );
    when(mockPnpNotifier.fetchDeviceInfo()).thenAnswer((_) async {});
    when(mockPnpNotifier.checkRouterConfigured()).thenAnswer((_) async {});
    when(mockPnpNotifier.checkAdminPassword(any)).thenAnswer((_) async {});
    when(mockPnpNotifier.checkAutoMasterStatus()).thenAnswer((_) async {
      return AutoMasterStatus.running;
    });
    // Return null 3 times to trigger connection error
    when(mockPnpNotifier.pollAutoMasterStatus()).thenAnswer((_) {
      return Stream.fromIterable([null, null, null]);
    });

    await tester.pumpWidget(
      testableSingleRoute(
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true),
          noNaviRail: true,
        ),
        child: const PnpAdminView(),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });

  testLocalizations(
      'Instant Setup - PnP: Auto Master check unauthorized redirects to login',
      (tester, locale) async {
    when(mockPnpNotifier.build()).thenReturn(
      PnpState(
        deviceInfo: NodeDeviceInfo.fromJson(
          jsonDecode(testDeviceInfo)['output'],
        ),
      ),
    );
    when(mockPnpNotifier.fetchDeviceInfo()).thenAnswer((_) async {});
    when(mockPnpNotifier.checkRouterConfigured()).thenAnswer((_) async {});
    when(mockPnpNotifier.checkAdminPassword(any)).thenAnswer((_) async {});
    when(mockPnpNotifier.checkAutoMasterStatus())
        .thenThrow(ExceptionAutoMasterUnauthorized());

    await tester.pumpWidget(
      testableSingleRoute(
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true),
          noNaviRail: true,
        ),
        child: const PnpAdminView(),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });

  // Regression: the poll STREAM (not just the pre-check Future) now terminates
  // on the first 401. make-Master rotates the admin password mid-poll; the
  // stream throws ExceptionAutoMasterUnauthorized, which the caller chain routes
  // to login instead of flattening to null and re-polling with stale creds.
  testLocalizations(
      'Instant Setup - PnP: Auto Master poll stream unauthorized redirects to login',
      (tester, locale) async {
    when(mockPnpNotifier.build()).thenReturn(
      PnpState(
        deviceInfo: NodeDeviceInfo.fromJson(
          jsonDecode(testDeviceInfo)['output'],
        ),
      ),
    );
    when(mockPnpNotifier.fetchDeviceInfo()).thenAnswer((_) async {});
    when(mockPnpNotifier.checkRouterConfigured()).thenAnswer((_) async {});
    when(mockPnpNotifier.checkAdminPassword(any)).thenAnswer((_) async {});
    when(mockPnpNotifier.checkAutoMasterStatus())
        .thenAnswer((_) async => AutoMasterStatus.running);
    when(mockPnpNotifier.pollAutoMasterStatus())
        .thenAnswer((_) => Stream.error(ExceptionAutoMasterUnauthorized()));

    await tester.pumpWidget(
      testableSingleRoute(
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true),
          noNaviRail: true,
        ),
        child: const PnpAdminView(),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
        extraRoutes: [_loginStubRoute()],
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    // The poll-stream 401 must land on the login page, not leave the waiting
    // spinner up (which would hang pumpAndSettle) nor stay on the admin view.
    expect(find.byKey(const Key('loginStub')), findsOneWidget);
  });
}
