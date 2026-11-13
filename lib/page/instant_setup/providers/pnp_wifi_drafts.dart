import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_draft_state.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_settings.dart';

/// What the PnP flow needs from a setting step's draft, whatever the step
/// edits (#1511 P4): beginning at what the router reported, whether it
/// changed, putting it back, and recording that it was saved.
///
/// **Not `PreservableAutoDisposeNotifierMixin`, on purpose.** A draft's state is
/// a `FeatureState` over a `Preservable`, like every L2 working copy, but a
/// draft never reads the router and never saves on its own — the flow does both,
/// once, for every step — so the mixin's fetch/save template would have
/// nothing to run: two template methods that throw, and a status that can carry
/// no read error, which `has_service_error_roster_test.dart` rightly refuses for
/// any notifier using the mixin. The last three methods below are one line
/// each on the draft's `Preservable`. What the route guards with is the
/// flow-level guard over the drafts, `pnpWizardDraftsProvider`, a
/// `PreservableContract`.
///
/// **The flow begins the drafts; a draft never reads the flow.** The flow reads
/// the drafts when it saves, so a draft that also read the flow would be a
/// dependency cycle, which Riverpod refuses.
abstract interface class PnpStepDraft {
  /// Starts the draft at its part of [router], unedited.
  void begin(PnpWizardData router);
  bool isDirty();
  void revert();
  void markAsSaved();
}

/// The Wi-Fi step's draft (#1511 P4).
///
/// `autoDispose`, and held by the flow from the moment it begins the draft:
/// `PnpNotifier` listens to every draft in its plan, so a draft lives exactly
/// as long as the flow does. A step's own page is unmounted as soon as the user
/// moves to the next step, and its edits must not go with it.
final pnpMainWifiDraftProvider =
    NotifierProvider.autoDispose<PnpMainWifiDraftNotifier, PnpMainWifiDraft>(
  PnpMainWifiDraftNotifier.new,
);

/// The guest step's draft. Built only when the plan has a guest step.
final pnpGuestWifiDraftProvider =
    NotifierProvider.autoDispose<PnpGuestWifiDraftNotifier, PnpGuestWifiDraft>(
  PnpGuestWifiDraftNotifier.new,
);

const _noMain = PnpMainWifiSettings(ssid: '', password: '');
const _noGuest = PnpGuestWifiSettings(enabled: false, ssid: '', password: '');

class PnpMainWifiDraftNotifier extends AutoDisposeNotifier<PnpMainWifiDraft>
    implements PnpStepDraft {
  /// Empty until the flow begins it.
  @override
  PnpMainWifiDraft build() => PnpMainWifiDraft.from(_noMain);

  @override
  void begin(PnpWizardData router) =>
      state = PnpMainWifiDraft.from(router.main);

  @override
  bool isDirty() => state.isDirty;

  @override
  void revert() => state = state.copyWith(
      settings: state.settings.copyWith(current: state.settings.original));

  @override
  void markAsSaved() =>
      state = state.copyWith(settings: state.settings.saved());

  void setSsid(String ssid) => _edit((s) => s.copyWith(ssid: ssid));

  void setPassword(String password) =>
      _edit((s) => s.copyWith(password: password));

  void setBandSsid(String ssidInstancePath, String ssid) =>
      _edit((s) => s.withBand(ssidInstancePath, ssid: ssid));

  void setBandPassword(String ssidInstancePath, String password) =>
      _edit((s) => s.withBand(ssidInstancePath, password: password));

  void _edit(PnpMainWifiSettings Function(PnpMainWifiSettings) change) =>
      state = state.copyWith(
        settings: state.settings.update(change(state.settings.current)),
      );
}

class PnpGuestWifiDraftNotifier extends AutoDisposeNotifier<PnpGuestWifiDraft>
    implements PnpStepDraft {
  /// Empty until the flow begins it.
  @override
  PnpGuestWifiDraft build() => PnpGuestWifiDraft.from(_noGuest);

  /// Begins at the router's guest network. Only the plan's steps are begun, so
  /// a router without one never reaches here.
  @override
  void begin(PnpWizardData router) =>
      state = PnpGuestWifiDraft.from(router.guest ?? _noGuest);

  @override
  bool isDirty() => state.isDirty;

  @override
  void revert() => state = state.copyWith(
      settings: state.settings.copyWith(current: state.settings.original));

  @override
  void markAsSaved() =>
      state = state.copyWith(settings: state.settings.saved());

  void setEnabled(bool enabled) => _edit((s) => s.copyWith(enabled: enabled));

  void setSsid(String ssid) => _edit((s) => s.copyWith(ssid: ssid));

  void setPassword(String password) =>
      _edit((s) => s.copyWith(password: password));

  void setBandSsid(String ssidInstancePath, String ssid) =>
      _edit((s) => s.withBand(ssidInstancePath, ssid: ssid));

  void setBandPassword(String ssidInstancePath, String password) =>
      _edit((s) => s.withBand(ssidInstancePath, password: password));

  void _edit(PnpGuestWifiSettings Function(PnpGuestWifiSettings) change) =>
      state = state.copyWith(
        settings: state.settings.update(change(state.settings.current)),
      );
}
