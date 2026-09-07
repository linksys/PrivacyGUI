import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_isp_config.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_notifier.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_providers.dart';

/// A [PnpNotifier] frozen at one phase.
///
/// Every other page in `test/mocks/provider_overrides/` overrides a provider that
/// *fetches*, so its fake only has to return a state and no-op its fetch. The PnP
/// flow is a state machine, so the thing that has to be stopped is different: the
/// nine views drive each other by **calling transition methods**, and the real
/// ones reach `pnpServiceProvider`, whose `ref.read(uspClientProvider)!` throws on
/// a null client and lands the flow in `AdminReadFailure` via
/// `startPostLoginFlow`'s `catch`.
///
/// That is not a hypothetical. `PnpEntryView.initState` calls
/// `startPostLoginFlow()` in a microtask, so without the override below a pumped
/// entry view reaches its error card *because the fixture crashed* — a page that
/// looks measured and is really measuring a null-check failure. Overriding the
/// transitions is what makes the pinned phase the phase.
///
/// What is overridden is every transition a *view* triggers: one during
/// `initState` (the entry view's, the only one a bare pump reaches) and one per
/// button on the other eight, so a test that taps stays inside the fixture too.
/// The `update*` field setters are deliberately **not** overridden — they only
/// `copyWith` local state, never touch the service, and stubbing them would make
/// a typed character invisible to any test that types one.
///
/// A method this class does not name calls through to the real service, which is
/// the failure mode above. A new entry point on `PnpNotifier` that a view calls
/// belongs here.
class FixedPnpNotifier extends PnpNotifier {
  FixedPnpNotifier(this._fixedState);

  final PnpState _fixedState;

  @override
  PnpState build() => _fixedState;

  // ── Entry (PnpEntryView.initState, and its error card's retry button) ──
  @override
  Future<void> startPostLoginFlow() async {}

  // ── Troubleshooter hub (PnpNoInternetView's two buttons) ──
  @override
  Future<void> retryInternetCheck() async {}

  @override
  Future<void> bypassToDashboard() async {}

  // ── Modem restart (PnpWaitingModemView's confirm button) ──
  @override
  Future<void> startModemRestartCountdown() async {}

  // ── ISP forms (PnpIspSettingsView / PnpPppoeView / PnpStaticIpView save) ──
  @override
  Future<void> saveIspWithProgress(PnpIspConfig config) async {}

  // ── Wizard (PnpSetupView's save, and its per-field edits) ──
  @override
  Future<void> saveChanges() async {}
}

/// Returns provider overrides pinning the PnP state machine to [state].
///
/// One builder for all nine instant_setup views rather than one per view: they
/// share a single provider, so a per-view builder would be the same two lines
/// with a different fixture — and the fixture is the argument. The composed
/// states are in `test/mocks/test_data/scenes/pnp_scene_data.dart`.
List<Override> pnpOverrides(PnpState state) => [
      pnpProvider.overrideWith(() => FixedPnpNotifier(state)),
    ];
