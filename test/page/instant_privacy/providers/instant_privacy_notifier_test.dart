import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_notifier.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_device_ui_model.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_fetch_result.dart';
import 'package:privacy_gui/page/mac_filter/services/mac_filter_service.dart';

class MockMacFilterService extends Mock implements UspMacFilterService {}

void main() {
  late MockMacFilterService mockService;

  const dev1 = MacFilterDeviceUIModel(
      mac: 'AA:BB:CC:DD:EE:01',
      displayName: 'Laptop',
      ipAddress: '192.168.1.10');
  const dev2 = MacFilterDeviceUIModel(
      mac: 'AA:BB:CC:DD:EE:02',
      displayName: 'Phone',
      ipAddress: '192.168.1.11');

  MacFilterFetchResult allowResult() => const MacFilterFetchResult(
        mode: MacFilterMode.allow,
        macs: ['AA:BB:CC:DD:EE:01'],
        connectedDevices: [dev1, dev2],
      );
  MacFilterFetchResult disabledResult() => const MacFilterFetchResult(
        mode: MacFilterMode.disabled,
        macs: [],
        connectedDevices: [dev1, dev2],
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

  Future<(ProviderContainer, UspInstantPrivacyNotifier)> loaded(
      MacFilterFetchResult result) async {
    when(() => mockService.fetchAll()).thenAnswer((_) async => result);
    final c = makeContainer();
    c.listen(uspInstantPrivacyProvider, (_, __) {});
    await Future.delayed(Duration.zero);
    return (c, c.read(uspInstantPrivacyProvider.notifier));
  }

  group('fetch', () {
    test('loads Allow mode + list, clean', () async {
      final (c, _) = await loaded(allowResult());
      final s = c.read(uspInstantPrivacyProvider);

      expect(s.settings.current.mode, MacFilterMode.allow);
      expect(s.settings.current.macs, ['AA:BB:CC:DD:EE:01']);
      expect(s.connectedDevices, [dev1, dev2]);
      expect(s.isDirty, isFalse);
      c.dispose();
    });
  });

  group('toggle (Allow ⟷ Disabled)', () {
    test('enabling from Disabled pre-populates ALL online devices', () async {
      final (c, n) = await loaded(disabledResult());

      n.setEnabled(true);
      final s = c.read(uspInstantPrivacyProvider);

      expect(s.settings.current.mode, MacFilterMode.allow);
      // Instant Privacy pre-populates the whole connected-device list.
      expect(
          s.settings.current.macs, ['AA:BB:CC:DD:EE:01', 'AA:BB:CC:DD:EE:02']);
      expect(s.isDirty, isTrue);
      verifyNever(() => mockService.setMacFilter(any(), any()));
      c.dispose();
    });

    test('disabling clears the list locally', () async {
      final (c, n) = await loaded(allowResult());

      n.setEnabled(false);
      final s = c.read(uspInstantPrivacyProvider);

      expect(s.settings.current.mode, MacFilterMode.disabled);
      expect(s.settings.current.macs, isEmpty);
      expect(s.isDirty, isTrue);
      c.dispose();
    });
  });

  group('add / remove (local)', () {
    test('addMac appends, removeMac drops — no write', () async {
      final (c, n) = await loaded(allowResult());

      n.addMac('AA:BB:CC:DD:EE:02');
      expect(c.read(uspInstantPrivacyProvider).settings.current.macs,
          ['AA:BB:CC:DD:EE:01', 'AA:BB:CC:DD:EE:02']);

      n.removeMac('AA:BB:CC:DD:EE:01');
      expect(c.read(uspInstantPrivacyProvider).settings.current.macs,
          ['AA:BB:CC:DD:EE:02']);

      verifyNever(() => mockService.setMacFilter(any(), any()));
      c.dispose();
    });
  });

  group('revert', () {
    test('restores original', () async {
      final (c, n) = await loaded(allowResult());
      n.setEnabled(false);
      expect(c.read(uspInstantPrivacyProvider).isDirty, isTrue);

      n.revert();
      final s = c.read(uspInstantPrivacyProvider);
      expect(s.settings.current.mode, MacFilterMode.allow);
      expect(s.settings.current.macs, ['AA:BB:CC:DD:EE:01']);
      expect(s.isDirty, isFalse);
      c.dispose();
    });
  });

  group('save', () {
    test('writes Allow + current macs once', () async {
      final (c, n) = await loaded(disabledResult());
      n.setEnabled(true); // populates dev1, dev2
      when(() => mockService.fetchAll()).thenAnswer((_) async => allowResult());

      await n.save();

      verify(() => mockService.setMacFilter(
              MacFilterMode.allow, ['AA:BB:CC:DD:EE:01', 'AA:BB:CC:DD:EE:02']))
          .called(1);
      expect(c.read(uspInstantPrivacyProvider).isDirty, isFalse);
      c.dispose();
    });

    test('clean state does not write', () async {
      final (c, n) = await loaded(allowResult());
      await n.save();
      verifyNever(() => mockService.setMacFilter(any(), any()));
      c.dispose();
    });

    test('surfaces a save failure', () async {
      final (c, n) = await loaded(disabledResult());
      n.setEnabled(true);
      when(() => mockService.setMacFilter(any(), any()))
          .thenThrow(const ConnectivityError(detail: 'down'));

      expect(() => n.save(), throwsA(isA<ConnectivityError>()));
      c.dispose();
    });
  });
}
