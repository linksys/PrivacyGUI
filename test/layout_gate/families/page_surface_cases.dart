/// The pages the gate sweeps: the #1349 pilot's two, #1377's wave 1 five,
/// #1378's wave 2 nine, #1379's wave 3 six, and #1380's wave 4 twenty-one — **43 of
/// the 45 page views under `lib/page/`**, the register's other two being excluded as
/// unreachable. `test/fixtures/page_roster.tsv` is where that arithmetic lives; this
/// file is where the 43 are declared, and the two are the same claim seen from the two
/// ends `page_roster_test.dart` joins.
///
/// ## The rule that constrained the choice
///
/// §8's graduation rule: **a surface earns a local probe only after it has been
/// fixed to zero.** A probe on a page that still carries debt would force a second
/// allowlist into existence, which is exactly what the empty
/// `test/fixtures/known_overflows.json` exists to avoid. That is what ruled out
/// every area holding the ~135 coordinates golden CI reports — devices, `_shared`,
/// statistics, topology, and admin's firmware-update page — *for the pilot*.
///
/// **Wave 1 (#1377) does not repeal that rule; it pays it.** Five of those pages
/// enter here, and the rule is why four of the five are one-line additions and the
/// fifth came with a widget fix: #1370's inventory re-checked #1302's five sites
/// and found four still clean, while the sweep it ran turned up a *different* site
/// — `usp_single_port_tab.dart:30`, 9 cells, worst +70px. It was fixed in the
/// widget before this list grew, so no page below arrives carrying debt. See
/// [kPortForwardingPageCase].
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

// `SelectionArea` is imported for one `requires` entry, on
// [kTestConsolePageCase] — see there for why the log pane needs an anchor of its
// own. No `Scaffold` here: the two dashboard pages that need one set
// [PageSurfaceCase.needsMaterialAncestor] and the host builds it — see
// [kSliverDashboardPageCase] for why those two need it and no other page does, and
// [PageSurfaceCase.view] for why the wrapper may not live in a `view` closure.
// Shown rather than imported whole because this file resolves widget names
// against ui_kit first, and a bare material import would quietly change which
// `AppText`-adjacent name a future `requires` entry means.
import 'package:flutter/material.dart' show GridView, SelectionArea;
import 'package:flutter_svg/flutter_svg.dart' show SvgPicture;
import 'package:privacy_gui/components/customs/circular_countdown_widget.dart';
import 'package:privacy_gui/components/styled/menus/widgets/app_menu_card.dart';
import 'package:privacy_gui/components/views/service_error_view.dart';
import 'package:privacy_gui/page/_shared/components/detail_widgets.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/admin/views/components/usp_password_card.dart';
import 'package:privacy_gui/page/admin/views/components/usp_system_actions_card.dart';
import 'package:privacy_gui/page/admin/views/components/usp_timezone_card.dart';
import 'package:privacy_gui/page/admin/views/usp_admin_view.dart';
import 'package:privacy_gui/page/advanced_settings/views/usp_advanced_settings_view.dart';
import 'package:privacy_gui/page/ai_assistant/views/router_assistant_view.dart';
import 'package:privacy_gui/page/apps/views/usp_apps_view.dart';
import 'package:privacy_gui/page/dashboard/views/components/dashboard_header_bar.dart';
import 'package:privacy_gui/page/dashboard/views/usp_dashboard_view.dart';
import 'package:privacy_gui/page/dashboard/views/usp_sliver_dashboard_view.dart';
import 'package:privacy_gui/page/devices/views/components/usp_device_filter_panel.dart';
import 'package:privacy_gui/page/devices/views/components/usp_device_list_tile.dart';
import 'package:privacy_gui/page/devices/views/components/usp_signal_strength_indicator.dart';
import 'package:privacy_gui/page/devices/views/usp_device_detail_view.dart';
import 'package:privacy_gui/page/devices/views/usp_device_list_view.dart';
import 'package:privacy_gui/page/dhcp/views/components/usp_dhcp_active_leases_card.dart';
import 'package:privacy_gui/page/dhcp/views/components/usp_dhcp_reservations_detail_card.dart';
import 'package:privacy_gui/page/dhcp/views/components/usp_dhcp_server_info_card.dart';
import 'package:privacy_gui/page/dhcp/views/usp_dhcp_detail_view.dart';
import 'package:privacy_gui/page/dmz/models/dmz_ui_model.dart'
    show DmzSourceType;
import 'package:privacy_gui/page/dmz/views/usp_dmz_view.dart';
import 'package:privacy_gui/page/firewall/views/usp_firewall_view.dart';
import 'package:privacy_gui/page/firmware_update/views/firmware_update_card.dart';
import 'package:privacy_gui/page/firmware_update/views/firmware_update_view.dart';
import 'package:privacy_gui/page/instant_privacy/views/instant_privacy_view.dart';
import 'package:privacy_gui/page/instant_safety/views/instant_safety_view.dart';
import 'package:privacy_gui/page/instant_setup/views/components/pnp_isp_saving_progress.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_entry_view.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_isp_settings_view.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_modem_lights_off_view.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_no_internet_view.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_pppoe_view.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_setup_view.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_static_ip_view.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_unplug_modem_view.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_waiting_modem_view.dart';
import 'package:privacy_gui/page/internet_settings/views/components/usp_connection_status_banner.dart';
import 'package:privacy_gui/page/internet_settings/views/sections/usp_ipv4_section.dart';
import 'package:privacy_gui/page/internet_settings/views/sections/usp_ipv6_section.dart';
import 'package:privacy_gui/page/internet_settings/views/sections/usp_optional_section.dart';
import 'package:privacy_gui/page/internet_settings/views/sections/usp_renew_section.dart';
import 'package:privacy_gui/page/internet_settings/views/usp_internet_settings_view.dart';
import 'package:privacy_gui/page/ipv6_port_service/views/usp_ipv6_port_service_view.dart';
import 'package:privacy_gui/page/local_network/views/usp_local_network_view.dart';
import 'package:privacy_gui/page/landing/views/home_view.dart';
import 'package:privacy_gui/page/login/auto_parent/views/auto_parent_first_login_view.dart';
import 'package:privacy_gui/page/login/views/local_reset_router_password_view.dart';
import 'package:privacy_gui/page/login/views/local_router_recovery_view.dart';
import 'package:privacy_gui/page/login/views/login_local_view.dart';
import 'package:privacy_gui/page/menu/views/usp_menu_view.dart';
import 'package:privacy_gui/page/port_forwarding/views/components/usp_single_port_tab.dart';
import 'package:privacy_gui/page/port_forwarding/views/usp_port_forwarding_detail_view.dart';
import 'package:privacy_gui/page/remote_assistance/views/remote_assistance_confirm_view.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:privacy_gui/page/static_routing/views/usp_static_routing_view.dart';
import 'package:privacy_gui/page/statistics/views/components/stats_section_card.dart';
import 'package:privacy_gui/page/statistics/views/usp_statistics_view.dart';
import 'package:privacy_gui/page/system_log/views/usp_system_log_view.dart';
import 'package:privacy_gui/page/support/views/usp_support_view.dart';
import 'package:privacy_gui/page/test_console/views/usp_test_console_view.dart';
import 'package:privacy_gui/page/test_console/widgets/tr181_autocomplete_field.dart';
import 'package:privacy_gui/page/topology/views/components/backhaul_signal_indicator.dart';
import 'package:privacy_gui/page/topology/views/usp_node_detail_view.dart';
import 'package:privacy_gui/page/topology/views/usp_topology_view.dart';
import 'package:privacy_gui/page/unified_diagnostics/views/unified_diagnostics_view.dart';
import 'package:privacy_gui/page/unified_diagnostics/views/widgets/diagnostic_start_view.dart';
import 'package:privacy_gui/page/wifi_settings/views/components/wifi_network_card.dart';
import 'package:privacy_gui/page/wifi_settings/views/usp_wifi_settings_view.dart';
import 'package:sliver_dashboard/sliver_dashboard.dart' show SliverDashboard;
import 'package:ui_kit_library/ui_kit.dart'
    show
        AppBadge,
        AppButton,
        AppCard,
        AppExpansionPanel,
        AppIconButton,
        AppIpv4TextField,
        AppLoader,
        AppPasswordInput,
        AppPinInput,
        AppRadioList,
        AppStepper,
        AppSwitch,
        AppTextField,
        AppTextFormField,
        AppTopology;

import '../../mocks/provider_overrides/mock_admin.dart';
import '../../mocks/provider_overrides/mock_apps.dart';
import '../../mocks/provider_overrides/mock_dashboard_page.dart';
import '../../mocks/provider_overrides/mock_devices.dart';
import '../../mocks/provider_overrides/mock_dhcp.dart';
import '../../mocks/provider_overrides/mock_dmz.dart';
import '../../mocks/provider_overrides/mock_firewall.dart';
import '../../mocks/provider_overrides/mock_firmware_update.dart';
import '../../mocks/provider_overrides/mock_instant_privacy.dart';
import '../../mocks/provider_overrides/mock_instant_safety.dart';
import '../../mocks/provider_overrides/mock_internet_settings.dart';
import '../../mocks/provider_overrides/mock_ipv6_port_service.dart';
import '../../mocks/provider_overrides/mock_local_network.dart';
import '../../mocks/provider_overrides/mock_static_routing.dart';
import '../../mocks/provider_overrides/mock_statistics.dart';
import '../../mocks/provider_overrides/mock_system_log.dart';
import '../../mocks/provider_overrides/mock_login.dart';
import '../../mocks/provider_overrides/mock_menu.dart';
import '../../mocks/provider_overrides/mock_pnp.dart';
import '../../mocks/provider_overrides/mock_port_forwarding.dart';
import '../../mocks/provider_overrides/mock_remote_assistance_confirm.dart';
import '../../mocks/provider_overrides/mock_router_assistant.dart';
import '../../mocks/provider_overrides/mock_topology.dart';
import '../../mocks/provider_overrides/mock_wifi_settings.dart';
import '../../mocks/test_data/scenes/devices_scene_data.dart';
// Both scene files export a top-level `dataState`, so both are prefixed rather
// than one — a bare `dataState()` beside a `pf.dataState()` reads as the same
// fixture twice, and picking the wrong one is exactly the confusion the
// `_scene_data` naming convention exists to prevent (CLAUDE.md, testing structure).
import '../../mocks/test_data/scenes/dhcp_scene_data.dart' as dhcp;
import '../../mocks/test_data/scenes/login_scene_data.dart';
import '../../mocks/test_data/scenes/pnp_scene_data.dart';
import '../../mocks/test_data/scenes/port_forwarding_scene_data.dart' as pf;
import '../../mocks/test_data/scenes/topology_scene_data.dart';
import '../../mocks/test_data/scenes/wifi_settings_scene_data.dart';
import 'page_surface_family.dart';

/// `page.dhcp` — the plain-form end of the bracket.
///
/// The fixture is the golden suite's `reservations_list` state: a populated
/// reservation list plus active leases, which is the widest of the three states
/// that page has (`empty` renders one placeholder row and would under-measure the
/// table).
///
/// ## The one exemption from the loader rule
///
/// Every case below forbids [AppLoader] except the one named in
/// [kPagesWhoseLoaderIsContent] — see there. The exemption is a value for the same
/// reason the premises are: `page_surface_family_test.dart` drives both branches off
/// it and pins its membership, so widening it is an edit someone has to make in a
/// named diff rather than a `forbids` list that quietly lost an entry.
///
/// All three cards are required, not just one. They are three independent
/// presentations — an info grid, a lease table and a reservation table — and each
/// is fed by a different provider, so requiring only the first would leave the
/// other two free to fall back to a spinner unnoticed.
final kDhcpPageCase = PageSurfaceCase(
  id: 'dhcp',
  view: () => const UspDhcpDetailView(),
  overrides: () => dhcpDetailOverrides(
    reservationState: dhcp.dataState(),
    lanInfo: dhcp.testLanInfo,
    clients: dhcp.testClients,
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

// ===========================================================================
// Wave 1 (#1377) — the five pages whose fixture was already written
// ===========================================================================
//
// Why these five and not five others: each is a `List<Override>` builder that
// already existed in `test/mocks/provider_overrides/`, so the wave's fixture cost
// is zero and what it validates is the wave *process* at the lowest price the epic
// can pay. #1370 then measured all six candidates through this family's own
// geometry, and `usp_statistics_view` dropped out — its builder exists and does not
// get that view past its loader, which is precisely the distinction `requires`
// exists to make. It is re-queued into #1380 with a fixture scope attached.
//
// Each fixture below is the *widest* state its builder offers, for the reason
// `kDhcpPageCase` states: an empty-list state renders a placeholder row and
// under-measures the page it is standing in for.

/// `page.device_list` — the most expensive page in the wave (49.5ms/cell, #1370).
///
/// `allDevices`, not `[]`: the empty state renders one [DetailEmptyBlock] where the
/// populated one renders a [UspDeviceListTile] per device, and the tile is the
/// widget that responds to width.
///
/// The premise names two widgets on two different providers. [UspDeviceListTile]
/// comes from `filteredDeviceListProvider` and [UspDeviceStatusSegmented] from
/// `deviceFilterOptionsProvider`, so requiring only the first would leave the
/// filter row free to vanish while the list still rendered.
///
/// Neither [UspDeviceFilterPanel] (desktop) nor `UspDeviceFilterChipBar` (mobile)
/// can be a premise here, and the reason generalises to every responsive page in
/// this family: a `requires` entry has to hold at **every** width in
/// `kPageSweepWidths` — nine since #1372 — and those two are on opposite sides of
/// the `AppResponsiveLayout` breakpoint. #1377 measured the panel at four of the
/// eight widths that existed then, which is four short of a premise either way.
final kDeviceListPageCase = PageSurfaceCase(
  id: 'device_list',
  view: () => const UspDeviceListView(),
  overrides: () => devicesListOverrides(devices: allDevices),
  requires: const [UspDeviceListTile, UspDeviceStatusSegmented],
  forbids: const [AppLoader],
);

/// `page.device_detail` — 33.7ms/cell (#1370).
///
/// `wifiDetailNoReservation` is the fixture `usp_device_detail_speed_card_overflow_test.dart`
/// picked and for the same reason: it carries **both** a downlink and an uplink
/// rate, so the page renders two [DetailSpeedCard]s side by side at half width
/// each. A single-rate fixture renders one full-width card that cannot overflow,
/// which is the shape that made #1302 invisible to the golden suite.
///
/// So this page's premise doubles as the regression guard for that fix: both
/// required widgets live in the Wi-Fi details card, which the view builds only when
/// `device.shouldShowWifiDetails`, and both are absent from the `device == null`
/// path. That path is why `forbids: [AppLoader]` is the weaker of the two
/// directions here — this view has no loader at all; its degenerate tree is a
/// centred "device not found" column. [PageSurfaceCase.requires] is what catches
/// it.
final kDeviceDetailPageCase = PageSurfaceCase(
  id: 'device_detail',
  view: () => UspDeviceDetailView(mac: wifiDetailNoReservation.device!.mac),
  overrides: () => deviceDetailOverrides(detail: wifiDetailNoReservation),
  requires: const [UspSignalStrengthIndicator, DetailSpeedCard],
  forbids: const [AppLoader],
);

/// `page.topology` — 28.7ms/cell (#1370).
///
/// `meshNetworkDevicesData`, not `singleNodeDevicesData`: the mesh state renders a
/// gateway plus extenders plus their clients, so the tree the ui_kit [AppTopology]
/// lays out is the wider of the two the golden suite covers.
///
/// [AppTopology] is the premise, and this is the page where a premise earns its
/// keep most visibly. `usp_topology_view.dart:57` returns `SizedBox.shrink()` when
/// `systemInfoDataProvider` has no model — a *zero-sized* tree, which is even more
/// reliably green than a loader. Requiring the topology widget is what makes a
/// dropped `systemInfoData` override fail instead of sweeping 208 empty cells.
final kTopologyPageCase = PageSurfaceCase(
  id: 'topology',
  view: () => const UspTopologyView(),
  overrides: () => topologyViewOverrides(
    devicesData: meshNetworkDevicesData,
    systemInfoData: testSystemInfoData,
  ),
  requires: const [AppTopology],
  forbids: const [AppLoader],
);

/// `page.node_detail` — 33.5ms/cell (#1370).
///
/// `slaveNodeWithBackhaulTiming`, the widest of the seven states the golden suite
/// covers: a **slave** node is what gets the backhaul card built at all
/// (`node is SlaveNode`), a Wi-Fi `mediaType` plus a `signalStrength` is what gets
/// its two-tile interface row instead of the single ethernet block, a non-zero
/// `phyRate` builds the PHY-rate tile and a `lastContactTime` builds the tile beside
/// it. `masterNodeWithDevices` skips the backhaul card entirely and
/// `nodeNotFoundState` renders the not-found column.
///
/// It is a getter over `DateTime.now()` rather than a fixed date, and that is
/// load-bearing here for a different reason than in the golden suite: the tile
/// renders through `DateFormatUtils.formatRelativeTime`, whose `Just now` branch is
/// the only one whose *string length* does not drift day to day — and a string
/// length that drifts is a width that drifts, in 26 locales.
///
/// **What this fixture does not reach, recorded rather than papered over.** The
/// backhaul throughput row is `if (uplinkRate != null || downlinkRate != null)`
/// (`usp_node_detail_view.dart:400`) — *not* `phyRate`, which is what an earlier
/// draft of this case assumed. No existing `UspNodeDetailState` carries either
/// rate, so no [DetailSpeedCard] renders on this page in any of the 234 cells, and
/// #1377 may not write a fixture that would (its own out-of-scope list). So the
/// row stays unmeasured here and is a later wave's fixture scope. The premise
/// caught the assumption at all 26 locales of the first width, which is the
/// argument for `requires` being a value stated up front.
///
/// The premise therefore takes one widget from each card the fixture *does* unlock:
/// [BackhaulSignalIndicator] (the backhaul card's signal tile) and
/// [UspDeviceListTile] (the connected-devices card). Two cards, two chances to
/// notice the fixture went thin.
final kNodeDetailPageCase = PageSurfaceCase(
  id: 'node_detail',
  view: () =>
      UspNodeDetailView(deviceId: slaveNodeWithBackhaulTiming.node!.deviceId),
  overrides: () => nodeDetailOverrides(slaveNodeWithBackhaulTiming),
  requires: const [BackhaulSignalIndicator, UspDeviceListTile],
  forbids: const [AppLoader],
);

/// `page.port_forwarding` — the cheapest page in the wave (22.5ms/cell, #1370) and
/// the only one that did **not** arrive at zero.
///
/// #1370's sweep found `usp_single_port_tab.dart:30` over by up to 70px in 9 of the
/// 208 cells: the tab's header `Row` gave its title no flex constraint, so a locale
/// whose `singlePortForwarding` is long pushed the add-button off the right edge.
/// §8 admits a page only at zero and forbids opening an allowlist entry for one, so
/// the title was wrapped in an `Expanded` **in the widget** and this case landed
/// with the fix, not beside it — the same order #1349 took for
/// `usp_dhcp_reservations_detail_card.dart`.
///
/// `dataState()` over `emptyDataState`: it carries two single-port rules, so the
/// rule rows are measured rather than a [DetailEmptyBlock] standing in for them.
/// Not `dirtyState()` — a dirty page also renders the bottom save bar, which is
/// page chrome the #1314/#1328 sweep already owns.
///
/// Only tab 0 is measured, for the reason `kWifiSettingsPageCase` gives about its
/// own second tab: the other two tabs are behind a `TabController` and would each
/// need a tap per cell, which is a second axis this wave does not buy.
/// [UspSinglePortTab] is therefore both the premise and the tab under measurement,
/// and it is on the loaded path only — `_buildTabContent` returns an [AppLoader]
/// while `status.isLoading` and a `ServiceErrorView` on error.
final kPortForwardingPageCase = PageSurfaceCase(
  id: 'port_forwarding',
  view: () => const UspPortForwardingDetailView(),
  overrides: () => portForwardingOverrides(pf.dataState()),
  requires: const [UspSinglePortTab],
  forbids: const [AppLoader],
);

// ===========================================================================
// Wave 2 (#1378) — the instant_setup flow, all nine of its reachable pages
// ===========================================================================
//
// A different kind of wave. Wave 1's five pages were *destinations*: each fetches,
// and its provider's state is "loading" then "loaded". These are the screens of a
// **state machine** — nine views over one `pnpProvider`, where the phase decides
// not merely whether a page has data but which page-sized tree it renders. So a
// fixture here is a phase, and `test/mocks/test_data/scenes/pnp_scene_data.dart`
// holds three composed `PnpState`s that all eight cases below draw from, through
// the single `pnpOverrides()` builder.
//
// **The fixture count, restated as a number (#1378 AC 3).** #1370's inventory said
// 2 of 9 would need a fixture. Reading the nine views says **6 of 9 need a pinned
// phase** and 3 need nothing — but all six are served by *one* override builder
// and three shared states, so the cost is one fixture file, not six. The six are
// the ones that read `pnpProvider` on their build path; the three that need
// nothing are `pnp_isp_settings` (reads it only while `_dhcpSaving`) and the two
// pure `StatelessWidget`s. #1369's projection should be corrected in that shape:
// more pages need a phase pinned than #1370 predicted, and the per-page fixture
// cost is lower than it assumed.
//
// **Nine, after a day at eight.** `pnp_setup` shipped `queued` because the wizard
// renders ui_kit's `AppStepper`, whose bar variant overflowed by `stepCount × 4` at
// every width in every locale — 208 of 208 cells at +12.0px — and the fix was in
// ui_kit rather than here. It was filed as `linksys/privacyGUI-UI-kit#70`, fixed
// there by `936c1da6` (the bar row is divided with `Expanded` instead of a measured
// width), released as **v2.40.2**, and the tripwire that pinned the arithmetic in
// `test/page/instant_setup/views/pnp_setup_view_test.dart` went red on the bump with
// an **empty** incident list — the signal it was written to give. So the last case
// below is the ninth, and the order it appears in is the order it was onboarded
// rather than the order the flow runs (see [kPageSurfaceCases]). `pnp_complete`
// stays excluded as unreachable, unchanged from #1370.

/// `page.pnp_entry` — the flow's front door, pinned at its one loader-free phase.
///
/// Three of this view's four branches are a loader: `_buildLoading` is a bare
/// [AppLoader] and `_buildCheckingInternet` is an [AppCard] *containing* one, so
/// the blanket `forbids: [AppLoader]` rule leaves exactly `AdminReadFailure` — the
/// error card, and also the widest of the four (an icon, a wrapped message, a text
/// button).
///
/// The override is doing more here than picking a branch. `initState` fires
/// `startPostLoginFlow()` in a microtask, which on a real notifier reaches
/// `ref.read(uspClientProvider)!` and lands the flow in `AdminReadFailure` **via
/// its own null-check failure** — a page that looks measured while it is really
/// measuring a crash. `FixedPnpNotifier` no-ops that transition, so the phase
/// under measurement is the phase this case named.
final kPnpEntryPageCase = PageSurfaceCase(
  id: 'pnp_entry',
  view: () => const PnpEntryView(),
  overrides: () => pnpOverrides(pnpAdminReadFailureState),
  requires: const [AppCard, AppButton],
  forbids: const [AppLoader],
);

/// `page.pnp_isp_settings` — the ISP-type hub: three tappable option cards.
///
/// One of the three pages in this wave that needs **no** fixture, and the case
/// says so with an empty override list rather than pinning a phase it does not
/// read. `build` watches `pnpProvider` only inside `_dhcpSaving ? … : null`, so at
/// rest this page is provider-independent — the real `PnpNotifier.build()` returns
/// `PnpState.initial()` and touches no service.
///
/// [PnpIspSavingProgress] is forbidden for that reason: it is the one tree that
/// replaces the whole page, and its absence is what makes "at rest" a checked
/// claim instead of an assumption about a `bool` field's initial value.
final kPnpIspSettingsPageCase = PageSurfaceCase(
  id: 'pnp_isp_settings',
  view: () => const PnpIspSettingsView(),
  overrides: () => const [],
  requires: const [AppCard],
  forbids: const [AppLoader, PnpIspSavingProgress],
);

/// `page.pnp_no_internet` — the troubleshooter hub.
///
/// The tree does not depend on the phase, so pinning `NoInternet` is not what gets
/// the page to render — it is what makes the branch a *decision*. Unpinned, this
/// page renders the same thing because `AdminCheckingInternet` happens to fail the
/// two `is` checks in `ref.listen`, and a fixture that is right by coincidence is
/// one nobody notices going wrong.
///
/// Both required widgets are here because they are on opposite sides of the page:
/// [AppCard] is the two option cards and [AppButton] is the two text buttons
/// beneath them, so a `Column` that lost its tail would still satisfy the first.
final kPnpNoInternetPageCase = PageSurfaceCase(
  id: 'pnp_no_internet',
  view: () => const PnpNoInternetView(),
  overrides: () => pnpOverrides(pnpNoInternetState),
  requires: const [AppCard, AppButton],
  forbids: const [AppLoader],
);

/// `page.pnp_pppoe` — the PPPoE form, prefilled and with its VLAN row open.
///
/// This is the page where the fixture changes what is measured rather than whether
/// anything is. `_prefillFromCurrentSettings` runs in `initState` and reads **only**
/// `NoInternet.currentWanSettings`; without it every field renders empty, and
/// `vlanEnabled` is what flips `_showVlan` and adds the VLAN label and field at
/// all. An unpinned fixture would sweep 234 cells of a shorter form than any real
/// user sees — the same under-measurement `kDhcpPageCase` warns about with its
/// empty-list state.
///
/// The premise names both field types because they are different widgets with
/// different intrinsic widths ([AppPasswordInput] carries a trailing reveal
/// button), plus the save button that closes the form.
final kPnpPppoePageCase = PageSurfaceCase(
  id: 'pnp_pppoe',
  view: () => const PnpPppoeView(),
  overrides: () => pnpOverrides(pnpNoInternetState),
  requires: const [AppTextField, AppPasswordInput, AppButton],
  forbids: const [AppLoader, PnpIspSavingProgress],
);

/// `page.pnp_static_ip` — the static-IP form, prefilled and with DNS expanded.
///
/// Same fixture and the same argument as [kPnpPppoePageCase], one field type
/// further: a non-empty `dnsServer1`/`dnsServer2` flips `_showDns`, which adds two
/// more [AppIpv4TextField]s to the three the form always has. Five labelled IPv4
/// fields in 26 locales is the widest this page gets.
final kPnpStaticIpPageCase = PageSurfaceCase(
  id: 'pnp_static_ip',
  view: () => const PnpStaticIpView(),
  overrides: () => pnpOverrides(pnpNoInternetState),
  requires: const [AppIpv4TextField, AppButton],
  forbids: const [AppLoader, PnpIspSavingProgress],
);

/// `page.pnp_unplug_modem` — step 1 of the modem-restart flow.
///
/// A pure [StatelessWidget] with no provider at all, so the empty override list is
/// the whole fixture. Its tip card's `Row` is the width-sensitive part: an icon, an
/// `Expanded` body and a chevron, with a tip string that triples in length in some
/// locales.
///
/// The tip **dialog** is not measured. It is behind a tap, and a dialog is a
/// surface of its own rather than a wider version of this page — the gate's own
/// §8 argument for why a new surface earns a new probe rather than a wider sweep.
final kPnpUnplugModemPageCase = PageSurfaceCase(
  id: 'pnp_unplug_modem',
  view: () => const PnpUnplugModemView(),
  overrides: () => const [],
  requires: const [AppCard, AppButton],
  forbids: const [AppLoader],
);

/// `page.pnp_modem_lights_off` — step 2 of the modem-restart flow.
///
/// Structurally [kPnpUnplugModemPageCase]'s twin — same shell, same tip card, a
/// different illustration and different strings. Both are declared rather than one
/// standing in for the other, because "different strings" is the entire axis this
/// family sweeps: they are the same layout only until a locale makes one of the two
/// tip strings wrap and the other not.
final kPnpModemLightsOffPageCase = PageSurfaceCase(
  id: 'pnp_modem_lights_off',
  view: () => const PnpModemLightsOffView(),
  overrides: () => const [],
  requires: const [AppCard, AppButton],
  forbids: const [AppLoader],
);

/// `page.pnp_waiting_modem` — step 3, at its instruction stage.
///
/// Three stages share this view and the phase picks between them: `NoInternet`
/// renders the plug-back-in instruction, `ModemRestartCountdown` a
/// [CircularCountdownWidget] and `ModemRestartCheckingInternet` a spinner. Only the
/// first is a page-shaped tree; the other two are centred fixed-size boxes.
///
/// So both forbids are load-bearing rather than ceremonial, and they are the reason
/// this page is pinned even though its instruction stage is also what an unpinned
/// fixture happens to render: [AppLoader] rules out the checking stage and
/// [CircularCountdownWidget] the countdown, which together are the only two ways
/// this case could be measuring 234 cells of something that cannot overflow.
final kPnpWaitingModemPageCase = PageSurfaceCase(
  id: 'pnp_waiting_modem',
  view: () => const PnpWaitingModemView(),
  overrides: () => pnpOverrides(pnpNoInternetState),
  requires: const [AppButton],
  forbids: const [AppLoader, CircularCountdownWidget],
);

/// `page.pnp_setup` — the wizard, at step 0 of its three-step split-mode form.
///
/// Wave 2's ninth, declared a day after the other eight and for a reason worth
/// keeping: it was never fixture debt. `pnpWizardConfiguringState` got this view
/// past its loader from the first attempt, and #1378 swept all 208 cells through it
/// — all 208 red at +12.0px, on a defect in ui_kit's `AppStepper` rather than in
/// anything this repo can edit (`linksys/privacyGUI-UI-kit#70`, fixed by `936c1da6`
/// in v2.40.2). §8's graduation rule is what kept the page out in the meantime: a
/// whole page of debt cannot enter the gate, and the one fixture that laid out clean
/// was a single-step wizard, i.e. one rendering no `AppStepper` at all.
///
/// [AppStepper] is therefore the premise that matters most here, and it is doing two
/// jobs. It pins that the wizard has **more than one step** — `_buildStepperForm`
/// renders no stepper when `totalSteps == 1` — which is the fixture workaround this
/// page was explicitly forbidden from taking, and it puts the regression test for
/// #70 in the gate: 234 cells of the widget that was over by `stepCount × 4` at
/// every one of them.
///
/// The two field types are the other half, and they pin the *step*. Only step 0 is
/// measured (`_currentStep` is widget state, and advancing it needs a tap per cell —
/// the same second axis `kWifiSettingsPageCase` declines), and step 0 is the only
/// one that renders a form: [AppTextField] and [AppPasswordInput] per band, three
/// bands deep because `pnpSplitWifiConfig` is split-mode. A premise naming only
/// `AppStepper` would hold against a wizard whose step content had gone missing.
final kPnpSetupPageCase = PageSurfaceCase(
  id: 'pnp_setup',
  view: () => const PnpSetupView(),
  overrides: () => pnpOverrides(pnpWizardConfiguringState),
  requires: const [AppStepper, AppTextField, AppPasswordInput],
  forbids: const [AppLoader],
);

// ===========================================================================
// Wave 3 (#1379) — the six entry surfaces
// ===========================================================================
//
// A third kind of wave. Wave 1's five were destinations that fetch; wave 2's nine
// were the screens of one state machine. These six are what a user sees **before**
// there is a session: the landing page, the three local-login pages, the menu the
// dashboard hands off to, and the first-login firmware screen. What they have in
// common is that four of the six read a provider that is a **USP-mode stub** —
// `routerPasswordProvider` and `autoParentFirstLoginProvider` return hardcoded
// values today — so a fixture here pins a *branch* rather than a payload, and two of
// the four pages have no loading state at all.
//
// **The prediction #1379 was filed on was falsified, and that is the wave's main
// finding.** #1370's inventory said to expect finds here, on the grounds that login
// pages are narrow-column forms in 26 locales. It then swept the five measurable
// ones and found all five at zero across every width and locale, and this wave
// re-confirms that at 9 widths: **no widget fix landed with these six.** So wave 3
// is five declarations and one fixture, and the cost of a wave is not predictable
// from how form-like its pages look.
//
// **The sixth is the 45th file.** `auto_parent_first_login_view.dart` sits one
// directory deeper than the roster's other login pages and was the one page #1370
// could not measure. It needed the wave's only new *behavioural* fixture and it is
// the one page in the whole family whose loader is content — see
// [kAutoParentFirstLoginPageCase] and [kPagesWhoseLoaderIsContent].

/// `page.home` — the landing page, and the cheapest page in the family
/// (13.8ms/cell, #1370).
///
/// No overrides at all, and unlike [kPnpIspSettingsPageCase] that is not a claim
/// about a provider's initial state: this view watches nothing. Its `_isLoading` is a
/// `final bool = false`, so its `AppFullScreenLoader` branch is dead code — which is
/// exactly why `forbids: [AppLoader]` is worth stating here. `AppFullScreenLoader`
/// *contains* an [AppLoader], so the blanket rule catches that branch coming back to
/// life without this case naming a second type.
///
/// The premise is the two halves of the page, which are structurally unrelated: the
/// [SvgPicture] is the wordmark that is the entire body, and the [AppButton] is the
/// footer's login button. The footer also carries a `FutureBuilder` over
/// `getVersion()` whose `initialData` is `'-'`, so the version line renders in every
/// cell whether the plugin resolves or not — no type of its own to require, and
/// nothing to wait for either.
final kHomePageCase = PageSurfaceCase(
  id: 'home',
  view: () => const HomeView(),
  overrides: () => const [],
  requires: const [SvgPicture, AppButton],
  forbids: const [AppLoader],
);

/// `page.login_local` — the local login form, on a router that has a password hint
/// (23.3ms/cell, #1370).
///
/// Two overrides doing two different jobs, and only one of them is about layout.
///
/// `sessionProvider` is what makes the cell measurable at all. `initState` calls
/// `session.fetchDeviceInfoAndInitializeServices()`, which on the real notifier
/// reaches `sessionServiceProvider` and throws
/// `Service not initialized: USP service not available` — an exception, so the cell
/// fails rather than under-measures. Nothing the view renders depends on the result.
///
/// `authProvider` is the layout half, and it is a *sharpening* of
/// `commonOverrides()`'s shared default rather than a duplicate of it: that one is
/// fixed at `AuthState.empty()`, whose null `localPasswordHint` drops the
/// [AppExpansionPanel] from the card entirely. A hintless router is a real state, but
/// it is the narrower one, so [localLoginWithHintState] is the fixture for the same
/// reason [kDhcpPageCase] takes a populated list over an empty one.
///
/// The panel is therefore in `requires`, where it does double duty: it is a widget on
/// the loaded path, and it is the assertion that this case's own override reached the
/// view. Drop it and 234 cells measure a card one row shorter with nothing failing.
///
/// The `error:` branch of `state.when` is not measured and is not a gap this wave can
/// close: it calls `setErrorMessage` — a `setState` — *during build*, and pinning it
/// would mean measuring 234 cells of a tree that rebuilds itself while being laid
/// out.
final kLoginLocalPageCase = PageSurfaceCase(
  id: 'login_local',
  view: () => const LoginLocalView(),
  overrides: () => loginLocalOverrides(
    authState: localLoginWithHintState,
    deviceInfo: testLoginDeviceInfo,
  ),
  requires: const [AppPasswordInput, AppExpansionPanel, AppButton],
  forbids: const [AppLoader],
);

/// `page.local_router_recovery` — the recovery-key page, showing its error paragraph
/// (21.6ms/cell, #1370).
///
/// A page with no loading state and no loader, like [kDeviceDetailPageCase]: the
/// whole card is built unconditionally, so `forbids: [AppLoader]` is the weak
/// direction here and [AppPinInput] plus [AppButton] are what actually stand between
/// a measured page and a green empty one.
///
/// The fixture's job is the one thing on this page that *is* conditional:
/// `if (state.remainingErrorAttempts != null)` adds a two-line error paragraph under
/// the pin field. [routerRecoveryTwoAttemptsLeftState] pins it present, and which of
/// `_getErrorString`'s three branches is measured is argued at the scene rather than
/// here.
///
/// No type-level premise can see that paragraph — it is an `AppText` like the
/// description above it — so the pin lives in the scene file and in
/// `page_surface_family_test.dart`, which asserts the scene's field is non-null. That
/// is the honest shape for a premise a widget type cannot express, and stating it
/// beats requiring `AppText` and calling the page pinned.
final kLocalRouterRecoveryPageCase = PageSurfaceCase(
  id: 'local_router_recovery',
  view: () => const LocalRouterRecoveryView(),
  overrides: () => routerPasswordOverrides(routerRecoveryTwoAttemptsLeftState),
  requires: const [AppPinInput, AppButton],
  forbids: const [AppLoader],
);

/// `page.local_reset_router_password` — the new-password form (26.2ms/cell, #1370).
///
/// The widest form in the wave: two [AppPasswordInput]s and an [AppTextFormField],
/// each with its own localized label, above a save button. All three are required
/// because they are three different widgets with three different intrinsic widths,
/// and the retype field sits inside a `Focus` wrapper that a refactor could drop
/// without touching the first.
///
/// Like [kLocalRouterRecoveryPageCase] this view has no loader at all.
/// [routerPasswordValidState] pins the save button's enabled branch; the scene file
/// records both why that is pinned and the one part of this form the sweep does not
/// reach — the seven password rules, which ui_kit renders only on focus.
final kLocalResetRouterPasswordPageCase = PageSurfaceCase(
  id: 'local_reset_router_password',
  view: () => const LocalResetRouterPasswordView(),
  overrides: () => routerPasswordOverrides(routerPasswordValidState),
  requires: const [AppPasswordInput, AppTextFormField, AppButton],
  forbids: const [AppLoader],
);

/// `page.menu` — the ten-card menu grid, badges included (40.1ms/cell, #1370 — but
/// **23.0 measured**, and the wave's dearest page is the reset form at 26.4).
///
/// The one case in this file whose #1370 figure did not survive its own fixture. The
/// inventory measured this page with no overrides, where both providers below land in
/// `AsyncError`, and an error path costs a throw, a stack capture and a log line per
/// cell — so 40.1 was 234 cells paying for two failures each, not a heavy grid.
/// §11.11 draws the general rule out of it: a queued figure taken without a fixture is
/// an upper bound on the swept one, never a prediction of it.
///
/// Ten cards, not nine: the tenth is `if (kDebugMode)`'s usp-console item, and
/// `kDebugMode` is **true** under `flutter test`. So this sweep measures a grid one
/// row taller than a release build renders, which is the conservative direction and
/// worth knowing when a cell's height is read off a report.
///
/// The grid is the page's width story. `crossAxisCount` is 3 above the mobile
/// breakpoint and 1 below it, with a fixed `mainAxisExtent` either way — so a card's
/// content box is roughly a third of the content width on six of this family's nine
/// widths and all of it on the other three, and its title row has to hold a localized
/// title plus a badge in both shapes.
///
/// Which is why both providers are overridden. Each feeds one badge and each renders
/// it only when its own value is non-null; unoverridden, both `build()`s reach a USP
/// service, land in `AsyncError`, and the page renders ten cards with two of them
/// silently missing an [AppBadge]. [AppBadge] is in `requires` to make that a failure
/// rather than a slightly narrower measurement — see `mock_menu.dart`.
final kMenuPageCase = PageSurfaceCase(
  id: 'menu',
  view: () => const UspMenuView(),
  // `dhcp.testLanInfo` rather than a LAN fixture of the menu's own: the view reads
  // exactly one field off it (`dnsServers`), so a second composed `LanInfoUIModel`
  // would be eight lines restating a fixture that already exists to say the same
  // thing. The scene stays where its own page's cases can see it.
  overrides: () =>
      menuOverrides(lanInfo: dhcp.testLanInfo, privacyEnabled: true),
  requires: const [AppMenuCard, AppBadge],
  forbids: const [AppLoader],
);

/// `page.auto_parent_first_login` — the firmware-check screen, and the roster's 45th
/// file.
///
/// The one page #1370 could not measure, for two reasons it recorded as one. It is a
/// directory deeper than the other login views, so the inventory's glob found it and
/// its `-` in the roster meant *no fixture gets this past its opening state*. And the
/// opening state is the only state: this screen exists to say "we are installing
/// firmware, do not unplug the router".
///
/// **So this is the family's one loader-is-content page**, and the exemption it takes
/// from the blanket `forbids: [AppLoader]` rule is declared in
/// [kPagesWhoseLoaderIsContent] rather than by omitting an entry here. [AppLoader] is
/// in `requires` instead, which is the same fact stated in the direction that can
/// fail: on this page a spinner is not the sign that a fixture went thin, it is the
/// page.
///
/// [AppCard] is the premise that does the work. The two localized paragraphs beside
/// the loader have no type of their own, and the card is what a cell that lost this
/// page would lack — which is a live risk here rather than a theoretical one. The
/// real `checkAndAutoInstallFirmware()` returns **false**, and false makes the view
/// call `finishFirstTimeLogin` and then `context.goNamed(RouteNamed.dashboardHome)`,
/// a route this family's single-route host does not have. `firmwareAvailable: true`
/// is what keeps the page mounted; `mock_login.dart` argues why that is the honest
/// branch and not merely the convenient one.
final kAutoParentFirstLoginPageCase = PageSurfaceCase(
  id: 'auto_parent_first_login',
  view: () => const AutoParentFirstLoginView(),
  overrides: () => autoParentFirstLoginOverrides(firmwareAvailable: true),
  requires: const [AppLoader, AppCard],
  forbids: const [],
);

// ## Wave 4 (#1380): the last twenty-one, and what "the last" cost
//
// The wave that closes the epic, so it is the one that has to account for every
// row rather than pick the tractable ones. Its shape is set by #1370's inventory
// finding, not by a theme: **13 of the 21 had no fixture that got the view past
// its loader**, which is a different kind of work from wave 3's declarations and is
// why this wave is written in two slices — the eight pages that already render,
// then the thirteen that needed a fixture first.
//
// The four exclusion candidates are argued in `test/fixtures/page_roster.tsv` and
// §11.12, and three of the four were **kept**. Only unreachability excludes a page
// here, and only two rows in the register meet it.

/// `page.advanced_settings` — six navigation rows, and the wave's first widget fix
/// (16.9ms/cell, #1370).
///
/// The cheapest page in the wave and the only one of the 21 that needs no overrides
/// at all: a `StatelessWidget` that watches nothing and builds six
/// [AppSectionItemData] literals. So [LayoutBlock] in `requires` is not standing in
/// for a provider having resolved — there is no provider — it is standing for the
/// body having been built at all, which is what a cell that lost the page to its
/// chrome would lack.
///
/// It is also the page that shows why a premise of one type is enough *here* and
/// would not be elsewhere: all six rows are the same widget with a different
/// localized title, so requiring a second type would pin nothing a refactor could
/// break independently.
///
/// **The fix that landed with it** is `usp_advanced_settings_view.dart:110`, one of
/// #1370's five open sites. `_buildCard`'s `Row` held an [AppText] and a chevron with
/// no flex on either, so a long localized title pushed the icon past the row — the
/// same shape #1349 fixed in the reservations card and #1377 fixed in the single-port
/// tab, and the same trade: an overflow becomes a **wrap**, which no cell in this
/// family can see. So it carries a readability guard in
/// `test/page/_shared/page_surface_overflow_test.dart`, beside the other two.
final kAdvancedSettingsPageCase = PageSurfaceCase(
  id: 'advanced_settings',
  view: () => const UspAdvancedSettingsView(),
  overrides: () => const [],
  requires: const [LayoutBlock],
  forbids: const [AppLoader],
);

/// `page.remote_assistance` — the CA's session-confirmation card (13.3ms/cell,
/// #1370).
///
/// The page a Linksys agent lands on from an emailed link, and the wave's one page
/// whose fixture is a service rather than a state — `mock_remote_assistance_confirm.dart`
/// argues both that and why the session is `pending`.
///
/// The two constructor arguments are the premise as much as the overrides are. Both
/// default to `''`, and `''` sends `build` down `_buildMissingParamsView` before it
/// reads a provider at all — a centred icon and two paragraphs, which is a page that
/// cannot overflow and would have made all 234 cells green over nothing. So they are
/// passed non-empty here, and [AppButton] in `requires` is what proves it: the retry
/// button exists only on the validated-with-error path, so a cell that fell back to
/// the missing-params screen fails rather than under-measures.
///
/// No loading state to forbid in the usual sense — the validating branch renders a
/// bare [CircularProgressIndicator], not an [AppLoader] — but the blanket rule is
/// kept for the reason [kHomePageCase] keeps it: it costs nothing and it catches a
/// refactor that swaps in the ui_kit component.
final kRemoteAssistancePageCase = PageSurfaceCase(
  id: 'remote_assistance',
  view: () => const RemoteAssistanceConfirmView(
    sessionId: 'gate-session-0001',
    token: 'gate-token',
  ),
  overrides: () =>
      remoteAssistanceConfirmOverrides(sessionInfo: gateSessionPendingInfo),
  requires: const [AppCard, AppButton],
  forbids: const [AppLoader],
);

/// `page.support` — the FAQ page (41.0ms/cell, #1370).
///
/// Five [AppExpansionPanel]s over a static `faq_data.dart` list, then two
/// [LayoutBlock] rows — the remote-assistance entry point and the visit-support
/// footer — each an icon, an `Expanded` two-line column and a trailing chevron. Both
/// types are required because they are the page's two halves and neither implies the
/// other: the accordions come from a `static final` list that cannot fail, so
/// [AppExpansionPanel] alone would pass on a page whose bottom half had vanished.
///
/// The one override is not a layout fixture, and `mock_remote_assistance_confirm.dart` says
/// so in the two directions it *is* one — the per-cell cost of two `AsyncError`s, and
/// which state of the page is the honest one to pin.
///
/// ## What this case does not measure, stated rather than implied
///
/// `AppExpansionPanel` builds its content behind `if (widget.isExpanded)`, and this
/// view passes no `initialExpandedIndices` — so all five panels are collapsed in
/// every cell and **no FAQ answer is ever laid out**. The answers are the page's
/// longest strings and each is an `Expanded` text beside a 16px external-link icon,
/// so this is a real gap rather than a technicality.
///
/// It is also not one a provider override can close: the expansion state is the
/// widget's own `ValueNotifier`, reachable only by tapping, and this family's runner
/// measures a settled tree without interacting with it (that is the dashboard card
/// sweep's `cardTabIndexProvider` trick, and there is no equivalent knob here). The
/// same shape as [kLocalResetRouterPasswordPageCase]'s seven password rules, which
/// ui_kit renders only on focus. Closing it needs an interaction axis in the runner,
/// which is a change to `sweep.dart` and not to this list.
final kSupportPageCase = PageSurfaceCase(
  id: 'support',
  view: () => const UspSupportView(),
  overrides: () => deviceCredentialsOverrides(),
  requires: const [AppExpansionPanel, LayoutBlock],
  forbids: const [AppLoader],
);

/// `page.unified_diagnostics` — the diagnostics landing step (17.8ms/cell, #1370).
///
/// No overrides, and here that is a claim about a provider's initial state rather
/// than about the page watching nothing. `UnifiedDiagnosticsNotifier.build()` returns
/// `const UnifiedDiagnosticsState()` synchronously — `step` defaults to
/// `DiagnosticStep.idle` — and nothing in `build` touches
/// `unifiedDiagnosticsServiceProvider`, so the `switch (state.step)` in the view lands
/// on `DiagnosticStartView` with no service reached and no error path taken. The other
/// eight steps all require a run, which requires a `DiagnosticScope` from a real
/// executor; they are not reachable from a provider override and are not measured
/// here.
///
/// [DiagnosticStartView] is in `requires` rather than a ui_kit type, and this is the
/// one case in the family where the premise names a page-private view: it *is* the
/// step pin. `AppCard` would be satisfied by six of the nine steps, so requiring it
/// would leave the sweep free to measure whichever one a default-state change landed
/// on, which is precisely the drift a premise exists to catch.
///
/// **The fix that landed with it** is `diagnostic_start_view.dart:125`, #1370's
/// widest single site at +74px over 9 cells. `_PrimaryAction`'s `Row` already had an
/// `Expanded` on its text column, so the overflow was not a missing flex — it was the
/// trailing [AppButton], whose intrinsic width is a localized label plus padding and
/// which a tight `Expanded` sibling cannot squeeze. See the view for the shape the fix
/// took and why it is not a third instance of the wrap trade.
final kUnifiedDiagnosticsPageCase = PageSurfaceCase(
  id: 'unified_diagnostics',
  view: () => const UnifiedDiagnosticsView(),
  overrides: () => const [],
  requires: const [DiagnosticStartView, AppCard, AppButton],
  forbids: const [AppLoader],
);

/// `firmware_update_view` — the manual firmware flow's landing phase.
///
/// Three stacked cards and a footnote: a router status card (56px image, model and
/// serial in an `Expanded` column, then a list of firmware banks), the OTA check card,
/// the phase-driven action card, and an icon-plus-`Expanded`-text warning note. Every
/// one of those is a `Row` whose fixed child is an icon or an image and whose flexible
/// child is a localized string, which is the shape this whole wave has been fixing.
///
/// **`forbids: [AppLoader]` earns its keep here**, which is worth saying because on
/// five of wave 3's six pages it was inert (§11.11). This page has *six* reachable
/// loaders: `_buildLoadingBanks` renders one whenever the banks list is empty and still
/// fetching, and five of the nine phases render a linear one. So a fixture that lost
/// either the banks override or the notifier override would land on a spinner, and the
/// `forbids` is what turns that into a failure instead of 234 green cells.
///
/// **The fixture pins the notifier, not just the data** — `mock_firmware_update.dart`
/// says why: `initState` posts a frame callback that calls `loadBanks()`, so without
/// that override the state a cell measures is decided by which frame the sweep settles
/// on.
///
/// **The fix that landed with it** is `firmware_update_view.dart:546`, the `Row` in
/// `_OtaCheckCard` and the wave's widest site: **50 of 234 cells**, all 26 locales at
/// 320px, worst `ru` at +357px and `en` itself at +160px. It is also the one site
/// where the obvious fix was wrong — the sibling card twenty lines up lays two buttons
/// out in a `Wrap`, but neither of *these* two children fits a 256px line alone, and
/// `RenderWrap` reports nothing when a child does not fit. Copying the sibling would
/// have turned a reported overflow into an unreported one. The view says what landed
/// instead and why the button changes size when it stacks.
final kFirmwareUpdatePageCase = PageSurfaceCase(
  id: 'firmware_update',
  view: () => const FirmwareUpdateView(),
  overrides: () => firmwareUpdateOverrides(),
  requires: const [AppCard, AppButton],
  forbids: const [AppLoader],
);

/// `router_assistant_view` — the AI assistant's configuration screen.
///
/// The one page in the family that builds its own `Scaffold` and Material `AppBar`
/// instead of going through the app's page chrome, which is why #1370 found a title
/// overflow here and nowhere else: the chrome sweep (#1314/#1328) measures
/// `AppTopBar`, and this page does not use it.
///
/// **Which of its two screens a cell measures, and why there is no choice.** `build`
/// returns the config screen while `_needsConfig`, the chat screen otherwise, and
/// `_needsConfig` is true for every cell because `dotenv` is never loaded in a widget
/// test — `mock_router_assistant.dart` argues that at length. The chat screen is not
/// merely unmeasured, it is unreachable: reaching it means constructing a
/// `RouterChatController`, whose first act is an AWS Bedrock call.
///
/// [AppPasswordInput] therefore carries the whole premise. It is the one widget of
/// the three that the chat screen cannot produce — the chat input is an
/// [AppTextField] and it has an [AppButton] too — so it is what fails if a future
/// edit makes the chat screen the default, or if the store override stops resolving
/// and the form is measured sealed.
///
/// **`forbids: [AppLoader]` is inert here**, as it was on five of wave 3's six pages
/// (§11.11): this view renders no [AppLoader] in either screen. While restoring, it
/// seals the inputs and relabels the button `loading` instead — a state the fixture
/// resolves inside the first frame, and one that a `forbids` could not have caught
/// anyway. Kept because the blanket rule is what makes an *exemption* argue for
/// itself; see [kPagesWhoseLoaderIsContent].
///
/// **The fix that landed with it** is `router_assistant_view.dart:409`, the wave's
/// only chrome site: 7 of 234 cells, all at 320px, `tr` worst at +89px. The title
/// needs a 409px screen to sit on one line, so the fix gives it a second line and
/// the toolbar the height for it below 420px. The view says why two lines beat both
/// an ellipsis and a smaller font, and the same edit covers the chat screen's copy
/// of the `Row` — which the gate does not measure and which this case's own doc
/// explains it cannot.
final kRouterAssistantPageCase = PageSurfaceCase(
  id: 'router_assistant',
  view: () => const RouterAssistantView(),
  overrides: () => routerAssistantOverrides(),
  requires: const [AppPasswordInput, AppTextField, AppButton],
  forbids: const [AppLoader],
);

/// `usp_test_console_view` — the raw USP CRUD / SSE / subscription debug console.
///
/// **The one page of 45 that needed no fixture at all.** Not because it reads no
/// providers — it reads three — but because all three answer null off the web:
/// `uspClientProvider` returns null when `!kIsWeb`, `sseManagerProvider` returns null
/// when the client is, and `sseConnectionStateProvider` then hands back
/// `Stream.value(SseConnectionState.disconnected)`. So `overrides` is empty by
/// argument rather than by omission, and the state every cell measures is the one a
/// developer sees when the console cannot find a session: manual connection fields
/// shown, `Not Connected` badge, `SSE Off` badge, one line in the log.
///
/// **Why it is in the gate at all**, which #1380 required a verdict on. It is a debug
/// tool behind `enableTestConsole`, so "exclude it, nobody ships it" was the obvious
/// call and it is wrong on two counts. The flag is settable at build time
/// (`--dart-define=test_console=true`) *and* at runtime from the config JSON, so a QA
/// build reaches this page; and the defect it was carrying was the worst kind the
/// gate finds — the only site of #1370's five that breaks in **`en`**, at every
/// locale, because the cause is a fixed two-pane layout rather than a long
/// translation. Excluding it would have cost exactly that: 52 found cells on the one
/// page whose overflow no translator could have caused.
///
/// **What the premise pins.** [Tr181AutocompleteField] is the page's own widget and
/// appears four times in the control pane, so it fails if the pane stops building.
/// [SelectionArea] is the log pane's only unique widget — the two panes are the page,
/// and after the fix below the narrow layout stacks them, so a future edit that drops
/// one pane would otherwise leave a green sweep over half a page. [AppButton] and
/// [AppTextField] are the ordinary content anchors.
///
/// **`forbids: [AppLoader]` is inert here**, the third time in two waves (§11.11):
/// this page has no loading state to render one in. Kept for the reason
/// [kPagesWhoseLoaderIsContent] gives.
///
/// **The fix that landed with it** is `usp_test_console_view.dart:1147`: **52 of 234
/// cells**, all 26 locales at 320px by +109px and all 26 at 480px by +29px. The two
/// panes were `Expanded(flex: 1)` with no narrow layout behind them, so a 320px screen
/// granted each 159px and the subscription dropdown 127px of the 236px its widest item
/// asks. The fix stacks them below 600px; the view's `_stackPanesBelow` says why 600
/// rather than the 537px the measurement strictly needs.
final kTestConsolePageCase = PageSurfaceCase(
  id: 'test_console',
  view: () => const UspTestConsoleView(),
  overrides: () => const [],
  requires: const [
    Tr181AutocompleteField,
    SelectionArea,
    AppTextField,
    AppButton,
  ],
  forbids: const [AppLoader],
);

/// `usp_sliver_dashboard_view` — the dashboard grid itself, and this family's most
/// expensive page by a factor of ten.
///
/// **The one page whose pieces were all already measured, and which is swept anyway.**
/// Its header is [DashboardHeaderBar], which the chrome sweep has pumped at every
/// screen width in every locale since #1314; its cards are the nineteen the #1183 card
/// sweep pumps at each one's narrowest realization. So the case for excluding it writes
/// itself, and it is wrong for a reason worth stating once: both of those sweeps
/// measure a piece in a box of the gate's own choosing. This one measures the
/// composition — the header at the page's `pageMargin`, and each card at the width the
/// *real* grid gives it, which is the widest realization rather than the narrowest,
/// under a `SliverDashboard` whose column count the controller re-derives per
/// breakpoint. A card that is clean at its narrowest 4-column slot and broken at its
/// 12-column one is invisible to every other suite in the gate.
///
/// **What it does not reach, said plainly.** `SliverDashboard` is a lazy sliver and
/// `kPageSweepHeight` is 1600px, so a cell builds the cards above the fold and stops:
/// measured, **4 of the 19 at 320–905px and 7 at 1080px and up**, in `createDefaultLayout`
/// order — the stats panel, device info, network status and topology, joined at the wide
/// widths by LAN info, ethernet ports and system status. The other twelve are measured by
/// the card sweep at their narrowest realization and by nothing at their widest. Raising
/// the height for one page is not something this family can express — `kPageSweepHeight`
/// is one number for 43 pages — and scrolling a cell is not something [runOverflowSweep]
/// does, so closing the gap is a §11 change rather than a fixture one. The 234 cells are
/// still worth their 15 seconds: the composition defect this sweep exists to catch is a
/// grid-width defect, and the grid is widest at the top.
///
/// **What the premise pins**, and here it earns its keep more than anywhere else in the
/// family. [DashboardHeaderBar] is the page's own header; [SliverDashboard] is the grid
/// engine, so it fails if the layout controller hands back nothing; [AppCard] is the
/// cards, so it fails if the factory builds none. Between them they say the three
/// layers this page is made of are all present — which is exactly the claim a fixture
/// this large can lose one layer of and stay green.
///
/// **One of the two cases that sets [PageSurfaceCase.needsMaterialAncestor]**, and what
/// the host then supplies is a bare `Scaffold`. Every other page in this list returns
/// its own — a `UiKitPageView`, a `StyledAppPageView` — so [pageSurfaceHost]'s
/// `LinksysRoute` is all the scaffolding they need. This page has none: in the app its
/// `Material` comes from `UspDashboardShell`, the `ShellRoute` above it
/// (`route_usp_dashboard.dart:5`). Pumped bare it throws `No Material widget found`
/// from every [AppCard]'s `InkWell` — 17 exceptions per cell, measured, and none of
/// them an overflow.
///
/// It is a flag and not a `Scaffold(body: …)` inside `view` because this case was
/// written the second way first, and it broke the #1382 roster oracle in both
/// directions on the day wave 4 finished the roster: the join reads
/// `view().runtimeType`, which was `Scaffold`, so this case resolved to no page file
/// and this page resolved to no case. See [PageSurfaceCase.view].
///
/// The wrapper is a `Scaffold` rather than the real shell for the reason the rest of
/// the family already settled: **no page here is pumped under the shell.** `device_list`,
/// `topology` and eleven others sit under the same `ShellRoute` in the app and are swept
/// without it, because the shell's content — the SSE banner, the bottom `MenuHolder`,
/// the mascot overlay, the theme-studio panel — belongs to none of them. Adding it here
/// alone would make this the one page measured with chrome the others are measured
/// without, and would pull SSE bootstrap, the mascot coordinator and the remote-assistance
/// guard into a fixture that today needs one override. What the shell contributes to
/// *this page's* geometry is a `Material` ancestor and a viewport shortened by the bottom
/// bar; the first is what `Scaffold` gives, and the second only removes height from a
/// page whose grid scrolls. The gap that leaves — the shell's own chrome is swept by
/// nothing — is real and is §11's, not this case's.
final kSliverDashboardPageCase = PageSurfaceCase(
  id: 'sliver_dashboard',
  view: () => const UspSliverDashboardView(),
  needsMaterialAncestor: true,
  overrides: () => dashboardPageOverrides(),
  requires: const [DashboardHeaderBar, SliverDashboard, AppCard],
  forbids: const [AppLoader],
);

/// `usp_dashboard_view` — the frame around [kSliverDashboardPageCase]: a top bar that
/// hides on scroll, and the three-way branch on the orchestrator.
///
/// **#1380 asked for this page's verdict on coordinates, so here they are.** The
/// exclusion argument is that the page is a delegator — 82 lines, no content of its own
/// — and every line of it is already measured: the bar by the chrome sweep since #1314,
/// the body by the case above. Two coordinates say otherwise.
///
/// `usp_dashboard_view.dart:38`–`:44` wraps [UspTopBar] in an
/// `AnimatedContainer(height: barsVisible ? 64 : 0, clipBehavior: Clip.hardEdge)`. The
/// chrome sweep pumps the same bar as a `Column` child at its natural height
/// (`page_chrome_family.dart:318`), so it measures what the bar *wants*; only this cell
/// measures the bar under a tight 64px, which is what the app gives it. A translation
/// that makes the bar taller than 64px is clipped here and reported nowhere there.
///
/// `usp_dashboard_view.dart:50`–`:66` is the branch, and it is why this case's
/// `forbids` is not the inert one three wave-3 pages carry. [AppLoader] here is the
/// `loading` arm at `:52` and the refresh strip at `:48`; [ServiceErrorView] is the
/// `error` arm at `:55`. Both are live states of this page, so forbidding them is the
/// assertion that the fixture reached `data` — which for a page whose whole job is that
/// choice is the only premise worth having. Without it this cell would be 234 green
/// measurements of an error page, which is exactly what an unfixtured run produces
/// (`mock_dashboard_page.dart`'s [SettledDashboardOrchestrator] says why).
///
/// The cost of the overlap with [kSliverDashboardPageCase] is real and is 234 cells of
/// mostly-repeated work. It is paid because the two pages fail differently: this one can
/// only fail in the bar's 64px or in the branch, and both are one-line edits away.
///
/// The second and last [PageSurfaceCase.needsMaterialAncestor] page, for the same reason
/// as the case above and by the same route: the shell it delegates to is where its
/// `Material` comes from in the app, and its body is that page's grid of [AppCard]s.
final kUspDashboardPageCase = PageSurfaceCase(
  id: 'usp_dashboard',
  view: () => const UspDashboardView(),
  needsMaterialAncestor: true,
  overrides: () => dashboardPageOverrides(),
  requires: const [UspTopBar, DashboardHeaderBar, SliverDashboard],
  forbids: const [AppLoader, ServiceErrorView],
);

/// `usp_admin_view` — timezone, password, firmware entry and the two destructive
/// actions, in one column through 905px and two above it.
///
/// **The `AppResponsiveLayout` is why this page is worth nine widths.** Four cards in one
/// column become two `SizedBox(width: context.colWidth(6))` columns on desktop
/// (`usp_admin_view.dart:112`–`:151`), so the widest card is measured at the full page
/// width in four of the nine widths (320, 480, 601, 905) and at half of it in five
/// (1080 up) — a difference no card suite reproduces, because the card in question is
/// `FirmwareUpdateCard` and it is not a dashboard card.
///
/// That split is four-and-five rather than two-and-seven because of this wave. The page
/// left `AppResponsiveLayout.tablet` unset, which falls back to `desktop`, so 601px and
/// 905px were laying two `colWidth(6)` columns out of a phone-width screen: ~253px each,
/// *narrower* than the 288px a 320px screen gives the same card in one column. The
/// sweep's worst coordinates were at 601px rather than at its floor, and the fix was to
/// name the band. Nothing about the desktop layout moved; four widths changed which
/// builder they reach.
///
/// All four cards are required. They are four independent presentations of four
/// different sources — `state.timeSettings`, `state.adminUser`,
/// `systemInfoDataProvider`, and nothing at all for the actions card — so requiring one
/// would leave the others free to fall back to a spinner or an `N/A` unnoticed.
/// `mock_admin.dart`'s [adminPageOverrides] says what the fourth one needed.
///
/// What stays unmeasured is the five dialogs: timezone edit, password change, reboot
/// and factory-reset confirmations, and the password-invalid state. #1380 puts dialogs
/// out of scope for the whole wave, and the golden suite already pumps all five.
final kAdminPageCase = PageSurfaceCase(
  id: 'admin',
  view: () => const UspAdminView(),
  overrides: () => adminPageOverrides(),
  requires: const [
    UspTimezoneCard,
    UspPasswordCard,
    FirmwareUpdateCard,
    UspSystemActionsCard,
  ],
  forbids: const [AppLoader, ServiceErrorView],
);

/// `usp_apps_view` — the installed-app grid, plus the `Store` button that leaves for
/// the router's own app store.
///
/// **Its `crossAxisCount` is why nine widths are not seven.** The grid is 1 column at
/// or below `context.isMobileLayout` and 3 above it, with a `mainAxisExtent` that also
/// switches (112px to 152px) and a `childAspectRatio` that does not — so the card box
/// this page hands `_AppGridCard` is a *step* function of screen width, and the step
/// lands between 480px and 601px. Below it a card is the page's whole content box; above
/// it a card is a third of it minus two `AppSpacing.lg` gutters, which at 601px is the
/// narrowest box any cell in this family gives a card that also has to hold a 36px icon
/// tile, a badge and a version-bearing description.
///
/// [GridView] carries the premise on its own, which is why this case's `forbids` is
/// short. The page has four arms — `loading`, `error`, empty-data and populated-data —
/// and exactly one of them builds a grid: the error arm at `usp_apps_view.dart:44` is a
/// hand-rolled `Column` (not [ServiceErrorView], because these failures are plain
/// `Exception`s off a lighttpd file rather than `ServiceError`s), and the empty arm at
/// `:66` is a centred icon and one line. So requiring the grid rules out all three
/// without naming any of them, and none of the three could be mistaken for the page by a
/// broken fixture.
///
/// [AppBadge] is required for the fixture rather than for the page. It is the only thing
/// in the card's header `Row` that is not fixed-size, and the row is under
/// `spaceBetween` beside a 36px tile, so a fixture that quietly stopped marking any app
/// `New` or `user` would take the badge out of every cell and leave the sweep green over
/// the one arrangement that cannot overflow. `apps_scene_data.dart` says why the recent
/// name is a system app.
///
/// What stays unmeasured is the store itself and the app links: both are `openUrl` calls
/// into another origin, and both read `uspClientProvider` inside `onTap` rather than in
/// `build`, so no cell touches them.
final kAppsPageCase = PageSurfaceCase(
  id: 'apps',
  view: () => const UspAppsView(),
  overrides: () => appsOverrides(),
  requires: const [UspTopBar, GridView, AppBadge],
  forbids: const [AppLoader],
);

/// `usp_dmz_view` — one switch, one IPv4 field and a two-option radio list, in three
/// cards that appear as the switch is turned on.
///
/// **The first Type A form page in this family that is not a `pnp` step**, and what it
/// adds over wave 2's forms is a field whose width is fixed in logical pixels rather
/// than granted by the layout. `AppIpv4TextField` is four boxes and three separators;
/// the CIDR field under the radio list is an `AppTextFormField` inside a
/// `BoxConstraints(maxWidth: 429)` (`usp_dmz_view.dart:276`). At 320px the content box
/// is 288px, so the constraint is inert and the field takes what it is given — but both
/// sit inside `LayoutBlock`s inside `AppCard`s with `AppSpacing.md` padding twice over,
/// which is 24px of the 288 gone before the field starts. That stack is what these
/// cells measure and what no `pnp` page has.
///
/// The premise is three widgets and each one is a card: [AppSwitch] is the enable card,
/// [AppIpv4TextField] the destination card, [AppRadioList] the source card. Naming all
/// three is not belt-and-braces here — the last two render only
/// `if (pending.isEnabled)`, so a fixture that lost `isEnabled` would still satisfy a
/// premise that named the switch alone, and 234 cells would measure a page with
/// two-thirds of its content absent and nothing to overflow. The radio list is named at
/// its **instantiation** — `AppRadioList<DmzSourceType>`, not the bare generic — because
/// `find.byType` compares `runtimeType`, so a `List<Type>` entry of `AppRadioList`
/// resolves to `AppRadioList<dynamic>` and matches nothing this page builds. It is the
/// family's first generic premise and the failure it produces is legible
/// (`Found 0 widgets with type "AppRadioList<dynamic>"`), which is the only reason this
/// is a comment and not a helper. [ServiceErrorView] joins
/// [AppLoader] in `forbids` because this page has a real error arm at `:93` that renders
/// it, so the blunt direction can actually fail here.
///
/// The `expandedWidget` is why the scene selects `cidr` — see `dmz_scene_data.dart`.
/// What stays unmeasured is the save path and the two snackbars: both are `onTap`
/// bodies, and `updateSetting` is stubbed in the override precisely so no cell can
/// change the state it is measuring.
final kDmzPageCase = PageSurfaceCase(
  id: 'dmz',
  view: () => const UspDmzView(),
  overrides: () => dmzOverrides(),
  requires: const [
    UspTopBar,
    AppSwitch,
    AppIpv4TextField,
    AppRadioList<DmzSourceType>,
  ],
  forbids: const [AppLoader, ServiceErrorView],
);

/// `usp_firewall_view` — nine rows in three cards: two SPI switches, three VPN
/// passthrough switches, three internet filters and a link out to IPv6 port service.
///
/// **The family's densest label-plus-control page, and the one with no branch at all.**
/// Every row is a [SwitchBlock] — a label on the left, a fixed-width `AppSwitch` on the
/// right — and the labels are the longest in the advanced-settings area
/// (`ipv4SpiFirewall`, `ipsecPassthrough`, `filterAnonymous`). Nine of them render
/// unconditionally, so unlike [kDmzPageCase] there is no state in which this page shows
/// less, and unlike every card page there is no grid to absorb a long string by
/// reflowing. What a cell measures is nine independent label/control rows at the same
/// width, which is nine chances for one locale to be the long one.
///
/// The premise is [SwitchBlock] and [NavLinkBlock] — the two row types — and nothing
/// finer. There is no count here on purpose: the page reads eight booleans out of one
/// model and renders the same nine rows whichever way they are set, so a fixture cannot
/// silently reduce what this sweep measures the way `apps`' badge or `dmz`' switch can.
/// The only fixture failure available is "no content at all", and that is what these two
/// types plus the two `forbids` cover.
///
/// [NavLinkBlock] is required rather than assumed because it is the one row whose right
/// half is not a switch: a chevron plus a two-line title/description column, so it is the
/// row that overflows first if the description is long and the block ever stops wrapping.
/// It also sits outside the three cards, directly in the page's `Column`.
final kFirewallPageCase = PageSurfaceCase(
  id: 'firewall',
  view: () => const UspFirewallView(),
  overrides: () => firewallOverrides(),
  requires: const [UspTopBar, SwitchBlock, NavLinkBlock],
  forbids: const [AppLoader, ServiceErrorView],
);

/// `instant_privacy_view` — the one-tap MAC whitelist: a description, an optional
/// warning banner, a toggle card, and a device list that is a different list on each
/// side of the toggle.
///
/// **The family's first page whose worst case is a list row, not a form field.** Every
/// device is a [LayoutBlock] holding one `Row`: an optional [AppBadge], a 20px icon, and
/// an `Expanded` two-line column of name over MAC. The badge is the interesting part —
/// it is fixed-width, it carries a localized string (`privateMacLabel`), and it sits
/// *before* the `Expanded`, so it takes its width off the top in every locale. At 320px
/// the column that remains has to hold a 17-character MAC, which does not wrap.
///
/// The premise names four widgets and each one pins a different branch:
///
/// - [UspTopBar] — the chrome, as everywhere in this family.
/// - [AppSwitch] — the toggle card, which is the only region that renders in every state.
/// - [AppButton] — the *ON* branch's `addDevice` action. `_buildConnectedDevicesList`
///   has no button and the top bar uses `AppIconButton`, so this type is present only
///   when `_buildAllowedDevicesList` ran, which is the branch with the `spaceBetween`
///   header row: a count label and a text button, neither of them `Expanded`.
/// - [AppBadge] — a device row rendered *and* it is a private-MAC row. This is the
///   premise that a fixture cannot satisfy by accident: `isPrivateMac` defaults to
///   false, so the badge and the page banner are exactly what the golden states never
///   show. `instant_privacy_scene_data.dart` says why the gate scene sets it.
///
/// The banner itself is a bare `Container` and cannot be named, which is the usual limit
/// of a type-level premise — but it renders under the same `hasPrivateMacInList` flag
/// the badge does, so [AppBadge] stands for both.
final kInstantPrivacyPageCase = PageSurfaceCase(
  id: 'instant_privacy',
  view: () => const InstantPrivacyView(),
  overrides: () => instantPrivacyOverrides(),
  requires: const [UspTopBar, AppSwitch, AppButton, AppBadge],
  forbids: const [AppLoader, ServiceErrorView],
);

/// `instant_safety_view` — one switch for OpenDNS safe browsing, and two lines of
/// server prose that appear only while it is on.
///
/// **The family's smallest page, and it is in the sweep because small is not the same
/// as safe.** The whole content is one `AppCard` holding a toggle row and an info
/// block, and the toggle row already carries the `Expanded` that
/// [kInstantPrivacyPageCase]'s header row was missing — so the row this page would
/// have failed at is the one row in wave 4 that was written correctly to begin with.
/// What is left to measure is the info block: `openDnsFamilyShieldDesc` is the longest
/// single string any page in this wave renders, and it sits in a `LayoutBlock` inside
/// an `AppCard` inside the page padding, which is three insets deep at 320px.
///
/// The premise is the toggle and the chrome, and the page's own honest limit is
/// recorded in `instant_safety_scene_data.dart` rather than here: both branches render
/// [AppSwitch] and `LayoutBlock`, so no type-level premise can tell the enabled card
/// from the disabled one. `dmz` could name its expanded field's type; this page cannot,
/// and saying so at the fixture is better than a premise that looks like it covers the
/// branch and does not.
final kInstantSafetyPageCase = PageSurfaceCase(
  id: 'instant_safety',
  view: () => const UspInstantSafetyView(),
  overrides: () => instantSafetyOverrides(),
  requires: const [UspTopBar, AppCard, AppSwitch],
  forbids: const [AppLoader, ServiceErrorView],
);

/// `usp_internet_settings_view` — a status banner over four sections, and **the first
/// page in this family that is two different layouts across the width axis**.
///
/// `AppResponsiveLayout` gives mobile a single stacked column and desktop a two-column
/// `Row` of `Expanded`s. That makes the nine widths #1372 settled do something here they
/// do at no other page: 320 and 480 measure one layout, 601 and up measure the other,
/// and the *narrowest content box on the page* is not at the narrowest screen. At 601px
/// each column is roughly 253px against the ~288px a 320px phone gives the whole page —
/// the same tablet-band step that `admin` and `apps` were both red at, arriving here by
/// a different mechanism.
///
/// What the rows look like is `usp_info_row.dart`: a label box capped at
/// `kUspLabelMaxWidth` beside an `Expanded` value. It cannot overflow — the label is
/// `maxLines: 1` with an ellipsis — so what this sweep actually guards on this page are
/// the *other* rows: `_switchRow`'s fixed 160px label box plus `Spacer` plus switch, the
/// renew cards' `Expanded` column plus button, and the banner's dot-plus-column-plus-icon.
/// The ellipsis is real gate blindness of the #1240 kind and is recorded rather than
/// worked around: an unreadable label here passes.
///
/// The premise names one widget per region, so a fixture that lost a whole section
/// fails rather than measuring less:
///
/// - [UspConnectionStatusBanner] — the banner, above the responsive split.
/// - [UspIpv4Section] and [UspIpv6Section] — the left column on desktop.
/// - [UspOptionalSection] and [UspRenewSection] — the right column, and [UspRenewSection]
///   is also the `isEditing == false` pin: it renders only `if (!isEditing)`, so an
///   editing fixture would drop it and take the form-field layout the scene argues
///   against.
///
/// No [UspTopBar] in the premise, because this page's `UiKitPageView` declares no
/// `topbar` — one of seven wave-4 views that do not (`remote_assistance`,
/// `unified_diagnostics`, `router_assistant`, `test_console`, `sliver_dashboard`,
/// `usp_dashboard` and this one; `usp_dashboard` is the one of the seven that mounts
/// [UspTopBar] itself instead, at `usp_dashboard_view.dart:43`). Being a child route of
/// `advanced_settings`, which has the bar, is *not* the explanation — `local_network` is
/// a sibling child route and declares one. So this is the page's own shape, and the
/// premise is written from what the tree contains rather than from a rule about where
/// the page sits.
final kInternetSettingsPageCase = PageSurfaceCase(
  id: 'internet_settings',
  view: () => const UspInternetSettingsView(),
  overrides: () => internetSettingsOverrides(),
  requires: const [
    UspConnectionStatusBanner,
    UspIpv4Section,
    UspIpv6Section,
    UspOptionalSection,
    UspRenewSection,
  ],
  forbids: const [AppLoader, ServiceErrorView],
);

/// The page ids whose [AppLoader] is content rather than a loading state.
///
/// `page_surface_family_test.dart` asserts that every case forbids [AppLoader],
/// because on a page that opens with `if (isLoading) return AppLoader()` a spinner is
/// the single most likely thing a broken fixture measures — 234 cells of a centred
/// 48px box, green at every width in every locale. That rule holds for 42 of the 43
/// cases — and wave 4 doubling the case list without adding a second entry here is
/// the evidence the paragraph below asks for: twenty-one more pages, every one of them
/// forbidding its loader.
///
/// It cannot hold for `auto_parent_first_login`, whose loader is the subject of the
/// screen rather than a stand-in for it. The exemption is a set here, and not an
/// omitted `forbids` entry there, so that:
///
/// 1. the oracle drives **both** branches off one value — an exempt case must *require*
///    [AppLoader], which is the claim "the loader is this page's content" written as
///    an assertion rather than as a gap;
/// 2. the membership is pinned. Adding an id is then an edit to a named set with a
///    reason attached, where dropping `AppLoader` from a `forbids` list is the exact
///    silent narrowing #1364/#1366 found three times.
///
/// A second entry here should be argued hard. "This page always shows a spinner" is
/// usually a fixture that has not been written yet, which is what a `-` in
/// `test/fixtures/page_roster.tsv` is for.
const kPagesWhoseLoaderIsContent = <String>{'auto_parent_first_login'};

/// Every case the gate sweeps, in sweep order: the pilot's two, then wave 1's five,
/// then wave 2's nine, then wave 3's six, then wave 4's twenty-one — 43 in all, which
/// is every page view under `lib/page/` except the two `page_roster.tsv` excludes as
/// unreachable.
///
/// One list, so `page_surface_family_test.dart` can pin the premises of all of
/// them without naming each — a case added here without a premise fails there.
///
/// The order is the order the pages were onboarded, and the oracle pins it exactly.
/// That pin is the epic's per-wave checkpoint: it goes red on every wave by design,
/// and the reason string it carries is where the wave says which pages it added and
/// why. A wave that empties the list to get green has deleted the checkpoint.
/// `usp_ipv6_port_service_view` — a CRUD list of IPv6 pinholes, and the second page
/// in this wave whose content is one repeated row.
///
/// The premise is the row, not the page: [AppSwitch] and [AppIconButton] are both in
/// `_buildRuleCard` *and* in the header ([AppIconButton] is the add button), so
/// [LayoutBlock] is what separates "the list rendered" from "the heading rendered
/// above an empty list" — it is the rule card's own container and nothing else on the
/// page uses it. [DetailEmptyBlock] is therefore forbidden rather than merely absent:
/// the fixture is what keeps it away, and a fixture that lost its rules would
/// otherwise sweep 234 cells of a one-line empty state and report them green.
///
/// The two dialogs (`_showAddDialog`, `_showEditDialog`) are not measured — dialogs
/// are out of scope for #1380 — and neither is the dirty page's save bar, for the
/// reason `ipv6_port_service_scene_data.dart` gives.
final kIpv6PortServicePageCase = PageSurfaceCase(
  id: 'ipv6_port_service',
  view: () => const UspIpv6PortServiceView(),
  overrides: () => ipv6PortServiceOverrides(),
  requires: const [UspTopBar, LayoutBlock, AppSwitch, AppIconButton],
  forbids: const [AppLoader, ServiceErrorView, DetailEmptyBlock],
);

/// `usp_local_network_view` — hostname, router IP and the whole DHCP server, which is
/// nine form fields in five [LayoutBlock]s once the server is on.
///
/// [AppIpv4TextField] is the premise that means "the DHCP server is expanded": the
/// router card has two of them and the expanded card has five more, but a *collapsed*
/// DHCP card renders only its header row — so the field type alone cannot tell the two
/// apart. `AppTextFormField` can: there are exactly two on the page, the hostname and
/// the lease time, and the lease time is inside the expanded block. Requiring both
/// types is what pins the scene open, and `gateLocalNetworkState` is what supplies it.
///
/// This page is the family's one unconditional bottom bar — `_buildBottomBar` returns
/// a config whether or not the page is dirty, deliberately, so its `UiKitBottomBar` is
/// in every one of these 234 cells. That is chrome the #1314/#1328 sweep does not own
/// (it sweeps the top bar and the dashboard header) and it is ui_kit's own internals,
/// so it is measured here but not fixable here: an overflow inside it goes upstream,
/// the way `pnp_setup`'s `AppStepper` did.
final kLocalNetworkPageCase = PageSurfaceCase(
  id: 'local_network',
  view: () => const UspLocalNetworkView(),
  overrides: () => localNetworkOverrides(),
  requires: const [
    UspTopBar,
    AppSwitch,
    AppIpv4TextField,
    AppTextFormField,
    LayoutBlock,
  ],
  forbids: const [AppLoader, ServiceErrorView],
);

/// `usp_static_routing_view` — the same CRUD-list shape as `ipv6_port_service`, one
/// page down the advanced-settings menu, and declared with the same premise for the
/// same reason: [LayoutBlock] is the rule card's own container, so it and not
/// [AppSwitch] or [AppIconButton] is what separates a rendered list from a heading
/// above an empty one.
///
/// [DetailEmptyBlock] is forbidden rather than merely absent — see
/// `kIpv6PortServicePageCase`, and `static_routing_scene_data.dart` for what the two
/// routes are chosen to make wide.
final kStaticRoutingPageCase = PageSurfaceCase(
  id: 'static_routing',
  view: () => const UspStaticRoutingView(),
  overrides: () => staticRoutingOverrides(),
  requires: const [UspTopBar, LayoutBlock, AppSwitch, AppIconButton],
  forbids: const [AppLoader, ServiceErrorView, DetailEmptyBlock],
);

/// `usp_statistics_view` — twenty chart sections behind three tabs, and the case in
/// this family whose coverage claim is the smallest relative to its page. Both limits
/// are by construction and neither is fixable here, so both are stated as numbers.
///
/// 1. **Tab 0 of 3**, for the reason `kWifiSettingsPageCase` and
///    `kPortForwardingPageCase` give about their own second tabs: the others are
///    behind a `TabController` and would need a tap per cell.
/// 2. **Four of tab 0's nine sections.** Every other page in this family hands its
///    scroll view a `Column`, which lays out all of its children whatever the
///    height. This one hands it a `CustomScrollView` + `SliverList`, which lays out
///    the viewport plus the cache extent and no more. Measured rather than assumed:
///    at [kPageSweepHeight] exactly `Traffic Monitor`, `Traffic Comparison`,
///    `Traffic Distribution` and `Traffic Trends` build — and the count is **4 at
///    all nine swept widths**, and 4 in `en`, `ru` and `zh` alike, because what
///    decides it is the sliver's extent and not the text. The other five
///    (`HealthScore`, `ErrorRates`, `PacketLoss`, `FirewallRules`, `PortMapping`)
///    never build, so this sweep says nothing about them at any width.
///
/// So 234 green cells here mean: the page frame — top bar, tab bar, the sliver
/// padding arithmetic — plus the four sections a phone opens on. Raising
/// [kPageSweepHeight] would measure more and would cost every other page in the
/// family the same multiple; that trade belongs to whoever wants the coverage, and
/// #1380 declined to take it silently.
///
/// **What already covers the rest, and did before this wave.**
/// `stats_traffic_monitor_legend_test.dart` and `stats_wifi_channels_section_test.dart`
/// pump single sections through `test/util/statistics/stats_section_probe.dart`, which
/// models this page's two different paddings on purpose — its header explains why the
/// Devices tab is measured narrower than production. This case does not replace them
/// and must not be read as covering what they cover: a section suite is how a section
/// below the fold gets measured at all.
///
/// [StatsSectionCard] is the premise because it is every section's own container, so
/// it separates "the tab's sliver laid out content" from "the tab bar rendered above
/// an empty viewport" — which is exactly what a fixture-less scene produces here, and
/// `gateStatisticsOverrides()` says why this scene populates every provider.
final kStatisticsPageCase = PageSurfaceCase(
  id: 'statistics',
  view: () => const UspStatisticsView(),
  overrides: () => gateStatisticsOverrides(),
  requires: const [UspTopBar, StatsSectionCard],
  forbids: const [AppLoader, ServiceErrorView],
);

/// `usp_system_log_view` — two log-file cards, and the 45th page.
///
/// The page's whole horizontal risk is one row per card: `Max Size: 512 KB`, a
/// `Persistent`/`Volatile` badge, a `Spacer`, and an `AppButton.text` carrying
/// `loc.export` — four inflexible children, which is the shape that has produced an
/// overflow on every other page in this wave that had it. The card's *other* row is
/// already `Expanded` around the file name, so it is not the one to watch.
/// `system_log_scene_data.dart` records which of the row's strings are localized (the
/// export label, and only it) and therefore what a locale-specific failure here means.
///
/// [AppCard] is the premise that does real work, and it does two jobs. It is the log
/// card's own container, so it separates the loaded page from the loader; and this page
/// has a third content state the other cases do not — an empty log list renders a
/// centred icon over one line of prose and **no card at all**, which is a tree that
/// cannot overflow at any width. Requiring [AppCard] is what stops a drifted fixture
/// from turning all 234 cells into a measurement of that.
final kSystemLogPageCase = PageSurfaceCase(
  id: 'system_log',
  view: () => const UspSystemLogView(),
  overrides: () => systemLogOverrides(),
  requires: const [UspTopBar, AppCard, AppButton],
  forbids: const [AppLoader, ServiceErrorView],
);

final kPageSurfaceCases = <PageSurfaceCase>[
  kDhcpPageCase,
  kWifiSettingsPageCase,
  kDeviceListPageCase,
  kDeviceDetailPageCase,
  kTopologyPageCase,
  kNodeDetailPageCase,
  kPortForwardingPageCase,
  // Wave 2 (#1378), in flow order rather than cost order — the flow is what makes
  // the set legible, and every page in it costs about the same anyway.
  kPnpEntryPageCase,
  kPnpNoInternetPageCase,
  kPnpIspSettingsPageCase,
  kPnpPppoePageCase,
  kPnpStaticIpPageCase,
  kPnpUnplugModemPageCase,
  kPnpModemLightsOffPageCase,
  kPnpWaitingModemPageCase,
  // The ninth, appended rather than slotted into the flow above: in flow order it
  // belongs between `pnp_entry` and `pnp_no_internet`, but it was onboarded a day
  // later — after ui_kit v2.40.2 fixed `AppStepper` — and this list's order is the
  // onboarding order the oracle pins. Moving it to its flow position would make the
  // list read as though wave 2 had declared nine pages in one go, which is the one
  // thing the record of this page should not say.
  kPnpSetupPageCase,
  // Wave 3 (#1379), in the order a user meets them: the landing page, then the three
  // local-login pages, then the menu, then the first-login firmware screen. Unlike
  // wave 2 this order is also the onboarding order — none of the six waited on
  // anything — so the two readings of this list agree here.
  kHomePageCase,
  kLoginLocalPageCase,
  kLocalRouterRecoveryPageCase,
  kLocalResetRouterPasswordPageCase,
  kMenuPageCase,
  kAutoParentFirstLoginPageCase,
  // Wave 4 (#1380), the epic's last twenty-one. Onboarding order again, and here that
  // is the order the two slices ran in: slice A is the seven pages whose
  // `List<Override>` builder already reached the view, and they came first because five
  // of them carried #1370's open sites and a fix has to land before a declaration does.
  // Slice B is the fourteen the roster had marked as owing a fixture. The slices are
  // not the fixture bill: **18 of the 21 pages ended up needing one**, because four of
  // slice A had a builder that the gate is not allowed to import or none at all, and
  // only three pages in the wave render under `commonOverrides()` alone. Architecture
  // doc §11.12 has the breakdown; `page_roster_test.dart` has why the column read 13.
  kAdvancedSettingsPageCase,
  kRemoteAssistancePageCase,
  kSupportPageCase,
  kUnifiedDiagnosticsPageCase,
  kFirmwareUpdatePageCase,
  kRouterAssistantPageCase,
  kTestConsolePageCase,
  // The two dashboard pages, inner first: `sliver_dashboard` is where the fixture was
  // written and `usp_dashboard` is 40 lines of frame around it, so the order is the
  // order they were debugged in and reads as the containment it is.
  kSliverDashboardPageCase,
  kUspDashboardPageCase,
  kAdminPageCase,
  kAppsPageCase,
  kDmzPageCase,
  kFirewallPageCase,
  kInstantPrivacyPageCase,
  kInstantSafetyPageCase,
  kInternetSettingsPageCase,
  kIpv6PortServicePageCase,
  kLocalNetworkPageCase,
  kStaticRoutingPageCase,
  kStatisticsPageCase,
  kSystemLogPageCase,
];
