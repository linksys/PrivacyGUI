import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_probe_settings.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_settings.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_wifi_draft_provider.dart';

/// **#1511 P6's probe — test-only, never shipped.** The probe step's draft,
/// held by the flow like every setting step's.
final pnpProbeDraftProvider = NotifierProvider.autoDispose<
    PnpProbeDraftNotifier,
    Preservable<PnpProbeSettings>>(PnpProbeDraftNotifier.new);

const _off = PnpProbeSettings(enabled: false);

class PnpProbeDraftNotifier
    extends AutoDisposeNotifier<Preservable<PnpProbeSettings>>
    implements PnpStepDraft {
  @override
  Preservable<PnpProbeSettings> build() =>
      const Preservable(original: _off, current: _off);

  @override
  void begin(PnpWizardData router) {
    final read = router.probe ?? _off;
    state = Preservable(original: read, current: read);
  }

  @override
  bool isDirty() => state.isDirty;

  @override
  void revert() => state = state.copyWith(current: state.original);

  @override
  void markAsSaved() => state = state.saved();

  void setEnabled(bool enabled) =>
      state = state.update(PnpProbeSettings(enabled: enabled));
}
