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
