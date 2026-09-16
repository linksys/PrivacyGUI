import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_auto_update_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/services/usp_firmware_update_service.dart';

/// Layer 1 data provider for the router's auto-update setting.
///
/// Not autoDispose, and it holds the setting for two surfaces that are never on
/// screen together: the switch on Administration's OTA card, and the dashboard
/// banner. Disposing between them would re-read `autoupdate_flags` on every
/// dashboard visit to answer a question whose answer only changes when this app
/// changes it.
///
/// There is no L2 working copy over this one, and the absence is deliberate. The
/// switch writes on release rather than on save, so there is nothing to hold
/// dirty and nothing to revert — a `Preservable` here would add a save/discard
/// contract to a control that has neither.
final firmwareAutoUpdateDataProvider = AsyncNotifierProvider<
    FirmwareAutoUpdateDataNotifier, FirmwareAutoUpdateUIModel>(
  FirmwareAutoUpdateDataNotifier.new,
);

class FirmwareAutoUpdateDataNotifier
    extends AsyncNotifier<FirmwareAutoUpdateUIModel> {
  @override
  Future<FirmwareAutoUpdateUIModel> build() => _fetch();

  /// Force a re-read. Used after anything that can change the router's own view
  /// of the setting from outside this app (a factory reset, a CLI change).
  ///
  /// Publishing both states is load-bearing on a provider that is not autoDispose:
  ///
  /// * the loading state keeps the previous reading, so the card's switch stays
  ///   readable and merely busy instead of falling back to its locked
  ///   "no value yet" frame every time someone refreshes;
  /// * a failed fetch has to publish `AsyncError`, because nothing invalidates this
  ///   provider on its own. A `refresh` that threw without publishing would leave
  ///   it `AsyncLoading` for the rest of the session: `valueOrNull` null forever,
  ///   the switch locked busy, and `hasError` false so the row does not hide
  ///   either.
  ///
  /// **The error is not a bare one and cannot be made one from here.** Riverpod's
  /// `AsyncNotifier.state` setter routes every assignment through
  /// `asyncTransition`, which applies `copyWithPrevious` unconditionally
  /// (`riverpod/lib/src/common.dart`) — so a failure after a successful read always
  /// reaches consumers as `hasValue && hasError`, with the stale reading still
  /// attached. Measured, not read off the source: the test that asserted a bare
  /// error failed.
  ///
  /// That is a trap rather than a convenience, because `valueOrNull` on that shape
  /// returns the stale value and reads exactly like fresh data. Both consumers
  /// therefore check `hasError` themselves — the switch row hides
  /// (`firmware_ota_card.dart`) and the dashboard banner withholds the offer
  /// (`firmware_update_banner_provider.dart`) — and neither can be simplified to a
  /// `valueOrNull` null check.
  Future<FirmwareAutoUpdateUIModel> refresh() async {
    state =
        const AsyncLoading<FirmwareAutoUpdateUIModel>().copyWithPrevious(state);
    try {
      final data = await _fetch();
      state = AsyncData(data);
      return data;
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      rethrow;
    }
  }

  /// Writes the policy and publishes it.
  ///
  /// No re-read afterwards: the service turns a rejected `Set` into a
  /// [ServiceError], so reaching the line below means the router holds exactly
  /// what was asked for, and a confirmation read would only add a round trip and
  /// a second thing that can fail after the change already landed.
  ///
  /// Throws on failure with the published state untouched — deliberately not an
  /// `AsyncError`. The card's switch has to be able to snap back to the value the
  /// router still holds, and an error state would blank the card that switch
  /// lives on instead of just refusing the change.
  ///
  /// **The mutation lock is held here, and it has to be here rather than inside
  /// [UspFirmwareUpdateService].** Article IV Rule 3 requires every write to take
  /// it, and this was the one firmware write that did not — the `Set` reached the
  /// WASM client unserialised, so flipping the switch during a check could put two
  /// messages in a client that cannot hold two. Pushing the lock down into the
  /// service instead would close this hole and open four: `triggerLocalDownload`,
  /// `triggerOtaDownload`, `requestOtaCheck` and `requestOtaInstall` are already
  /// wrapped by their callers, and [UspMutationLock] is not re-entrant — its
  /// `withLock` waits on `isLocked` before claiming the lock, so a second
  /// acquisition from inside the first blocks until the 30 s force-release. So the
  /// rule is the service's mutations are locked by whoever calls them, and this
  /// method is the caller.
  ///
  /// `TimeoutException` is mapped here for the reason
  /// `FirmwareRouterOtaInstallService.install` gives at its own `withLock`: the
  /// lock throws a bare one, deliberately not a [ServiceError], so it would reach
  /// the switch as `errorUnexpected` instead of as the timeout it is.
  Future<void> setPolicy(FirmwareAutoUpdatePolicy policy) async {
    // `await future` rather than a fabricated default: a write racing the first
    // read has no status or progress to keep, and inventing them would publish a
    // reading the router never gave.
    final current = state.valueOrNull ?? await future;
    logger.d('[FirmwareUpdate] autoUpdate: setPolicy '
        '${current.policy.name} → ${policy.name}');
    try {
      await ref.read(uspMutationLockProvider).withLock(() async {
        await ref
            .read(uspFirmwareUpdateServiceProvider)
            .setAutoUpdatePolicy(policy);
      });
    } on TimeoutException catch (e) {
      throw TimeoutError(
        detail: 'another router mutation was still running when the '
            'auto-update setting was written (${e.message ?? '30s'})',
      );
    }
    state = AsyncData(current.withPolicy(policy));
  }

  Future<FirmwareAutoUpdateUIModel> _fetch() async {
    final data =
        await ref.read(uspFirmwareUpdateServiceProvider).fetchAutoUpdate();
    logger.d('[FirmwareUpdate] autoUpdate: policy=${data.policy.name} '
        'flags="${data.rawFlags}" status=${data.status.name}');
    return data;
  }
}
