import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';

/// Helper class for unit testing with mocktail
///
/// This provides lightweight mocks for service-layer unit tests.
/// Compliant with PrivacyGUI constitution requirement: "使用 mocktail 模擬所有依賴"
class UnitTestHelper {
  static void setupMocktailFallbacks() {
    // Register any generic fallback values needed
  }

  /// Creates a mock Ref with RouterRepository and DashboardHomeProvider
  ///
  /// Usage:
  /// ```dart
  /// final mockRef = UnitTestHelper.createMockRef(
  ///   routerRepository: mockRepository,
  ///   dashboardState: const DashboardHomeState(lanPortConnections: []),
  /// );
  /// ```
  static Ref createMockRef({
    required RouterRepository routerRepository,
    DashboardHomeState? dashboardState,
  }) {
    final mockRef = _MockRef(
      routerRepository,
      dashboardState: dashboardState ?? const DashboardHomeState(lanPortConnections: []),
    );
    return mockRef;
  }
}

/// Mock implementation of Ref with mocktail
class _MockRef extends Mock implements Ref {
  final RouterRepository _routerRepository;
  final DashboardHomeState _dashboardState;

  _MockRef(this._routerRepository, {required DashboardHomeState dashboardState})
      : _dashboardState = dashboardState;

  @override
  T read<T>(ProviderListenable<T> provider) {
    if (provider == routerRepositoryProvider) {
      return _routerRepository as T;
    }
    if (provider == dashboardHomeProvider) {
      return _dashboardState as T;
    }
    throw Exception('Unknown provider: $provider');
  }
}
