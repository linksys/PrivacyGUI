import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_device_ui_model.dart';
import 'package:privacy_gui/page/mac_filter/providers/mac_filter_notifier.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_fetch_result.dart';
import 'package:privacy_gui/page/mac_filter/providers/mac_filter_state.dart';
import 'package:privacy_gui/page/mac_filter/services/mac_filter_service.dart';

class MockMacFilterService extends Mock implements UspMacFilterService {}

void main() {
  late MockMacFilterService mockService;

  const device1 = MacFilterDeviceUIModel(
      mac: 'AA:BB:CC:DD:EE:01', displayName: 'Laptop', ipAddress: '192.168.1.10');

  // Device currently Deny with one blocked MAC.
  MacFilterFetchResult denyResult() => const MacFilterFetchResult(
        mode: MacFilterMode.deny,
        macs: ['AA:BB:CC:DD:EE:99'],
        connectedDevices: [device1],
      );
  MacFilterFetchResult disabledResult() => const MacFilterFetchResult(
        mode: MacFilterMode.disabled,
        macs: [],
        connectedDevices: [device1],
      );

  setUpAll(() {
    registerFallbackValue(MacFilterMode.disabled);
    registerFallbackValue(<String>[]);
  });

  setUp(() {
    mockService = MockMacFilterService();
    when(() => mockService.setMacFilter(any(), any())).thenAnswer((_) async {});
  });

  ProviderContainer makeContainer() => ProviderContainer(overrides: [
        uspMacFilterServiceProvider.overrideWithValue(mockService),
      ]);

  Future<(ProviderContainer, UspMacFilterNotifier)> loaded(
      MacFilterFetchResult result) async {
    when(() => mockService.fetchAll()).thenAnswer((_) async => result);
    final c = makeContainer();
    // Keep the AutoDispose provider alive across the async fetch, then let
    // build()'s microtask-triggered fetch() settle.
    c.listen(uspMacFilterProvider, (_, __) {});
    await Future.delayed(Duration.zero);
    return (c, c.read(uspMacFilterProvider.notifier));
  }

  group('fetch', () {
    test('loads mode + list into a clean (non-dirty) state', () async {
      final (c, _) = await loaded(denyResult());
      final s = c.read(uspMacFilterProvider);

      expect(s.settings.current.mode, MacFilterMode.deny);
      expect(s.settings.current.macs, ['AA:BB:CC:DD:EE:99']);
      expect(s.status.connectedDevices, [device1]);
      expect(s.isDirty, isFalse);
      c.dispose();
    });
  });

  group('toggle (Deny ⟷ Disabled)', () {
    test('enabling from Disabled sets Deny and stays dirty, no write', () async {
      final (c, n) = await loaded(disabledResult());

      n.setEnabled(true);
      final s = c.read(uspMacFilterProvider);

      expect(s.settings.current.mode, MacFilterMode.deny);
      expect(s.isDirty, isTrue);
      // MAC Filter does NOT pre-populate.
      expect(s.settings.current.macs, isEmpty);
      verifyNever(() => mockService.setMacFilter(any(), any()));
      c.dispose();
    });

    test('disabling sets Disabled and clears the list locally', () async {
      final (c, n) = await loaded(denyResult());

      n.setEnabled(false);
      final s = c.read(uspMacFilterProvider);

      expect(s.settings.current.mode, MacFilterMode.disabled);
      expect(s.settings.current.macs, isEmpty);
      expect(s.isDirty, isTrue);
      c.dispose();
    });
  });

  group('add / remove (local, no write until save)', () {
    test('addMac appends to current, no write', () async {
      final (c, n) = await loaded(denyResult());

      n.addMac('AA:BB:CC:DD:EE:02');
      final s = c.read(uspMacFilterProvider);

      expect(s.settings.current.macs,
          ['AA:BB:CC:DD:EE:99', 'AA:BB:CC:DD:EE:02']);
      expect(s.isDirty, isTrue);
      verifyNever(() => mockService.setMacFilter(any(), any()));
      c.dispose();
    });

    test('addMac ignores a duplicate', () async {
      final (c, n) = await loaded(denyResult());

      n.addMac('aa:bb:cc:dd:ee:99');
      expect(c.read(uspMacFilterProvider).settings.current.macs,
          ['AA:BB:CC:DD:EE:99']);
      c.dispose();
    });

    test('removeMac drops from current', () async {
      final (c, n) = await loaded(denyResult());

      n.removeMac('AA:BB:CC:DD:EE:99');
      expect(c.read(uspMacFilterProvider).settings.current.macs, isEmpty);
      c.dispose();
    });
  });

  group('revert', () {
    test('restores original after edits', () async {
      final (c, n) = await loaded(denyResult());

      n.addMac('AA:BB:CC:DD:EE:02');
      n.setEnabled(false);
      expect(c.read(uspMacFilterProvider).isDirty, isTrue);

      n.revert();
      final s = c.read(uspMacFilterProvider);
      expect(s.settings.current.mode, MacFilterMode.deny);
      expect(s.settings.current.macs, ['AA:BB:CC:DD:EE:99']);
      expect(s.isDirty, isFalse);
      c.dispose();
    });
  });

  group('save', () {
    test('writes current (mode, macs) exactly once', () async {
      final (c, n) = await loaded(disabledResult());
      n.setEnabled(true);
      n.addMac('AA:BB:CC:DD:EE:02');
      // Post-save re-fetch returns the now-persisted state.
      when(() => mockService.fetchAll()).thenAnswer((_) async =>
          const MacFilterFetchResult(
              mode: MacFilterMode.deny,
              macs: ['AA:BB:CC:DD:EE:02'],
              connectedDevices: [device1]));

      await n.save();

      verify(() => mockService.setMacFilter(
          MacFilterMode.deny, ['AA:BB:CC:DD:EE:02'])).called(1);
      expect(c.read(uspMacFilterProvider).isDirty, isFalse);
      c.dispose();
    });

    test('a clean state does not write', () async {
      final (c, n) = await loaded(denyResult());
      await n.save();
      verifyNever(() => mockService.setMacFilter(any(), any()));
      c.dispose();
    });

    test('surfaces a save failure', () async {
      final (c, n) = await loaded(disabledResult());
      n.setEnabled(true);
      n.addMac('AA:BB:CC:DD:EE:02');
      when(() => mockService.setMacFilter(any(), any()))
          .thenThrow(const ConnectivityError(detail: 'down'));

      expect(() => n.save(), throwsA(isA<ConnectivityError>()));
      c.dispose();
    });
  });
}
