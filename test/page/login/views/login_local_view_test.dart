// Widget tests for what the login page says about a locked admin account.
//
// This is the far end of the poll loop's forced logout: a router that starts
// refusing the stored credential locks the admin account after a handful of
// attempts, and PollingNotifier logs the operator out rather than go on spending
// them (see polling_provider_test.dart's 'a locked admin account logs out'). The
// page they land on is the only thing that tells them why, and it works that out
// for itself - it asks the router for the admin password auth status on the way
// in, rather than being handed a message by whatever logged them out.
//
// Rendered by the localization goldens already, but nothing asserted the text,
// which is the half that matters: an operator dropped onto a login page with no
// explanation would keep trying the password they have and keep the lockout
// alive.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/page/login/views/login_local_view.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/route/route_model.dart';

import '../../../common/di.dart';
import '../../../common/testable_router.dart';
import '../../../mocks/_index.dart';
import '../../../test_data/device_info_test_data.dart';

void main() {
  late MockDashboardManagerNotifier mockDashboardManagerNotifier;
  late MockAuthNotifier mockAuthNotifier;

  mockDependencyRegister();

  setUp(() {
    mockDashboardManagerNotifier = MockDashboardManagerNotifier();
    when(mockDashboardManagerNotifier.checkDeviceInfo(null)).thenAnswer(
      (_) async =>
          NodeDeviceInfo.fromJson(jsonDecode(testDeviceInfo)['output']),
    );

    mockAuthNotifier = MockAuthNotifier();
    when(mockAuthNotifier.build()).thenAnswer(
      (_) async => AuthState.empty().copyWith(localPasswordHint: 'Linksys'),
    );
    when(mockAuthNotifier.getPasswordHint()).thenAnswer((_) async {});
  });

  /// Stands the login page up over a router reporting [authStatus] for the admin
  /// password - which is what the page asks for on the way in.
  Future<void> pumpLoginLocal(
    WidgetTester tester,
    Map<String, dynamic>? authStatus,
  ) async {
    when(mockAuthNotifier.getAdminPasswordAuthStatus(any))
        .thenAnswer((_) async => authStatus);

    await tester.pumpWidget(testableSingleRoute(
      child: const LoginLocalView(),
      locale: const Locale('en'),
      config: LinksysRouteConfig(noNaviRail: true),
      overrides: [
        dashboardManagerProvider
            .overrideWith(() => mockDashboardManagerNotifier),
        authProvider.overrideWith(() => mockAuthNotifier),
      ],
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('a locked account says so without being asked', (tester) async {
    // The state a forced logout lands in: the attempts are gone, so there is no
    // countdown to offer and nothing the operator can usefully type.
    await pumpLoginLocal(tester, {'attemptsRemaining': 0});

    expect(find.textContaining('Too many failed attempts'), findsOneWidget);
  });

  testWidgets('an account with attempts left is told how many', (tester) async {
    // Short of the lockout, the useful thing to say is how much room is left -
    // this is the page's own count, read from the router rather than guessed at.
    await pumpLoginLocal(
        tester, {'attemptsRemaining': 4, 'delayTimeRemaining': 5});

    expect(find.textContaining('Remaining attempts: 4'), findsOneWidget);
  });

  testWidgets('a router with nothing to report is left alone', (tester) async {
    // getAdminPasswordAuthStatus is a core7 service; an older router answers
    // null, and an unexplained warning would be worse than none.
    await pumpLoginLocal(tester, null);

    expect(find.textContaining('Too many failed attempts'), findsNothing);
    expect(find.textContaining('Remaining attempts'), findsNothing);
  });
}
