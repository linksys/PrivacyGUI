import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_auto_update_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_auto_update_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/services/usp_firmware_update_service.dart';

import '../../../mocks/test_data/firmware_update_test_data.dart';

class MockUspFirmwareUpdateService extends Mock
    implements UspFirmwareUpdateService {}

void main() {
  late MockUspFirmwareUpdateService mockService;

  setUpAll(() {
    registerFallbackValue(FirmwareAutoUpdatePolicy.notifyOnly);
  });

  setUp(() {
    mockService = MockUspFirmwareUpdateService();
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        uspFirmwareUpdateServiceProvider.overrideWithValue(mockService),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('FirmwareAutoUpdateDataNotifier — read', () {
    test('build reads the router through the service', () async {
      when(() => mockService.fetchAutoUpdate()).thenAnswer(
        (_) async => FirmwareUpdateTestData.autoUpdateModel(
          policy: FirmwareAutoUpdatePolicy.autoInstall,
        ),
      );

      final container = createContainer();
      final data = await container.read(firmwareAutoUpdateDataProvider.future);

      expect(data.policy, FirmwareAutoUpdatePolicy.autoInstall);
      expect(data.checksForUpdates, isTrue);
      verify(() => mockService.fetchAutoUpdate()).called(1);
    });

    test('a read failure surfaces as an error state, not a default policy',
        () async {
      // The switch has no safe default: rendering `off` would tell the user the
      // router is not updating itself when nobody knows, and rendering `on` is
      // the same lie the other way.
      when(() => mockService.fetchAutoUpdate())
          .thenThrow(const NetworkError(detail: 'timeout'));

      final container = createContainer();

      await expectLater(
        container.read(firmwareAutoUpdateDataProvider.future),
        throwsA(isA<NetworkError>()),
      );
      expect(container.read(firmwareAutoUpdateDataProvider).hasError, isTrue);
    });

    test('refresh re-reads and republishes', () async {
      var call = 0;
      when(() => mockService.fetchAutoUpdate()).thenAnswer((_) async {
        call++;
        return FirmwareUpdateTestData.autoUpdateModel(
          policy: call == 1
              ? FirmwareAutoUpdatePolicy.autoInstall
              : FirmwareAutoUpdatePolicy.notifyOnly,
        );
      });

      final container = createContainer();
      final first = await container.read(firmwareAutoUpdateDataProvider.future);
      expect(first.policy, FirmwareAutoUpdatePolicy.autoInstall);

      final second = await container
          .read(firmwareAutoUpdateDataProvider.notifier)
          .refresh();

      expect(second.policy, FirmwareAutoUpdatePolicy.notifyOnly);
      expect(
        container.read(firmwareAutoUpdateDataProvider).requireValue.policy,
        FirmwareAutoUpdatePolicy.notifyOnly,
      );
      verify(() => mockService.fetchAutoUpdate()).called(2);
    });

    test('a refresh in flight keeps the previous reading', () async {
      final second = Completer<FirmwareAutoUpdateUIModel>();
      var call = 0;
      when(() => mockService.fetchAutoUpdate()).thenAnswer((_) {
        call++;
        return call == 1
            ? Future.value(FirmwareUpdateTestData.autoUpdateModel(
                policy: FirmwareAutoUpdatePolicy.autoInstall))
            : second.future;
      });

      final container = createContainer();
      await container.read(firmwareAutoUpdateDataProvider.future);

      final pending =
          container.read(firmwareAutoUpdateDataProvider.notifier).refresh();
      final inFlight = container.read(firmwareAutoUpdateDataProvider);

      // Readable *and* busy at the same time, which is what the switch needs: it
      // keeps drawing the position the router last gave while the new read is on
      // the wire, with the spinner on top, instead of blanking to a skeleton
      // every time the dashboard refreshes.
      expect(inFlight.isLoading, isTrue);
      expect(
          inFlight.valueOrNull?.policy, FirmwareAutoUpdatePolicy.autoInstall);

      second.complete(FirmwareUpdateTestData.autoUpdateModel(
          policy: FirmwareAutoUpdatePolicy.notifyOnly));
      await pending;
    });

    test(
        'a failed refresh publishes an error that still carries the last value',
        () async {
      var call = 0;
      when(() => mockService.fetchAutoUpdate()).thenAnswer((_) {
        call++;
        if (call == 1) {
          return Future.value(FirmwareUpdateTestData.autoUpdateModel(
              policy: FirmwareAutoUpdatePolicy.autoInstall));
        }
        throw const NetworkError(detail: 'timeout');
      });

      final container = createContainer();
      await container.read(firmwareAutoUpdateDataProvider.future);

      await expectLater(
        container.read(firmwareAutoUpdateDataProvider.notifier).refresh(),
        throwsA(isA<NetworkError>()),
      );

      final state = container.read(firmwareAutoUpdateDataProvider);
      expect(state.hasError, isTrue);
      // This assertion is riverpod's behaviour, not this notifier's intent. The
      // notifier assigns a *bare* `AsyncError`; `AsyncNotifier`'s `state` setter
      // routes it through `asyncTransition`, which applies `copyWithPrevious`
      // unconditionally, so the stale reading comes back attached and there is no
      // spelling here that prevents it. It is pinned because it is the reason the
      // consumers cannot use `valueOrNull`: on this state it returns the position
      // the router gave before it went unreachable, and reads like fresh data.
      expect(state.hasValue, isTrue);
      expect(state.valueOrNull?.policy, FirmwareAutoUpdatePolicy.autoInstall);
    });
  });

  group('FirmwareAutoUpdateDataNotifier — round trip', () {
    /// Every value the router can hold, read in and written back out again.
    /// `unknown` is not here on purpose: it has no raw value to write, and the
    /// service refuses it — covered in the service's own tests.
    for (final policy in [
      FirmwareAutoUpdatePolicy.off,
      FirmwareAutoUpdatePolicy.notifyOnly,
      FirmwareAutoUpdatePolicy.autoInstall,
    ]) {
      test('${policy.name} survives read → state → write', () async {
        when(() => mockService.fetchAutoUpdate()).thenAnswer(
          (_) async => FirmwareUpdateTestData.autoUpdateModel(policy: policy),
        );
        when(() => mockService.setAutoUpdatePolicy(any()))
            .thenAnswer((_) async {});

        final container = createContainer();
        final read =
            await container.read(firmwareAutoUpdateDataProvider.future);

        // Read side: the raw string the router sent is the string this policy
        // means, both ways round.
        expect(read.policy, policy);
        expect(read.rawFlags, policy.rawValue);

        await container
            .read(firmwareAutoUpdateDataProvider.notifier)
            .setPolicy(policy);

        // Write side: the same value reaches the service unchanged.
        verify(() => mockService.setAutoUpdatePolicy(policy)).called(1);
        expect(
          container.read(firmwareAutoUpdateDataProvider).requireValue.rawFlags,
          policy.rawValue,
        );
      });
    }

    test('a confirmed write is published without a second read', () async {
      // The Set already failed loudly if the router rejected it, so re-reading
      // would only add a round trip and a second way to fail. What it must not
      // do is leave the old value on screen.
      when(() => mockService.fetchAutoUpdate()).thenAnswer(
        (_) async => FirmwareUpdateTestData.autoUpdateModel(
          policy: FirmwareAutoUpdatePolicy.notifyOnly,
          status: FirmwareAutoUpdateStatus.downloading,
          progress: 42,
          rawState: '3',
        ),
      );
      when(() => mockService.setAutoUpdatePolicy(any()))
          .thenAnswer((_) async {});

      final container = createContainer();
      await container.read(firmwareAutoUpdateDataProvider.future);

      await container
          .read(firmwareAutoUpdateDataProvider.notifier)
          .setPolicy(FirmwareAutoUpdatePolicy.autoInstall);

      final after = container.read(firmwareAutoUpdateDataProvider).requireValue;
      expect(after.policy, FirmwareAutoUpdatePolicy.autoInstall);
      expect(after.rawFlags, '2');
      // Only the policy moved. Status and progress belong to the daemon, and a
      // policy write is not an observation of what it is doing.
      expect(after.status, FirmwareAutoUpdateStatus.downloading);
      expect(after.progress, 42);
      expect(after.rawState, '3');
      verify(() => mockService.fetchAutoUpdate()).called(1);
    });

    test('a rejected write leaves the published policy alone and rethrows',
        () async {
      when(() => mockService.fetchAutoUpdate()).thenAnswer(
        (_) async => FirmwareUpdateTestData.autoUpdateModel(
          policy: FirmwareAutoUpdatePolicy.notifyOnly,
        ),
      );
      when(() => mockService.setAutoUpdatePolicy(any()))
          .thenThrow(const UnauthorizedError(detail: 'denied'));

      final container = createContainer();
      await container.read(firmwareAutoUpdateDataProvider.future);

      await expectLater(
        container
            .read(firmwareAutoUpdateDataProvider.notifier)
            .setPolicy(FirmwareAutoUpdatePolicy.autoInstall),
        throwsA(isA<UnauthorizedError>()),
      );

      // Still data, still the old value: the switch has to be able to snap back
      // to what the router actually holds, and an error state would blank the
      // card instead.
      final after = container.read(firmwareAutoUpdateDataProvider);
      expect(after.hasError, isFalse);
      expect(after.requireValue.policy, FirmwareAutoUpdatePolicy.notifyOnly);
    });

    test('setPolicy on an unread provider reads first, then writes', () async {
      // Reachable if a write races the initial fetch. Without the read there is
      // no status/progress to preserve, so the published value would be
      // fabricated rather than partially known.
      when(() => mockService.fetchAutoUpdate()).thenAnswer(
        (_) async => FirmwareUpdateTestData.autoUpdateModel(
          policy: FirmwareAutoUpdatePolicy.off,
          status: FirmwareAutoUpdateStatus.checking,
          rawState: '1',
        ),
      );
      when(() => mockService.setAutoUpdatePolicy(any()))
          .thenAnswer((_) async {});

      final container = createContainer();
      await container
          .read(firmwareAutoUpdateDataProvider.notifier)
          .setPolicy(FirmwareAutoUpdatePolicy.autoInstall);

      final after = container.read(firmwareAutoUpdateDataProvider).requireValue;
      expect(after.policy, FirmwareAutoUpdatePolicy.autoInstall);
      expect(after.status, FirmwareAutoUpdateStatus.checking);
    });
  });
}
