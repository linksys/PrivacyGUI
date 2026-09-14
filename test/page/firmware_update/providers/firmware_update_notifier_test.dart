import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/core/connection/services/recovery_probe_service.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/mode/app_mode_profile.dart';
import 'package:privacy_gui/core/mode/remote_mode_profile.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/usp/services/sse_connection_manager.dart';
import 'package:privacy_gui/core/usp/services/sse_manager.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_check_result.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_phase.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_banks_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_update_notifier.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_file_picker_service.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_local_upload_service.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_router_ota_check_service.dart';
import 'package:privacy_gui/page/firmware_update/services/usp_firmware_update_service.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';

import '../../../mocks/test_data/firmware_update_test_data.dart';

class MockFirmwareRouterOtaCheckService extends Mock
    implements FirmwareRouterOtaCheckService {}

class MockUspClient extends Mock implements UspClient {}

class MockUspFirmwareUpdateService extends Mock
    implements UspFirmwareUpdateService {}

class MockFirmwareLocalUploadService extends Mock
    implements FirmwareLocalUploadService {}

class MockRecoveryProbeService extends Mock implements RecoveryProbeService {}

class MockSseManager extends Mock implements SseManager {}

class MockAuthNotifier extends AsyncNotifier<AuthState>
    with Mock
    implements AuthNotifier {
  @override
  Future<AuthState> build() async => AuthState(
        loginType: LoginType.local,
      );
}

class _StubPickerService extends FirmwareFilePickerService {
  _StubPickerService(this._result);
  final FirmwarePickedFile? _result;

  @override
  Future<FirmwarePickedFile?> pickFirmwareImage() async => _result;
}

class _FakeBanksNotifier extends FirmwareBanksDataNotifier {
  _FakeBanksNotifier(this._value);
  final AsyncValue<FirmwareBanksData> _value;

  @override
  Future<FirmwareBanksData> build() async {
    state = _value;
    return _value.valueOrNull ?? const FirmwareBanksData(banks: []);
  }

  @override
  Future<FirmwareBanksData> refresh() async {
    // Return the same data without actually fetching
    final data = _value.valueOrNull ?? const FirmwareBanksData(banks: []);
    state = AsyncData(data);
    return data;
  }
}

/// Counts refreshes, so "the L1 cache was invalidated" is measurable rather than
/// assumed. The count is an instance field: a static would leak across tests in a
/// file this long and make the first failure look like the third one's fault.
class _CountingBanksNotifier extends _FakeBanksNotifier {
  _CountingBanksNotifier(super.value);

  int refreshes = 0;

  @override
  Future<FirmwareBanksData> refresh() {
    refreshes++;
    return super.refresh();
  }
}

/// A router that answers the first read and then stops answering.
///
/// The shape that matters after a check: the check itself succeeded, and the
/// bookkeeping behind it did not.
class _FailingRefreshBanksNotifier extends _FakeBanksNotifier {
  _FailingRefreshBanksNotifier(super.value);

  @override
  Future<FirmwareBanksData> refresh() async =>
      throw const NetworkError(detail: 'bridge busy');
}

void main() {
  late MockUspClient mockUsp;
  late MockUspFirmwareUpdateService mockService;
  late MockFirmwareLocalUploadService mockUploader;
  late MockFirmwareRouterOtaCheckService mockOtaChecker;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    mockUsp = MockUspClient();
    mockService = MockUspFirmwareUpdateService();
    mockUploader = MockFirmwareLocalUploadService();
    mockOtaChecker = MockFirmwareRouterOtaCheckService();
    when(() => mockUsp.isAuthenticated).thenReturn(true);
    when(() => mockUploader.totalFragmentsFor(any())).thenReturn(32);
  });

  ProviderContainer createContainer({
    FirmwareFilePickerService? picker,
    FirmwareLocalUploadService? uploader,
    FirmwareRouterOtaCheckService? otaChecker,
    AsyncValue<FirmwareBanksData>? banksData,
    List<Override> extra = const [],
  }) {
    final container = ProviderContainer(
      overrides: [
        uspClientProvider.overrideWithValue(mockUsp),
        uspFirmwareUpdateServiceProvider.overrideWithValue(mockService),
        uspMutationLockProvider.overrideWithValue(UspMutationLock()),
        firmwareLocalUploadServiceProvider
            .overrideWithValue(uploader ?? mockUploader),
        firmwareRouterOtaCheckServiceProvider
            .overrideWithValue(otaChecker ?? mockOtaChecker),
        if (picker != null)
          firmwareFilePickerServiceProvider.overrideWithValue(picker),
        if (banksData != null)
          firmwareBanksDataProvider.overrideWith(
            () => _FakeBanksNotifier(banksData),
          ),
        // Last, so a caller can replace any of the above — and, more to the
        // point, so this helper reads the same way as the one in
        // `usp_admin_notifier_test.dart`. Two sibling helpers with the same
        // signature and opposite precedence is a trap that costs an afternoon
        // exactly once.
        ...extra,
      ],
    );
    // Keep the autoDispose notifier alive across `await` boundaries inside
    // tests — without a subscriber the chunked MD5 yields trigger auto-dispose
    // mid-flow and reset state to defaults.
    container.listen(firmwareUpdateNotifierProvider, (_, __) {});
    return container;
  }

  Uint8List validImage() {
    final bytes = Uint8List(2 * 1024 * 1024);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = i & 0xff;
    }
    return bytes;
  }

  group('FirmwareUpdateNotifier', () {
    test('initial state is idle with empty fields', () {
      final container = createContainer();
      addTearDown(container.dispose);

      final state = container.read(firmwareUpdateNotifierProvider);
      expect(state.phase, FirmwareUpdatePhase.idle);
      expect(state.activeBank, isNull);
      expect(state.targetBank, isNull);
      expect(state.totalChunks, 0);
    });

    test('loadBanks populates active and target banks', () async {
      final banksData = FirmwareBanksData(banks: [
        FirmwareUpdateTestData.activeBank(),
        FirmwareUpdateTestData.availableBank(),
      ]);
      final container = createContainer(
        banksData: AsyncData(banksData),
      );
      addTearDown(container.dispose);

      await container.read(firmwareUpdateNotifierProvider.notifier).loadBanks();

      final state = container.read(firmwareUpdateNotifierProvider);
      expect(state.activeBank?.instance, 1);
      expect(state.targetBank?.instance, 2);
    });

    test('loadBanks failure transitions to failed phase', () async {
      final container = createContainer(
        banksData: AsyncError(
            const NetworkError(detail: 'timeout'), StackTrace.current),
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(firmwareUpdateNotifierProvider.notifier).loadBanks(),
        throwsA(isA<NetworkError>()),
      );

      final state = container.read(firmwareUpdateNotifierProvider);
      expect(state.phase, FirmwareUpdatePhase.failed);
      expect(state.errorMessage, isNotNull);
    });

    test('pickAndValidateFile cancellation returns to idle without error', () {
      final container = createContainer(picker: _StubPickerService(null));
      addTearDown(container.dispose);
      final notifier = container.read(firmwareUpdateNotifierProvider.notifier);

      return notifier.pickAndValidateFile().then((ok) {
        expect(ok, isFalse);
        final state = container.read(firmwareUpdateNotifierProvider);
        expect(state.phase, FirmwareUpdatePhase.idle);
        expect(state.errorMessage, isNull);
      });
    });

    test('pickAndValidateFile success captures filename, size, md5', () async {
      final bytes = validImage();
      final container = createContainer(
        picker: _StubPickerService(
          FirmwarePickedFile(name: 'fw.img', size: bytes.length, bytes: bytes),
        ),
      );
      addTearDown(container.dispose);
      final notifier = container.read(firmwareUpdateNotifierProvider.notifier);

      final ok = await notifier.pickAndValidateFile();

      expect(ok, isTrue);
      final state = container.read(firmwareUpdateNotifierProvider);
      expect(state.phase, FirmwareUpdatePhase.idle);
      expect(state.selectedFileName, 'fw.img');
      expect(state.selectedFileSize, bytes.length);
      expect(state.selectedFileMd5, isNotNull);
      expect(state.selectedFileMd5!.length, 32);
      expect(notifier.pickedBytes, isNotNull);
      expect(notifier.pickedBytes!.length, bytes.length);
    });

    test('pickAndValidateFile rejects unsupported extension', () async {
      final bytes = validImage();
      final container = createContainer(
        picker: _StubPickerService(
          FirmwarePickedFile(name: 'fw.zip', size: bytes.length, bytes: bytes),
        ),
      );
      addTearDown(container.dispose);
      final notifier = container.read(firmwareUpdateNotifierProvider.notifier);

      final ok = await notifier.pickAndValidateFile();

      expect(ok, isFalse);
      final state = container.read(firmwareUpdateNotifierProvider);
      expect(state.phase, FirmwareUpdatePhase.failed);
      expect(state.errorMessage, contains('Unsupported file extension'));
    });

    test('pickAndValidateFile rejects too-small files', () async {
      final tinyBytes = Uint8List(1024);
      final container = createContainer(
        picker: _StubPickerService(
          FirmwarePickedFile(
              name: 'tiny.img', size: tinyBytes.length, bytes: tinyBytes),
        ),
      );
      addTearDown(container.dispose);
      final notifier = container.read(firmwareUpdateNotifierProvider.notifier);

      final ok = await notifier.pickAndValidateFile();

      expect(ok, isFalse);
      final state = container.read(firmwareUpdateNotifierProvider);
      expect(state.phase, FirmwareUpdatePhase.failed);
    });

    test('runUpload fails fast when no image was picked', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      final notifier = container.read(firmwareUpdateNotifierProvider.notifier);

      await notifier.runUpload(commandKey: 'cmd-1');

      final state = container.read(firmwareUpdateNotifierProvider);
      expect(state.phase, FirmwareUpdatePhase.failed);
      expect(state.errorMessage, 'No firmware image selected');
      verifyNever(() => mockUploader.uploadFile(
            bytes: any(named: 'bytes'),
            md5: any(named: 'md5'),
            commandKey: any(named: 'commandKey'),
          ));
    });

    test('runUpload mirrors uploader progress into state', () async {
      final bytes = validImage();
      when(() => mockUploader.totalFragmentsFor(bytes.length)).thenReturn(64);
      when(() => mockUploader.uploadFile(
            bytes: any(named: 'bytes'),
            md5: any(named: 'md5'),
            commandKey: any(named: 'commandKey'),
            isCancelled: any(named: 'isCancelled'),
            onProgress: any(named: 'onProgress'),
          )).thenAnswer((invocation) async {
        final onProgress =
            invocation.namedArguments[#onProgress] as void Function(int, int)?;
        onProgress?.call(0, 64);
        onProgress?.call(32, 64);
        onProgress?.call(64, 64);
      });
      final container = createContainer(
        picker: _StubPickerService(
          FirmwarePickedFile(name: 'fw.img', size: bytes.length, bytes: bytes),
        ),
      );
      addTearDown(container.dispose);
      final notifier = container.read(firmwareUpdateNotifierProvider.notifier);

      await notifier.pickAndValidateFile();
      await notifier.runUpload(commandKey: 'cmd-1');

      final state = container.read(firmwareUpdateNotifierProvider);
      expect(state.phase, FirmwareUpdatePhase.uploading);
      expect(state.uploadedChunks, 64);
      expect(state.totalChunks, 64);
    });

    test('runUpload cancellation resets state to idle', () async {
      final bytes = validImage();
      when(() => mockUploader.totalFragmentsFor(bytes.length)).thenReturn(8);
      when(() => mockUploader.uploadFile(
            bytes: any(named: 'bytes'),
            md5: any(named: 'md5'),
            commandKey: any(named: 'commandKey'),
            isCancelled: any(named: 'isCancelled'),
            onProgress: any(named: 'onProgress'),
          )).thenThrow(const FirmwareUploadCancelledException());
      final container = createContainer(
        picker: _StubPickerService(
          FirmwarePickedFile(name: 'fw.img', size: bytes.length, bytes: bytes),
        ),
      );
      addTearDown(container.dispose);
      final notifier = container.read(firmwareUpdateNotifierProvider.notifier);

      await notifier.pickAndValidateFile();
      await expectLater(
        notifier.runUpload(commandKey: 'cmd-1'),
        throwsA(isA<FirmwareUploadCancelledException>()),
      );

      final state = container.read(firmwareUpdateNotifierProvider);
      expect(state.phase, FirmwareUpdatePhase.idle);
      expect(notifier.pickedBytes, isNull);
    });

    test('runUpload propagates ServiceError and transitions to failed',
        () async {
      final bytes = validImage();
      when(() => mockUploader.totalFragmentsFor(bytes.length)).thenReturn(8);
      when(() => mockUploader.uploadFile(
            bytes: any(named: 'bytes'),
            md5: any(named: 'md5'),
            commandKey: any(named: 'commandKey'),
            isCancelled: any(named: 'isCancelled'),
            onProgress: any(named: 'onProgress'),
          )).thenThrow(const NetworkError(detail: 'chunk timeout'));
      final container = createContainer(
        picker: _StubPickerService(
          FirmwarePickedFile(name: 'fw.img', size: bytes.length, bytes: bytes),
        ),
      );
      addTearDown(container.dispose);
      final notifier = container.read(firmwareUpdateNotifierProvider.notifier);

      await notifier.pickAndValidateFile();
      await expectLater(
        notifier.runUpload(commandKey: 'cmd-1'),
        throwsA(isA<NetworkError>()),
      );

      final state = container.read(firmwareUpdateNotifierProvider);
      expect(state.phase, FirmwareUpdatePhase.failed);
      expect(state.errorMessage, contains('Network error'));
    });

    test('triggerInstall succeeds, moves through triggering→installing',
        () async {
      when(() => mockService.triggerLocalDownload(
            targetInstance: any(named: 'targetInstance'),
          )).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);
      final notifier = container.read(firmwareUpdateNotifierProvider.notifier);

      await notifier.triggerInstall(targetInstance: 2);

      expect(
        container.read(firmwareUpdateNotifierProvider).phase,
        FirmwareUpdatePhase.installing,
      );
      verify(() => mockService.triggerLocalDownload(targetInstance: 2))
          .called(1);
    });

    test('triggerInstall failure transitions to failed phase', () async {
      when(() => mockService.triggerLocalDownload(
            targetInstance: any(named: 'targetInstance'),
          )).thenThrow(const UnauthorizedError());

      final container = createContainer();
      addTearDown(container.dispose);
      final notifier = container.read(firmwareUpdateNotifierProvider.notifier);

      await expectLater(
        notifier.triggerInstall(targetInstance: 2),
        throwsA(isA<UnauthorizedError>()),
      );

      expect(
        container.read(firmwareUpdateNotifierProvider).phase,
        FirmwareUpdatePhase.failed,
      );
    });

    test('updateUploadProgress reports chunk count and uploading phase', () {
      final container = createContainer();
      addTearDown(container.dispose);
      final notifier = container.read(firmwareUpdateNotifierProvider.notifier);

      notifier.updateUploadProgress(42, 100);

      final state = container.read(firmwareUpdateNotifierProvider);
      expect(state.phase, FirmwareUpdatePhase.uploading);
      expect(state.uploadedChunks, 42);
      expect(state.totalChunks, 100);
      expect(state.uploadProgress, closeTo(0.42, 1e-9));
    });

    test('enterRebooting carries the estimated remaining duration', () {
      final container = createContainer();
      addTearDown(container.dispose);
      final notifier = container.read(firmwareUpdateNotifierProvider.notifier);

      notifier.enterRebooting(const Duration(minutes: 5));

      final state = container.read(firmwareUpdateNotifierProvider);
      expect(state.phase, FirmwareUpdatePhase.rebooting);
      expect(state.rebootRemaining, const Duration(minutes: 5));
    });

    test('verify returns done on version match', () async {
      // After reboot, instance 2 should be active with expected version
      final banksData = FirmwareBanksData(banks: [
        FirmwareUpdateTestData.bankWithStatus(instance: 1, status: 'Available'),
        FirmwareUpdateTestData.bankWithStatus(
          instance: 2,
          status: 'Active',
          version: '1.0.17.0',
        ),
      ]);
      final container = createContainer(
        banksData: AsyncData(banksData),
      );
      addTearDown(container.dispose);
      final notifier = container.read(firmwareUpdateNotifierProvider.notifier);

      await notifier.verify(
        expectedVersion: '1.0.17.0',
        expectedActiveInstance: 2,
      );

      expect(
        container.read(firmwareUpdateNotifierProvider).phase,
        FirmwareUpdatePhase.done,
      );
    });

    test('verify with mismatched version still succeeds (bank flip is primary)',
        () async {
      // After reboot, instance 2 is active but version doesn't match.
      // Per design: bank flip is the primary check, version mismatch only logs warning.
      final banksData = FirmwareBanksData(banks: [
        FirmwareUpdateTestData.bankWithStatus(instance: 1, status: 'Available'),
        FirmwareUpdateTestData.bankWithStatus(
          instance: 2,
          status: 'Active',
          version: '1.0.16.0', // Different version, but bank flip succeeded
        ),
      ]);
      final container = createContainer(
        banksData: AsyncData(banksData),
      );
      addTearDown(container.dispose);
      final notifier = container.read(firmwareUpdateNotifierProvider.notifier);

      await notifier.verify(
        expectedVersion: '1.0.17.0',
        expectedActiveInstance: 2,
      );

      // Bank flip succeeded → done (version mismatch only logs warning)
      final state = container.read(firmwareUpdateNotifierProvider);
      expect(state.phase, FirmwareUpdatePhase.done);
      expect(state.activeBank?.instance, 2);
    });

    test('verify fails when expected bank did not become active', () async {
      // After reboot, instance 2 is still Available (not Active) — bank flip failed
      final banksData = FirmwareBanksData(banks: [
        FirmwareUpdateTestData.bankWithStatus(instance: 1, status: 'Active'),
        FirmwareUpdateTestData.bankWithStatus(
          instance: 2,
          status: 'Available', // Expected to be Active but isn't
          version: '1.0.17.0',
        ),
      ]);
      final container = createContainer(
        banksData: AsyncData(banksData),
      );
      addTearDown(container.dispose);
      final notifier = container.read(firmwareUpdateNotifierProvider.notifier);

      await notifier.verify(
        expectedVersion: '1.0.17.0',
        expectedActiveInstance: 2,
      );

      final state = container.read(firmwareUpdateNotifierProvider);
      expect(state.phase, FirmwareUpdatePhase.failed);
      expect(state.errorMessage, contains('did not boot the new image'));
    });

    test('verify passes on a three-instance router', () async {
      final banksData = FirmwareBanksData(banks: [
        FirmwareUpdateTestData.bankWithStatus(
          instance: 1,
          status: 'Available',
          alias: 'fw1',
        ),
        FirmwareUpdateTestData.bankWithStatus(
          instance: 2,
          status: 'Active',
          version: '1.0.17.0',
          alias: 'fw2',
        ),
        FirmwareUpdateTestData.otaInstance(instance: 3),
      ]);
      final container = createContainer(banksData: AsyncData(banksData));
      addTearDown(container.dispose);
      final notifier = container.read(firmwareUpdateNotifierProvider.notifier);

      await notifier.verify(
        expectedVersion: '1.0.17.0',
        expectedActiveInstance: 2,
      );

      expect(
        container.read(firmwareUpdateNotifierProvider).phase,
        FirmwareUpdatePhase.done,
      );
    });

    test('verify ignores the ota row in the multi-Active consistency check',
        () async {
      // The ota row is virtual — it is not a bank that can be booted, so it
      // cannot make the physical banks inconsistent. Measured firmware never
      // reports it Active; this fixture forces the case so the narrowing is
      // pinned by something other than the happy path.
      final banksData = FirmwareBanksData(banks: [
        FirmwareUpdateTestData.bankWithStatus(
          instance: 1,
          status: 'Available',
          alias: 'fw1',
        ),
        FirmwareUpdateTestData.bankWithStatus(
          instance: 2,
          status: 'Active',
          version: '1.0.17.0',
          alias: 'fw2',
        ),
        FirmwareUpdateTestData.bankWithStatus(
          instance: 3,
          status: 'Active',
          alias: 'ota',
        ),
      ]);
      final container = createContainer(banksData: AsyncData(banksData));
      addTearDown(container.dispose);
      final notifier = container.read(firmwareUpdateNotifierProvider.notifier);

      await notifier.verify(
        expectedVersion: '1.0.17.0',
        expectedActiveInstance: 2,
      );

      final state = container.read(firmwareUpdateNotifierProvider);
      expect(state.phase, FirmwareUpdatePhase.done);
      expect(state.errorMessage, isNull);
    });

    test('cancel resets to initial state', () {
      final container = createContainer();
      addTearDown(container.dispose);
      final notifier = container.read(firmwareUpdateNotifierProvider.notifier);

      notifier.updateUploadProgress(10, 100);
      notifier.cancel();

      final state = container.read(firmwareUpdateNotifierProvider);
      expect(state.phase, FirmwareUpdatePhase.idle);
      expect(state.uploadedChunks, 0);
      expect(state.totalChunks, 0);
      expect(notifier.pickedBytes, isNull);
    });

    test(
        'enterRecoveryWaiting flips local phase to rebooting AND drives the '
        'shared connection state into waitingForRecovery', () {
      final mockProbe = MockRecoveryProbeService();
      final mockSseManager = MockSseManager();
      final mockAuth = MockAuthNotifier();
      when(() => mockSseManager.disconnect()).thenAnswer((_) async {});
      when(() => mockProbe.probe(healthOnly: any(named: 'healthOnly')))
          .thenAnswer((_) async => ProbeResult.unreachable);

      final container = ProviderContainer(
        overrides: [
          uspClientProvider.overrideWithValue(mockUsp),
          uspFirmwareUpdateServiceProvider.overrideWithValue(mockService),
          uspMutationLockProvider.overrideWithValue(UspMutationLock()),
          firmwareLocalUploadServiceProvider.overrideWithValue(mockUploader),
          recoveryProbeServiceProvider.overrideWithValue(mockProbe),
          sseManagerProvider.overrideWithValue(mockSseManager),
          sseConnectionStateProvider.overrideWith(
            (ref) => Stream.value(SseConnectionState.connected),
          ),
          authProvider.overrideWith(() => mockAuth),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(firmwareUpdateNotifierProvider.notifier);
      notifier.enterRecoveryWaiting();

      expect(
        container.read(firmwareUpdateNotifierProvider).phase,
        FirmwareUpdatePhase.rebooting,
      );
      expect(
        container.read(appConnectionStateProvider),
        AppConnectionState.waitingForRecovery,
      );
      verify(() => mockSseManager.disconnect()).called(1);
    });

    // ════════════════════════════════════════════════════════════════════════
    // OTA Check Tests
    // ════════════════════════════════════════════════════════════════════════

    /// #1550 moved the check off the cloud OTA API and onto the router, and the
    /// notifier's share of that is three decisions:
    ///
    ///   * which instance to ask about — the virtual `ota` row, read out of the L1
    ///     banks cache, never a NAND bank;
    ///   * what to do when there is no such row — answer `notChecked` without
    ///     asking anything and without failing (REQ-A1);
    ///   * what a failure must **not** turn into — `noUpdateFound`. "We could not
    ///     ask" and "we asked and there is nothing" are the same sentence to a user
    ///     and only one of them is true, so the failing arm is asserted on the
    ///     verdict as well as on the throw.
    group('checkForUpdate', () {
      /// Two physical banks and a virtual row the router can be asked about.
      AsyncValue<FirmwareBanksData> banksWithOta({bool available = false}) =>
          AsyncData(FirmwareBanksData(banks: [
            FirmwareUpdateTestData.activeBank(alias: 'fw1'),
            FirmwareUpdateTestData.emptyVersionBank(),
            FirmwareUpdateTestData.otaInstance(available: available),
          ]));

      /// The same router without the fwup stack: nothing to ask.
      final banksWithoutOta = AsyncData(FirmwareBanksData(banks: [
        FirmwareUpdateTestData.activeBank(alias: 'fw1'),
        FirmwareUpdateTestData.emptyVersionBank(),
      ]));

      test('asks about the ota row, not about a bank', () async {
        when(() => mockOtaChecker.check(otaInstance: any(named: 'otaInstance')))
            .thenAnswer((_) async =>
                const FirmwareOtaCheckResult.updateAvailable(version: '2.0.1'));

        final container = createContainer(banksData: banksWithOta());
        addTearDown(container.dispose);
        final notifier =
            container.read(firmwareUpdateNotifierProvider.notifier);

        final result = await notifier.checkForUpdate();

        // Instance 3, which is the ota row; instance 1 is the running bank and
        // instance 2 the spare, and both also report `Available=1`.
        verify(() => mockOtaChecker.check(otaInstance: 3)).called(1);
        expect(
          result,
          const FirmwareOtaCheckResult.updateAvailable(version: '2.0.1'),
        );
        final state = container.read(firmwareUpdateNotifierProvider);
        expect(state.phase, FirmwareUpdatePhase.idle);
        expect(state.otaCheck, result);
      });

      test('publishes a "found nothing" verdict as itself', () async {
        when(() => mockOtaChecker.check(otaInstance: any(named: 'otaInstance')))
            .thenAnswer(
                (_) async => const FirmwareOtaCheckResult.noUpdateFound());

        final container = createContainer(banksData: banksWithOta());
        addTearDown(container.dispose);
        final notifier =
            container.read(firmwareUpdateNotifierProvider.notifier);

        final result = await notifier.checkForUpdate();

        expect(result.verdict, FirmwareOtaCheckVerdict.noUpdateFound);
        final state = container.read(firmwareUpdateNotifierProvider);
        expect(state.phase, FirmwareUpdatePhase.idle);
        expect(state.otaCheck.verdict, FirmwareOtaCheckVerdict.noUpdateFound);
        expect(state.otaCheck.isUpdateAvailable, isFalse);
      });

      // REQ-A1, the notifier's half. The view decides whether to draw the button
      // from the same fact; this arm is the race where the row disappears between
      // that read and this one — and it must not look like a fault, because on OEM
      // and rebadged builds it is permanent.
      test('answers notChecked, and asks nothing, with no ota row', () async {
        final container = createContainer(banksData: banksWithoutOta);
        addTearDown(container.dispose);
        final notifier =
            container.read(firmwareUpdateNotifierProvider.notifier);

        final result = await notifier.checkForUpdate();

        expect(result.verdict, FirmwareOtaCheckVerdict.notChecked);
        verifyNever(
            () => mockOtaChecker.check(otaInstance: any(named: 'otaInstance')));
        final state = container.read(firmwareUpdateNotifierProvider);
        expect(state.phase, FirmwareUpdatePhase.idle,
            reason: 'the phase never left idle, so no busy state was shown for '
                'a check that was never dispatched');
        expect(state.otaCheck.verdict, FirmwareOtaCheckVerdict.notChecked);
        expect(state.errorMessage, isNull,
            reason: 'a router built without the fwup stack has not failed');
      });

      // The single failure this whole work package is arranged to prevent.
      test('rethrows, and leaves no verdict behind', () async {
        when(() => mockOtaChecker.check(otaInstance: any(named: 'otaInstance')))
            .thenThrow(const UspCompleteFailureError(
                summary: 'the router refused the firmware check',
                failures: []));

        final container = createContainer(banksData: banksWithOta());
        addTearDown(container.dispose);
        final notifier =
            container.read(firmwareUpdateNotifierProvider.notifier);

        await expectLater(
          notifier.checkForUpdate(),
          throwsA(isA<ServiceError>()),
        );

        final state = container.read(firmwareUpdateNotifierProvider);
        expect(state.phase, FirmwareUpdatePhase.idle);
        expect(state.otaCheck.verdict, FirmwareOtaCheckVerdict.notChecked,
            reason: 'a failed check must not publish noUpdateFound — that is '
                'the substitution that turns a broken check into reassurance');
      });

      // The same assertion for the exception this notifier is not written to
      // expect. `on ServiceError` is the right catch — Article XIII says the
      // provider layer sees nothing else — but it is not a guarantee, and the one
      // thing that must not depend on the service keeping its promise is whether
      // the button ever stops spinning. `checkingOta` is what makes
      // `AppButton.isLoading` true and it has no other way back to idle: no
      // timeout, no navigation, nothing else clears it for the rest of the
      // session. Found by review on the real path — opening the SSE subscription
      // is an HTTP POST that threw past the phase — which is fixed in the service;
      // this pins the floor under it.
      test('an exception it does not expect still frees the button', () async {
        when(() => mockOtaChecker.check(otaInstance: any(named: 'otaInstance')))
            .thenThrow(StateError('not a ServiceError'));

        final container = createContainer(banksData: banksWithOta());
        addTearDown(container.dispose);

        await expectLater(
          container
              .read(firmwareUpdateNotifierProvider.notifier)
              .checkForUpdate(),
          throwsA(isA<StateError>()),
        );

        final state = container.read(firmwareUpdateNotifierProvider);
        expect(state.phase, FirmwareUpdatePhase.idle,
            reason: 'a phase that outlives the call it belongs to is a button '
                'that spins until the session ends');
        expect(state.otaCheck.verdict, FirmwareOtaCheckVerdict.notChecked);
      });

      // Two checks, because the state under test is what the *second* one starts
      // from. Seeding the verdict through a test-only setter would prove the
      // clearing works on a state no check produced; running one check for real
      // and inspecting from inside the next is the same assertion against the
      // sequence a user actually performs.
      test('clears the previous verdict before the next check runs', () async {
        late final ProviderContainer container;
        var calls = 0;
        when(() => mockOtaChecker.check(otaInstance: any(named: 'otaInstance')))
            .thenAnswer((_) async {
          calls++;
          if (calls == 2) {
            // Read mid-flight: the stale verdict has to be gone *while* the
            // second check runs, not merely replaced when it returns. A card
            // still showing "update available" beside a running spinner is
            // reporting the previous check's answer as this one's.
            final inFlight = container.read(firmwareUpdateNotifierProvider);
            expect(inFlight.phase, FirmwareUpdatePhase.checkingOta);
            expect(
                inFlight.otaCheck.verdict, FirmwareOtaCheckVerdict.notChecked);
          }
          return const FirmwareOtaCheckResult.updateAvailable(version: '2.0.1');
        });

        container = createContainer(banksData: banksWithOta(available: true));
        addTearDown(container.dispose);
        final notifier =
            container.read(firmwareUpdateNotifierProvider.notifier);

        await notifier.checkForUpdate();
        expect(
          container
              .read(firmwareUpdateNotifierProvider)
              .otaCheck
              .isUpdateAvailable,
          isTrue,
          reason:
              'the first check has to leave a verdict behind, or the second '
              'one has nothing to clear and this test measures nothing',
        );

        await notifier.checkForUpdate();

        expect(calls, 2);
        expect(container.read(firmwareUpdateNotifierProvider).errorMessage,
            isNull);
      });

      // The check writes `Available`/`Version` on the router, so the L1 cache the
      // dashboard banner and the mascot read is stale the moment it returns.
      test('refreshes the banks cache after a successful check', () async {
        when(() => mockOtaChecker.check(otaInstance: any(named: 'otaInstance')))
            .thenAnswer((_) async =>
                const FirmwareOtaCheckResult.updateAvailable(version: '2.0.1'));
        final banks = _CountingBanksNotifier(banksWithOta());
        final container = createContainer(extra: [
          firmwareBanksDataProvider.overrideWith(() => banks),
        ]);
        addTearDown(container.dispose);

        await container
            .read(firmwareUpdateNotifierProvider.notifier)
            .checkForUpdate();

        expect(banks.refreshes, 1);
      });

      // ...and a refresh that fails is a stale banner, not a failed check. The
      // user watched this check succeed; reporting an error for the bookkeeping
      // behind it would contradict what they just saw.
      test('survives a banks refresh that fails', () async {
        when(() => mockOtaChecker.check(otaInstance: any(named: 'otaInstance')))
            .thenAnswer((_) async =>
                const FirmwareOtaCheckResult.updateAvailable(version: '2.0.1'));

        final container = createContainer(extra: [
          firmwareBanksDataProvider
              .overrideWith(() => _FailingRefreshBanksNotifier(banksWithOta())),
        ]);
        addTearDown(container.dispose);

        final result = await container
            .read(firmwareUpdateNotifierProvider.notifier)
            .checkForUpdate();

        expect(result.verdict, FirmwareOtaCheckVerdict.updateAvailable);
        expect(container.read(firmwareUpdateNotifierProvider).phase,
            FirmwareUpdatePhase.idle);
      });
    });

    group('triggerOtaInstall', () {
      test('transitions triggering → installing on success', () async {
        when(() => mockService.triggerOtaDownload(
              targetInstance: any(named: 'targetInstance'),
              firmwareUrl: any(named: 'firmwareUrl'),
            )).thenAnswer((_) async {});

        final container = createContainer();
        addTearDown(container.dispose);
        final notifier =
            container.read(firmwareUpdateNotifierProvider.notifier);

        await notifier.triggerOtaInstall(
          targetInstance: 2,
          firmwareUrl: 'http://example.com/fw.img',
        );

        expect(
          container.read(firmwareUpdateNotifierProvider).phase,
          FirmwareUpdatePhase.installing,
        );
        verify(() => mockService.triggerOtaDownload(
              targetInstance: 2,
              firmwareUrl: 'http://example.com/fw.img',
            )).called(1);
      });

      test('transitions to failed on ServiceError', () async {
        when(() => mockService.triggerOtaDownload(
              targetInstance: any(named: 'targetInstance'),
              firmwareUrl: any(named: 'firmwareUrl'),
            )).thenThrow(const NetworkError(detail: 'Download failed'));

        final container = createContainer();
        addTearDown(container.dispose);
        final notifier =
            container.read(firmwareUpdateNotifierProvider.notifier);

        await expectLater(
          notifier.triggerOtaInstall(
            targetInstance: 2,
            firmwareUrl: 'http://example.com/fw.img',
          ),
          throwsA(isA<NetworkError>()),
        );

        final state = container.read(firmwareUpdateNotifierProvider);
        expect(state.phase, FirmwareUpdatePhase.failed);
        expect(state.errorMessage, contains('Network error'));
      });
    });

    // #1496 phase 6, acceptance 6. This class holds the pair that made phase 6
    // necessary: `runUpload` and `triggerOtaInstall` both mean "update the
    // firmware", they are 60 lines apart, and one of them cannot work in Remote
    // Assistance at all.
    //
    // Not a policy choice for the upload — a measurement.
    // `firmware_local_upload_service.dart` derives the router host from
    // `window.location` and has zero mode reads in the whole file, so under RA it
    // pushes the image at Guardian instead of at the router. It was broken before
    // this phase, silently; the guard makes it say so.
    //
    // Note what could NOT be tested here, and why the guard is at the notifier.
    // Both flows converge one line later: `firmware_update_view.dart` calls the
    // same `notifier.enterRecoveryWaiting()` (hard-coding
    // `RecoveryTrigger.operationalFirmwareUpgrade`) and then the same
    // `showFirmwareUpdateRecoveryDialog(context, ref)` with identical arguments.
    // #1496's own 🔴 section proposed carrying the DisruptionClass on
    // `RecoveryContext`, which is downstream of that convergence: both operations
    // would have passed the same value and the pair could not have differed.
    group('the operation guard (#1496)', () {
      /// Remote Assistance by provider override — falsification criterion 3.
      ProviderContainer remoteContainer({FirmwareFilePickerService? picker}) =>
          createContainer(
            picker: picker,
            extra: [
              appModeProfileProvider
                  .overrideWithValue(const RemoteModeProfile()),
            ],
          );

      test('local upload is refused, and no bytes are pushed', () async {
        final bytes = validImage();
        final container = remoteContainer(
          picker: _StubPickerService(
            FirmwarePickedFile(
                name: 'fw.img', size: bytes.length, bytes: bytes),
          ),
        );
        addTearDown(container.dispose);
        final notifier =
            container.read(firmwareUpdateNotifierProvider.notifier);

        // A real image is picked first, so `verifyNever` below means "the guard
        // stopped it" and not "there was nothing to upload anyway".
        expect(await notifier.pickAndValidateFile(), isTrue);

        await expectLater(
          notifier.runUpload(commandKey: 'cmd-1'),
          throwsA(isA<UnauthorizedError>()),
        );

        verifyNever(() => mockUploader.uploadFile(
              bytes: any(named: 'bytes'),
              md5: any(named: 'md5'),
              commandKey: any(named: 'commandKey'),
              isCancelled: any(named: 'isCancelled'),
              onProgress: any(named: 'onProgress'),
            ));

        // Refused *before* the phase moves. The roster test asserts this by
        // regex — the guard must be `runUpload`'s first statement — and a regex
        // is the wrong place for the only copy of a behavioural claim. The state
        // is what the view renders: `uploading` here would put a progress bar
        // and a cancel button on screen for an upload that never started, and
        // `failed` would be honest but would swallow the snackbar
        // `_onConfirmInstall` now shows on `UnauthorizedError`.
        final state = container.read(firmwareUpdateNotifierProvider);
        expect(state.phase, FirmwareUpdatePhase.idle);
        expect(state.totalChunks, 0);
      });

      test('cloud OTA install is not refused', () async {
        when(() => mockService.triggerOtaDownload(
              targetInstance: any(named: 'targetInstance'),
              firmwareUrl: any(named: 'firmwareUrl'),
            )).thenAnswer((_) async {});
        final container = remoteContainer();
        addTearDown(container.dispose);

        await container
            .read(firmwareUpdateNotifierProvider.notifier)
            .triggerOtaInstall(
              targetInstance: 2,
              firmwareUrl: 'http://example.com/fw.img',
            );

        verify(() => mockService.triggerOtaDownload(
              targetInstance: 2,
              firmwareUrl: 'http://example.com/fw.img',
            )).called(1);
        // The pair's other half, and the reason `DisruptionClass` is named for
        // consequences: an OTA is *more* disruptive to look at than a local
        // upload — the router downloads, flashes and reboots — and it is the one
        // that works remotely, because nothing it destroys is on the agent's path.
      });

      test('the local install trigger is not refused either', () async {
        when(() => mockService.triggerLocalDownload(
                targetInstance: any(named: 'targetInstance')))
            .thenAnswer((_) async {});
        final container = remoteContainer();
        addTearDown(container.dispose);

        await container
            .read(firmwareUpdateNotifierProvider.notifier)
            .triggerInstall(targetInstance: 2);

        verify(() => mockService.triggerLocalDownload(targetInstance: 2))
            .called(1);
        // Deliberate, and worth stating because it reads like a contradiction:
        // the local *flow* is blocked, but this step is not what blocks it.
        // Triggering an install of an image the router already holds only
        // restarts the box. The local-only feature is *pushing the bytes*, so
        // that is where the refusal belongs; putting a second one here would
        // classify by flow instead of by consequence — the failure mode
        // `DisruptionClass` exists to avoid. In RA this method is unreachable
        // anyway: `_onConfirmInstall` returns as soon as `runUpload` throws.
      });
    });
  });
}
