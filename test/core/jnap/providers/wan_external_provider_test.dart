import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/page/instant_verify/models/instant_verify_ui_models.dart';
import 'package:privacy_gui/page/instant_verify/providers/wan_external_provider.dart';
import 'package:privacy_gui/page/instant_verify/providers/wan_external_state.dart';
import 'package:privacy_gui/page/instant_verify/services/wan_external_service.dart';

class MockWanExternalService extends Mock implements WanExternalService {}

class MockServiceHelper extends Mock implements ServiceHelper {}

void main() {
  late MockWanExternalService mockService;
  late MockServiceHelper mockServiceHelper;
  late ProviderContainer container;

  final getIt = GetIt.instance;

  setUpAll(() {
    getIt.allowReassignment = true;
  });

  setUp(() {
    mockService = MockWanExternalService();
    mockServiceHelper = MockServiceHelper();

    // Register mock ServiceHelper with GetIt
    getIt.registerSingleton<ServiceHelper>(mockServiceHelper);

    // Default stub: WAN External is supported
    when(() => mockServiceHelper.isSupportWANExternal()).thenReturn(true);
  });

  tearDown(() {
    container.dispose();
    getIt.unregister<ServiceHelper>();
  });

  group('WANExternalNotifier - build', () {
    test('returns initial state with null wanExternal', () {
      // Arrange
      container = ProviderContainer(
        overrides: [
          wanExternalServiceProvider.overrideWithValue(mockService),
        ],
      );

      // Act
      final state = container.read(wanExternalProvider);

      // Assert
      expect(state.wanExternal, isNull);
      expect(state.lastUpdate, 0);
    });
  });

  group('WANExternalNotifier - fetch', () {
    test('calls service and updates state on success', () async {
      // Arrange
      const uiModel = WanExternalUIModel(
        publicWanIPv4: '1.1.1.1',
        privateWanIPv4: '192.168.1.1',
      );

      when(() => mockService.fetchWanExternal(force: any(named: 'force')))
          .thenAnswer((_) async => uiModel);

      container = ProviderContainer(
        overrides: [
          wanExternalServiceProvider.overrideWithValue(mockService),
        ],
      );

      // Act
      final result =
          await container.read(wanExternalProvider.notifier).fetch(force: true);

      // Assert
      verify(() => mockService.fetchWanExternal(force: true)).called(1);
      expect(result.wanExternal, uiModel);
      expect(result.lastUpdate, greaterThan(0));
    });

    // Note: Testing isSupportWANExternal() behavior requires integration test
    // because the serviceHelper getter is evaluated at library load time.
    // The actual business logic (service call, cache, error handling) is tested below.

    test('handles service error gracefully', () async {
      // Arrange
      when(() => mockService.fetchWanExternal(force: any(named: 'force')))
          .thenThrow(Exception('Service error'));

      container = ProviderContainer(
        overrides: [
          wanExternalServiceProvider.overrideWithValue(mockService),
        ],
      );

      // Act
      final result =
          await container.read(wanExternalProvider.notifier).fetch(force: true);

      // Assert - should not throw, just update lastUpdate
      expect(result.wanExternal, isNull);
      expect(result.lastUpdate, greaterThan(0));
    });

    test('respects cache timing and skips fetch when within cache period',
        () async {
      // Arrange
      const cachedModel = WanExternalUIModel(publicWanIPv4: 'cached');
      final cachedState = WANExternalState(
        wanExternal: cachedModel,
        lastUpdate: DateTime.now().millisecondsSinceEpoch,
      );

      when(() => mockService.fetchWanExternal(force: any(named: 'force')))
          .thenAnswer((_) async => const WanExternalUIModel(
                publicWanIPv4: 'fresh',
              ));

      container = ProviderContainer(
        overrides: [
          wanExternalServiceProvider.overrideWithValue(mockService),
          wanExternalProvider.overrideWith(() => _MockNotifier(cachedState)),
        ],
      );

      // Act
      final result = await container.read(wanExternalProvider.notifier).fetch();

      // Assert - should return cached state, not call service
      verifyNever(
          () => mockService.fetchWanExternal(force: any(named: 'force')));
      expect(result.wanExternal?.publicWanIPv4, 'cached');
    });

    test('fetches when cache is expired (> 1 hour)', () async {
      // Arrange
      const cachedModel = WanExternalUIModel(publicWanIPv4: 'cached');
      final expiredTimestamp =
          DateTime.now().millisecondsSinceEpoch - (3600 * 1000 + 1);
      final expiredState = WANExternalState(
        wanExternal: cachedModel,
        lastUpdate: expiredTimestamp,
      );

      const freshModel = WanExternalUIModel(publicWanIPv4: 'fresh');

      when(() => mockService.fetchWanExternal(force: any(named: 'force')))
          .thenAnswer((_) async => freshModel);

      container = ProviderContainer(
        overrides: [
          wanExternalServiceProvider.overrideWithValue(mockService),
          wanExternalProvider.overrideWith(() => _MockNotifier(expiredState)),
        ],
      );

      // Act
      final result = await container.read(wanExternalProvider.notifier).fetch();

      // Assert - should call service since cache expired
      verify(() => mockService.fetchWanExternal(force: false)).called(1);
      expect(result.wanExternal?.publicWanIPv4, 'fresh');
    });
  });
}

/// Test notifier that starts with a pre-set state
class _MockNotifier extends WANExternalNotifier {
  final WANExternalState _initialState;

  _MockNotifier(this._initialState);

  @override
  WANExternalState build() => _initialState;
}
