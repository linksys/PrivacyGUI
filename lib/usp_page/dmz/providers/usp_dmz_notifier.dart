import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/dmz.g.dart';
import 'package:privacy_gui/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/usp_page/_framework/preservable_contract.dart';
import 'package:privacy_gui/usp_page/_framework/preservable_notifier_mixin.dart';
import 'package:privacy_gui/usp_page/dmz/models/dmz_feature_state.dart';
import 'package:privacy_gui/usp_page/dmz/models/dmz_settings.dart';
import 'package:privacy_gui/usp_page/dmz/models/dmz_status.dart';
import 'package:privacy_gui/usp_page/dmz/models/dmz_ui_model.dart';
import 'package:privacy_gui/usp_page/dmz/services/usp_dmz_service.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final uspDmzProvider =
    AutoDisposeNotifierProvider<UspDmzNotifier, DmzFeatureState>(
  UspDmzNotifier.new,
);

/// Exposes the notifier as a [PreservableContract] for [LinksysRoute]
/// dirty-check integration.
final preservableUspDmzProvider =
    AutoDisposeProvider<PreservableContract<DmzSettings, DmzStatus>>(
  (ref) => ref.watch(uspDmzProvider.notifier),
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
    // SSE invalidation: re-fetch when DMZ config changes externally.
    // Uses the framework's onSseInvalidation() — skips if dirty.
    ref.listen(sseInvalidationProvider, (_, next) {
      if (next.valueOrNull == InvalidationDomain.dmz) {
        onSseInvalidation();
      }
    });

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
      final usp = ref.read(uspServiceProvider)!;
      final dmzData = await Dmz.fetch(usp);

      final uiModel = _svc.buildUIModel(dmzData);
      final instancePath =
          dmzData.items.isNotEmpty ? dmzData.items.first.instancePath : null;

      logger.d('[USP][Firewall][DMZ] Fetched — '
          'entries: ${dmzData.items.length}, '
          'enabled: ${uiModel.isEnabled}, '
          'instancePath: $instancePath');

      return (
        DmzSettings(model: uiModel, instancePath: instancePath),
        const DmzStatus(isLoading: false),
      );
    } catch (e) {
      logger.e('[USP][Firewall][DMZ] Fetch failed', error: e);
      return (
        null,
        DmzStatus(isLoading: false, errorMessage: '$e'),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // performSave — required by PreservableAutoDisposeNotifierMixin
  // ---------------------------------------------------------------------------

  @override
  Future<void> performSave() async {
    state = state.copyWith(
      status: state.status.copyWith(isSaving: true),
    );

    try {
      final usp = ref.read(uspServiceProvider)!;
      final settings = state.settings.current;
      final pending = settings.model;

      await ref.read(uspMutationLockProvider).withLock(() async {
        if (settings.isNewEntry && pending.isEnabled) {
          // ADD new DMZ entry
          final sourcePrefix = pending.sourceType == DmzSourceType.any
              ? '0.0.0.0/0'
              : pending.sourcePrefix;
          await Dmz.add(
            usp,
            enable: true,
            destIp: pending.destIp,
            sourcePrefix: sourcePrefix,
            description: 'DMZ',
          );
          logger.d(
              '[USP][Firewall][DMZ] Entry added — destIp: ${pending.destIp}');
        } else if (!settings.isNewEntry) {
          // UPDATE existing entry
          final sourcePrefix = pending.sourceType == DmzSourceType.any
              ? '0.0.0.0/0'
              : pending.sourcePrefix;
          await Dmz.update(
            usp,
            DmzEntryUpdate(
              instancePath: settings.instancePath!,
              enable: pending.isEnabled,
              destIp: pending.destIp,
              sourcePrefix: sourcePrefix,
            ),
          );
          logger.d('[USP][Firewall][DMZ] Entry updated — '
              'enabled: ${pending.isEnabled}, destIp: ${pending.destIp}');
        }
      });
    } catch (e) {
      state = state.copyWith(
        status: state.status.copyWith(isSaving: false),
      );
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // UI Mutation (synchronous — no network call)
  // ---------------------------------------------------------------------------

  /// Update a single DMZ setting.
  void updateSetting(DmzUIModel Function(DmzUIModel) updater) {
    final current = state.settings.current;
    state = state.copyWith(
      settings: state.settings.update(
        current.copyWith(model: updater(current.model)),
      ),
    );
  }
}
