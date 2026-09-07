// Composed scenes, not builders — see `test/mocks/test_data/` one directory up,
// and `port_forwarding_scene_data.dart`'s header for the full statement of the
// split. Top-level finals holding whole `PnpState`s, ready to hand to
// `pnpOverrides()`.
//
// ## Why the PnP flow needs composed states at all (#1378)
//
// Every other page in the layout gate is a *destination*: it fetches, and its
// provider's state is "loading" then "loaded". The PnP pages are a **state
// machine's screens** — nine views over one `pnpProvider`, where the phase
// decides not just whether the page has data but *which page-sized tree it
// renders*. `PnpNotifier.build()` returns `AdminCheckingInternet` for all of
// them, which is the phase before any of the nine has anything to show.
//
// So a "fixture" here is a phase, and picking it is picking which of a view's
// branches is measured. Each state below records the branch it selects and why
// that branch is the widest one the view has — the same rule
// `page_surface_cases.dart` applies to every other page's fixture.

import 'package:privacy_gui/page/_shared/models/backhaul_info.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_band.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_config.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_wan_connection_type.dart';

// ---------------------------------------------------------------------------
// WiFi configuration — the wizard's editable payload
// ---------------------------------------------------------------------------

/// Unified mode: one SSID and one password across all bands.
///
/// `mainBands` is empty, so `PnpWifiConfig.isSplitMode` is false and
/// `PnpSetupView` renders its single unified `LayoutBlock`. Used by the
/// lifecycle test in `test/page/instant_setup/views/pnp_setup_view_test.dart`,
/// which is about the four unified-mode controllers specifically.
///
/// `guestSsidInstancePaths` is non-empty on purpose: it is what
/// `_buildStepperForm` counts to decide there is a guest step, so an empty list
/// would render a one-step wizard with no `AppStepper` at all.
const pnpUnifiedWifiConfig = PnpWifiConfig(
  ssid: 'Linksys-Unified',
  password: 'unified-password',
  originalSsid: 'Linksys-Unified',
  originalPassword: 'unified-password',
  ssidInstancePaths: ['Device.WiFi.SSID.1'],
  accessPointInstancePaths: ['Device.WiFi.AccessPoint.1'],
  guestEnabled: true,
  guestSsid: 'Linksys-Unified-Guest',
  guestPassword: 'guest-password',
  originalGuestEnabled: true,
  originalGuestSsid: 'Linksys-Unified-Guest',
  originalGuestPassword: 'guest-password',
  guestSsidInstancePaths: ['Device.WiFi.SSID.4'],
  guestAccessPointInstancePaths: ['Device.WiFi.AccessPoint.4'],
);

/// Split mode: three bands, each with its own SSID and password.
///
/// The **widest** of the two modes and therefore the gate's fixture.
/// `_buildSplitModeMainWifi` emits one `LayoutBlock` per band, each holding a
/// band label, an `AppTextField` and an `AppPasswordInput` with its rule list —
/// so three bands render three times the form the unified block does. Unified
/// mode renders one block and would under-measure the page, which is the same
/// argument `kDhcpPageCase` makes about its empty-list state.
///
/// `PnpWifiConfig.isSplitMode` compares `originalSsid` across bands, so the
/// three differ there and not merely in `ssid` — a fixture whose bands shared an
/// `originalSsid` would silently fall back to the unified block.
const pnpSplitWifiConfig = PnpWifiConfig(
  // Still required by the model, and still what `dispose()` tears down: split
  // mode does not stop the four unified-mode controllers from existing.
  ssid: 'Linksys-2.4G',
  password: 'band-password-24',
  originalSsid: 'Linksys-2.4G',
  originalPassword: 'band-password-24',
  mainBands: [
    PnpWifiBand(
      bandName: '2.4 GHz',
      frequency: '2.4GHz',
      ssid: 'Linksys-2.4G',
      password: 'band-password-24',
      originalSsid: 'Linksys-2.4G',
      originalPassword: 'band-password-24',
      ssidInstancePath: 'Device.WiFi.SSID.1',
      accessPointInstancePath: 'Device.WiFi.AccessPoint.1',
      radioPath: 'Device.WiFi.Radio.1',
    ),
    PnpWifiBand(
      bandName: '5 GHz',
      frequency: '5GHz',
      ssid: 'Linksys-5G',
      password: 'band-password-5',
      originalSsid: 'Linksys-5G',
      originalPassword: 'band-password-5',
      ssidInstancePath: 'Device.WiFi.SSID.2',
      accessPointInstancePath: 'Device.WiFi.AccessPoint.2',
      radioPath: 'Device.WiFi.Radio.2',
    ),
    PnpWifiBand(
      bandName: '6 GHz',
      frequency: '6GHz',
      ssid: 'Linksys-6G',
      password: 'band-password-6',
      originalSsid: 'Linksys-6G',
      originalPassword: 'band-password-6',
      ssidInstancePath: 'Device.WiFi.SSID.3',
      accessPointInstancePath: 'Device.WiFi.AccessPoint.3',
      radioPath: 'Device.WiFi.Radio.3',
    ),
  ],
  guestEnabled: true,
  guestSsid: 'Linksys-Guest-2.4G',
  guestPassword: 'guest-password-24',
  originalGuestEnabled: true,
  originalGuestSsid: 'Linksys-Guest-2.4G',
  originalGuestPassword: 'guest-password-24',
  guestSsidInstancePaths: ['Device.WiFi.SSID.4', 'Device.WiFi.SSID.5'],
  guestAccessPointInstancePaths: [
    'Device.WiFi.AccessPoint.4',
    'Device.WiFi.AccessPoint.5',
  ],
  guestBands: [
    PnpWifiBand(
      bandName: '2.4 GHz',
      frequency: '2.4GHz',
      ssid: 'Linksys-Guest-2.4G',
      password: 'guest-password-24',
      originalSsid: 'Linksys-Guest-2.4G',
      originalPassword: 'guest-password-24',
      ssidInstancePath: 'Device.WiFi.SSID.4',
      accessPointInstancePath: 'Device.WiFi.AccessPoint.4',
      radioPath: 'Device.WiFi.Radio.1',
    ),
    PnpWifiBand(
      bandName: '5 GHz',
      frequency: '5GHz',
      ssid: 'Linksys-Guest-5G',
      password: 'guest-password-5',
      originalSsid: 'Linksys-Guest-5G',
      originalPassword: 'guest-password-5',
      ssidInstancePath: 'Device.WiFi.SSID.5',
      accessPointInstancePath: 'Device.WiFi.AccessPoint.5',
      radioPath: 'Device.WiFi.Radio.2',
    ),
  ],
);

// ---------------------------------------------------------------------------
// Mesh nodes — what turns the two-step wizard into a three-step one
// ---------------------------------------------------------------------------

/// Two nodes, because `_buildStepperForm` adds its network step on
/// `meshNodes.length > 1` and a single-node network gets no third step.
///
/// The step itself is never rendered by the gate — only step 0 is measured — but
/// the step *count* is, because `AppStepper` lays out one label per step and
/// three localized labels in a 288px content box is a strictly harder layout
/// problem than two.
final pnpMeshNodes = <NodeEntity>[
  MasterNode(
    deviceId: '11:22:33:44:55:66',
    model: 'MR7500',
    manufacturer: 'Linksys',
    serialNumber: 'ABC123456',
    softwareVersion: '1.0.16.215118',
  ),
  SlaveNode(
    deviceId: 'AA:BB:CC:DD:FF:01',
    model: 'MX2000',
    manufacturer: 'Linksys',
    serialNumber: 'DEF789012',
    softwareVersion: '1.0.10.200000',
    backhaul: const BackhaulInfo(mediaType: 'Wi-Fi', signalStrength: -50),
  ),
];

// ---------------------------------------------------------------------------
// WAN settings — what the two ISP forms prefill from
// ---------------------------------------------------------------------------

/// The router's current WAN settings, carried on [NoInternet].
///
/// Both ISP forms prefill from this in `initState` and **only** from this:
/// `PnpPppoeView._prefillFromCurrentSettings` and its `PnpStaticIpView`
/// counterpart both bail unless the phase is `NoInternet` with a non-null
/// `currentWanSettings`. A fixture without it renders every field empty, which
/// is a narrower tree than any real user sees.
///
/// Two fields are load-bearing beyond their own text:
/// - `vlanEnabled` flips `PnpPppoeView._showVlan`, which adds the VLAN label and
///   field to the form.
/// - a non-empty `dnsServer1`/`dnsServer2` flips `PnpStaticIpView._showDns`,
///   which adds two more `AppIpv4TextField`s.
///
/// So this is the state that renders the *complete* form on both pages rather
/// than its collapsed default.
///
/// `connectionType` is required by the model and read by neither PnP form — both
/// look at the individual fields — so it carries the value that makes the rest of
/// the object coherent rather than one either form branches on.
const pnpCurrentWanSettings = UspInternetSettingsForm(
  connectionType: UspWanConnectionType.pppoe,
  pppUsername: 'subscriber@isp.example',
  pppPassword: 'ppp-password',
  vlanEnabled: true,
  vlanId: 201,
  staticIpAddress: '203.0.113.42',
  subnetMask: '255.255.255.0',
  defaultGateway: '203.0.113.1',
  dnsServer1: '203.0.113.10',
  dnsServer2: '203.0.113.11',
);

// ---------------------------------------------------------------------------
// Composed PnpStates — one per branch the gate measures
// ---------------------------------------------------------------------------

/// `AdminReadFailure` — the only phase `PnpEntryView` renders without a loader.
///
/// That view's other three branches are `_buildLoading` (a bare `AppLoader`) and
/// `_buildCheckingInternet` (an `AppCard` *containing* an `AppLoader`), so
/// `PageSurfaceCase.forbids`' blanket `AppLoader` rule — pinned for every case by
/// `page_surface_family_test.dart` — leaves exactly this one. It is also the
/// widest of the four: an icon, a wrapped message and a text button.
/// `code` is 9998 because that is the codegen fault `AdminReadFailure`'s own
/// doc comment names as the shape it carries — "required fields missing" from a
/// `Device.DeviceInfo.` read. Neither field reaches the UI (the view derives its
/// message from the phase), so they are here to make the state truthful rather
/// than to change a pixel.
const pnpAdminReadFailureState = PnpState(
  phase: AdminReadFailure(
    code: 9998,
    detail: 'Device.DeviceInfo. returned no parameters',
  ),
  serialNumber: 'SN-TEST',
);

/// `NoInternet` — the phase the whole troubleshooter branch runs under.
///
/// Four of the nine views are on screen while the state machine sits here:
/// `PnpNoInternetView` (the hub), `PnpIspSettingsView`, and the two ISP forms.
/// `PnpWaitingModemView` is on screen here too, before its countdown starts.
///
/// `currentWanSettings` is what makes it the widest such state — see
/// [pnpCurrentWanSettings].
const pnpNoInternetState = PnpState(
  phase: NoInternet(
    ssid: 'Linksys-Test',
    currentWanSettings: pnpCurrentWanSettings,
  ),
  serialNumber: 'SN-TEST',
);

/// `WizardConfiguring` — the only phase `PnpSetupView` renders a form in.
///
/// Split mode plus guest bands plus two mesh nodes, i.e. the three-step wizard
/// with a per-band form on step 0: the widest tree that view has. See
/// [pnpSplitWifiConfig] and [pnpMeshNodes] for why each of the three is the
/// wider choice.
final pnpWizardConfiguringState = PnpState(
  phase: WizardConfiguring(
    wifiConfig: pnpSplitWifiConfig,
    meshNodes: pnpMeshNodes,
  ),
  serialNumber: 'SN-TEST',
);
