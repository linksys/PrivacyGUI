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
import 'package:privacy_gui/page/firmware_update/models/firmware_update_phase.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_banks_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_update_notifier.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_info.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_file_picker_service.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_local_upload_service.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_ota_check_service.dart';
import 'package:privacy_gui/page/firmware_update/services/usp_firmware_update_service.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';

import '../../../mocks/test_data/firmware_update_test_data.dart';

class MockFirmwareOtaCheckService extends Mock
    implements FirmwareOtaCheckService {}

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

void main() {
  late MockUspClient mockUsp;
  late MockUspFirmwareUpdateService mockService;
  late MockFirmwareLocalUploadService mockUploader;
  late MockFirmwareOtaCheckService mockOtaChecker;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(const FirmwareOtaCheckParams(
      macAddress: '',
      installedVersion: '',
      modelNumber: '',
      hardwareVersion: '',
      ipAddress: '',
    ));
  });

  setUp(() {
    mockUsp = MockUspClient();
    mockService = MockUspFirmwareUpdateService();
    mockUploader = MockFirmwareLocalUploadService();
    mockOtaChecker = MockFirmwareOtaCheckService();
    when(() => mockUsp.isAuthenticated).thenReturn(true);
    when(() => mockUploader.totalFragmentsFor(any())).thenReturn(32);
  });

  ProviderContainer createContainer({
    FirmwareFilePickerService? picker,
    FirmwareLocalUploadService? uploader,
    FirmwareOtaCheckService? otaChecker,
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
        firmwareOtaCheckServiceProvider
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

    group('checkForOtaUpdate', () {
      const testParams = FirmwareOtaCheckParams(
        macAddress: '74-12-13-21-56-3A',
        installedVersion: '1.2.1',
        modelNumber: 'M60-US',
        hardwareVersion: '1',
        ipAddress: '192.168.1.1',
      );

      test(
          'transitions idle → checkingOta → idle with otaInfo when update available',
          () async {
        final otaInfo = FirmwareOtaInfo(
          version: '1.0.10.25092307',
          releaseDate: DateTime.utc(2025, 9, 23),
          downloadUrl: 'http://download.linksys.com/updates/firmware.img',
          checksum: '1022217387',
          checkInterval: 'daily',
          checkTime: '06:00:00Z',
        );
        when(() => mockOtaChecker.checkForUpdate(any()))
            .thenAnswer((_) async => otaInfo);

        final container = createContainer();
        addTearDown(container.dispose);
        final notifier =
            container.read(firmwareUpdateNotifierProvider.notifier);

        final result = await notifier.checkForOtaUpdate(testParams);

        expect(result, equals(otaInfo));
        final state = container.read(firmwareUpdateNotifierProvider);
        expect(state.phase, FirmwareUpdatePhase.idle);
        expect(state.otaInfo, equals(otaInfo));
        expect(state.otaUpToDate, isFalse);
      });

      test(
          'transitions idle → checkingOta → idle with otaUpToDate when no update',
          () async {
        when(() => mockOtaChecker.checkForUpdate(any()))
            .thenAnswer((_) async => null);

        final container = createContainer();
        addTearDown(container.dispose);
        final notifier =
            container.read(firmwareUpdateNotifierProvider.notifier);

        final result = await notifier.checkForOtaUpdate(testParams);

        expect(result, isNull);
        final state = container.read(firmwareUpdateNotifierProvider);
        expect(state.phase, FirmwareUpdatePhase.idle);
        expect(state.otaInfo, isNull);
        expect(state.otaUpToDate, isTrue);
      });

      test('rethrows FirmwareOtaCheckException and returns to idle', () async {
        when(() => mockOtaChecker.checkForUpdate(any()))
            .thenThrow(FirmwareOtaCheckException('API error'));

        final container = createContainer();
        addTearDown(container.dispose);
        final notifier =
            container.read(firmwareUpdateNotifierProvider.notifier);

        await expectLater(
          notifier.checkForOtaUpdate(testParams),
          throwsA(isA<FirmwareOtaCheckException>()),
        );

        final state = container.read(firmwareUpdateNotifierProvider);
        expect(state.phase, FirmwareUpdatePhase.idle);
        expect(state.otaInfo, isNull);
      });

      test('clears previous otaInfo and error on new check', () async {
        when(() => mockOtaChecker.checkForUpdate(any()))
            .thenAnswer((_) async => null);

        final container = createContainer();
        addTearDown(container.dispose);
        final notifier =
            container.read(firmwareUpdateNotifierProvider.notifier);

        // Simulate previous state with otaInfo
        notifier.debugSeedBanks(
          active: FirmwareUpdateTestData.activeBank(),
        );

        await notifier.checkForOtaUpdate(testParams);

        final state = container.read(firmwareUpdateNotifierProvider);
        expect(state.otaInfo, isNull);
        expect(state.errorMessage, isNull);
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
