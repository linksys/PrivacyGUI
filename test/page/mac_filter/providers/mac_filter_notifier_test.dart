import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/mac_filter/providers/mac_filter_notifier.dart';
import 'package:privacy_gui/page/mac_filter/providers/mac_filter_state.dart';
import 'package:privacy_gui/page/mac_filter/services/mac_filter_service.dart';

class MockMacFilterService extends Mock implements UspMacFilterService {}

void main() {
  late MockMacFilterService mockService;

  const device1 = MacFilterDeviceUIModel(
      mac: 'AA:BB:CC:DD:EE:01',
      displayName: 'Laptop',
      ipAddress: '192.168.1.10');

  final denyResult = MacFilterFetchResult(
    mode: MacFilterMode.deny,
    macs: const ['AA:BB:CC:DD:EE:99'],
    connectedDevices: const [device1],
  );
  final disabledResult = MacFilterFetchResult(
    mode: MacFilterMode.disabled,
    macs: const [],
    connectedDevices: const [device1],
  );

  setUpAll(() {
    registerFallbackValue(MacFilterMode.disabled);
    registerFallbackValue(<String>[]);
  });

  setUp(() {
    mockService = MockMacFilterService();
  });

  ProviderContainer createContainer() => ProviderContainer(overrides: [
        uspMacFilterServiceProvider.overrideWithValue(mockService),
      ]);

  group('build', () {
    test('loads mode + macs + connected devices', () async {
      when(() => mockService.fetchAll()).thenAnswer((_) async => denyResult);

      final container = createContainer();
      final state = await container.read(uspMacFilterProvider.future);

      expect(state.mode, MacFilterMode.deny);
      expect(state.macs, ['AA:BB:CC:DD:EE:99']);
      expect(state.connectedDevices, [device1]);
      container.dispose();
    });

    test('rethrows ServiceError from the service', () async {
      when(() => mockService.fetchAll())
          .thenThrow(const ConnectivityError(detail: 'down'));

      final container = createContainer();

      expect(() => container.read(uspMacFilterProvider.future),
          throwsA(isA<ConnectivityError>()));
      container.dispose();
    });
  });

  group('setMode', () {
    test('writes the new mode with the current list and refetches', () async {
      when(() => mockService.fetchAll()).thenAnswer((_) async => denyResult);
      when(() => mockService.setMacFilter(any(), any()))
          .thenAnswer((_) async {});

      final container = createContainer();
      await container.read(uspMacFilterProvider.future);

      when(() => mockService.fetchAll())
          .thenAnswer((_) async => disabledResult);
      await container
          .read(uspMacFilterProvider.notifier)
          .setMode(MacFilterMode.disabled);

      verify(() => mockService.setMacFilter(
          MacFilterMode.disabled, ['AA:BB:CC:DD:EE:99'])).called(1);
      container.dispose();
    });

    test('surfaces a validation error and does not crash the notifier',
        () async {
      when(() => mockService.fetchAll())
          .thenAnswer((_) async => disabledResult);
      when(() => mockService.setMacFilter(any(), any()))
          .thenThrow(const InvalidInputError(detail: 'Allow needs one'));

      final container = createContainer();
      await container.read(uspMacFilterProvider.future);

      expect(
        () => container
            .read(uspMacFilterProvider.notifier)
            .setMode(MacFilterMode.allow),
        throwsA(isA<InvalidInputError>()),
      );
      container.dispose();
    });
  });

  group('addMac / removeMac', () {
    test('addMac writes the extended list', () async {
      when(() => mockService.fetchAll()).thenAnswer((_) async => denyResult);
      when(() => mockService.setMacFilter(any(), any()))
          .thenAnswer((_) async {});

      final container = createContainer();
      await container.read(uspMacFilterProvider.future);
      when(() => mockService.fetchAll()).thenAnswer((_) async => denyResult);

      await container
          .read(uspMacFilterProvider.notifier)
          .addMac('AA:BB:CC:DD:EE:02');

      verify(() => mockService.setMacFilter(
              MacFilterMode.deny, ['AA:BB:CC:DD:EE:99', 'AA:BB:CC:DD:EE:02']))
          .called(1);
      container.dispose();
    });

    test('removeMac writes the reduced list', () async {
      when(() => mockService.fetchAll()).thenAnswer((_) async => denyResult);
      when(() => mockService.setMacFilter(any(), any()))
          .thenAnswer((_) async {});

      final container = createContainer();
      await container.read(uspMacFilterProvider.future);
      when(() => mockService.fetchAll()).thenAnswer((_) async => denyResult);

      await container
          .read(uspMacFilterProvider.notifier)
          .removeMac('AA:BB:CC:DD:EE:99');

      verify(() => mockService.setMacFilter(MacFilterMode.deny, [])).called(1);
      container.dispose();
    });
  });
}
