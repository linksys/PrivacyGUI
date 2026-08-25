/// The two pages the #1349 pilot swept, and why those two.
///
/// ## The rule that constrained the choice
///
/// §8's graduation rule: **a surface earns a local probe only after it has been
/// fixed to zero.** A probe on a page that still carries debt would force a second
/// allowlist into existence, which is exactly what the empty
/// `test/fixtures/known_overflows.json` exists to avoid. That rules out every area
/// holding the ~135 coordinates golden CI reports — devices, `_shared`, statistics,
/// topology, and admin's firmware-update page — regardless of how interesting they
/// would be to measure.
///
/// ## Why these two, and not one of them twice
///
/// The pilot's deliverable is a **bracket**, not a point: §1.2 has chrome-style
/// provider-free hosts at ~6ms per cell and golden's full-page pumps at ~170ms,
/// and a real page could resemble either. One page sampled once would produce a
/// number with nothing to compare it against, so the two are picked from opposite
/// ends of the cost range this family can span:
///
/// - **`page.dhcp`** — [UspDhcpDetailView], the cheap end and the shape most pages
///   have: a `UiKitPageView.withSliver` holding three cards, fed by three
///   overridden providers. It is also the page whose fixtures were already outside
///   `test/golden_test/` after #1361, so nothing had to move for it.
/// - **`page.wifi_settings`** — [UspWifiSettingsView], the expensive end: a
///   `TabController`, two `Preservable` feature-state providers, a responsive
///   column count that re-derives the grid per width, and four network cards each
///   holding its own row of tiles. If a page-level probe is unaffordable anywhere,
///   it is unaffordable here first.
///
/// Neither needed an allowlist entry, and both are at zero — but only
/// `page.wifi_settings` was at zero *before* this file existed. `page.dhcp` was
/// not: its first sweep reported `usp_dhcp_reservations_detail_card.dart:31` over
/// by 113px at 320px and 141px at 601px in `ar`, and #1349 chose to **fix** the
/// card rather than swap the page out, so the fix and the probe land together. The
/// spec's own remedy was a swap; §11.3 of
/// `doc/testing/overflow_gate_architecture.md` records why the fix was taken
/// instead, along with the run and the numbers. The order matters to anyone reading
/// this list as evidence that the graduation rule was followed: it was followed in
/// substance — no page enters the gate carrying debt — and not in sequence.
///
/// ## What each case pins, and why a page needs a premise a card does not
///
/// Both pages open with `if (status.isLoading) return AppLoader()`. A loader is a
/// centred 48px box: it cannot overflow at any width in any locale. So a fixture
/// that drifts out of shape does not turn this sweep red — it turns it *green over
/// nothing*, which is #1366's F11 finding one layer up (78 popup cells measured a
/// 122px tile while the coverage baseline stayed byte-identical). [PageSurfaceCase.requires]
/// is what closes it, and `page_surface_family_test.dart` is what stops the lists
/// from being quietly emptied.
library;

import 'package:privacy_gui/page/dhcp/views/components/usp_dhcp_active_leases_card.dart';
import 'package:privacy_gui/page/dhcp/views/components/usp_dhcp_reservations_detail_card.dart';
import 'package:privacy_gui/page/dhcp/views/components/usp_dhcp_server_info_card.dart';
import 'package:privacy_gui/page/dhcp/views/usp_dhcp_detail_view.dart';
import 'package:privacy_gui/page/wifi_settings/views/components/wifi_network_card.dart';
import 'package:privacy_gui/page/wifi_settings/views/usp_wifi_settings_view.dart';
import 'package:ui_kit_library/ui_kit.dart' show AppLoader;

import '../../mocks/provider_overrides/mock_dhcp.dart';
import '../../mocks/provider_overrides/mock_wifi_settings.dart';
import '../../mocks/test_data/scenes/dhcp_scene_data.dart';
import '../../mocks/test_data/scenes/wifi_settings_scene_data.dart';
import 'page_surface_family.dart';

/// `page.dhcp` — the plain-form end of the bracket.
///
/// The fixture is the golden suite's `reservations_list` state: a populated
/// reservation list plus active leases, which is the widest of the three states
/// that page has (`empty` renders one placeholder row and would under-measure the
/// table).
///
/// All three cards are required, not just one. They are three independent
/// presentations — an info grid, a lease table and a reservation table — and each
/// is fed by a different provider, so requiring only the first would leave the
/// other two free to fall back to a spinner unnoticed.
final kDhcpPageCase = PageSurfaceCase(
  id: 'dhcp',
  view: () => const UspDhcpDetailView(),
  overrides: () => dhcpDetailOverrides(
    reservationState: dataState(),
    lanInfo: testLanInfo,
    clients: testClients,
  ),
  requires: const [
    UspDhcpServerInfoCard,
    UspDhcpActiveLeasesCard,
    UspDhcpReservationsDetailCard,
  ],
  forbids: const [AppLoader],
);

/// `page.wifi_settings` — the provider-heavy end of the bracket.
///
/// `quickSetupOffState`, not `quickSetupOnState`: quick-setup-on collapses the four
/// per-band networks into two aggregate cards, so the off state renders strictly
/// more of the page. Paired with `defaultAdvancedState` because the view watches
/// both providers on every build regardless of which tab is showing.
///
/// Only the WiFi tab is measured. `UspWifiAdvancedTab` is behind a `TabController`
/// and would need a tap per cell — a second axis, and one the pilot deliberately
/// does not buy: the point of these two pages is a cost number, and doubling the
/// expensive page's cells before that number exists would be deciding the question
/// the sweep is meant to answer.
///
/// `DetailSpeedCard` is not here and would be wrong here: it belongs to the device
/// and node detail pages, which are two of the areas §8's rule excludes.
final kWifiSettingsPageCase = PageSurfaceCase(
  id: 'wifi_settings',
  view: () => const UspWifiSettingsView(),
  overrides: () => wifiSettingsOverrides(
    wifiState: quickSetupOffState,
    advancedState: defaultAdvancedState,
  ),
  requires: const [WifiNetworkCard],
  forbids: const [AppLoader],
);

/// Every case the pilot swept, in sweep order.
///
/// One list, so `page_surface_family_test.dart` can pin the premises of all of
/// them without naming each — a case added here without a premise fails there.
final kPageSurfaceCases = <PageSurfaceCase>[
  kDhcpPageCase,
  kWifiSettingsPageCase,
];
