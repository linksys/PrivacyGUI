import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/framework/preservable_notifier_mixin.dart';
import 'package:privacy_gui/page/dmz/models/dmz_feature_state.dart';
import 'package:privacy_gui/page/dmz/models/dmz_settings.dart';
import 'package:privacy_gui/page/dmz/models/dmz_status.dart';
import 'package:privacy_gui/page/dmz/models/dmz_ui_model.dart';
import 'package:privacy_gui/page/dmz/services/usp_dmz_service.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final uspDmzProvider =
    AutoDisposeNotifierProvider<UspDmzNotifier, DmzFeatureState>(
  UspDmzNotifier.new,
);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class UspDmzNotifier extends AutoDisposeNotifier<DmzFeatureState>
    with
        PreservableAutoDisposeNotifierMixin<DmzSettings, DmzStatus,
            DmzFeatureState> {
  UspDmzService get _svc => ref.read(uspDmzServiceProvider);

  @override
  DmzFeatureState build() {
    // Synchronous build with loading state; async fetch follows immediately.
    Future.microtask(() => fetch());
    return DmzFeatureState.initial();
  }

  // ---------------------------------------------------------------------------
  // performFetch — required by PreservableAutoDisposeNotifierMixin
  // ---------------------------------------------------------------------------

  @override
  Future<(DmzSettings?, DmzStatus?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async {
    try {
      final (settings, status) = await _svc.fetch();

      logger.d('[USP][Firewall][DMZ]: Fetched — '
          'enabled: ${settings.model.isEnabled}, '
          'instancePath: ${settings.instancePath}');

      return (settings, status);
    } on ServiceError catch (e) {
      logger.e('[USP][Firewall][DMZ]: Fetch failed', error: e);
      return (
        null,
        DmzStatus(isLoading: false, error: e),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // save — re-read the router after a save that wrote part of itself
  // ---------------------------------------------------------------------------

  /// A save that wrote part of itself reads the router again before its error
  /// reaches the page. A DMZ save gets there two ways:
  /// - A refused switch between IP and MAC may leave the router with no host:
  ///   FW keeps the clear it did not refuse (#1775, bench 2.0.4.26103108).
  /// - A refused first save (an Add) whose row the service could not delete
  ///   leaves a DMZ row on the router (usp-client 0.14.0,
  ///   linksys/usp_framework#114). The next save must update that row, not
  ///   add a second.
  ///
  /// A save that wrote nothing keeps the user's edit for a retry. Same rule as
  /// port forwarding.
  @override
  Future<DmzFeatureState> save() =>
      saveReadingBackAfterPartialWrite(super.save);

  // ---------------------------------------------------------------------------
  // performSave — required by PreservableAutoDisposeNotifierMixin
  // ---------------------------------------------------------------------------

  @override
  Future<void> performSave() async {
    // The Save button needs no field errors, but those are set on blur, so a
    // save checks again. That keeps a malformed value off the router: a
    // refused first save (an Add) creates the row with the field emptied
    // (FWDEV#204), and the service then has to delete it.
    validate();
    final errors = state.status.fieldErrors;
    if (errors.isNotEmpty) {
      throw InvalidInputError(
        field: errors.keys.first,
        detail: 'DMZ form: ${errors.values.join(', ')}',
      );
    }

    state = state.copyWith(
      status: state.status.copyWith(isSaving: true),
    );

    try {
      final settings = state.settings.current;
      final pending = settings.model;

      await ref.read(uspMutationLockProvider).withLock(() async {
        if (settings.isNewEntry && pending.isEnabled) {
          await _svc.add(model: pending);
          logger.d('[USP][Firewall][DMZ]: Entry added — '
              'by ${pending.destinationType.name}');
        } else if (!settings.isNewEntry) {
          await _svc.update(
            instancePath: settings.instancePath!,
            // How the router holds the host now: the original, not the edit.
            savedType: state.settings.original.model.destinationType,
            model: pending,
          );
          logger.d('[USP][Firewall][DMZ]: Entry updated — '
              'enabled: ${pending.isEnabled}, '
              'by ${pending.destinationType.name}');
        }
      });
    } on ServiceError catch (e) {
      logger.e('[USP][Firewall][DMZ]: Save failed', error: e);
      rethrow;
    } finally {
      state = state.copyWith(
        status: state.status.copyWith(isSaving: false),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // UI Mutation (synchronous — no network call)
  // ---------------------------------------------------------------------------

  /// Update a single DMZ setting WITHOUT triggering validation.
  ///
  /// Use this for onChange handlers to avoid TextField unfocus on Web.
  /// Call [validate] separately on unfocus.
  void updateSetting(DmzUIModel Function(DmzUIModel) updater) {
    final current = state.settings.current;
    final newModel = updater(current.model);
    state = state.copyWith(
      settings: state.settings.update(
        current.copyWith(model: newModel),
      ),
    );
  }

  /// Trigger validation on current settings.
  ///
  /// Call this on TextField unfocus to avoid unfocus issues on Web.
  void validate() {
    final current = state.settings.current.model;
    final errors = _svc.validateForm(current);
    state = state.copyWith(
      status: state.status.copyWith(fieldErrors: errors),
    );
  }
}
