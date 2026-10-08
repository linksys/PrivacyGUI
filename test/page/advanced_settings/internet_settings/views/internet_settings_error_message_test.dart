import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/_providers.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/views/internet_settings_view.dart';

import '../../../../common/config.dart';
import '../../../../common/di.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../common/testable_router.dart';
import '../../../../mocks/internet_settings_notifier_mocks.dart';
import '../../../../test_data/internet_settings_state_data.dart';

// #1637: Release & Renew reports its failures through PageSnackbarMixin now.
// The page built the same message itself before, so what a user reads must not
// change: the two WAN-type errors keep their own text, and every other error is
// worded as it was.
void main() {
  late MockInternetSettingsNotifier internetSettings;

  mockDependencyRegister();
  final ServiceHelper mockServiceHelper = GetIt.I<ServiceHelper>();

  setUp(() {
    internetSettings = MockInternetSettingsNotifier();
    final state = InternetSettingsState.fromMap(internetSettingsStateDHCP);
    when(internetSettings.build()).thenReturn(state);
    when(internetSettings.fetch(fetchRemote: anyNamed('fetchRemote')))
        .thenAnswer((_) async => state);
  });

  tearDown(() => reset(mockServiceHelper));

  Future<void> Function() failingAfterRoundTrip(Object error) => () async {
        // doSomethingWithSpinner only attaches to the task once its spinner is
        // up, about 100 ms in.
        await Future<void>.delayed(const Duration(milliseconds: 300));
        throw error;
      };

  /// Opens Release & Renew for the [index]th WAN section (IPv4 first, then
  /// IPv6) and confirms it.
  Future<void> releaseAndRenew(WidgetTester tester, int index) async {
    await tester.setScreenSize(device1440w);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(testableSingleRoute(
      locale: const Locale('en'),
      child: const InternetSettingsView(),
      overrides: [
        internetSettingsProvider.overrideWith(() => internetSettings),
      ],
    ));
    await tester.pumpAndSettle();

    // English only, so tapping the tab is safe: the label fits.
    await tester.tap(find.byType(Tab).at(2));
    await tester.pumpAndSettle();
    final buttons = find.descendant(
        of: find.byType(TabBarView), matching: find.text('Release & Renew'));
    await tester.tap(buttons.at(index));
    await tester.pumpAndSettle();
    // The confirm alert's own Release & Renew button.
    await tester.tap(find.text('Release & Renew').last);
    await tester.pump(const Duration(seconds: 1));
  }

  group('IPv4', () {
    Future<void> failWith(WidgetTester tester, Object error) async {
      when(internetSettings.renewDHCPWANLease())
          .thenAnswer((_) => failingAfterRoundTrip(error)());
      await releaseAndRenew(tester, 0);
    }

    testWidgets('a WAN type that is not DHCP says so', (tester) async {
      await failWith(tester, const JNAPError(result: 'ErrorInvalidWANType'));

      expect(find.text('The current WAN type is not DHCP.'), findsOneWidget);
    });

    testWidgets('a known error code keeps its message', (tester) async {
      await failWith(tester, const JNAPError(result: 'ErrorInvalidIPAddress'));

      expect(find.text('Invalid IP address'), findsOneWidget);
    });

    testWidgets('an unknown error code is named', (tester) async {
      await failWith(tester, const JNAPError(result: 'ErrorSomethingNew'));

      expect(find.text('Unknown error: ErrorSomethingNew'), findsOneWidget);
    });

    testWidgets('a refused write adds no message of its own', (tester) async {
      await failWith(
          tester, const ReadOnlyAccessException(JNAPAction.renewDHCPWANLease));

      expect(find.byType(SnackBar), findsNothing);
    });
  });

  group('IPv6', () {
    Future<void> failWith(WidgetTester tester, Object error) async {
      when(internetSettings.renewDHCPIPv6WANLease())
          .thenAnswer((_) => failingAfterRoundTrip(error)());
      await releaseAndRenew(tester, 1);
    }

    testWidgets('a connection type that is not automatic says so',
        (tester) async {
      await failWith(
          tester, const JNAPError(result: 'ErrorInvalidIPv6WANType'));

      expect(
          find.text('The current WAN IPv6 connection type is not automatic.'),
          findsOneWidget);
    });

    testWidgets('a known error code keeps its message', (tester) async {
      await failWith(tester, const JNAPError(result: 'ErrorInvalidIPAddress'));

      expect(find.text('Invalid IP address'), findsOneWidget);
    });
  });
}
