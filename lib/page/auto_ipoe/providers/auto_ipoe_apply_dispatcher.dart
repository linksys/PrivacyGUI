import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_state.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_models.dart';
import 'package:privacy_gui/page/auto_ipoe/service/auto_ipoe_internet_settings_bridge.dart';

/// Sends Auto-IPoE Apply on behalf of a screen.
///
/// This adds no logic. Screens used to call the bridge themselves, which put a
/// service call in the presentation tier; this gives the dispatch one
/// provider-tier entry point and puts it next to the reconciliation that
/// follows it.
///
/// It is deliberately not on [AutoIPoENotifier]: these calls need to know what
/// WAN type the router is coming from, and that is Internet Settings' concept.
/// The notifier and the Auto-IPoE models are free of it today, and pulling it in
/// to save a class would be the wrong trade. The bridge stays what it already
/// was -- the one component that knows both sides of a WAN type change.
class AutoIPoEApplyDispatcher {
  AutoIPoEApplyDispatcher({required AutoIPoEInternetSettingsBridge bridge})
      : _bridge = bridge;

  final AutoIPoEInternetSettingsBridge _bridge;

  /// Applies the edited settings from Advanced settings, which may also have to
  /// tear down an existing tunnel first when the WAN type is changing.
  Future<void> applyFromInternetSettings({
    required AutoIPoESettings settings,
    required WanType? originalWanType,
    AutoIPoEStatus? originalStatus,
  }) =>
      _bridge.saveIPoEInternetSettings(
        settings: settings,
        originalWanType: originalWanType,
        originalStatus: originalStatus,
      );

  /// Applies during setup, where there is no previous WAN type to unwind.
  Future<void> applyFromPnp({AutoIPoESettings? settings}) =>
      _bridge.savePnpIPoE(settings: settings);

  /// Undoes Auto-IPoE before an ordinary WAN save takes the router off IPoE.
  Future<void> resetBeforeLeavingIPoE({
    required WanType? originalWanType,
    AutoIPoEStatus? originalStatus,
  }) =>
      _bridge.resetIfNeededBeforeSaving(
        originalWanType: originalWanType,
        originalStatus: originalStatus,
      );
}

final autoIPoEApplyDispatcherProvider = Provider<AutoIPoEApplyDispatcher>(
  (ref) => AutoIPoEApplyDispatcher(
    bridge: ref.read(autoIPoEInternetSettingsBridgeProvider),
  ),
);
