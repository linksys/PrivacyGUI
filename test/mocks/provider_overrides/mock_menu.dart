/// Provider overrides for `usp_menu_view` (#1379, wave 3).
///
/// The menu is the only page in the wave whose fixture changes what is *measured*
/// rather than whether anything is. Both providers below feed a badge, and each badge
/// is rendered only when its provider has a value:
///
/// ```dart
/// badges: lanData != null ? [isSafetyEnabled ? MenuBadge.on : MenuBadge.off] : []
/// ```
///
/// Unoverridden, both `build()`s reach a USP service and land in `AsyncError`, whose
/// `valueOrNull` is null — so the page renders, ten menu cards render, and two of
/// them silently render **without** the `AppBadge` that sits in their title row. That
/// is a page measured a badge narrower than the one a user sees, in all 234 cells,
/// with nothing failing. The same under-measurement `kDhcpPageCase` warns about with
/// its empty-list state.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/models/lan_info_ui_model.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_notifier.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/instant_privacy/services/instant_privacy_service.dart';
import 'package:privacy_gui/page/local_network/providers/lan_data_provider.dart';

// `FixedLanDataNotifier` is imported rather than restated. It is the same one-method
// subclass either way, and two of them would be two places to fix when
// `LanDataNotifier` gains a member — the reason the constitution wants one canonical
// definition of anything a test depends on.
import 'mock_dhcp.dart' show FixedLanDataNotifier;

/// A [UspInstantPrivacyNotifier] pinned to one state.
///
/// `build()` is the only member overridden: the menu reads `isEnabled` and nothing
/// else, and none of the notifier's mutations are reachable from this page — the
/// card's `onTap` navigates to the privacy page rather than toggling anything.
class FixedInstantPrivacyNotifier extends UspInstantPrivacyNotifier {
  final UspInstantPrivacyState _fixedState;

  FixedInstantPrivacyNotifier(this._fixedState);

  @override
  Future<UspInstantPrivacyState> build() async => _fixedState;
}

/// Overrides for `usp_menu_view`.
///
/// [lanInfo] is required rather than defaulted so the case naming it also owns the
/// choice: the view reads exactly one field off it (`dnsServers`, through
/// `UspInstantSafetyService.isOpenDns`), which decides `MenuBadge.on` vs
/// `MenuBadge.off` — two labels of near-identical width, both of which put an
/// `AppBadge` in the row. So the presence of a value is the axis here, not which
/// value it is.
List<Override> menuOverrides({
  required LanInfoUIModel lanInfo,
  required bool privacyEnabled,
}) =>
    [
      lanDataProvider
          .overrideWith(() => FixedLanDataNotifier(LanData(model: lanInfo))),
      uspInstantPrivacyProvider.overrideWith(
        () => FixedInstantPrivacyNotifier(
          UspInstantPrivacyState(
            isEnabled: privacyEnabled,
            connectedDevices: const [],
            allowedDevices: const [],
            macFilterContext: MacFilterContext.empty,
          ),
        ),
      ),
    ];
