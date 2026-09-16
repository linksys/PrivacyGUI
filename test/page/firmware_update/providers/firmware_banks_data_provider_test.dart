import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_image_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_banks_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_banks_data_service.dart';

import '../../../mocks/test_data/firmware_update_test_data.dart';

class MockFirmwareBanksDataService extends Mock
    implements FirmwareBanksDataService {}

void main() {
  late MockFirmwareBanksDataService mockService;

  setUp(() {
    mockService = MockFirmwareBanksDataService();
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        firmwareBanksDataServiceProvider.overrideWithValue(mockService),
      ],
    );
  }

  group('FirmwareBanksData', () {
    test('activeBank returns bank with Active status', () {
      final data = FirmwareBanksData(banks: [
        FirmwareUpdateTestData.bankWithStatus(instance: 1, status: 'Available'),
        FirmwareUpdateTestData.bankWithStatus(instance: 2, status: 'Active'),
      ]);

      expect(data.activeBank?.instance, 2);
      expect(data.activeBank?.isActive, isTrue);
    });

    test('activeBank returns null when no active bank', () {
      final data = FirmwareBanksData(banks: [
        FirmwareUpdateTestData.bankWithStatus(instance: 1, status: 'Available'),
        FirmwareUpdateTestData.bankWithStatus(instance: 2, status: 'Available'),
      ]);

      expect(data.activeBank, isNull);
    });

    test('availableBank returns available non-active bank', () {
      final data = FirmwareBanksData(banks: [
        FirmwareUpdateTestData.bankWithStatus(instance: 1, status: 'Active'),
        FirmwareUpdateTestData.bankWithStatus(
          instance: 2,
          status: 'Available',
          available: true,
        ),
      ]);

      expect(data.availableBank?.instance, 2);
      expect(data.availableBank?.isActive, isFalse);
    });

    test('availableBank returns null when no available bank', () {
      final data = FirmwareBanksData(banks: [
        FirmwareUpdateTestData.bankWithStatus(instance: 1, status: 'Active'),
        FirmwareUpdateTestData.bankWithStatus(
          instance: 2,
          status: 'Available',
          available: false,
        ),
      ]);

      expect(data.availableBank, isNull);
    });

    test('props includes banks for equality', () {
      final banks = [
        FirmwareUpdateTestData.bankWithStatus(instance: 1, status: 'Active'),
      ];
      final data1 = FirmwareBanksData(banks: banks);
      final data2 = FirmwareBanksData(banks: banks);

      expect(data1, equals(data2));
    });

    test('empty banks returns null for activeBank and availableBank', () {
      const data = FirmwareBanksData(banks: []);

      expect(data.activeBank, isNull);
      expect(data.availableBank, isNull);
    });
  });

  group('FirmwareBanksData ota / physical split', () {
    /// The measured three-instance shape: fw1 Active, fw2 spare with an empty
    /// version, ota virtual.
    FirmwareBanksData threeInstances({
      bool otaAvailable = false,
      String otaVersion = '',
    }) =>
        FirmwareBanksData(banks: [
          FirmwareUpdateTestData.activeBank(instance: 1, alias: 'fw1'),
          FirmwareUpdateTestData.emptyVersionBank(instance: 2),
          FirmwareUpdateTestData.otaInstance(
            instance: 3,
            available: otaAvailable,
            version: otaVersion,
          ),
        ]);

    test('otaInstance resolves the alias == ota row', () {
      final data = threeInstances(otaAvailable: true, otaVersion: '2.0.2');

      expect(data.otaInstance?.alias, 'ota');
      expect(data.otaInstance?.version, '2.0.2');
      expect(data.otaInstance?.available, isTrue);
    });

    test('otaInstance is null when the router reports no ota row', () {
      final data = FirmwareBanksData(banks: [
        FirmwareUpdateTestData.activeBank(instance: 1, alias: 'fw1'),
        FirmwareUpdateTestData.emptyVersionBank(instance: 2),
      ]);

      expect(data.otaInstance, isNull);
    });

    test('an offer naming the version already running is not an offer', () {
      // Measured from a recording of a full install (2026-09-16): seconds after
      // "Update complete — now running 2.0.1.26091516" the same page still read
      // "Update available — Available: 2.0.1.26091516". The `ota` row keeps the last
      // offer until `fwupd` next checks, so straight after a reboot it names the
      // build that just went in — and both the OTA card and the dashboard banner
      // announced it.
      final data = FirmwareBanksData(banks: [
        FirmwareUpdateTestData.activeBank(
            instance: 1, alias: 'fw1', version: '2.0.1.26091516'),
        FirmwareUpdateTestData.emptyVersionBank(instance: 2),
        FirmwareUpdateTestData.otaInstance(
          instance: 3,
          available: true,
          version: '2.0.1.26091516',
        ),
      ]);

      expect(data.hasOtaOffer, isFalse);
      expect(data.otaOfferedVersion, isNull);
      // The row itself is untouched — this is a reading of it, not a filter on it.
      // A diagnostic still needs to be able to say what the router reported.
      expect(data.otaInstance?.available, isTrue);
      expect(data.otaInstance?.version, '2.0.1.26091516');
    });

    test('an offer naming a different version is an offer', () {
      final data = FirmwareBanksData(banks: [
        FirmwareUpdateTestData.activeBank(
            instance: 1, alias: 'fw1', version: '2.0.1.26091515'),
        FirmwareUpdateTestData.emptyVersionBank(instance: 2),
        FirmwareUpdateTestData.otaInstance(
          instance: 3,
          available: true,
          version: '2.0.1.26091516',
        ),
      ]);

      expect(data.hasOtaOffer, isTrue);
      expect(data.otaOfferedVersion, '2.0.1.26091516');
    });

    test('an offer with no version stays an offer', () {
      // The router does publish `Available=true` with an empty `Version`, and an
      // unnamed build cannot be compared to the running one. Withholding it would
      // turn "we cannot tell" into "there is nothing" — the substitution this
      // feature exists to prevent. `hasOtaOffer` is therefore the predicate and
      // `otaOfferedVersion` only the label.
      final data = threeInstances(otaAvailable: true);

      expect(data.hasOtaOffer, isTrue);
      expect(data.otaOfferedVersion, isNull);
    });

    test('Available=false is never an offer, whatever the version says', () {
      // `Available=false` carries two meanings — checked and found nothing, and
      // nobody has asked yet — and neither is an offer.
      final data = threeInstances(otaVersion: '2.0.9');

      expect(data.hasOtaOffer, isFalse);
      expect(data.otaOfferedVersion, isNull);
    });

    test('physicalBanks excludes the ota row', () {
      final data = threeInstances();

      expect(data.physicalBanks.map((b) => b.alias), ['fw1', 'fw2']);
    });

    test('physicalBanks keeps rows whose alias is absent', () {
      // A build without the Linksys fwup stack reports no Alias at all. Those
      // rows are still physical banks; a strict fw1/fw2 allow-list would blank
      // the whole banks card on such a box.
      final data = FirmwareBanksData(banks: [
        FirmwareUpdateTestData.activeBank(instance: 1),
        FirmwareUpdateTestData.availableBank(instance: 2),
      ]);

      expect(data.physicalBanks, hasLength(2));
      expect(data.otaInstance, isNull);
    });

    test('availableBank searches physical banks only', () {
      // The ota row is available && !isActive, so an unfiltered search would
      // return it and callers would read the upgradeable version as "the spare
      // bank we can flash".
      final data = FirmwareBanksData(banks: [
        FirmwareUpdateTestData.activeBank(instance: 1, alias: 'fw1'),
        FirmwareUpdateTestData.otaInstance(
          instance: 3,
          available: true,
          version: '2.0.2',
        ),
      ]);

      expect(data.availableBank, isNull);
    });

    test('availableBank still finds the spare physical bank', () {
      final data = threeInstances(otaAvailable: true, otaVersion: '2.0.2');

      expect(data.availableBank?.alias, 'fw2');
    });

    test('instance numbering does not change the resolved rows', () {
      // Same three rows, renumbered: ota is instance 1 and the banks are 7/9.
      final renumbered = FirmwareBanksData(banks: [
        FirmwareUpdateTestData.otaInstance(
          instance: 1,
          available: true,
          version: '2.0.2',
        ),
        FirmwareUpdateTestData.activeBank(instance: 7, alias: 'fw1'),
        FirmwareUpdateTestData.emptyVersionBank(instance: 9),
      ]);

      expect(renumbered.otaInstance?.version, '2.0.2');
      expect(renumbered.physicalBanks.map((b) => b.alias), ['fw1', 'fw2']);
      expect(renumbered.availableBank?.instance, 9);
      expect(renumbered.activeBank?.instance, 7);
    });
  });

  group('FirmwareBanksDataNotifier', () {
    test('build fetches banks from service', () async {
      when(() => mockService.fetch()).thenAnswer((_) async => [
            FirmwareImageUIModel(
              instance: 1,
              instancePath: 'Device.DeviceInfo.FirmwareImage.1.',
              name: 'linux',
              version: '1.0.16.0',
              status: 'Active',
              available: true,
            ),
            FirmwareImageUIModel(
              instance: 2,
              instancePath: 'Device.DeviceInfo.FirmwareImage.2.',
              name: 'linux',
              version: '1.0.15.0',
              status: 'Available',
              available: true,
            ),
          ]);

      final container = createContainer();
      addTearDown(container.dispose);

      final data = await container.read(firmwareBanksDataProvider.future);

      expect(data.banks.length, 2);
      expect(data.activeBank?.version, '1.0.16.0');
      expect(data.availableBank?.version, '1.0.15.0');
      verify(() => mockService.fetch()).called(1);
    });

    test('refresh returns fresh data', () async {
      var callCount = 0;
      when(() => mockService.fetch()).thenAnswer((_) async {
        callCount++;
        return [
          FirmwareImageUIModel(
            instance: 1,
            instancePath: 'Device.DeviceInfo.FirmwareImage.1.',
            name: 'linux',
            version: callCount == 1 ? '1.0.16.0' : '1.0.17.0',
            status: 'Active',
            available: true,
          ),
        ];
      });

      final container = createContainer();
      addTearDown(container.dispose);

      // Initial fetch
      final data1 = await container.read(firmwareBanksDataProvider.future);
      expect(data1.activeBank?.version, '1.0.16.0');

      // Refresh
      final data2 =
          await container.read(firmwareBanksDataProvider.notifier).refresh();
      expect(data2.activeBank?.version, '1.0.17.0');
      verify(() => mockService.fetch()).called(2);
    });

    test(
        'a refresh in flight keeps the previous reading, a failed one does not',
        () async {
      // Two assertions in one test because they are two halves of one shape, and
      // the second is only meaningful given the first: the loading state carries
      // the previous banks so the OTA page keeps showing versions while it
      // re-reads, and the *error* state carries them too — riverpod attaches them
      // whether asked to or not — which is why every consumer has to check
      // `hasError` rather than `valueOrNull` (see the auto-update notifier for the
      // whole argument).
      final second = Completer<List<FirmwareImageUIModel>>();
      var call = 0;
      when(() => mockService.fetch()).thenAnswer((_) {
        call++;
        return call == 1
            ? Future.value([
                FirmwareImageUIModel(
                  instance: 1,
                  instancePath: 'Device.DeviceInfo.FirmwareImage.1.',
                  name: 'linux',
                  version: '1.0.16.0',
                  status: 'Active',
                  available: true,
                ),
              ])
            : second.future;
      });

      final container = createContainer();
      addTearDown(container.dispose);
      await container.read(firmwareBanksDataProvider.future);

      final pending =
          container.read(firmwareBanksDataProvider.notifier).refresh();
      final inFlight = container.read(firmwareBanksDataProvider);
      expect(inFlight.isLoading, isTrue);
      expect(inFlight.valueOrNull?.activeBank?.version, '1.0.16.0');

      second.completeError(Exception('Network error'), StackTrace.empty);
      await expectLater(pending, throwsA(isA<Exception>()));

      final state = container.read(firmwareBanksDataProvider);
      expect(state.hasError, isTrue);
      expect(state.hasValue, isTrue);
      expect(state.valueOrNull?.activeBank?.version, '1.0.16.0');
    });

    test('propagates service errors', () async {
      when(() => mockService.fetch()).thenThrow(Exception('Network error'));

      final container = createContainer();
      addTearDown(container.dispose);

      expect(
        () => container.read(firmwareBanksDataProvider.future),
        throwsA(isA<Exception>()),
      );
    });
  });
}
