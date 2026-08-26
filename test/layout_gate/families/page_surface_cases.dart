/// The pages the gate sweeps: the #1349 pilot's two, #1377's wave 1 five,
/// #1378's wave 2 nine, and #1379's wave 3 six.
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

import 'package:flutter_svg/flutter_svg.dart' show SvgPicture;
import 'package:privacy_gui/components/customs/circular_countdown_widget.dart';
import 'package:privacy_gui/components/styled/menus/widgets/app_menu_card.dart';
import 'package:privacy_gui/page/_shared/components/detail_widgets.dart';
import 'package:privacy_gui/page/devices/views/components/usp_device_filter_panel.dart';
import 'package:privacy_gui/page/devices/views/components/usp_device_list_tile.dart';
import 'package:privacy_gui/page/devices/views/components/usp_signal_strength_indicator.dart';
import 'package:privacy_gui/page/devices/views/usp_device_detail_view.dart';
import 'package:privacy_gui/page/devices/views/usp_device_list_view.dart';
import 'package:privacy_gui/page/dhcp/views/components/usp_dhcp_active_leases_card.dart';
import 'package:privacy_gui/page/dhcp/views/components/usp_dhcp_reservations_detail_card.dart';
import 'package:privacy_gui/page/dhcp/views/components/usp_dhcp_server_info_card.dart';
import 'package:privacy_gui/page/dhcp/views/usp_dhcp_detail_view.dart';
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
import 'package:privacy_gui/page/landing/views/home_view.dart';
import 'package:privacy_gui/page/login/auto_parent/views/auto_parent_first_login_view.dart';
import 'package:privacy_gui/page/login/views/local_reset_router_password_view.dart';
import 'package:privacy_gui/page/login/views/local_router_recovery_view.dart';
import 'package:privacy_gui/page/login/views/login_local_view.dart';
import 'package:privacy_gui/page/menu/views/usp_menu_view.dart';
import 'package:privacy_gui/page/port_forwarding/views/components/usp_single_port_tab.dart';
import 'package:privacy_gui/page/port_forwarding/views/usp_port_forwarding_detail_view.dart';
import 'package:privacy_gui/page/topology/views/components/backhaul_signal_indicator.dart';
import 'package:privacy_gui/page/topology/views/usp_node_detail_view.dart';
import 'package:privacy_gui/page/topology/views/usp_topology_view.dart';
import 'package:privacy_gui/page/wifi_settings/views/components/wifi_network_card.dart';
import 'package:privacy_gui/page/wifi_settings/views/usp_wifi_settings_view.dart';
import 'package:ui_kit_library/ui_kit.dart'
    show
        AppBadge,
        AppButton,
        AppCard,
        AppExpansionPanel,
        AppIpv4TextField,
        AppLoader,
        AppPasswordInput,
        AppPinInput,
        AppStepper,
        AppTextField,
        AppTextFormField,
        AppTopology;

import '../../mocks/provider_overrides/mock_devices.dart';
import '../../mocks/provider_overrides/mock_dhcp.dart';
import '../../mocks/provider_overrides/mock_login.dart';
import '../../mocks/provider_overrides/mock_menu.dart';
import '../../mocks/provider_overrides/mock_pnp.dart';
import '../../mocks/provider_overrides/mock_port_forwarding.dart';
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

/// The page ids whose [AppLoader] is content rather than a loading state.
///
/// `page_surface_family_test.dart` asserts that every case forbids [AppLoader],
/// because on a page that opens with `if (isLoading) return AppLoader()` a spinner is
/// the single most likely thing a broken fixture measures — 234 cells of a centred
/// 48px box, green at every width in every locale. That rule holds for 21 of the 22
/// cases.
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
/// then wave 2's nine, then wave 3's six.
///
/// One list, so `page_surface_family_test.dart` can pin the premises of all of
/// them without naming each — a case added here without a premise fails there.
///
/// The order is the order the pages were onboarded, and the oracle pins it exactly.
/// That pin is the epic's per-wave checkpoint: it goes red on every wave by design,
/// and the reason string it carries is where the wave says which pages it added and
/// why. A wave that empties the list to get green has deleted the checkpoint.
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
];
