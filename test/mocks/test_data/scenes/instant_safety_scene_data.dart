/// Composed scenes for `instant_safety_view` — the golden suite's three states and
/// the gate's one.
///
/// Moved here from
/// `test/golden_test/page/instant_safety/fixtures/instant_safety_test_data.dart` by
/// #1380 (wave 4), for the reason `dmz_scene_data.dart` records: the layout gate may
/// not import from `test/golden_test/` (#1361), and one fixture read by both suites
/// beats two that can disagree.
library;

import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/instant_safety/models/instant_safety_feature_state.dart';
import 'package:privacy_gui/page/instant_safety/models/instant_safety_settings.dart';
import 'package:privacy_gui/page/instant_safety/models/instant_safety_status.dart';
import 'package:privacy_gui/page/instant_safety/models/safe_browsing_ui_model.dart';

InstantSafetyFeatureState enabledState() {
  const settings = InstantSafetySettings(type: SafeBrowsingType.openDNS);
  return InstantSafetyFeatureState(
    settings: Preservable(original: settings, current: settings),
    status: const InstantSafetyStatus(isLoading: false),
  );
}

InstantSafetyFeatureState disabledState() {
  const settings = InstantSafetySettings(type: SafeBrowsingType.off);
  return InstantSafetyFeatureState(
    settings: Preservable(original: settings, current: settings),
    status: const InstantSafetyStatus(isLoading: false),
  );
}

InstantSafetyFeatureState dirtyState() {
  const original = InstantSafetySettings(type: SafeBrowsingType.off);
  const current = InstantSafetySettings(type: SafeBrowsingType.openDNS);
  return InstantSafetyFeatureState(
    settings: Preservable(original: original, current: current),
    status: const InstantSafetyStatus(isLoading: false),
  );
}

// ---------------------------------------------------------------------------
// The gate scene
// ---------------------------------------------------------------------------

/// The router shape every `page.instant_safety` cell is measured against.
///
/// [enabledState] rather than [disabledState], because `_buildSafeBrowsingCard`
/// renders its second `LayoutBlock` — the two lines of OpenDNS server prose, which
/// are the longest strings on the page — only `if (isEnabled)`. The disabled state
/// is the toggle row alone.
///
/// Not [dirtyState], for the reason `dmz_scene_data.dart` gives at the same fork: a
/// dirty state adds `UiKitBottomBarConfig`, ui_kit's own widget, and ui_kit-internal
/// overflow is out of scope per #1380. `enabledState` is also a *clean* edit, so
/// nothing here depends on the bottom bar being absent for a second reason.
///
/// The limit of this page's premise, said where the choice is made: both branches
/// render `LayoutBlock` and `AppSwitch`, so `requires` cannot tell the enabled card
/// from the disabled one. What holds the coverage is this line, not an assertion —
/// unlike `dmz`, whose expanded field has a type of its own to name.
final gateInstantSafetyState = enabledState();
