import 'dart:async';
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
import 'package:privacy_gui/page/firmware_update/models/firmware_auto_update_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_failure.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_check_result.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_install_progress.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_install_result.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_phase.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_state.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_banks_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_update_notifier.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_file_picker_service.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_local_upload_service.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_router_ota_check_service.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_router_ota_install_service.dart';
import 'package:privacy_gui/page/firmware_update/services/usp_firmware_update_service.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';

import '../../../mocks/test_data/firmware_update_test_data.dart';

class MockFirmwareRouterOtaCheckService extends Mock
    implements FirmwareRouterOtaCheckService {}

class MockFirmwareRouterOtaInstallService extends Mock
    implements FirmwareRouterOtaInstallService {}

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

/// A router that refuses the first read and answers every one after it.
///
/// The shape a retry needs: the failure has to be able to *stop* being true, and
/// the only honest way to show that is through the L1 provider rather than a
/// seeded field.
///
/// **The counter is an instance field, and that is a consequence of driving the
/// real retry path.** It used to be a `static` with a hand-called `reset()`,
/// because the test replaced the notifier with `container.invalidate` — which
/// constructs a new one, so instance state could not carry the count. But the
/// retry button does not invalidate anything: it passes `refresh: true`, which
/// reaches `refresh()` on the notifier *that already failed*. Same instance, so
/// the field works — and the order-dependent static, whose omitted `reset()`
/// would have made this file's first failure look like a later test's fault, goes
/// away as a side effect.
class _FlakyBanksNotifier extends FirmwareBanksDataNotifier {
  int reads = 0;

  @override
  Future<FirmwareBanksData> build() => _read();

  @override
  Future<FirmwareBanksData> refresh() async {
    final data = await _read();
    state = AsyncData(data);
    return data;
  }

  Future<FirmwareBanksData> _read() async {
    if (++reads == 1) throw const NetworkError(detail: 'timeout');
    return FirmwareBanksData(banks: [
      FirmwareUpdateTestData.activeBank(),
      FirmwareUpdateTestData.availableBank(),
    ]);
  }
}

/// A read that fails with something other than a [ServiceError].
///
/// `TimeoutException` because it is the one this app raises on purpose:
/// `UspMutationLock.withLock` throws it after 30 s, deliberately not as a
/// `ServiceError`. A codegen parse of an unexpected payload reaches the same arm
/// with a `TypeError`.
class _TimingOutBanksNotifier extends FirmwareBanksDataNotifier {
  @override
  Future<FirmwareBanksData> build() async =>
      throw TimeoutException('mutation lock', const Duration(seconds: 30));

  /// The same failure on the path `verify()` takes. `refresh()` rethrows raw, so
  /// this is what actually arrives at the notifier's own catch.
  @override
  Future<FirmwareBanksData> refresh() async =>
      throw TimeoutException('mutation lock', const Duration(seconds: 30));
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
  late MockFirmwareRouterOtaInstallService mockOtaInstaller;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    mockUsp = MockUspClient();
    mockService = MockUspFirmwareUpdateService();
    mockUploader = MockFirmwareLocalUploadService();
    mockOtaChecker = MockFirmwareRouterOtaCheckService();
    mockOtaInstaller = MockFirmwareRouterOtaInstallService();
    when(() => mockUsp.isAuthenticated).thenReturn(true);
    when(() => mockUploader.totalFragmentsFor(any())).thenReturn(32);
  });

  ProviderContainer createContainer({
    FirmwareFilePickerService? picker,
    FirmwareLocalUploadService? uploader,
    FirmwareRouterOtaCheckService? otaChecker,
    FirmwareRouterOtaInstallService? otaInstaller,
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
        firmwareRouterOtaInstallServiceProvider
            .overrideWithValue(otaInstaller ?? mockOtaInstaller),
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

    /// #1551 — the page opens knowing what the router is already offering.
    ///
    /// The same `ota` row the dashboard banner is built from arrives in the banks
    /// read, so a user who taps that banner must not land on a page that asks them
    /// to check for the update it just told them about. `Available` on that row is
    /// the router's own record of its last completed check, so showing it is not a
    /// claim of ours — and `Available=false` is reported both for "checked, nothing
    /// new" and for "never checked", which is why the false case seeds nothing at
    /// all rather than "up to date".
    group('the verdict the banks read already answers', () {
      test('an available ota row opens the page as an offer', () async {
        final container = createContainer(
          banksData: AsyncData(FirmwareBanksData(banks: [
            FirmwareUpdateTestData.activeBank(),
            FirmwareUpdateTestData.availableBank(),
            FirmwareUpdateTestData.otaInstance(
                available: true, version: '2.0.1.26091321'),
          ])),
        );
        addTearDown(container.dispose);

        await container
            .read(firmwareUpdateNotifierProvider.notifier)
            .loadBanks();

        final state = container.read(firmwareUpdateNotifierProvider);
        expect(state.otaCheck.verdict, FirmwareOtaCheckVerdict.updateAvailable);
        // The version carries too — the card prints it, and the install offer is
        // what `verify()` compares the rebooted router against.
        expect(state.otaCheck.version, '2.0.1.26091321');
        // A read, not an operation: nothing about the phase moves.
        expect(state.phase, FirmwareUpdatePhase.idle);
      });

      test('a router with no ota row claims nothing', () async {
        // REQ-A1: OEM and rebadged builds never ship the row. The absence is
        // permanent and says nothing about firmware, so the page stays in
        // `notChecked` and the card renders the not-supported sentence instead.
        final container = createContainer(
          banksData: AsyncData(FirmwareBanksData(banks: [
            FirmwareUpdateTestData.activeBank(),
            FirmwareUpdateTestData.availableBank(),
          ])),
        );
        addTearDown(container.dispose);

        await container
            .read(firmwareUpdateNotifierProvider.notifier)
            .loadBanks();

        expect(container.read(firmwareUpdateNotifierProvider).otaCheck.verdict,
            FirmwareOtaCheckVerdict.notChecked);
      });

      test('an ota row with nothing on offer is not "up to date"', () async {
        // The row reads `Available=false` / `NoImage` both after a check that found
        // nothing and before any check has ever run, so it cannot be turned into
        // `noUpdateFound` — that is the substitution this whole work package exists
        // to prevent.
        final container = createContainer(
          banksData: AsyncData(FirmwareBanksData(banks: [
            FirmwareUpdateTestData.activeBank(),
            FirmwareUpdateTestData.otaInstance(available: false),
          ])),
        );
        addTearDown(container.dispose);

        await container
            .read(firmwareUpdateNotifierProvider.notifier)
            .loadBanks();

        expect(container.read(firmwareUpdateNotifierProvider).otaCheck.verdict,
            FirmwareOtaCheckVerdict.notChecked);
      });

      test('a check that has run outranks the row', () async {
        // `loadBanks` runs again on the read-error card's retry, so the seed has to
        // be one-way. The check is the later answer — the row it read is the one the
        // check has since superseded — and re-seeding would put the offer back on a
        // page whose check had just ruled it out.
        when(() => mockOtaChecker.check(otaInstance: any(named: 'otaInstance')))
            .thenAnswer(
                (_) async => const FirmwareOtaCheckResult.noUpdateFound());
        final container = createContainer(
          banksData: AsyncData(FirmwareBanksData(banks: [
            FirmwareUpdateTestData.activeBank(),
            FirmwareUpdateTestData.otaInstance(
                available: true, version: '2.0.1.26091321'),
          ])),
        );
        addTearDown(container.dispose);
        final notifier =
            container.read(firmwareUpdateNotifierProvider.notifier);

        await notifier.checkForUpdate();
        await notifier.loadBanks(refresh: true);

        expect(container.read(firmwareUpdateNotifierProvider).otaCheck.verdict,
            FirmwareOtaCheckVerdict.noUpdateFound);
      });
    });

    /// #1551: a read that failed is not an update that failed.
    ///
    /// This used to assert `failed` + `errorMessage` (now `failure`), which is what
    /// the code did
    /// and what #1549's handover called out as wrong. Both pages render that pair
    /// as "Update failed" with a `firmware-retry` button whose `onTap` is
    /// `cancel()` — so an unreachable router painted a failed *update* over a page
    /// where nothing had been attempted, and offered a retry that resets the flow
    /// instead of re-reading. The read failure now has its own field.
    test('loadBanks failure is a read error, not a failed update', () async {
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
      expect(state.stateReadError, isNotNull);
      expect(state.phase, FirmwareUpdatePhase.idle);
      expect(state.failure, isNull);
      // Still rethrown: `firmware_ota_view.dart` and `firmware_update_view.dart`
      // both `catchError` this call, and a swallowed failure would make the
      // post-frame callback drop the only signal it has.
    });

    test('the retry re-reads, and a successful read clears the error',
        () async {
      // The retry the new card offers re-reads, so the error has to be able to go
      // away without anything else in the state moving. Driven through the real
      // provider — a router that fails once and then answers — rather than seeded,
      // and through the **argument the button actually passes**: this used to call
      // `container.invalidate` and then a bare `loadBanks()`, which replaced the
      // provider by hand and so never went near the `refresh: true` branch the
      // retry depends on.
      final container = createContainer(extra: [
        firmwareBanksDataProvider.overrideWith(_FlakyBanksNotifier.new),
      ]);
      addTearDown(container.dispose);
      final notifier = container.read(firmwareUpdateNotifierProvider.notifier);

      await expectLater(notifier.loadBanks(), throwsA(isA<NetworkError>()));
      expect(container.read(firmwareUpdateNotifierProvider).stateReadError,
          isNotNull);

      await notifier.loadBanks(refresh: true);

      final state = container.read(firmwareUpdateNotifierProvider);
      expect(state.stateReadError, isNull);
      expect(state.activeBank?.instance, 1);
    });

    test('a retry without refresh replays the cached failure', () async {
      // Why `refresh: true` is not politeness. Once the L1 provider is in
      // `AsyncError`, `ref.read(provider.future)` rethrows the *cached* error
      // without going near the router — so a retry button wired to a bare
      // `loadBanks()` would redraw the same card forever against a router that had
      // started answering. The flaky notifier answers every read after the first,
      // so a second read that reached it would succeed; this one does not.
      final flaky = _FlakyBanksNotifier();
      final container = createContainer(extra: [
        firmwareBanksDataProvider.overrideWith(() => flaky),
      ]);
      addTearDown(container.dispose);
      final notifier = container.read(firmwareUpdateNotifierProvider.notifier);

      await expectLater(notifier.loadBanks(), throwsA(isA<NetworkError>()));
      await expectLater(notifier.loadBanks(), throwsA(isA<NetworkError>()));

      expect(flaky.reads, 1,
          reason: 'the second call never reached the router — it replayed the '
              'error the first one cached');
      expect(container.read(firmwareUpdateNotifierProvider).stateReadError,
          isNotNull);
    });

    test('a read failure that is not a ServiceError is still a read error',
        () async {
      // The bridge does not only fail with `ServiceError`. `UspMutationLock`
      // throws a bare `TimeoutException` after 30 s by design, and a codegen
      // parse of an unexpected payload throws a `TypeError` — neither is caught by
      // an `on ServiceError` arm. Recording nothing for them leaves
      // `stateReadError` null with the banks provider in `AsyncError`, and the
      // page's card needs **both**: the result is a firmware page with no card, no
      // error and no explanation.
      final container = createContainer(extra: [
        firmwareBanksDataProvider.overrideWith(_TimingOutBanksNotifier.new),
      ]);
      addTearDown(container.dispose);

      await expectLater(
        container.read(firmwareUpdateNotifierProvider.notifier).loadBanks(),
        throwsA(isA<TimeoutException>()),
      );

      final state = container.read(firmwareUpdateNotifierProvider);
      expect(state.stateReadError, isNotNull,
          reason: 'the card is keyed on this field, and the failure is no less '
              'unreadable for having an unexpected type');
      expect(state.phase, FirmwareUpdatePhase.idle);
      expect(state.failure, isNull);
    });

    test('pickAndValidateFile cancellation returns to idle without error', () {
      final container = createContainer(picker: _StubPickerService(null));
      addTearDown(container.dispose);
      final notifier = container.read(firmwareUpdateNotifierProvider.notifier);

      return notifier.pickAndValidateFile().then((ok) {
        expect(ok, isFalse);
        final state = container.read(firmwareUpdateNotifierProvider);
        expect(state.phase, FirmwareUpdatePhase.idle);
        expect(state.failure, isNull);
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
      // The reason, not a sentence: the sentence now lives in twenty-six ARBs and
      // asserting the English one here would pass while the other twenty-five
      // were wrong — which is the defect this field was introduced to fix.
      expect(state.failure?.reason, FirmwareFailureReason.fileTypeUnsupported);
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
      // Too small, and the size that says so. The validator threw `tooLarge` for
      // this case until the sentence started being chosen by `kind` — harmless
      // while the notifier copied the English `message` verbatim, and a 1 KB file
      // reported as too big the moment it wasn't.
      expect(
        state.failure,
        FirmwareFailure.fileTooSmall(sizeBytes: tinyBytes.length),
      );
    });

    test('runUpload fails fast when no image was picked', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      final notifier = container.read(firmwareUpdateNotifierProvider.notifier);

      await notifier.runUpload(commandKey: 'cmd-1');

      final state = container.read(firmwareUpdateNotifierProvider);
      expect(state.phase, FirmwareUpdatePhase.failed);
      expect(state.failure, const FirmwareFailure.noImageSelected());
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
      // The transport failure travels as a `ServiceError`, so its copy stays with
      // `localizeServiceError` — this layer only has to carry it, not word it.
      expect(state.failure?.reason, FirmwareFailureReason.serviceError);
      expect(state.failure?.error, isA<NetworkError>());
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
      // Both halves of the diagnostic: which image was expected, and what the
      // router says that image is instead. `Available` stays untranslated on
      // purpose — it is a TR-181 token, so it has to match the router's own output.
      expect(
        state.failure,
        FirmwareFailure.bootedOldImage(instance: 2, status: 'Available'),
      );
    });

    group('a manual upload the router refused (#1572)', () {
      // Measured on FW `2.0.1.26091601` with a deliberately bad image: the router
      // wrote `fwup_error_code=5`, left `fwup_state` at `0`, left the banks unchanged,
      // and logged **nothing at all**. So that parameter is not the best account of the
      // failure, it is the only one that exists — and the app was reporting "the router
      // restarted but did not start the new firmware", which is wrong twice over.
      FirmwareBanksData unflashed() => FirmwareBanksData(banks: [
            FirmwareUpdateTestData.bankWithStatus(
                instance: 1, status: 'Active', version: '2.0.1.26091601'),
            FirmwareUpdateTestData.bankWithStatus(
                instance: 2, status: 'Available', version: ''),
          ]);

      /// Runs the real manual sequence — baseline read, dispatch, verify — with the
      /// error code moving from [before] to [after].
      Future<FirmwareUpdateState> runInstall({
        required FirmwareUpdateErrorCode before,
        required FirmwareUpdateErrorCode after,
        bool baselineReadFails = false,
      }) async {
        var call = 0;
        when(() => mockService.fetchAutoUpdate()).thenAnswer((_) async {
          final isBaseline = call++ == 0;
          if (isBaseline && baselineReadFails) throw NetworkError();
          return FirmwareUpdateTestData.autoUpdateModel(
              errorCode: isBaseline ? before : after);
        });
        when(() => mockService.triggerLocalDownload(
                targetInstance: any(named: 'targetInstance')))
            .thenAnswer((_) async {});

        final container = createContainer(banksData: AsyncData(unflashed()));
        addTearDown(container.dispose);
        final notifier =
            container.read(firmwareUpdateNotifierProvider.notifier);

        await notifier.triggerInstall(targetInstance: 2);
        await notifier.verify(expectedVersion: '', expectedActiveInstance: 2);
        return container.read(firmwareUpdateNotifierProvider);
      }

      test('the router\'s reason replaces the reboot sentence', () async {
        final state = await runInstall(
          before: FirmwareUpdateErrorCode.none,
          after: FirmwareUpdateErrorCode.signature,
        );

        expect(state.phase, FirmwareUpdatePhase.failed);
        expect(
            state.failure,
            const FirmwareFailure.routerReported(
                FirmwareUpdateErrorCode.signature));
        expect(
            state.failure?.reason, isNot(FirmwareFailureReason.bootedOldImage));
      });

      test('a code that did not move is the previous upload\'s', () async {
        // The regression this baseline exists for, and it is not hypothetical: `fwcc`
        // writes the error at four sites and clears it at **none**, and the only clear
        // in the firmware outside `fwupd` runs on boot. So without the diff, one bad
        // image would make every later upload — including the ones that work — report
        // a signature failure for the rest of the boot.
        final state = await runInstall(
          before: FirmwareUpdateErrorCode.signature,
          after: FirmwareUpdateErrorCode.signature,
        );

        expect(state.failure,
            FirmwareFailure.bootedOldImage(instance: 2, status: 'Available'),
            reason: 'the bank shape is all this install actually established');
      });

      test('a refusal is reported without waiting for a reboot', () async {
        // The placement bug, pinned. The first version of this fix lived only in
        // `verify()` — which the manual flow reaches after a fixed 60 s "Installing
        // firmware" delay *and* a 60 s recovery cooldown, so a refused image took over
        // two minutes to produce a message about an update that was already over.
        // Nothing reboots, so the wait was for an event that never comes.
        var call = 0;
        when(() => mockService.fetchAutoUpdate()).thenAnswer((_) async {
          final isBaseline = call++ == 0;
          return FirmwareUpdateTestData.autoUpdateModel(
              errorCode: isBaseline
                  ? FirmwareUpdateErrorCode.none
                  : FirmwareUpdateErrorCode.signature);
        });
        when(() => mockService.triggerLocalDownload(
                targetInstance: any(named: 'targetInstance')))
            .thenAnswer((_) async {});

        final container = createContainer(banksData: AsyncData(unflashed()));
        addTearDown(container.dispose);
        final notifier =
            container.read(firmwareUpdateNotifierProvider.notifier);

        await notifier.triggerInstall(targetInstance: 2);
        final refused = await notifier.awaitInstallRefusal(
          window: const Duration(milliseconds: 40),
          pollInterval: const Duration(milliseconds: 5),
        );

        expect(refused, isTrue,
            reason: 'the caller skips the reboot wait on a true');
        final state = container.read(firmwareUpdateNotifierProvider);
        expect(
            state.failure,
            const FirmwareFailure.routerReported(
                FirmwareUpdateErrorCode.signature));
        // `failed` is not `isUpdating`, so the back arrow works again — which it does
        // not while the page sits in `rebooting` waiting for nothing.
        expect(state.phase, FirmwareUpdatePhase.failed);
        expect(state.isUpdating, isFalse);
      });

      test('a window that runs out lets the reboot wait proceed', () async {
        // The success path must not be slowed or diverted: an install that is really
        // flashing reports no code, so the poll runs out and the caller carries on to
        // the recovery wait exactly as before.
        when(() => mockService.fetchAutoUpdate()).thenAnswer((_) async =>
            FirmwareUpdateTestData.autoUpdateModel(
                errorCode: FirmwareUpdateErrorCode.none));
        when(() => mockService.triggerLocalDownload(
                targetInstance: any(named: 'targetInstance')))
            .thenAnswer((_) async {});

        final container = createContainer(banksData: AsyncData(unflashed()));
        addTearDown(container.dispose);
        final notifier =
            container.read(firmwareUpdateNotifierProvider.notifier);

        await notifier.triggerInstall(targetInstance: 2);
        final refused = await notifier.awaitInstallRefusal(
          window: const Duration(milliseconds: 30),
          pollInterval: const Duration(milliseconds: 5),
        );

        expect(refused, isFalse);
        expect(container.read(firmwareUpdateNotifierProvider).failure, isNull);
      });

      test('a baseline that could not be read attributes nothing', () async {
        final state = await runInstall(
          before: FirmwareUpdateErrorCode.none,
          after: FirmwareUpdateErrorCode.signature,
          baselineReadFails: true,
        );

        expect(state.failure,
            FirmwareFailure.bootedOldImage(instance: 2, status: 'Available'),
            reason: 'with nothing to compare against, the code proves nothing');
      });

      test('a successful flash is not failed by a standing code', () async {
        // The other half of the same hazard: the flash worked, and a code left over
        // from an earlier upload must not turn a bank flip into a failure.
        // The same code on both reads — the baseline and the post-verify one — which
        // is what a router carrying an earlier upload's failure looks like.
        when(() => mockService.fetchAutoUpdate()).thenAnswer((_) async =>
            FirmwareUpdateTestData.autoUpdateModel(
                errorCode: FirmwareUpdateErrorCode.signature));
        when(() => mockService.triggerLocalDownload(
                targetInstance: any(named: 'targetInstance')))
            .thenAnswer((_) async {});

        final flashed = FirmwareBanksData(banks: [
          FirmwareUpdateTestData.bankWithStatus(
              instance: 1, status: 'Available', version: '2.0.1.26091601'),
          FirmwareUpdateTestData.bankWithStatus(
              instance: 2, status: 'Active', version: '2.0.1.26091602'),
        ]);
        final container = createContainer(banksData: AsyncData(flashed));
        addTearDown(container.dispose);
        final notifier =
            container.read(firmwareUpdateNotifierProvider.notifier);

        await notifier.triggerInstall(targetInstance: 2);
        await notifier.verify(expectedVersion: '', expectedActiveInstance: 2);

        final state = container.read(firmwareUpdateNotifierProvider);
        expect(state.phase, FirmwareUpdatePhase.done);
        expect(state.failure, isNull);
      });
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
      expect(state.failure, isNull);
    });

    test(
        'a verify failure that is not a ServiceError still reports, and still '
        'lets the user leave', () async {
      // The trap this closes: `verify()` used to catch `on ServiceError` only,
      // while `firmwareBanksDataProvider.refresh()` rethrows whatever it got. A
      // `TimeoutException` — which `UspMutationLock` raises on purpose — therefore
      // went straight past `_fail()`, the phase stayed `verifying`, and
      // `verifying` is `isUpdating`: `_firmwareExitGuard` in
      // `route_usp_dashboard.dart` returns `!isUpdating`, so the back arrow was
      // *silently* vetoed on a page showing no failure card. Both halves are
      // asserted, because the failure card and the working back arrow are two
      // different bugs.
      final container = createContainer(
        extra: [
          firmwareBanksDataProvider.overrideWith(_TimingOutBanksNotifier.new),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(firmwareUpdateNotifierProvider.notifier);

      await expectLater(
        notifier.verify(expectedVersion: '1.0.17.0', expectedActiveInstance: 2),
        throwsA(isA<TimeoutException>()),
      );

      final state = container.read(firmwareUpdateNotifierProvider);
      expect(state.phase, FirmwareUpdatePhase.failed);
      // The honest sentence for every way out of here: the reboot happened and
      // the firmware information did not get read.
      expect(state.failure, const FirmwareFailure.banksUnreadableAfterReboot());
      // And the guard lets go.
      expect(state.isUpdating, isFalse);
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

    test('cancel keeps the banks it read', () async {
      // `cancel()` is what `firmware-retry` calls — the Try Again on the failure
      // card — and it used to assign `const FirmwareUpdateState()`, which took the
      // banks with it. The banks are not part of the flow being abandoned: they are
      // a reading of the router, and both install paths need `targetBank` to start
      // anything. Dropping it dead-ends the retry the button exists to offer, with
      // "No target bank available" on the second tap and no way to get the reading
      // back short of leaving the page.
      final container = createContainer(
        banksData: AsyncData(FirmwareBanksData(banks: [
          FirmwareUpdateTestData.activeBank(),
          FirmwareUpdateTestData.availableBank(),
        ])),
      );
      addTearDown(container.dispose);
      final notifier = container.read(firmwareUpdateNotifierProvider.notifier);
      await notifier.loadBanks();

      notifier.cancel();

      final state = container.read(firmwareUpdateNotifierProvider);
      expect(state.phase, FirmwareUpdatePhase.idle);
      expect(state.failure, isNull);
      expect(state.activeBank?.instance, 1,
          reason: 'the router still has the firmware it had a moment ago');
      expect(state.targetBank?.instance, 2,
          reason: 'without this the next install offer cannot be dispatched');
      // What cancel *does* clear, so the two halves stay distinguishable: the
      // check verdict is stale the moment an install has been attempted, and
      // leaving it up would re-offer an image whose install just failed.
      expect(state.otaCheck.verdict, FirmwareOtaCheckVerdict.notChecked);
      expect(state.selectedFileName, isNull);
      expect(state.otaProgress, isNull);
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

      test('a router-reported failure lands in state.failure (#1572)',
          () async {
        // The point of the whole error-code channel, at the layer that has to route
        // it: this is not a `ServiceError` about the transport, it is the router
        // naming a firmware reason, so it belongs where `localizeFirmwareFailure`
        // reads rather than where `localizeServiceError` does.
        when(() => mockOtaChecker.check(otaInstance: any(named: 'otaInstance')))
            .thenAnswer((_) async => const FirmwareOtaCheckResult.checkFailed(
                FirmwareUpdateErrorCode.serverUnreachable));

        final container = createContainer(banksData: banksWithOta());
        addTearDown(container.dispose);
        final notifier =
            container.read(firmwareUpdateNotifierProvider.notifier);

        final result = await notifier.checkForUpdate();

        expect(result.verdict, FirmwareOtaCheckVerdict.checkFailed);
        final state = container.read(firmwareUpdateNotifierProvider);
        expect(
            state.failure?.reason, FirmwareFailureReason.routerReportedFailure);
        expect(state.failure?.errorCode,
            FirmwareUpdateErrorCode.serverUnreachable);
        // Idle, not `failed`: nothing was being installed, so there is no update to
        // report as having failed — and `failed` is a phase the card draws a retry
        // button on.
        expect(state.phase, FirmwareUpdatePhase.idle);
        // And the verdict says nothing about the firmware, which is what stops the
        // card claiming "no new firmware was found" for a check that never got an
        // answer.
        expect(state.otaCheck.isUpdateAvailable, isFalse);
      });

      test('a failed check can still be re-seeded with a standing offer',
          () async {
        // `_offerAlreadyOnTheRouter` only re-seeds `notChecked`, so publishing
        // `checkFailed` made it permanently inert: the router would still be offering
        // an update, the app would know it from the banks read, and the card would show
        // nothing but a Check button until another check succeeded. Found in review.
        when(() => mockOtaChecker.check(otaInstance: any(named: 'otaInstance')))
            .thenAnswer((_) async => const FirmwareOtaCheckResult.checkFailed(
                FirmwareUpdateErrorCode.serverUnreachable));

        final container =
            createContainer(banksData: banksWithOta(available: true));
        addTearDown(container.dispose);
        final notifier =
            container.read(firmwareUpdateNotifierProvider.notifier);

        await notifier.checkForUpdate();
        expect(container.read(firmwareUpdateNotifierProvider).otaCheck.verdict,
            FirmwareOtaCheckVerdict.checkFailed);

        // What the read-error card's retry, or any later banks read, does.
        await notifier.loadBanks();

        expect(container.read(firmwareUpdateNotifierProvider).otaCheck.verdict,
            FirmwareOtaCheckVerdict.updateAvailable,
            reason:
                'an offer the router is still making outlives our failed check');
      });

      test('a later successful check clears the previous reason', () async {
        // A failure that outlives the check that produced it is the same defect in a
        // slower form: the snack bar is transient, but `state.failure` is not, and the
        // install card reads it.
        when(() => mockOtaChecker.check(otaInstance: any(named: 'otaInstance')))
            .thenAnswer((_) async => const FirmwareOtaCheckResult.checkFailed(
                FirmwareUpdateErrorCode.flash));

        final container = createContainer(banksData: banksWithOta());
        addTearDown(container.dispose);
        final notifier =
            container.read(firmwareUpdateNotifierProvider.notifier);

        await notifier.checkForUpdate();
        expect(
            container.read(firmwareUpdateNotifierProvider).failure, isNotNull);

        when(() => mockOtaChecker.check(otaInstance: any(named: 'otaInstance')))
            .thenAnswer(
                (_) async => const FirmwareOtaCheckResult.noUpdateFound());
        await notifier.checkForUpdate();

        expect(container.read(firmwareUpdateNotifierProvider).failure, isNull,
            reason:
                'the second check answered, so the first reason is history');
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
        expect(state.failure, isNull,
            reason: 'a router built without the fwup stack has not failed');
      });

      test('is refused while an update is in flight', () async {
        // Two things go wrong if it is not, and the second is the serious one.
        // `checkingOta` is a phase with no install card, so a check started
        // mid-flash takes the "do not power off the router" card off the screen.
        // And `Download()` at a router writing NAND is a second firmware operation
        // dispatched at a busy one.
        //
        // The OTA page's own Check button is dead in these phases, but the refusal
        // belongs here as well: this is the layer that owns the phase, so it holds
        // for the dashboard banner, the mascot, and whatever calls it next.
        when(() => mockOtaInstaller.install(
                  otaInstance: any(named: 'otaInstance'),
                  onProgress: any(named: 'onProgress'),
                  isCancelled: any(named: 'isCancelled'),
                ))
            .thenAnswer((_) async => const FirmwareOtaInstallResult(
                verdict: FirmwareOtaInstallVerdict.flashing, rawState: '4'));
        final container = createContainer(banksData: banksWithOta());
        addTearDown(container.dispose);
        final notifier =
            container.read(firmwareUpdateNotifierProvider.notifier);
        await notifier.triggerRouterOtaInstall(otaInstance: 3);
        expect(
            container.read(firmwareUpdateNotifierProvider).isUpdating, isTrue,
            reason:
                'the fixture has to be mid-update for this to test anything');

        final result = await notifier.checkForUpdate();

        expect(result.verdict, FirmwareOtaCheckVerdict.notChecked);
        verifyNever(
            () => mockOtaChecker.check(otaInstance: any(named: 'otaInstance')));
        expect(container.read(firmwareUpdateNotifierProvider).phase,
            FirmwareUpdatePhase.installing,
            reason: 'the install card stays up — the refusal must not cost the '
                '"do not power off" copy even for a frame');
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
        expect(container.read(firmwareUpdateNotifierProvider).failure, isNull);
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

    /// #1551 (W5) — the router-side install, and what each of its five endings
    /// does to the page.
    ///
    /// The verdict is the whole point of this seam. `Download(ota,"true")` is
    /// `fwupd -m 2`, which **checks first**, so an accepted install can legitimately
    /// end in "there was nothing to install" — and the router reboots on success, so
    /// the good ending is a router that stopped answering. Nothing here may collapse
    /// those two into each other, or into a failure.
    group('triggerRouterOtaInstall', () {
      /// One `fwup_state`/`fwup_progress` reading, through the real mapping site.
      FirmwareOtaInstallProgress at(String state, [int progress = 0]) =>
          FirmwareOtaInstallProgress.from(
            UspFirmwareUpdateService.mapAutoUpdateStatus(
              FirmwareUpdateTestData.autoUpdate(
                fwupState: state,
                fwupProgress: '$progress',
              ),
            ),
          );

      /// Stub the install: feed [readings] to the progress sink, then end on
      /// [verdict].
      void stubInstall({
        required FirmwareOtaInstallVerdict verdict,
        List<FirmwareOtaInstallProgress> readings = const [],
        FirmwareUpdateErrorCode? errorCode,
      }) {
        when(() => mockOtaInstaller.install(
              otaInstance: any(named: 'otaInstance'),
              onProgress: any(named: 'onProgress'),
              isCancelled: any(named: 'isCancelled'),
            )).thenAnswer((invocation) async {
          final sink = invocation.namedArguments[const Symbol('onProgress')]
              as FirmwareOtaInstallProgressSink?;
          for (final reading in readings) {
            sink?.call(reading);
          }
          return FirmwareOtaInstallResult(
            verdict: verdict,
            rawState: readings.isEmpty ? '' : readings.last.rawState,
            lastProgress: readings.isEmpty ? null : readings.last,
            errorCode: errorCode,
          );
        });
      }

      test('asks the router to install, and says it is flashing', () async {
        stubInstall(
          verdict: FirmwareOtaInstallVerdict.flashing,
          readings: [at('1'), at('3', 40), at('4')],
        );
        final container = createContainer();
        addTearDown(container.dispose);

        final result = await container
            .read(firmwareUpdateNotifierProvider.notifier)
            .triggerRouterOtaInstall(otaInstance: 3);

        expect(result.verdict, FirmwareOtaInstallVerdict.flashing);
        verify(() => mockOtaInstaller.install(
              otaInstance: 3,
              onProgress: any(named: 'onProgress'),
              isCancelled: any(named: 'isCancelled'),
            )).called(1);
        // `installing`, not `rebooting`. The view drives the handover to the
        // recovery framework — the same `enterRecoveryWaiting()` the manual path
        // uses — because only the view can put the blocking dialog up around it.
        expect(container.read(firmwareUpdateNotifierProvider).phase,
            FirmwareUpdatePhase.installing);
      });

      test('publishes each reading as it arrives', () async {
        final seen = <FirmwareOtaInstallProgress?>[];
        stubInstall(
          verdict: FirmwareOtaInstallVerdict.flashing,
          readings: [at('1', 0), at('3', 12), at('3', 88)],
        );
        final container = createContainer();
        addTearDown(container.dispose);
        container.listen(
          firmwareUpdateNotifierProvider,
          (_, next) => seen.add(next.otaProgress),
          fireImmediately: false,
        );

        await container
            .read(firmwareUpdateNotifierProvider.notifier)
            .triggerRouterOtaInstall(otaInstance: 3);

        // Every reading reached the state, and the checking one carried no
        // percentage — the bar and the spinner are chosen from this.
        expect(seen.map((p) => p?.percent).toList(),
            containsAllInOrder(<int?>[null, 12, 88]));
      });

      test('a run that starts moves the phase to installing', () async {
        stubInstall(
          verdict: FirmwareOtaInstallVerdict.flashing,
          readings: [at('3', 5)],
        );
        final container = createContainer();
        addTearDown(container.dispose);
        final phases = <FirmwareUpdatePhase>[];
        container.listen(firmwareUpdateNotifierProvider,
            (_, next) => phases.add(next.phase));

        await container
            .read(firmwareUpdateNotifierProvider.notifier)
            .triggerRouterOtaInstall(otaInstance: 3);

        // `triggering` first, so the card says "preparing" for the window between
        // the dispatch and the router acting on it — the grace the service waits
        // out. Then `installing` off the first busy reading, not off a timer.
        expect(phases.first, FirmwareUpdatePhase.triggering);
        expect(phases, contains(FirmwareUpdatePhase.installing));
      });

      test('an idle ending is the router finding nothing, not a failure',
          () async {
        // Mode 2's own check disagreed with the version we offered. It is not an
        // error and it must not read as one — but it is also not silence: the card
        // says what the router concluded.
        stubInstall(
          verdict: FirmwareOtaInstallVerdict.idle,
          readings: [at('1'), at('0', 100)],
        );
        final container = createContainer();
        addTearDown(container.dispose);

        await container
            .read(firmwareUpdateNotifierProvider.notifier)
            .triggerRouterOtaInstall(otaInstance: 3);

        final state = container.read(firmwareUpdateNotifierProvider);
        expect(state.phase, FirmwareUpdatePhase.idle);
        expect(state.otaCheck.verdict, FirmwareOtaCheckVerdict.noUpdateFound);
        expect(state.failure, isNull);
        // No progress card left behind for an install that is not running.
        expect(state.otaProgress, isNull);
      });

      test('an install the router never acted on claims nothing', () async {
        // The measured firmware defect (Architecture#194): on `2.0.1.26091319` the
        // install trigger is accepted and never consumed, so `fwup_state` never
        // leaves 0 and the service's 15 s startup grace expires on an unchanged
        // value — the *other* way to reach an `idle` verdict. There is no check to
        // report the result of, and the page used to answer it with "No new firmware
        // was found" about a router that was, at that moment, still offering the
        // update the user had just pressed Update on.
        stubInstall(
          verdict: FirmwareOtaInstallVerdict.idle,
          readings: [at('0')],
        );
        final container = createContainer(
          banksData: AsyncData(FirmwareBanksData(banks: [
            FirmwareUpdateTestData.activeBank(),
            FirmwareUpdateTestData.availableBank(),
            FirmwareUpdateTestData.otaInstance(
                available: true, version: '2.0.1.26091321'),
          ])),
        );
        addTearDown(container.dispose);
        final notifier =
            container.read(firmwareUpdateNotifierProvider.notifier);
        // Through the page's own opening read, so the verdict being protected is
        // the one a real user would be looking at when they tapped.
        await notifier.loadBanks();

        await notifier.triggerRouterOtaInstall(otaInstance: 3);

        final state = container.read(firmwareUpdateNotifierProvider);
        expect(state.otaCheck.verdict, FirmwareOtaCheckVerdict.updateAvailable,
            reason: 'the offer is still true — the router did not deny it, it '
                'did not answer at all');
        expect(state.otaCheck.version, '2.0.1.26091321');
        // The page has to be usable again: idle phase, no failure card, no stale
        // progress, so the button the user pressed can be pressed again.
        expect(state.phase, FirmwareUpdatePhase.idle);
        expect(state.failure, isNull);
        expect(state.otaProgress, isNull);
      });

      test('an unrecognised state is not a check either', () async {
        // The asymmetry `namesRouterWork` is drawn for. An unknown `fwup_state` is
        // drawn as an update in progress (REQ-A7) because it cannot be ruled out
        // being a flash — and for exactly that reason it is no evidence that a check
        // ran, so the idle that follows it concludes nothing.
        stubInstall(
          verdict: FirmwareOtaInstallVerdict.idle,
          readings: [at('9'), at('0')],
        );
        final container = createContainer();
        addTearDown(container.dispose);

        await container
            .read(firmwareUpdateNotifierProvider.notifier)
            .triggerRouterOtaInstall(otaInstance: 3);

        final state = container.read(firmwareUpdateNotifierProvider);
        expect(state.otaCheck.verdict, FirmwareOtaCheckVerdict.notChecked);
        expect(state.phase, FirmwareUpdatePhase.idle);
      });

      test('a stalled ending keeps the reading it stalled on', () async {
        // Was `failed` on `fwup_state=5` until 2026-09-16, when 5 turned out to be
        // the reboot and the verdict was deleted. `timedOut` is now the only way
        // this watch reports a failure of its own, and it carries the same two
        // things this test is about: the phase and the raw state behind it.
        stubInstall(
          verdict: FirmwareOtaInstallVerdict.timedOut,
          readings: [at('3', 62), at('4')],
        );
        final container = createContainer();
        addTearDown(container.dispose);

        await container
            .read(firmwareUpdateNotifierProvider.notifier)
            .triggerRouterOtaInstall(otaInstance: 3);

        final state = container.read(firmwareUpdateNotifierProvider);
        expect(state.phase, FirmwareUpdatePhase.failed);
        // The raw `fwup_state` reaches the failure, and from there the sentence. It
        // is the only thing the firmware says about *why*, so it is the one part of
        // this copy that is deliberately not translated.
        expect(state.failure,
            const FirmwareFailure.progressStalled(fwupState: '4'));
        // Retained on purpose: the failure card can say where it stopped, which is
        // the difference between "the update failed" and a bug report.
        expect(state.otaProgress?.rawState, '4');
      });

      test('a router-named failure becomes that reason, not a stall (#1572)',
          () async {
        // The verdict that came back. Before the error code this watch had nothing to
        // report a failure *from* — a flash that failed rested at `state=0` exactly
        // like one that succeeded — so the user waited out the ceiling and got "the
        // router stopped reporting progress". Now they get the reason.
        stubInstall(
          verdict: FirmwareOtaInstallVerdict.failed,
          readings: [at('4', 50)],
          errorCode: FirmwareUpdateErrorCode.signature,
        );
        final container = createContainer();
        addTearDown(container.dispose);

        await container
            .read(firmwareUpdateNotifierProvider.notifier)
            .triggerRouterOtaInstall(otaInstance: 3);

        final state = container.read(firmwareUpdateNotifierProvider);
        expect(state.phase, FirmwareUpdatePhase.failed);
        expect(
            state.failure,
            const FirmwareFailure.routerReported(
                FirmwareUpdateErrorCode.signature));
        // The reading it stopped on is kept for the same reason a stall keeps one:
        // "where did it get to" is the difference between a complaint and a report.
        expect(state.otaProgress?.rawState, '4');
      });

      test('a timeout is a failure, and never "up to date"', () async {
        stubInstall(
          verdict: FirmwareOtaInstallVerdict.timedOut,
          readings: [at('1')],
        );
        final container = createContainer();
        addTearDown(container.dispose);

        await container
            .read(firmwareUpdateNotifierProvider.notifier)
            .triggerRouterOtaInstall(otaInstance: 3);

        final state = container.read(firmwareUpdateNotifierProvider);
        expect(state.phase, FirmwareUpdatePhase.failed);
        // The substitution this whole work package exists to avoid: a router that
        // stopped reporting is not a router with nothing to report.
        expect(state.otaCheck.verdict,
            isNot(FirmwareOtaCheckVerdict.noUpdateFound));
        expect(state.failure,
            const FirmwareFailure.progressStalled(fwupState: '1'));
      });

      test('a timeout with no reading at all names no reading', () async {
        // The other stall, and the reason it is a second reason rather than a
        // sentinel. Passing a stand-in token here — the first version used the
        // literal `unread` — puts an English word inside the twenty-five
        // translated sentences, through the very placeholder that exists so the
        // sentence *around* `fwup_state` can be translated.
        stubInstall(
          verdict: FirmwareOtaInstallVerdict.timedOut,
          readings: const [],
        );
        final container = createContainer();
        addTearDown(container.dispose);

        await container
            .read(firmwareUpdateNotifierProvider.notifier)
            .triggerRouterOtaInstall(otaInstance: 3);

        final state = container.read(firmwareUpdateNotifierProvider);
        expect(state.phase, FirmwareUpdatePhase.failed);
        expect(state.failure, const FirmwareFailure.progressStalledNoReading());
        expect(state.failure?.detail, isNull,
            reason: 'nothing was read, so there is no token to carry — and a '
                'token invented here would be untranslated in 25 locales');
      });

      test('an abandoned watch leaves the state alone', () async {
        stubInstall(verdict: FirmwareOtaInstallVerdict.abandoned);
        final container = createContainer();
        addTearDown(container.dispose);

        await container
            .read(firmwareUpdateNotifierProvider.notifier)
            .triggerRouterOtaInstall(otaInstance: 3);

        // The user cancelled, or the page went away. `cancel()` has already
        // replaced the whole state, so writing a verdict over it here would put a
        // failure card back on a page the user just left.
        expect(container.read(firmwareUpdateNotifierProvider).failure, isNull);
      });

      test('a service error fails the phase and is rethrown', () async {
        when(() => mockOtaInstaller.install(
              otaInstance: any(named: 'otaInstance'),
              onProgress: any(named: 'onProgress'),
              isCancelled: any(named: 'isCancelled'),
            )).thenThrow(const NetworkError(detail: 'bridge busy'));
        final container = createContainer();
        addTearDown(container.dispose);

        await expectLater(
          container
              .read(firmwareUpdateNotifierProvider.notifier)
              .triggerRouterOtaInstall(otaInstance: 3),
          throwsA(isA<NetworkError>()),
        );

        final state = container.read(firmwareUpdateNotifierProvider);
        expect(state.phase, FirmwareUpdatePhase.failed);
        // The transport failure travels as a `ServiceError`, so its copy stays with
        // `localizeServiceError` — this layer only has to carry it, not word it.
        expect(state.failure?.reason, FirmwareFailureReason.serviceError);
        expect(state.failure?.error, isA<NetworkError>());
      });

      test('an unforeseen throw does not leave the page mid-update', () async {
        // The belt `checkForUpdate` already has, and the consequence here is worse
        // than a button that spins. `triggering` is `isUpdating`, and
        // `_firmwareExitGuard` in `route_usp_dashboard.dart` returns
        // `!state.isUpdating` — a phase left set silently vetoes the back arrow and
        // the browser Back button for the rest of the session, with no card on
        // screen saying why.
        //
        // A `TimeoutException` rather than a contrived one: `UspMutationLock`
        // throws exactly this after 30 s, deliberately not as a `ServiceError`, and
        // the install dispatch runs under that lock.
        when(() => mockOtaInstaller.install(
                  otaInstance: any(named: 'otaInstance'),
                  onProgress: any(named: 'onProgress'),
                  isCancelled: any(named: 'isCancelled'),
                ))
            .thenThrow(
                TimeoutException('mutation lock', const Duration(seconds: 30)));
        final container = createContainer();
        addTearDown(container.dispose);

        await expectLater(
          container
              .read(firmwareUpdateNotifierProvider.notifier)
              .triggerRouterOtaInstall(otaInstance: 3),
          throwsA(isA<TimeoutException>()),
        );

        final state = container.read(firmwareUpdateNotifierProvider);
        expect(state.phase, FirmwareUpdatePhase.idle);
        expect(state.isUpdating, isFalse,
            reason:
                'the exit guard reads this, and a user who cannot leave the '
                'page has no way to find out why');
      });

      test('a failure after the page is gone does not throw', () async {
        // A twenty-minute poll loop outlives the page that started it by design —
        // `isCancelled` stops it at the *next* read, so the read already in flight
        // still lands. When it lands as a failure, `_fail` writes to a disposed
        // notifier, and `state =` on one throws `StateError`: the real error is
        // replaced by a bookkeeping one on its way out.
        final gate = Completer<FirmwareOtaInstallResult>();
        when(() => mockOtaInstaller.install(
              otaInstance: any(named: 'otaInstance'),
              onProgress: any(named: 'onProgress'),
              isCancelled: any(named: 'isCancelled'),
            )).thenAnswer((_) => gate.future);
        final container = createContainer();

        final pending = container
            .read(firmwareUpdateNotifierProvider.notifier)
            .triggerRouterOtaInstall(otaInstance: 3);
        container.dispose();
        gate.completeError(const NetworkError(detail: 'lost the router'));

        await expectLater(pending, throwsA(isA<NetworkError>()));
      });

      test('a mutation timeout reaches the failure card', () async {
        // The consumer end of the mapping the install service does. The lock throws
        // a bare `TimeoutException`, which is not a `ServiceError` and so matched no
        // `catch` between it and the button: the dispatch appeared to do nothing for
        // 30 s, left no card, and escaped an unawaited `onTap`. Mapped in the
        // service — where Article XIII §13.3 puts it — this arm now runs, and what
        // it has to produce is a phase the user can leave: `triggering` is
        // `isUpdating`, which `_firmwareExitGuard` silently vetoes the back arrow on.
        when(() => mockOtaInstaller.install(
                  otaInstance: any(named: 'otaInstance'),
                  onProgress: any(named: 'onProgress'),
                  isCancelled: any(named: 'isCancelled'),
                ))
            .thenThrow(const TimeoutError(
                detail: 'another router mutation was still running'));
        final container = createContainer();
        addTearDown(container.dispose);

        await expectLater(
          container
              .read(firmwareUpdateNotifierProvider.notifier)
              .triggerRouterOtaInstall(otaInstance: 3),
          throwsA(isA<TimeoutError>()),
        );

        final state = container.read(firmwareUpdateNotifierProvider);
        expect(state.phase, FirmwareUpdatePhase.failed);
        expect(state.failure, isNotNull);
        expect(state.isUpdating, isFalse,
            reason:
                'a dispatch that never happened must not hold the exit guard');
      });

      test('the Try Again on a failed install can start another one', () async {
        // `cancel()` is what `firmware-retry` calls, and it sets `_cancelRequested`
        // — the flag the poll loop terminates on. Nothing clears it except the two
        // entry points, so without the reset in this one the loop of every
        // subsequent install would abandon itself on its first poll: "Try Again"
        // would leave the page at idle, forever, with no error to explain it.
        var attempt = 0;
        final cancelledAt = <bool>[];
        when(() => mockOtaInstaller.install(
              otaInstance: any(named: 'otaInstance'),
              onProgress: any(named: 'onProgress'),
              isCancelled: any(named: 'isCancelled'),
            )).thenAnswer((invocation) async {
          attempt++;
          final isCancelled = invocation
              .namedArguments[const Symbol('isCancelled')] as bool Function()?;
          cancelledAt.add(isCancelled?.call() ?? false);
          return FirmwareOtaInstallResult(
            verdict: attempt == 1
                ? FirmwareOtaInstallVerdict.timedOut
                : FirmwareOtaInstallVerdict.flashing,
            rawState: attempt == 1 ? '3' : '4',
          );
        });
        final container = createContainer();
        addTearDown(container.dispose);
        final notifier =
            container.read(firmwareUpdateNotifierProvider.notifier);

        await notifier.triggerRouterOtaInstall(otaInstance: 3);
        expect(container.read(firmwareUpdateNotifierProvider).phase,
            FirmwareUpdatePhase.failed);
        notifier.cancel();
        final second = await notifier.triggerRouterOtaInstall(otaInstance: 3);

        expect(cancelledAt, [false, false],
            reason:
                'the second attempt started with the flag the first left set');
        expect(second.verdict, FirmwareOtaInstallVerdict.flashing);
        expect(container.read(firmwareUpdateNotifierProvider).phase,
            FirmwareUpdatePhase.installing);
      });

      test('a stale failure after a cancelled watch is not attributed',
          () async {
        // The other half of the same reset. `cancel()` clears the sighting as well as
        // the state that described it — left set, the next watch would inherit the
        // previous one's "I saw it running" and be entitled to report a stall it
        // only ever read as history.
        //
        // The observed reading is `7`, not `5`: since 5 became the reboot it *is* an
        // update phase and would set the sighting on its own, which would test the
        // reading rather than the reset. An unrecognised value sets nothing, so what
        // is left is the flag — exactly what this test is for.
        when(() => mockOtaInstaller.install(
              otaInstance: any(named: 'otaInstance'),
              onProgress: any(named: 'onProgress'),
              isCancelled: any(named: 'isCancelled'),
            )).thenAnswer((invocation) async {
          (invocation.namedArguments[const Symbol('onProgress')]
                  as FirmwareOtaInstallProgressSink?)
              ?.call(at('4'));
          return const FirmwareOtaInstallResult(
              verdict: FirmwareOtaInstallVerdict.flashing, rawState: '4');
        });
        when(() => mockOtaInstaller.observe(
              onProgress: any(named: 'onProgress'),
              isCancelled: any(named: 'isCancelled'),
            )).thenAnswer((invocation) async {
          (invocation.namedArguments[const Symbol('onProgress')]
                  as FirmwareOtaInstallProgressSink?)
              ?.call(at('7'));
          return const FirmwareOtaInstallResult(
              verdict: FirmwareOtaInstallVerdict.timedOut, rawState: '7');
        });
        final container = createContainer();
        addTearDown(container.dispose);
        final notifier =
            container.read(firmwareUpdateNotifierProvider.notifier);

        await notifier.triggerRouterOtaInstall(otaInstance: 3);
        notifier.cancel();
        await notifier.observeRunningOtaInstall();

        final state = container.read(firmwareUpdateNotifierProvider);
        expect(state.phase, FirmwareUpdatePhase.idle);
        expect(state.failure, isNull);
      });

      test('stops polling once the notifier is disposed', () async {
        // The termination condition, from the page's side. An autoDispose notifier
        // outlives nothing, but its poll loop would: twenty minutes of reads
        // against a router nobody is watching, and a `state =` on a disposed
        // notifier the first time one lands.
        bool Function()? cancelled;
        when(() => mockOtaInstaller.install(
              otaInstance: any(named: 'otaInstance'),
              onProgress: any(named: 'onProgress'),
              isCancelled: any(named: 'isCancelled'),
            )).thenAnswer((invocation) async {
          cancelled = invocation.namedArguments[const Symbol('isCancelled')]
              as bool Function()?;
          return const FirmwareOtaInstallResult(
              verdict: FirmwareOtaInstallVerdict.flashing);
        });
        final container = createContainer();

        await container
            .read(firmwareUpdateNotifierProvider.notifier)
            .triggerRouterOtaInstall(otaInstance: 3);

        expect(cancelled, isNotNull);
        expect(cancelled!(), isFalse);
        container.dispose();
        expect(cancelled!(), isTrue);
      });
    });

    /// #1551 REQ-A6 — an update this app did not start.
    ///
    /// Auto-update can begin a flash on its own, so the page can be opened in the
    /// middle of one. What must not happen is a second install being dispatched to
    /// find out.
    group('observeRunningOtaInstall', () {
      void stubObserve({
        required FirmwareOtaInstallVerdict verdict,
        List<FirmwareOtaInstallProgress> readings = const [],
        FirmwareUpdateErrorCode? errorCode,
      }) {
        when(() => mockOtaInstaller.observe(
              onProgress: any(named: 'onProgress'),
              isCancelled: any(named: 'isCancelled'),
            )).thenAnswer((invocation) async {
          final sink = invocation.namedArguments[const Symbol('onProgress')]
              as FirmwareOtaInstallProgressSink?;
          for (final reading in readings) {
            sink?.call(reading);
          }
          return FirmwareOtaInstallResult(
            verdict: verdict,
            rawState: readings.isEmpty ? '' : readings.last.rawState,
            lastProgress: readings.isEmpty ? null : readings.last,
            errorCode: errorCode,
          );
        });
      }

      FirmwareOtaInstallProgress at(String state, [int progress = 0]) =>
          FirmwareOtaInstallProgress.from(
            UspFirmwareUpdateService.mapAutoUpdateStatus(
              FirmwareUpdateTestData.autoUpdate(
                fwupState: state,
                fwupProgress: '$progress',
              ),
            ),
          );

      test('a failure is discarded when nothing was seen running (#1572)',
          () async {
        // The second gate, on the weaker evidence. The service will not attribute a
        // code it cannot own, but on the observe path there is no baseline at all — so
        // the notifier also refuses to report a failure for an update it never saw,
        // because a code from last week on a page where nothing was attempted is how
        // a healthy router gets reported as broken.
        stubObserve(
          verdict: FirmwareOtaInstallVerdict.failed,
          readings: const [],
          errorCode: FirmwareUpdateErrorCode.flash,
        );
        final container = createContainer();
        addTearDown(container.dispose);

        await container
            .read(firmwareUpdateNotifierProvider.notifier)
            .observeRunningOtaInstall();

        final state = container.read(firmwareUpdateNotifierProvider);
        expect(state.failure, isNull);
        expect(state.phase, FirmwareUpdatePhase.idle);
      });

      test('a failure is reported when the update was seen running (#1572)',
          () async {
        stubObserve(
          verdict: FirmwareOtaInstallVerdict.failed,
          readings: [at('4', 20)],
          errorCode: FirmwareUpdateErrorCode.flash,
        );
        final container = createContainer();
        addTearDown(container.dispose);

        await container
            .read(firmwareUpdateNotifierProvider.notifier)
            .observeRunningOtaInstall();

        final state = container.read(firmwareUpdateNotifierProvider);
        expect(
            state.failure,
            const FirmwareFailure.routerReported(
                FirmwareUpdateErrorCode.flash));
        expect(state.phase, FirmwareUpdatePhase.failed);
      });

      test('watches without dispatching anything', () async {
        stubObserve(
          verdict: FirmwareOtaInstallVerdict.flashing,
          readings: [at('3', 30)],
        );
        final container = createContainer();
        addTearDown(container.dispose);

        await container
            .read(firmwareUpdateNotifierProvider.notifier)
            .observeRunningOtaInstall();

        verifyNever(() => mockOtaInstaller.install(
              otaInstance: any(named: 'otaInstance'),
              onProgress: any(named: 'onProgress'),
              isCancelled: any(named: 'isCancelled'),
            ));
        final state = container.read(firmwareUpdateNotifierProvider);
        expect(state.phase, FirmwareUpdatePhase.installing);
        expect(state.otaProgress?.percent, 30);
      });

      test('a router that turns out to be idle claims nothing', () async {
        // The ordinary case: the page opened, nothing was running. This path never
        // asked the router anything, so it must not leave a check verdict behind —
        // "no new firmware was found" off a read of `fwup_state` would be an answer
        // to a question nobody asked.
        stubObserve(
          verdict: FirmwareOtaInstallVerdict.idle,
          readings: [at('0', 100)],
        );
        final container = createContainer();
        addTearDown(container.dispose);

        await container
            .read(firmwareUpdateNotifierProvider.notifier)
            .observeRunningOtaInstall();

        final state = container.read(firmwareUpdateNotifierProvider);
        expect(state.phase, FirmwareUpdatePhase.idle);
        expect(state.otaCheck.verdict, FirmwareOtaCheckVerdict.notChecked);
        expect(state.otaProgress, isNull);
      });

      test('a second watch does not start while one is running', () async {
        // Two callers reach this method: the page opening, and the read-failure
        // card's retry. A router that is slow to answer therefore gets a fresh
        // twenty-minute poll loop per tap — all of them publishing into one
        // `otaProgress`, and each one resetting the `_cancelRequested` flag the
        // others terminate on, so a `cancel()` in between is undone rather than
        // obeyed and the extra loops keep reading against a rebooting router.
        final release = Completer<void>();
        var started = 0;
        when(() => mockOtaInstaller.observe(
              onProgress: any(named: 'onProgress'),
              isCancelled: any(named: 'isCancelled'),
            )).thenAnswer((_) async {
          started++;
          await release.future;
          return const FirmwareOtaInstallResult(
              verdict: FirmwareOtaInstallVerdict.idle, rawState: '0');
        });
        final container = createContainer();
        addTearDown(container.dispose);
        final notifier =
            container.read(firmwareUpdateNotifierProvider.notifier);

        final first = notifier.observeRunningOtaInstall();
        await pumpEventQueue();
        final second = await notifier.observeRunningOtaInstall();

        expect(started, 1);
        // `abandoned` because that is already the verdict meaning "this call is not
        // the one that will answer", and the outcome switch writes nothing for it.
        expect(second.verdict, FirmwareOtaInstallVerdict.abandoned);
        release.complete();
        await first;
        // And the door is unlocked again once the watch that held it has finished,
        // so the retry after a real read failure still works.
        expect((await notifier.observeRunningOtaInstall()).verdict,
            FirmwareOtaInstallVerdict.idle);
        expect(started, 2);
      });

      test('an install dispatched from this page outranks the observe watch',
          () async {
        // Both reads the OTA page opens with run concurrently, and the observe loop
        // keeps polling for its whole window — so it is still sampling the router
        // when the user taps Update Now, and it is one reading behind. Unowned, it
        // needs only to read idle for a moment to reset the phase, clear the
        // download percentage and re-offer "Update Now" on top of a router that is
        // writing NAND.
        //
        // Both halves are asserted, because the fix has two sites: the readings it
        // publishes and the verdict it applies.
        final release = Completer<void>();
        when(() => mockOtaInstaller.install(
              otaInstance: any(named: 'otaInstance'),
              onProgress: any(named: 'onProgress'),
              isCancelled: any(named: 'isCancelled'),
            )).thenAnswer((invocation) async {
          (invocation.namedArguments[const Symbol('onProgress')]
                  as FirmwareOtaInstallProgressSink?)
              ?.call(at('3', 40));
          await release.future;
          return const FirmwareOtaInstallResult(
              verdict: FirmwareOtaInstallVerdict.flashing, rawState: '4');
        });
        stubObserve(
          verdict: FirmwareOtaInstallVerdict.idle,
          readings: [at('0', 100)],
        );
        final container = createContainer();
        addTearDown(container.dispose);
        final notifier =
            container.read(firmwareUpdateNotifierProvider.notifier);

        final install = notifier.triggerRouterOtaInstall(otaInstance: 3);
        await pumpEventQueue();
        await notifier.observeRunningOtaInstall();

        final midFlash = container.read(firmwareUpdateNotifierProvider);
        expect(midFlash.phase, FirmwareUpdatePhase.installing);
        expect(midFlash.otaProgress?.percent, 40,
            reason:
                'the observe reading must not blank the download percentage '
                'the user is watching');
        expect(midFlash.otaCheck.verdict,
            isNot(FirmwareOtaCheckVerdict.noUpdateFound));

        release.complete();
        await install;
      });

      test('a read failure is a read error, not a failed update', () async {
        when(() => mockOtaInstaller.observe(
              onProgress: any(named: 'onProgress'),
              isCancelled: any(named: 'isCancelled'),
            )).thenThrow(const NetworkError(detail: 'bridge busy'));
        final container = createContainer();
        addTearDown(container.dispose);

        await expectLater(
          container
              .read(firmwareUpdateNotifierProvider.notifier)
              .observeRunningOtaInstall(),
          throwsA(isA<NetworkError>()),
        );

        final state = container.read(firmwareUpdateNotifierProvider);
        expect(state.stateReadError, isNotNull);
        expect(state.phase, FirmwareUpdatePhase.idle);
        expect(state.failure, isNull);
      });

      test('a read failure that is not a ServiceError is still a read error',
          () async {
        // Same argument as `loadBanks`': the two reads share one field and one
        // card, and a `TimeoutException` out of the mutation lock leaves the page
        // exactly as unreadable as a `NetworkError` does.
        when(() => mockOtaInstaller.observe(
                  onProgress: any(named: 'onProgress'),
                  isCancelled: any(named: 'isCancelled'),
                ))
            .thenThrow(
                TimeoutException('mutation lock', const Duration(seconds: 30)));
        final container = createContainer();
        addTearDown(container.dispose);

        await expectLater(
          container
              .read(firmwareUpdateNotifierProvider.notifier)
              .observeRunningOtaInstall(),
          throwsA(isA<TimeoutException>()),
        );

        final state = container.read(firmwareUpdateNotifierProvider);
        expect(state.stateReadError, isNotNull);
        expect(state.failure, isNull);
      });

      /// Opening a page is not starting an update, and the state this page reads is
      /// **not** scoped to the current one.
      ///
      /// `fwup_state` is a sysevent scalar that persists: 5 stays 5 until the next
      /// update moves it, and `linksys.fwup.lastsuccess_checktime` — the anchor that
      /// would say *when* — exists in the sysevent store and is not exposed in the
      /// data model (contract request 6 on #1547). So a reading of 5 on page open
      /// says "an update failed at some point", possibly weeks ago, possibly the one
      /// that installed the firmware now running fine.
      ///
      /// Which means the observe path cannot use the install path's conclusions.
      /// `state.phase == installing` is the discriminator, and it is sound because
      /// the ordering makes it so: `_publishOtaProgress` runs on every reading
      /// *before* the outcome is applied, and only a reading of a running update
      /// promotes the phase. Watched running then failed ⇒ a failure worth showing;
      /// failed on the very first reading ⇒ history.
      group('a state left over from an update nobody watched', () {
        test('a stale outcome is not an update that just failed', () async {
          // `7` rather than the `5` this used to open on: 5 is the reboot now, so a
          // page that opens on it is opening on a router that really is restarting.
          // What is still stale is an unrecognised value the watch then gives up on.
          stubObserve(
            verdict: FirmwareOtaInstallVerdict.timedOut,
            readings: [at('7')],
          );
          final container = createContainer();
          addTearDown(container.dispose);

          await container
              .read(firmwareUpdateNotifierProvider.notifier)
              .observeRunningOtaInstall();

          final state = container.read(firmwareUpdateNotifierProvider);
          expect(state.phase, FirmwareUpdatePhase.idle,
              reason: 'nothing was attempted from here, so there is nothing to '
                  'report as failed');
          expect(state.failure, isNull,
              reason: '"Update failed" over a page the user just opened is the '
                  'sentence that makes someone power-cycle a healthy router');
          expect(state.otaProgress, isNull,
              reason:
                  'the reading is history — there is no card to draw it on');
        });

        test('a failure while we were watching is still a failure', () async {
          // The other side of the discriminator, and the reason it cannot simply be
          // `!dispatched`: auto-update starts flashes on its own, so an update the
          // page merely *found* running is exactly the one a user needs told about
          // when it fails.
          stubObserve(
            verdict: FirmwareOtaInstallVerdict.timedOut,
            readings: [at('4'), at('4')],
          );
          final container = createContainer();
          addTearDown(container.dispose);

          await container
              .read(firmwareUpdateNotifierProvider.notifier)
              .observeRunningOtaInstall();

          final state = container.read(firmwareUpdateNotifierProvider);
          expect(state.phase, FirmwareUpdatePhase.failed);
          // The raw `fwup_state` reaches the failure, and from there the sentence. It
          // is the only thing the firmware says about *where* it stopped, so it is
          // the one part of this copy that is deliberately not translated.
          expect(state.failure,
              const FirmwareFailure.progressStalled(fwupState: '4'));
        });

        test('one unrecognised reading is not enough to blame for a failure',
            () async {
          // The seam between two requirements that pull opposite ways. REQ-A7 says
          // an unrecognised `fwup_state` keeps the progress card up, because a value
          // that cannot be ruled out being a flash must not read as "nothing is
          // happening" — so `unknown` promotes the phase. But it is also the weakest
          // possible evidence that an update was ever running, so it must not
          // license the *next* verdict: a watch whose only sighting was one
          // unrecognised value cannot go on to report "the firmware update failed"
          // for an update it never identified.
          //
          // Keying the discriminator on `phase == installing` conflated the two —
          // `unknown` had promoted the phase, so the phase then said the failure was
          // ours. `namesAnUpdatePhase` splits what is drawn from what is claimed.
          stubObserve(
            verdict: FirmwareOtaInstallVerdict.timedOut,
            readings: [at('7'), at('7')],
          );
          final container = createContainer();
          addTearDown(container.dispose);

          await container
              .read(firmwareUpdateNotifierProvider.notifier)
              .observeRunningOtaInstall();

          final state = container.read(firmwareUpdateNotifierProvider);
          expect(state.failure, isNull);
          // And the phase goes back, which is the half that is not tidiness: the
          // `unknown` reading promoted it to `installing`, `installing` is
          // `isUpdating`, and `_firmwareExitGuard` vetoes the Navigator pop
          // *silently*. Left promoted, the user sits on a page with no card, no
          // error, and a back arrow that does nothing at all.
          expect(state.phase, FirmwareUpdatePhase.idle);
          expect(state.isUpdating, isFalse);
          expect(state.otaProgress, isNull);
        });

        test('an unrecognised reading that stalls does not trap the page',
            () async {
          // The same hole reached through the other verdict. Twenty minutes of
          // unrecognised readings is a firmware this build does not understand, not
          // an update whose progress stopped — and the cost of getting it wrong is
          // the same silently-vetoed back arrow.
          stubObserve(
            verdict: FirmwareOtaInstallVerdict.timedOut,
            readings: [at('7')],
          );
          final container = createContainer();
          addTearDown(container.dispose);

          await container
              .read(firmwareUpdateNotifierProvider.notifier)
              .observeRunningOtaInstall();

          final state = container.read(firmwareUpdateNotifierProvider);
          expect(state.phase, FirmwareUpdatePhase.idle);
          expect(state.isUpdating, isFalse);
          expect(state.failure, isNull);
        });

        test('a ceiling reached without ever seeing it run reports nothing',
            () async {
          // `timedOut` on this path means twenty minutes of readings that were
          // never busy. Nothing was dispatched and nothing was seen running, so
          // there is no update whose progress could have stopped.
          stubObserve(
            verdict: FirmwareOtaInstallVerdict.timedOut,
            readings: [at('1')],
          );
          final container = createContainer();
          addTearDown(container.dispose);

          await container
              .read(firmwareUpdateNotifierProvider.notifier)
              .observeRunningOtaInstall();

          final state = container.read(firmwareUpdateNotifierProvider);
          expect(state.phase, FirmwareUpdatePhase.idle);
          expect(state.failure, isNull);
        });
      });

      /// The router checking is not the router updating — on this path.
      ///
      /// `fwup_state=1` is `fwupd` deciding whether an image exists, and on an idle
      /// router it is reached by the **auto-update daemon's own scheduled check**,
      /// which runs whether or not anybody is on this page. Promoting the phase for
      /// it costs the user the back arrow: `installing` is `isUpdating`, and
      /// `_firmwareExitGuard` vetoes the Navigator pop silently — so opening the OTA
      /// page during a routine check trapped the user on it, and an unrecognised
      /// state would trap them for the twenty-minute ceiling.
      ///
      /// The install path keeps promoting on `checking`, because there the check is
      /// mode 2's own first step: something *was* started, and the card's "Checking
      /// for new firmware" is the accurate thing to say about it.
      group('what a reading is allowed to promote', () {
        test('a check the router runs on its own does not start an update',
            () async {
          final phases = <FirmwareUpdatePhase>[];
          stubObserve(
            verdict: FirmwareOtaInstallVerdict.idle,
            readings: [at('1'), at('0')],
          );
          final container = createContainer();
          addTearDown(container.dispose);
          container.listen(firmwareUpdateNotifierProvider,
              (_, next) => phases.add(next.phase));

          await container
              .read(firmwareUpdateNotifierProvider.notifier)
              .observeRunningOtaInstall();

          expect(phases, isNot(contains(FirmwareUpdatePhase.installing)),
              reason:
                  'no frame may claim an update is running, however brief — '
                  'the exit guard reads the phase, not how long it lasted');
          expect(container.read(firmwareUpdateNotifierProvider).isUpdating,
              isFalse);
        });

        test('a state this build does not recognise does promote', () async {
          // REQ-A7, and the deliberate asymmetry with `checking` above. An
          // unrecognised state cannot be ruled out being a flash, and offering
          // "Update Now" to a router that is already writing NAND is the worse of
          // the two mistakes. The ceiling bounds how long it can be wrong.
          stubObserve(
            verdict: FirmwareOtaInstallVerdict.flashing,
            readings: [at('7')],
          );
          final container = createContainer();
          addTearDown(container.dispose);

          await container
              .read(firmwareUpdateNotifierProvider.notifier)
              .observeRunningOtaInstall();

          expect(container.read(firmwareUpdateNotifierProvider).phase,
              FirmwareUpdatePhase.installing);
        });

        test('the install path still promotes on its own check', () async {
          // The install path's dispatch *is* what started the check, so "Checking
          // for new firmware" is the accurate card — and it is the only wording
          // that keeps a spinner on screen for the 1–2 s before the download.
          final phases = <FirmwareUpdatePhase>[];
          when(() => mockOtaInstaller.install(
                otaInstance: any(named: 'otaInstance'),
                onProgress: any(named: 'onProgress'),
                isCancelled: any(named: 'isCancelled'),
              )).thenAnswer((invocation) async {
            (invocation.namedArguments[const Symbol('onProgress')]
                    as FirmwareOtaInstallProgressSink?)
                ?.call(at('1'));
            return const FirmwareOtaInstallResult(
                verdict: FirmwareOtaInstallVerdict.flashing, rawState: '1');
          });
          final container = createContainer();
          addTearDown(container.dispose);
          container.listen(firmwareUpdateNotifierProvider,
              (_, next) => phases.add(next.phase));

          await container
              .read(firmwareUpdateNotifierProvider.notifier)
              .triggerRouterOtaInstall(otaInstance: 3);

          expect(phases, contains(FirmwareUpdatePhase.installing));
        });
      });
    });

    // #1496 phase 6, acceptance 6. This class holds the pair that made phase 6
    // necessary: `runUpload` and `triggerRouterOtaInstall` both mean "update the
    // firmware", they are a screen apart, and one of them cannot work in Remote
    // Assistance at all. (The pair was `runUpload` and the cloud-URL
    // `triggerOtaInstall` when phase 6 was written; that half was replaced by the
    // router-side install and then deleted with the cloud path.)
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

      test('the router OTA install is not refused', () async {
        // #1551's addition to the pair, and the same argument: the router fetches
        // the image over its own uplink, so nothing a support agent depends on is
        // destroyed by it. `transientRestart`, allowed on every surface — and this
        // is the seam that made the classification worth re-stating, because it is
        // the one that reboots the router *and* the one that works remotely.
        when(() => mockOtaInstaller.install(
                  otaInstance: any(named: 'otaInstance'),
                  onProgress: any(named: 'onProgress'),
                  isCancelled: any(named: 'isCancelled'),
                ))
            .thenAnswer((_) async => const FirmwareOtaInstallResult(
                verdict: FirmwareOtaInstallVerdict.flashing));
        final container = remoteContainer();
        addTearDown(container.dispose);

        await container
            .read(firmwareUpdateNotifierProvider.notifier)
            .triggerRouterOtaInstall(otaInstance: 3);

        verify(() => mockOtaInstaller.install(
              otaInstance: 3,
              onProgress: any(named: 'onProgress'),
              isCancelled: any(named: 'isCancelled'),
            )).called(1);
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
