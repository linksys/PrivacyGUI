import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/page/dmz/models/dmz_settings.dart';
import 'package:privacy_gui/page/dmz/models/dmz_status.dart';
import 'package:privacy_gui/page/dmz/models/dmz_ui_model.dart';
import 'package:privacy_gui/page/dmz/providers/usp_dmz_notifier.dart';
import 'package:privacy_gui/page/dmz/services/usp_dmz_service.dart';

class MockUspDmzService extends Mock implements UspDmzService {}

void main() {
  late MockUspDmzService mockService;

  final testSettings = DmzSettings(
    model: DmzUIModel(
      isEnabled: true,
      destIp: '192.168.1.100',
      sourceType: DmzSourceType.any,
      sourcePrefix: '',
    ),
    instancePath: 'Device.Firewall.DMZ.1.',
  );
  const testStatus = DmzStatus(isLoading: false);

  setUpAll(() {
    registerFallbackValue(const DmzUIModel.disabled());
  });

  setUp(() {
    mockService = MockUspDmzService();
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        uspDmzServiceProvider.overrideWithValue(mockService),
        uspMutationLockProvider.overrideWithValue(UspMutationLock()),
      ],
    );
    // Prevent auto-dispose.
    container.listen(uspDmzProvider, (_, __) {});
    return container;
  }

  group('UspDmzNotifier', () {
    test('build returns initial loading state', () {
      when(() => mockService.fetch())
          .thenAnswer((_) async => (testSettings, testStatus));
      final container = createContainer();

      final state = container.read(uspDmzProvider);
      expect(state.status.isLoading, isTrue);
      expect(state.settings.current, const DmzSettings.empty());
      container.dispose();
    });

    test('fetch success populates settings and status', () async {
      when(() => mockService.fetch())
          .thenAnswer((_) async => (testSettings, testStatus));
      final container = createContainer();

      // Let microtask (Future.microtask in build) complete.
      await Future.delayed(Duration.zero);

      final state = container.read(uspDmzProvider);
      expect(state.settings.current.model.isEnabled, isTrue);
      expect(state.settings.current.model.destIp, '192.168.1.100');
      expect(state.settings.current.instancePath, 'Device.Firewall.DMZ.1.');
      expect(state.status.isLoading, isFalse);
      container.dispose();
    });

    test('fetch error sets error status, no settings change', () async {
      when(() => mockService.fetch()).thenThrow(Exception('network error'));
      final container = createContainer();

      await Future.delayed(Duration.zero);

      final state = container.read(uspDmzProvider);
      expect(state.status.errorMessage, contains('network error'));
      // Settings remain empty (initial) since performFetch returned null.
      expect(state.settings.current, const DmzSettings.empty());
      container.dispose();
    });

    test('performSave calls add for new entry', () async {
      // Existing entry returned from fetch.
      final newSettings = DmzSettings(
        model: DmzUIModel(
          isEnabled: true,
          destIp: '192.168.1.50',
          sourceType: DmzSourceType.any,
          sourcePrefix: '',
        ),
        // No instancePath → isNewEntry = true.
      );
      when(() => mockService.fetch())
          .thenAnswer((_) async => (newSettings, testStatus));
      when(() => mockService.add(model: any(named: 'model')))
          .thenAnswer((_) async {});
      when(() => mockService.validateForm(any())).thenReturn({});

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspDmzProvider.notifier);
      // Trigger save — the current settings have isNewEntry = true.
      await notifier.save();

      verify(() => mockService.add(model: any(named: 'model'))).called(1);
      verifyNever(() => mockService.update(
          instancePath: any(named: 'instancePath'),
          model: any(named: 'model')));
      container.dispose();
    });

    test('performSave calls update for existing entry', () async {
      when(() => mockService.fetch())
          .thenAnswer((_) async => (testSettings, testStatus));
      when(() => mockService.update(
            instancePath: any(named: 'instancePath'),
            model: any(named: 'model'),
          )).thenAnswer((_) async {});
      when(() => mockService.validateForm(any())).thenReturn({});

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspDmzProvider.notifier);
      // Mutate to make dirty — then save.
      notifier.updateSetting((m) => m.copyWith(destIp: '192.168.1.200'));
      await notifier.save();

      verify(() => mockService.update(
            instancePath: 'Device.Firewall.DMZ.1.',
            model: any(named: 'model'),
          )).called(1);
      verifyNever(() => mockService.add(model: any(named: 'model')));
      container.dispose();
    });

    test('updateSetting mutates current model and validates', () async {
      when(() => mockService.fetch())
          .thenAnswer((_) async => (testSettings, testStatus));
      when(() => mockService.validateForm(any())).thenReturn({});

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspDmzProvider.notifier);
      notifier.updateSetting((m) => m.copyWith(destIp: '10.0.0.1'));

      final state = container.read(uspDmzProvider);
      expect(state.settings.current.model.destIp, '10.0.0.1');
      verify(() => mockService.validateForm(any())).called(1);
      container.dispose();
    });

    test('updateSetting propagates validation errors to status', () async {
      when(() => mockService.fetch())
          .thenAnswer((_) async => (testSettings, testStatus));
      when(() => mockService.validateForm(any()))
          .thenReturn({'destIp': 'Invalid IP'});

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspDmzProvider.notifier);
      notifier.updateSetting((m) => m.copyWith(destIp: 'bad'));

      final state = container.read(uspDmzProvider);
      expect(state.status.fieldErrors['destIp'], 'Invalid IP');
      container.dispose();
    });

    test('performSave skips when new entry and disabled', () async {
      final disabledNew = DmzSettings(
        model: DmzUIModel(
          isEnabled: false,
          destIp: '',
          sourceType: DmzSourceType.any,
          sourcePrefix: '',
        ),
        // No instancePath → isNewEntry = true.
      );
      when(() => mockService.fetch())
          .thenAnswer((_) async => (disabledNew, testStatus));
      when(() => mockService.validateForm(any())).thenReturn({});

      final container = createContainer();
      await Future.delayed(Duration.zero);

      await container.read(uspDmzProvider.notifier).save();

      verifyNever(() => mockService.add(model: any(named: 'model')));
      verifyNever(() => mockService.update(
          instancePath: any(named: 'instancePath'),
          model: any(named: 'model')));
      container.dispose();
    });

    test('isDirty true after mutation, false after fetch', () async {
      when(() => mockService.fetch())
          .thenAnswer((_) async => (testSettings, testStatus));
      when(() => mockService.validateForm(any())).thenReturn({});

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspDmzProvider.notifier);
      expect(notifier.isDirty(), isFalse);

      notifier.updateSetting((m) => m.copyWith(destIp: '10.0.0.1'));
      expect(notifier.isDirty(), isTrue);

      await notifier.fetch();
      expect(notifier.isDirty(), isFalse);
      container.dispose();
    });

    test('performSave rethrows on error and clears isSaving', () async {
      when(() => mockService.fetch())
          .thenAnswer((_) async => (testSettings, testStatus));
      when(() => mockService.update(
            instancePath: any(named: 'instancePath'),
            model: any(named: 'model'),
          )).thenThrow(Exception('save failed'));
      when(() => mockService.validateForm(any())).thenReturn({});

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspDmzProvider.notifier);
      notifier.updateSetting((m) => m.copyWith(destIp: '10.0.0.1'));

      expect(() => notifier.save(), throwsA(isA<Exception>()));
      await Future.delayed(Duration.zero);

      expect(container.read(uspDmzProvider).status.isSaving, isFalse);
      container.dispose();
    });

    test('SSE invalidation triggers re-fetch when clean', () async {
      final sseController = StreamController<InvalidationDomain>();
      when(() => mockService.fetch())
          .thenAnswer((_) async => (testSettings, testStatus));

      final container = ProviderContainer(
        overrides: [
          uspDmzServiceProvider.overrideWithValue(mockService),
          uspMutationLockProvider.overrideWithValue(UspMutationLock()),
          sseInvalidationProvider.overrideWith((_) => sseController.stream),
        ],
      );
      container.listen(uspDmzProvider, (_, __) {});
      await Future.delayed(Duration.zero);

      // Initial fetch happened once.
      verify(() => mockService.fetch()).called(1);

      // Push a DMZ invalidation event.
      sseController.add(InvalidationDomain.dmz);
      await Future.delayed(Duration.zero);

      // Should have re-fetched.
      verify(() => mockService.fetch()).called(1);

      await sseController.close();
      container.dispose();
    });

    test('revert restores original settings', () async {
      when(() => mockService.fetch())
          .thenAnswer((_) async => (testSettings, testStatus));
      when(() => mockService.validateForm(any())).thenReturn({});

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspDmzProvider.notifier);
      notifier.updateSetting((m) => m.copyWith(destIp: '10.0.0.1'));
      expect(container.read(uspDmzProvider).settings.current.model.destIp,
          '10.0.0.1');

      notifier.revert();
      expect(container.read(uspDmzProvider).settings.current.model.destIp,
          '192.168.1.100');
      container.dispose();
    });
  });
}
