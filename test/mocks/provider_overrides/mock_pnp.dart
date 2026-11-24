import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_draft_state.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_settings.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_notifier.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_providers.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_wifi_draft_provider.dart';

/// A [PnpNotifier] frozen at one phase.
///
/// Every other page in `test/mocks/provider_overrides/` overrides a provider that
/// *fetches*, so its fake only has to return a state and no-op its fetch. The PnP
/// flow is a state machine, so the thing that has to be stopped is different: its
/// views drive each other by **calling transition methods**, and the real
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
/// button on the wizard's steps and status screens, so a test that taps stays
/// inside the fixture too. The troubleshooting pages' transitions are not here:
/// since #1511 P1 they are `InternetTroubleshootingNotifier`'s, pinned by
/// `mock_internet_troubleshooting.dart`. What the user types is not here
/// either: since #1511 P4 it goes to the steps' drafts, which never touch the
/// service — see [pnpOverrides]' `router`.
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

  // ── Wizard (the save step's Save, Your Network's Done) ──
  /// Times Save was pressed.
  int saves = 0;

  @override
  Future<void> saveChanges() async => saves++;

  /// Times Your Network's Done was pressed (#1511 P5).
  int finishes = 0;

  @override
  Future<void> finishWizard() async => finishes++;

  /// Times the Your Network step asked for the nodes again (#1734), which it
  /// does once the add-nodes page it pushed has popped.
  int meshRefreshes = 0;

  @override
  Future<void> refreshMeshNodes() async => meshRefreshes++;

  @override
  Future<void> testReconnect() async {}
}

/// A setting step's draft begun at a fixed router read, the way the flow
/// begins it when it enters the steps (#1511 P4).
class FixedMainWifiDraft extends PnpMainWifiDraftNotifier {
  FixedMainWifiDraft(this._read);
  final PnpMainWifiSettings _read;

  @override
  PnpMainWifiDraftState build() => PnpMainWifiDraftState.from(_read);
}

/// See [FixedMainWifiDraft].
class FixedGuestWifiDraft extends PnpGuestWifiDraftNotifier {
  FixedGuestWifiDraft(this._read);
  final PnpGuestWifiSettings _read;

  @override
  PnpGuestWifiDraftState build() => PnpGuestWifiDraftState.from(_read);
}

/// Returns provider overrides pinning the PnP state machine to [state].
///
/// One builder for the views that read `pnpProvider` — the entry, the frame and
/// the wizard's steps — rather than one per view: they share a single provider,
/// so a per-view builder would be the same two lines with a different fixture,
/// and the fixture is the argument. The composed states are in
/// `test/mocks/test_data/scenes/pnp_scene_data.dart`.
///
/// [router] begins the setting steps' drafts at that read. A [FixedPnpNotifier]
/// never runs the wizard's read, which is what begins them in the app, so a
/// step pumped without it shows empty fields.
List<Override> pnpOverrides(PnpState state, {PnpWizardData? router}) => [
      pnpProvider.overrideWith(() => FixedPnpNotifier(state)),
      if (router != null) ...[
        pnpMainWifiDraftProvider.overrideWith(
          () => FixedMainWifiDraft(router.main),
        ),
        if (router.guest case final guest?)
          pnpGuestWifiDraftProvider.overrideWith(
            () => FixedGuestWifiDraft(guest),
          ),
      ],
    ];
