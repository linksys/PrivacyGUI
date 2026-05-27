import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/core/connection/services/recovery_probe_service.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/usp/services/sse_connection_manager.dart';
import 'package:privacy_gui/core/usp/services/sse_manager.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_phase.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_banks_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_update_notifier.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_file_picker_service.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_local_upload_service.dart';
import 'package:privacy_gui/page/firmware_update/services/usp_firmware_update_service.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';

import '../../../mocks/test_data/firmware_update_test_data.dart';

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
  Future<AuthState> build() async =>
      AuthState(loginType: LoginType.local, localPassword: 'test');
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

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    mockUsp = MockUspClient();
    mockService = MockUspFirmwareUpdateService();
    mockUploader = MockFirmwareLocalUploadService();
    when(() => mockUsp.isAuthenticated).thenReturn(true);
    when(() => mockUploader.totalFragmentsFor(any())).thenReturn(32);
  });

  ProviderContainer createContainer({
    FirmwareFilePickerService? picker,
    FirmwareLocalUploadService? uploader,
    AsyncValue<FirmwareBanksData>? banksData,
  }) {
    final container = ProviderContainer(
      overrides: [
        uspClientProvider.overrideWithValue(mockUsp),
        uspFirmwareUpdateServiceProvider.overrideWithValue(mockService),
        uspMutationLockProvider.overrideWithValue(UspMutationLock()),
        firmwareLocalUploadServiceProvider
            .overrideWithValue(uploader ?? mockUploader),
        if (picker != null)
          firmwareFilePickerServiceProvider.overrideWithValue(picker),
        if (banksData != null)
          firmwareBanksDataProvider.overrideWith(
            () => _FakeBanksNotifier(banksData),
          ),
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
            const NetworkError(message: 'timeout'), StackTrace.current),
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
          )).thenThrow(const NetworkError(message: 'chunk timeout'));
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
  });
}
