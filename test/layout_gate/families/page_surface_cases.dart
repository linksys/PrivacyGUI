/// The pages the gate sweeps: the #1349 pilot's two, #1377's wave 1 five, and
/// #1378's wave 2 eight.
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

import 'package:privacy_gui/components/customs/circular_countdown_widget.dart';
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
import 'package:privacy_gui/page/instant_setup/views/pnp_static_ip_view.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_unplug_modem_view.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_waiting_modem_view.dart';
import 'package:privacy_gui/page/port_forwarding/views/components/usp_single_port_tab.dart';
import 'package:privacy_gui/page/port_forwarding/views/usp_port_forwarding_detail_view.dart';
import 'package:privacy_gui/page/topology/views/components/backhaul_signal_indicator.dart';
import 'package:privacy_gui/page/topology/views/usp_node_detail_view.dart';
import 'package:privacy_gui/page/topology/views/usp_topology_view.dart';
import 'package:privacy_gui/page/wifi_settings/views/components/wifi_network_card.dart';
import 'package:privacy_gui/page/wifi_settings/views/usp_wifi_settings_view.dart';
import 'package:ui_kit_library/ui_kit.dart'
    show
        AppButton,
        AppCard,
        AppIpv4TextField,
        AppLoader,
        AppPasswordInput,
        AppTextField,
        AppTopology;

import '../../mocks/provider_overrides/mock_devices.dart';
import '../../mocks/provider_overrides/mock_dhcp.dart';
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
// Wave 2 (#1378) — the instant_setup flow, eight of its nine reachable pages
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
// **Eight, not nine.** `pnp_setup` is measurable and still cannot be declared: the
// wizard renders ui_kit's `AppStepper`, whose bar variant overflows by
// `stepCount × 4` at every width in every locale, and the fix is in ui_kit rather
// than here. The finding is pinned as a tripwire test in
// `test/page/instant_setup/views/pnp_setup_view_test.dart` — read that test's doc
// comment for the arithmetic and for what to do when it goes red. `pnp_complete`
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

/// Every case the gate sweeps, in sweep order: the pilot's two, then wave 1's five,
/// then wave 2's eight.
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
];
