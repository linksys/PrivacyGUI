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
import 'package:privacy_gui/page/mac_filter/models/mac_filter_data.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_mode.dart';
import 'package:privacy_gui/page/mac_filter/providers/mac_filter_data_provider.dart';
import 'package:privacy_gui/page/local_network/providers/lan_data_provider.dart';
import 'package:privacy_gui/core/capability/capability_provider.dart';
import 'package:privacy_gui/core/capability/device_capability.dart';

// `FixedLanDataNotifier` is imported rather than restated. It is the same one-method
// subclass either way, and two of them would be two places to fix when
// `LanDataNotifier` gains a member — the reason the constitution wants one canonical
// definition of anything a test depends on. `FixedMacFilterDataNotifier` likewise.
import 'mock_dhcp.dart' show FixedLanDataNotifier;
import 'mock_mac_filter.dart' show FixedMacFilterDataNotifier;

/// Overrides for `usp_menu_view`.
///
/// [lanInfo] is required rather than defaulted so the case naming it also owns the
/// choice: the view reads exactly one field off it (`dnsServers`, through
/// `SafeBrowsingUIModel.isOpenDns`), which decides `MenuBadge.on` vs
/// `MenuBadge.off` — two labels of near-identical width, both of which put an
/// `AppBadge` in the row. So the presence of a value is the axis here, not which
/// value it is.
List<Override> menuOverrides({
  required LanInfoUIModel lanInfo,
  required MacFilterMode privacyMode,
}) =>
    [
      lanDataProvider
          .overrideWith(() => FixedLanDataNotifier(LanData(model: lanInfo))),
      // The badge reads the session-wide MAC filter (L1), not the Instant
      // Privacy page's notifier (#1755).
      macFilterDataProvider.overrideWith(
        () => FixedMacFilterDataNotifier(
            MacFilterData(mode: privacyMode, macs: const [])),
      ),
      // The Instant Privacy card exists only on firmware that serves the MAC
      // filter (#1635); without this the card, and the badge row this fixture pins
      // a state for, would not render at all.
      deviceCapabilitiesProvider.overrideWithValue(
          DeviceCapabilities(const {DeviceCapability.wifiMacFilter})),
    ];
