import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/page/dashboard/mascot/mascot_providers.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_domain_ready_provider.dart';
import 'package:privacy_gui/providers/app_settings/app_settings.dart';
import 'package:privacy_gui/providers/app_settings/app_settings_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

class MockMascotController extends Mock implements MascotController {}

void main() {
  late MockMascotController mockController;

  setUp(() {
    mockController = MockMascotController();

    when(() => mockController.isVisible).thenReturn(true);
    when(() => mockController.isDialogVisible).thenReturn(false);
    when(() => mockController.state).thenReturn(MascotState.idle);
    when(() => mockController.addListener(any())).thenReturn(null);
    when(() => mockController.removeListener(any())).thenReturn(null);
  });

  group('MascotCoordinatorNotifier - activation conditions', () {
    test('does not start timer when showMascot is false', () async {
      final container = ProviderContainer(
        overrides: [
          mascotControllerProvider.overrideWithValue(mockController),
          appSettingsProvider.overrideWith(
            () => _TestAppSettingsNotifier(showMascot: false),
          ),
          dashboardDomainReadyProvider.overrideWith((ref) async {}),
        ],
      );
      addTearDown(container.dispose);

      // Wait for FutureProvider to complete
      await container.read(dashboardDomainReadyProvider.future);
      container.read(mascotCoordinatorProvider);

      verifyNever(() => mockController.addListener(any()));
    });

    test('does not start timer when dashboard is not ready', () async {
      final container = ProviderContainer(
        overrides: [
          mascotControllerProvider.overrideWithValue(mockController),
          appSettingsProvider.overrideWith(
            () => _TestAppSettingsNotifier(showMascot: true),
          ),
          dashboardDomainReadyProvider.overrideWith(
            (ref) => Future.error('Not ready'),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Try to read - will be in error state
      try {
        await container.read(dashboardDomainReadyProvider.future);
      } catch (_) {}
      container.read(mascotCoordinatorProvider);

      verifyNever(() => mockController.addListener(any()));
    });

    test('starts timer when showMascot is true and dashboard is ready',
        () async {
      final container = ProviderContainer(
        overrides: [
          mascotControllerProvider.overrideWithValue(mockController),
          appSettingsProvider.overrideWith(
            () => _TestAppSettingsNotifier(showMascot: true),
          ),
          dashboardDomainReadyProvider.overrideWith((ref) async {}),
        ],
      );
      addTearDown(container.dispose);

      // Wait for FutureProvider to complete
      await container.read(dashboardDomainReadyProvider.future);
      container.read(mascotCoordinatorProvider);

      verify(() => mockController.addListener(any())).called(1);
    });
  });

  group('MascotCoordinatorNotifier - cleanup', () {
    test('removes listener on dispose', () async {
      final container = ProviderContainer(
        overrides: [
          mascotControllerProvider.overrideWithValue(mockController),
          appSettingsProvider.overrideWith(
            () => _TestAppSettingsNotifier(showMascot: true),
          ),
          dashboardDomainReadyProvider.overrideWith((ref) async {}),
        ],
      );

      // Wait for FutureProvider to complete
      await container.read(dashboardDomainReadyProvider.future);
      container.read(mascotCoordinatorProvider);

      container.dispose();

      verify(() => mockController.removeListener(any())).called(1);
    });
  });
}

class _TestAppSettingsNotifier extends AppSettingsNotifier {
  _TestAppSettingsNotifier({required bool showMascot})
      : _settings = AppSettings(showMascot: showMascot);

  final AppSettings _settings;

  @override
  AppSettings build() => _settings;
}
