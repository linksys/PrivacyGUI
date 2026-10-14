import 'dart:async';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/internet_settings/models/auto_ipoe_models.dart';
import 'package:privacy_gui/page/internet_settings/models/auto_ipoe_snapshot.dart';
import 'package:privacy_gui/page/internet_settings/providers/auto_ipoe_data_provider.dart';
import 'package:privacy_gui/page/internet_settings/providers/auto_ipoe_page_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/framework/preservable_notifier_mixin.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_feature_state.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_settings.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_status.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_wan_connection_type.dart';
import 'package:privacy_gui/page/internet_settings/providers/wan_data_provider.dart';
import 'package:privacy_gui/page/internet_settings/services/usp_internet_settings_service.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Main provider for the USP Internet Settings page.
final uspInternetSettingsProvider = AutoDisposeNotifierProvider<
    UspInternetSettingsNotifier, InternetSettingsFeatureState>(
  UspInternetSettingsNotifier.new,
);

/// Service provider — stateless, created from the current UspClient.
final uspInternetSettingsServiceProvider =
    Provider.autoDispose<UspInternetSettingsService>((ref) {
  final usp = ref.watch(uspClientProvider);
  if (usp == null) {
    throw const ServiceNotInitializedError(detail: 'USP service not available');
  }
  return UspInternetSettingsService(usp);
});

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class UspInternetSettingsNotifier
    extends AutoDisposeNotifier<InternetSettingsFeatureState>
    with
        PreservableAutoDisposeNotifierMixin<InternetSettingsSettings,
            InternetSettingsStatus, InternetSettingsFeatureState> {
  /// One-shot guard for a device-timing race (#759): immediately after a save
  /// that did NOT change the connection type, the device can transiently report
  /// an empty `addressingType`. Under the AddressingType-only detection rule
  /// (see [UspWanConnectionType.fromRawFields]) that empty value would read as
  /// Bridge. This guard is set in [performSave] when the type was unchanged and
  /// consumed by the next [performFetch] to preserve the known type.
  ///
  /// This is independent of detection correctness and must NOT be removed:
  /// detection keys on a real device value, while this protects against a
  /// transient one during the save→refetch window.
  UspWanConnectionType? _preservedConnectionType;
  bool _disposed = false;
  bool _connectionTypeEdited = false;
  bool _savingIPoE = false;
  ServiceError? _operationReadError;
  Completer<void>? _completion;
  AutoIPoESubmission? _waitingFor;

  static bool isManagedIPoE(AutoIPoESnapshot? snapshot) =>
      snapshot?.settings.isEnabled == true ||
      snapshot?.runtime.isEnabled == true ||
      snapshot?.runtime.needsResetBeforeLeaving == true ||
      snapshot?.runtime.blockIPv6ManualConfiguration == true;

  bool get needsIPoEReset {
    final snapshot = ref.read(autoIPoEDataProvider).valueOrNull;
    final submission = ref.read(autoIPoESubmissionProvider);
    if (snapshot != null &&
        submission?.reset == true &&
        snapshot.outcomeFor(submission) == AutoIPoEOutcome.succeeded &&
        !isManagedIPoE(snapshot)) {
      return false;
    }
    return state.original.connectionType == UspWanConnectionType.ipoe ||
        isManagedIPoE(snapshot);
  }

  void _syncManagedIPoE(AutoIPoESnapshot? snapshot) {
    if (state.status.isLoading || _savingIPoE || !isManagedIPoE(snapshot)) {
      return;
    }
    final original = state.settings.original.copyWith(
        form:
            state.original.copyWith(connectionType: UspWanConnectionType.ipoe));
    final current = state.isEditing && _connectionTypeEdited
        ? state.settings.current
        : state.settings.current.copyWith(
            form: state.edited
                .copyWith(connectionType: UspWanConnectionType.ipoe));
    state = state.copyWith(
        settings: Preservable(original: original, current: current));
  }

  void _observeIPoE(AsyncValue<AutoIPoESnapshot> next) {
    if (!_savingIPoE) return;
    if (next.hasError) {
      _operationReadError = next.error is ServiceError
          ? next.error as ServiceError
          : const ConnectivityError();
    }
    final completion = _completion;
    final submission = _waitingFor;
    if (completion == null || completion.isCompleted || submission == null) {
      return;
    }
    if (_operationReadError != null) {
      completion.completeError(_operationReadError!);
      return;
    }
    final snapshot = next.valueOrNull;
    if (snapshot == null) return;
    final outcome = snapshot.outcomeFor(submission);
    if (outcome == AutoIPoEOutcome.pending) return;
    if (outcome == AutoIPoEOutcome.succeeded &&
        (!submission.reset || !isManagedIPoE(snapshot))) {
      completion.complete();
    } else {
      completion.completeError(const InvalidInputError());
    }
  }

  Future<void> _submitAndVerifyIPoE(Future<void> Function() submit,
      {required bool reset}) async {
    final previous = ref.read(autoIPoESubmissionProvider);
    _operationReadError = null;
    await submit();
    if (_disposed) throw const ConnectivityError();
    final submission = ref.read(autoIPoESubmissionProvider);
    if (submission == null ||
        submission == previous ||
        submission.reset != reset ||
        ref.read(autoIPoERejectionProvider) != null) {
      throw const InvalidInputError();
    }
    if (_operationReadError != null) throw _operationReadError!;
    _waitingFor = submission;
    final completion = _completion = Completer<void>();
    _observeIPoE(ref.read(autoIPoEDataProvider));
    try {
      // Reuse the data provider's UUID-correlated status polling. This waiter
      // never submits or resumes a WAN mutation after navigation/reconnection.
      await completion.future.timeout(const Duration(minutes: 6),
          onTimeout: () => throw const TimeoutError());
    } finally {
      _waitingFor = null;
      _completion = null;
    }
  }

  @override
  InternetSettingsFeatureState build() {
    ref.onDispose(() {
      _disposed = true;
      final completion = _completion;
      if (completion != null && !completion.isCompleted) {
        completion.completeError(const ConnectivityError());
      }
    });
    // Optional backend reads never block or fail the ordinary WAN fetch.
    ref.listen(autoIPoEDataProvider, (_, next) {
      _observeIPoE(next);
      _syncManagedIPoE(next.valueOrNull);
    });
    // Synchronous build with loading state; async fetch follows immediately.
    Future.microtask(() => fetch());
    return InternetSettingsFeatureState.initial();
  }

  // ---------------------------------------------------------------------------
  // performFetch — required by PreservableAutoDisposeNotifierMixin
  // ---------------------------------------------------------------------------

  @override
  Future<(InternetSettingsSettings?, InternetSettingsStatus?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async {
    try {
      final usp = ref.read(uspClientProvider);
      if (usp == null) {
        throw const ServiceNotInitializedError(
            detail: 'USP service not available');
      }

      // No auth gate here: the router already guards all /usp routes on
      // loginType (RA-aware), and the WAN service surfaces real errors. The raw
      // usp.isAuthenticated flag is a WASM transport signal that stays false in
      // Remote Assistance (authToken bypass), so gating on it here wrongly
      // blocked RA sessions (issue #1119). The usp == null gate above (and the
      // service provider itself) still cover the "USP unavailable" case.
      final service = ref.read(uspInternetSettingsServiceProvider);
      final result = await service.fetchSettings();

      logger.d('[USP][Network][WAN]: Fetched — '
          'raw addressingType: "${result.debugAddressingType}", '
          'bridgeEnabled: ${result.debugBridgeEnabled}, '
          'detected type: ${result.form.connectionType.name}, '
          'mtu: ${result.debugMtu}, ipv6: ${result.debugIpv6Enabled}');

      // Consume the one-shot guard: if connection type was not changed during
      // the last save but the device returned a different type (transient empty
      // addressingType), preserve the known type to avoid Bridge misdetection.
      final savedType = _preservedConnectionType;
      _preservedConnectionType = null;
      var form = result.form;
      if (savedType != null && form.connectionType != savedType) {
        logger.w('[USP][Network][WAN]: Transient type mismatch — '
            'fetched: ${form.connectionType.name}, '
            'preserving: ${savedType.name}');
        form = form.copyWith(connectionType: savedType);
      }

      if (isManagedIPoE(ref.read(autoIPoEDataProvider).valueOrNull)) {
        form = form.copyWith(connectionType: UspWanConnectionType.ipoe);
      }
      return (
        InternetSettingsSettings(form: form),
        InternetSettingsStatus(
          isLoading: false,
          readOnlyInfo: result.readOnlyInfo,
          pppInstancePath: result.pppInstancePath,
          vlanInstancePath: result.vlanInstancePath,
          mtuModeSupported: result.mtuModeSupported,
        ),
      );
    } on ServiceError catch (e) {
      logger.e('[USP][Network][WAN]: Fetch failed', error: e);
      return (
        null,
        InternetSettingsStatus(isLoading: false, error: e),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // performSave — required by PreservableAutoDisposeNotifierMixin
  // ---------------------------------------------------------------------------

  @override
  Future<void> performSave() async {
    // Guard connection type for post-save re-fetch if type was not changed.
    final original = state.original;
    final edited = state.edited;
    _preservedConnectionType = original.connectionType == edited.connectionType
        ? edited.connectionType
        : null;

    state = state.copyWith(
      status: state.status.copyWith(isSaving: true, activeMutation: 'save'),
    );

    try {
      final service = ref.read(uspInternetSettingsServiceProvider);

      await ref.read(uspMutationLockProvider).withLock(() async {
        await service.saveAll(
          state.original,
          state.edited,
          pppInstancePath: state.status.pppInstancePath,
          vlanInstancePath: state.status.vlanInstancePath,
        );
        logger.d('[USP][Network][WAN]: Save complete');

        // Invalidate L1 wanDataProvider so Dashboard card refreshes
        ref.invalidate(wanDataProvider);
      });

      // After save, exit edit mode (status will be updated by re-fetch)
      state = state.copyWith(
        status: state.status.copyWith(
          isEditing: false,
          clearActiveMutation: true,
        ),
      );
    } on ServiceError catch (e) {
      logger.e('[USP][Network][WAN]: Save failed', error: e);
      rethrow;
    } finally {
      state = state.copyWith(
        status: state.status.copyWith(
          isSaving: false,
          clearActiveMutation: true,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // save — override the mixin's default (performSave -> markAsSaved -> refetch)
  // to special-case the entering-bridge transition.
  // ---------------------------------------------------------------------------

  @override
  Future<InternetSettingsFeatureState> save(
      {bool resetConfirmed = false}) async {
    if (state.status.isSaving || _savingIPoE) throw const InvalidInputError();
    final selected = state.edited.connectionType;
    if (selected == UspWanConnectionType.ipoe || needsIPoEReset) {
      if (selected != UspWanConnectionType.ipoe && !resetConfirmed) {
        throw const InvalidInputError();
      }
      final submitted = state.edited;
      _savingIPoE = true;
      state = state.copyWith(
          status:
              state.status.copyWith(isSaving: true, activeMutation: 'save'));
      try {
        if (selected == UspWanConnectionType.ipoe) {
          await _submitAndVerifyIPoE(
              () => ref.read(autoIPoEPageProvider.notifier).performSave(),
              reset: false);
          if (_disposed || state.edited != submitted) {
            throw const InvalidInputError();
          }
          ref.read(autoIPoEPageProvider.notifier).markAsSaved();
          markAsSaved();
          state =
              state.copyWith(status: state.status.copyWith(isEditing: false));
          return state;
        }
        await _submitAndVerifyIPoE(
            () => ref.read(autoIPoEDataProvider.notifier).reset(),
            reset: true);
        if (_disposed || state.edited != submitted) {
          throw const InvalidInputError();
        }
      } finally {
        _savingIPoE = false;
        if (!_disposed) {
          state = state.copyWith(
              status: state.status
                  .copyWith(isSaving: false, clearActiveMutation: true));
        }
      }
    }
    return _saveOrdinary();
  }

  Future<InternetSettingsFeatureState> _saveOrdinary() async {
    // Detect the entering-bridge transition BEFORE saving: `original` is the
    // baseline type, `edited` is what the user just chose. markAsSaved() below
    // collapses original into current, so this must be read up front.
    final enteringBridge =
        state.original.connectionType != UspWanConnectionType.bridge &&
            state.edited.connectionType == UspWanConnectionType.bridge;

    await performSave();
    // A successful ordinary Save also discards an unapplied IPoE draft.
    if (ref.exists(autoIPoEPageProvider)) {
      ref.read(autoIPoEPageProvider.notifier).revert();
    }
    markAsSaved();

    if (enteringBridge) {
      // Entering bridge makes the router unreachable on this origin (the WAN
      // port joins br-lan and the local DHCP server is disabled). Two effects
      // are handled here, both specific to this terminal transition:
      //
      // 1. Drop SSE intentionally. disconnect() sets _intentionalDisconnect,
      //    which stops the reconnect backoff and suppresses onReconnectFailed,
      //    so the app-level recovery flow (2 reconnect failures ->
      //    waitingForRecovery) never fires on top of the bridge redirect
      //    dialog.
      // 2. Skip the post-save re-fetch. The SET already succeeded; the device
      //    is now gone from this origin, so fetch(forceRemote: true) would only
      //    time out (~15s per GET) and surface a spurious "something went
      //    wrong" error for an operation that actually succeeded. The redirect
      //    dialog is the only valid next step from here.
      await ref.read(sseManagerProvider)?.disconnect();
      return state;
    }

    return fetch(forceRemote: true);
  }

  // ---------------------------------------------------------------------------
  // Edit mode
  // ---------------------------------------------------------------------------

  void enterEditMode() {
    _connectionTypeEdited = false;
    state = state.copyWith(
      status: state.status.copyWith(isEditing: true),
    );
  }

  void exitEditMode() {
    if (_savingIPoE || state.status.isSaving) return;
    _connectionTypeEdited = false;
    if (ref.exists(autoIPoEPageProvider)) {
      ref.read(autoIPoEPageProvider.notifier).revert();
    }
    // Revert form to original + exit edit mode
    state = state.copyWith(
      settings: state.settings.copyWith(current: state.settings.original),
      status: state.status.copyWith(isEditing: false),
    );
  }

  // ---------------------------------------------------------------------------
  // revert — override to also clear isEditing
  // ---------------------------------------------------------------------------

  @override
  bool isDirty() =>
      state.isDirty ||
      _savingIPoE ||
      (ref.exists(autoIPoEPageProvider) &&
          ref.read(autoIPoEPageProvider).isDirty);

  @override
  void revert() {
    exitEditMode();
  }

  // ---------------------------------------------------------------------------
  // Form field updates
  // ---------------------------------------------------------------------------

  /// Generic field updater — takes a function that returns a modified form.
  void updateField(
      UspInternetSettingsForm Function(UspInternetSettingsForm) updater) {
    final current = state.settings.current;
    state = state.copyWith(
      settings: state.settings.update(
        current.copyWith(form: updater(current.form)),
      ),
    );
  }

  /// Update connection type with appropriate field resets.
  void updateConnectionType(UspWanConnectionType type) {
    if (_savingIPoE || state.status.isSaving) return;
    _connectionTypeEdited = true;
    if (type == UspWanConnectionType.ipoe) {
      final page = ref.read(autoIPoEPageProvider);
      ref.read(autoIPoEPageProvider.notifier).updateSettings(page.current
          .copyWith(
              isEnabled: true,
              selectedMode: page.current.selectedMode == AutoIPoEMode.disabled
                  ? AutoIPoEMode.auto
                  : page.current.selectedMode));
    }
    final current = state.settings.current;
    var form = current.form.copyWith(connectionType: type);

    // Normalize MTU for the new type (issue #1083): keep the current MTU when it
    // still fits the type's range, otherwise fall back to the type's max — this
    // clamps an over-limit value (e.g. 1500 → 1492 on PPPoE).
    //
    // Bridge and auto mode both leave MTU untouched. Bridge ignores it entirely
    // (the service skips both SETs and the view shows a fixed "Auto" row), so a
    // bridge round-trip must not flip mtuAuto and make the save write a mode the
    // user never chose. In auto mode the number is device-reported rather than
    // user-owned, so the app has no business rewriting it.
    if (type != UspWanConnectionType.bridge && !form.mtuAuto) {
      form = form.copyWith(mtu: type.clampMtu(form.mtu));
    }

    state = state.copyWith(
      settings: state.settings.update(
        current.copyWith(form: form),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DHCP Renewal (separate from form editing)
  // ---------------------------------------------------------------------------

  Future<void> renewDhcpLease() async {
    await ref.read(uspMutationLockProvider).withLock(() async {
      state = state.copyWith(
        status: state.status.copyWith(activeMutation: 'renewIpv4'),
      );
      try {
        final service = ref.read(uspInternetSettingsServiceProvider);
        logger.d('[USP][Network][WAN]: Renewing DHCPv4 lease...');
        await service.renewDhcpLease();
        // Wait for lease renewal to take effect before refreshing WAN status
        await Future.delayed(const Duration(seconds: 2));
      } on ServiceError catch (e) {
        logger.e('[USP][Network][WAN]: DHCP renew failed', error: e);
        rethrow;
      } finally {
        state = state.copyWith(
          status: state.status.copyWith(clearActiveMutation: true),
        );
      }
    });
    ref.invalidate(wanDataProvider);
  }

  Future<void> renewDhcpv6Lease() async {
    await ref.read(uspMutationLockProvider).withLock(() async {
      state = state.copyWith(
        status: state.status.copyWith(activeMutation: 'renewIpv6'),
      );
      try {
        final service = ref.read(uspInternetSettingsServiceProvider);
        logger.d('[USP][Network][WAN]: Renewing DHCPv6 lease...');
        await service.renewDhcpv6Lease();
      } on ServiceError catch (e) {
        logger.e('[USP][Network][WAN]: DHCPv6 renew failed', error: e);
        rethrow;
      } finally {
        state = state.copyWith(
          status: state.status.copyWith(clearActiveMutation: true),
        );
      }
    });
  }
}
