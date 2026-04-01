import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/cs_diagnostic/providers/cs_diagnostic_auth_provider.dart';
import 'package:privacy_gui/page/cs_diagnostic/providers/cs_diagnostic_provider.dart';
import 'package:privacy_gui/page/cs_diagnostic/providers/cs_diagnostic_state.dart';
import 'package:privacy_gui/page/cs_diagnostic/views/diagnostic_entry_view.dart';
import 'package:privacy_gui/page/cs_diagnostic/views/customer/customer_home_view.dart';
import 'package:privacy_gui/page/cs_diagnostic/views/customer/flow_slow_internet_view.dart';
import 'package:privacy_gui/page/cs_diagnostic/views/agent/agent_dashboard_view.dart';

import '../../../../common/config.dart';
import '../../../../common/di.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../common/testable_router.dart';
import '../../../../mocks/_index.dart';
import 'cs_diagnostic_test_data.dart';

void main() async {
  late MockDiagnosticAuthNotifier mockDiagnosticAuthNotifier;
  late MockCsDiagnosticNotifier mockCsDiagnosticNotifier;

  mockDependencyRegister();

  List<Override> overrideRegister() {
    return [
      diagnosticAuthProvider.overrideWith(() => mockDiagnosticAuthNotifier),
      csDiagnosticProvider.overrideWith(() => mockCsDiagnosticNotifier),
    ];
  }

  setUp(() {
    mockDiagnosticAuthNotifier = MockDiagnosticAuthNotifier();
    mockCsDiagnosticNotifier = MockCsDiagnosticNotifier();
  });

  group('CS Diagnostic Views - Customer Flow', () {
    setUp(() {
      when(mockDiagnosticAuthNotifier.build()).thenReturn(
        const DiagnosticAuthState(status: DiagnosticAuthStatus.unauthenticated),
      );
    });

    testLocalizations('Diagnostic Entry View - Customer Mode',
        (tester, locale) async {
      await tester.pumpWidget(
        testableRouteShellWidget(
          child: const DiagnosticEntryView(),
          locale: locale,
          overrides: overrideRegister(),
        ),
      );
      await tester.pumpAndSettle();
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1200)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 800)).toList()
    ]);

    testLocalizations('Customer Home View - Default State',
        (tester, locale) async {
      await tester.pumpWidget(
        testableRouteShellWidget(
          child: const CustomerHomeView(),
          locale: locale,
          overrides: overrideRegister(),
        ),
      );
      await tester.pumpAndSettle();
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1200)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 800)).toList()
    ]);

    testLocalizations('Flow Slow Internet View - Initial Loading',
        (tester, locale) async {
      await tester.pumpWidget(
        testableRouteShellWidget(
          child: const FlowSlowInternetView(),
          locale: locale,
          overrides: overrideRegister(),
        ),
      );
      await tester.pump(); // Don't settle to capture loading state
      await tester.pump(const Duration(milliseconds: 100));
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1200)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 800)).toList()
    ]);
  });

  group('CS Diagnostic Views - Agent Dashboard', () {
    setUp(() {
      when(mockDiagnosticAuthNotifier.build()).thenReturn(
        const DiagnosticAuthState(status: DiagnosticAuthStatus.authenticated),
      );
      // Mock auth methods
      when(mockDiagnosticAuthNotifier.logout()).thenReturn(null);
      when(mockCsDiagnosticNotifier.build()).thenReturn(
        csDiagnosticLoadedState,
      );
      // Mock fetch() method to prevent actual API calls in all tests
      when(mockCsDiagnosticNotifier.fetch()).thenAnswer((_) async {});
      // Mock other methods that might be called
      when(mockCsDiagnosticNotifier.toggleDegraded()).thenReturn(null);
      when(mockCsDiagnosticNotifier.toggleMock()).thenReturn(null);
      when(mockCsDiagnosticNotifier.useMock).thenReturn(false);
      when(mockCsDiagnosticNotifier.useDegraded).thenReturn(false);
    });

    testLocalizations('Agent Dashboard - Loading State',
        (tester, locale) async {
      when(mockCsDiagnosticNotifier.build()).thenReturn(
        const CsDiagnosticState(loadState: DiagnosticLoadState.loading),
      );
      // Mock fetch() method to prevent actual API calls during loading state test
      when(mockCsDiagnosticNotifier.fetch()).thenAnswer((_) async {});

      await tester.pumpWidget(
        testableRouteShellWidget(
          child: const AgentDashboardView(),
          locale: locale,
          overrides: overrideRegister(),
        ),
      );
      // Use pump() instead of pumpAndSettle() to capture loading state
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 800)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 600)).toList()
    ]);

    testLocalizations('Agent Dashboard - Loaded State',
        (tester, locale) async {
      when(mockCsDiagnosticNotifier.build()).thenReturn(
        csDiagnosticLoadedState,
      );
      // Mock fetch() method to prevent actual API calls
      when(mockCsDiagnosticNotifier.fetch()).thenAnswer((_) async {});

      await tester.pumpWidget(
        testableRouteShellWidget(
          child: const AgentDashboardView(),
          locale: locale,
          overrides: overrideRegister(),
        ),
      );
      await tester.pumpAndSettle();
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1400)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1000)).toList()
    ]);

    testLocalizations('Agent Dashboard - Error State',
        (tester, locale) async {
      when(mockCsDiagnosticNotifier.build()).thenReturn(
        const CsDiagnosticState(
          loadState: DiagnosticLoadState.error,
          errorMessage: 'Connection failed',
        ),
      );
      // Mock fetch() method to prevent actual API calls
      when(mockCsDiagnosticNotifier.fetch()).thenAnswer((_) async {});

      await tester.pumpWidget(
        testableRouteShellWidget(
          child: const AgentDashboardView(),
          locale: locale,
          overrides: overrideRegister(),
        ),
      );
      await tester.pumpAndSettle();
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 800)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 600)).toList()
    ]);

    testLocalizations('Agent Dashboard - Degraded Network State',
        (tester, locale) async {
      when(mockCsDiagnosticNotifier.build()).thenReturn(
        csDiagnosticDegradedState,
      );
      // Mock fetch() method to prevent actual API calls
      when(mockCsDiagnosticNotifier.fetch()).thenAnswer((_) async {});

      await tester.pumpWidget(
        testableRouteShellWidget(
          child: const AgentDashboardView(),
          locale: locale,
          overrides: overrideRegister(),
        ),
      );
      await tester.pumpAndSettle();
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1400)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1000)).toList()
    ]);
  });
}