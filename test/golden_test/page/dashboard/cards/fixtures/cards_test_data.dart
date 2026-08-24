import 'package:privacy_gui/page/_shared/models/client_connection_detail.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/_shared/models/device_analytics_state.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_client_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/ethernet_port_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/lan_info_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/system_monitor_state.dart';
import 'package:privacy_gui/page/_shared/models/time_settings_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/traffic_analysis_state.dart';
import 'package:privacy_gui/page/_shared/models/wan_status_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/wifi_client_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/wifi_connection_info.dart';
import 'package:privacy_gui/page/_shared/models/wifi_radio_ui_model.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/admin/providers/time_data_provider.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/dmz/models/dmz_ui_model.dart';
import 'package:privacy_gui/page/firewall/models/firewall_ui_model.dart';
import 'package:privacy_gui/page/firewall/providers/firewall_data_provider.dart';
import 'package:privacy_gui/page/firewall/services/usp_firewall_service.dart';
import 'package:privacy_gui/page/internet_settings/providers/wan_data_provider.dart';
import 'package:privacy_gui/page/local_network/providers/dhcp_data_provider.dart';
import 'package:privacy_gui/page/local_network/providers/ethernet_data_provider.dart';
import 'package:privacy_gui/page/local_network/providers/lan_data_provider.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_triggering_rule_ui_model.dart';
import 'package:privacy_gui/page/port_forwarding/providers/port_forwarding_data_provider.dart';
import 'package:privacy_gui/page/port_forwarding/providers/port_triggering_data_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';

// ---------------------------------------------------------------------------
// System Info
// ---------------------------------------------------------------------------

const testSystemInfo = SystemInfoUIModel(
  manufacturer: 'Linksys',
  modelName: 'MR7500',
  serialNumber: 'ABC123456789',
  hardwareVersion: '1.0',
  softwareVersion: '1.0.16.215370',
  uptime: 300000,
  totalMemory: 524288,
  freeMemory: 204800,
  cpuUsage: 23,
);

final testSystemInfoData = SystemInfoData(model: testSystemInfo);

// ---------------------------------------------------------------------------
// Time Settings
// ---------------------------------------------------------------------------

const testTimeModel = TimeSettingsUIModel(
  enable: true,
  status: 'Synchronized',
  currentLocalTime: '2024-06-15T14:30:45-07:00',
  localTimeZone: 'America/Los_Angeles',
  ntpServer1: 'pool.ntp.org',
  ntpServer2: '',
);

final testTimeData = TimeData(model: testTimeModel);

const testTimeUnsyncModel = TimeSettingsUIModel(
  enable: true,
  status: 'Error',
  currentLocalTime: '2024-06-15T14:30:45-07:00',
  localTimeZone: 'America/Los_Angeles',
  ntpServer1: 'pool.ntp.org',
  ntpServer2: '',
);

final testTimeUnsyncData = TimeData(model: testTimeUnsyncModel);

// ---------------------------------------------------------------------------
// WAN Status
// ---------------------------------------------------------------------------

const testWanOnline = WanStatusUIModel(
  isUp: true,
  ipAddress: '203.0.113.42',
  subnetMask: '255.255.255.0',
  addressingType: 'DHCP',
  mtu: 1500,
  gateway: '203.0.113.1',
  ipv6Enabled: true,
  ipv6Addresses: ['2001:db8::1'],
);

const testWanOffline = WanStatusUIModel(
  isUp: false,
  ipAddress: '0.0.0.0',
  subnetMask: '0.0.0.0',
  addressingType: 'DHCP',
  mtu: 1500,
);

// WAN whose upstream assigns no global/ULA prefix — only a link-local
// (fe80::/10) address. The card still shows it, tagged with a scope badge.
const testWanLinkLocalOnly = WanStatusUIModel(
  isUp: true,
  ipAddress: '10.92.12.87',
  subnetMask: '255.255.255.0',
  addressingType: 'DHCP',
  mtu: 1500,
  gateway: '10.92.12.1',
  ipv6Enabled: true,
  ipv6Addresses: ['fe80::7612:13ff:fe21:5502'],
);

final testWanOnlineData = WanData(model: testWanOnline);
final testWanOfflineData = WanData(model: testWanOffline);
final testWanLinkLocalOnlyData = WanData(model: testWanLinkLocalOnly);

// ---------------------------------------------------------------------------
// LAN Info
// ---------------------------------------------------------------------------

const testLanDhcpEnabled = LanInfoUIModel(
  ipAddress: '192.168.1.1',
  subnetMask: '255.255.255.0',
  dhcpEnabled: true,
  minAddress: '192.168.1.100',
  maxAddress: '192.168.1.200',
  leaseTimeMinutes: 1440,
  dnsServers: '8.8.8.8, 8.8.4.4',
  ipv6Enabled: true,
  ipv6Addresses: ['fd00::1'],
);

// LAN whose bridge holds only a link-local (fe80::/10) address — no global/ULA
// prefix. The card still shows it, tagged with a scope badge.
const testLanLinkLocalOnly = LanInfoUIModel(
  ipAddress: '192.168.1.1',
  subnetMask: '255.255.255.0',
  dhcpEnabled: true,
  minAddress: '192.168.1.100',
  maxAddress: '192.168.1.200',
  leaseTimeMinutes: 1440,
  dnsServers: '8.8.8.8, 8.8.4.4',
  ipv6Enabled: true,
  ipv6Addresses: ['fe80::7612:13ff:fe21:5502'],
);

final testLanData = LanData(model: testLanDhcpEnabled);
final testLanLinkLocalOnlyData = LanData(model: testLanLinkLocalOnly);

const testLanDhcpDisabled = LanInfoUIModel(
  ipAddress: '192.168.1.1',
  subnetMask: '255.255.255.0',
  dhcpEnabled: false,
  minAddress: '',
  maxAddress: '',
  leaseTimeMinutes: 0,
  dnsServers: '',
  ipv6Enabled: false,
  ipv6Addresses: [],
);

final testLanDisabledData = LanData(model: testLanDhcpDisabled);

// ---------------------------------------------------------------------------
// Ethernet Ports
// ---------------------------------------------------------------------------

const testEthernetPorts = [
  EthernetPortUIModel(
    name: 'eth0',
    label: 'WAN',
    isWan: true,
    isUp: true,
    instancePath: 'Device.Ethernet.Interface.1.',
    currentBitRate: 1000,
    connectedDevices: [],
  ),
  EthernetPortUIModel(
    name: 'eth1',
    label: 'LAN 1',
    isWan: false,
    isUp: true,
    instancePath: 'Device.Ethernet.Interface.2.',
    currentBitRate: 1000,
    connectedDevices: [
      WiredDeviceInfo(
        hostName: 'Desktop-PC',
        macAddress: 'AA:BB:CC:DD:EE:01',
        ipAddress: '192.168.1.101',
      ),
    ],
  ),
  EthernetPortUIModel(
    name: 'eth2',
    label: 'LAN 2',
    isWan: false,
    isUp: true,
    instancePath: 'Device.Ethernet.Interface.3.',
    currentBitRate: 100,
    connectedDevices: [
      WiredDeviceInfo(
        hostName: 'NAS-Storage',
        macAddress: 'AA:BB:CC:DD:EE:02',
        ipAddress: '192.168.1.102',
      ),
      WiredDeviceInfo(
        hostName: 'Smart-TV',
        macAddress: 'AA:BB:CC:DD:EE:03',
        ipAddress: '192.168.1.103',
      ),
    ],
  ),
  EthernetPortUIModel(
    name: 'eth3',
    label: 'LAN 3',
    isWan: false,
    isUp: false,
    instancePath: 'Device.Ethernet.Interface.4.',
    currentBitRate: 0,
  ),
  EthernetPortUIModel(
    name: 'eth4',
    label: 'LAN 4',
    isWan: false,
    isUp: false,
    instancePath: 'Device.Ethernet.Interface.5.',
    currentBitRate: 0,
  ),
];

final testEthernetData = EthernetData(ethernetPortModels: testEthernetPorts);

// ---------------------------------------------------------------------------
// Connected Devices
// ---------------------------------------------------------------------------

final testDevices = [
  ClientDevice(
    mac: 'AA:BB:CC:DD:EE:01',
    ip: '192.168.1.101',
    hostName: 'Desktop-PC',
    isActive: true,
    connectionType: ConnectionType.wired,
  ),
  ClientDevice(
    mac: 'AA:BB:CC:DD:EE:02',
    ip: '192.168.1.102',
    hostName: 'iPhone-15',
    isActive: true,
    connectionType: ConnectionType.wifi,
    wifi: WifiConnectionInfo(
      signalStrength: -45,
      band: '5GHz',
      ssidName: 'HomeNetwork',
    ),
    parentNodeName: 'MR7500',
  ),
  ClientDevice(
    mac: 'AA:BB:CC:DD:EE:03',
    ip: '192.168.1.103',
    hostName: 'MacBook-Air',
    isActive: true,
    connectionType: ConnectionType.wifi,
    wifi: WifiConnectionInfo(
      signalStrength: -55,
      band: '5GHz',
      ssidName: 'HomeNetwork',
    ),
    parentNodeName: 'MR7500',
  ),
  ClientDevice(
    mac: 'AA:BB:CC:DD:EE:04',
    ip: '192.168.1.104',
    hostName: 'Smart-Speaker',
    isActive: true,
    connectionType: ConnectionType.wifi,
    wifi: WifiConnectionInfo(
      signalStrength: -65,
      band: '2.4GHz',
      ssidName: 'HomeNetwork',
    ),
  ),
  ClientDevice(
    mac: 'AA:BB:CC:DD:EE:05',
    ip: '192.168.1.105',
    hostName: 'Gaming-Console',
    isActive: true,
    connectionType: ConnectionType.wired,
  ),
  ClientDevice(
    mac: 'AA:BB:CC:DD:EE:06',
    ip: '192.168.1.106',
    hostName: 'Old-Tablet',
    isActive: false,
    connectionType: ConnectionType.wifi,
    wifi: WifiConnectionInfo(
      signalStrength: -80,
      band: '2.4GHz',
    ),
  ),
];

final testMeshNetwork = MeshNetwork(
  master: MasterNode(
    deviceId: 'GATEWAY',
    model: 'MR7500',
    manufacturer: 'Linksys',
    serialNumber: 'ABC123456789',
    softwareVersion: '1.0.16',
    connectedClients: testDevices,
  ),
);

final testDevicesData = DevicesData(meshNetwork: testMeshNetwork);

final testDevicesEmptyData = DevicesData(
  meshNetwork: MeshNetwork(
    master: MasterNode(
      deviceId: 'GATEWAY',
      model: 'MR7500',
      manufacturer: 'Linksys',
      serialNumber: 'ABC123456789',
      softwareVersion: '1.0.16',
      connectedClients: [],
    ),
  ),
);

// ---------------------------------------------------------------------------
// DHCP Reservations & Clients
// ---------------------------------------------------------------------------

final testDhcpReservations = [
  DhcpReservationUIModel(
    instancePath: 'Device.DHCPv4.Server.Pool.1.StaticAddress.1.',
    mac: 'AA:BB:CC:DD:EE:01',
    ip: '192.168.1.101',
    enable: true,
  ),
  DhcpReservationUIModel(
    instancePath: 'Device.DHCPv4.Server.Pool.1.StaticAddress.2.',
    mac: 'AA:BB:CC:DD:EE:05',
    ip: '192.168.1.105',
    enable: true,
  ),
  DhcpReservationUIModel(
    instancePath: 'Device.DHCPv4.Server.Pool.1.StaticAddress.3.',
    mac: 'AA:BB:CC:DD:EE:06',
    ip: '192.168.1.150',
    enable: false,
  ),
];

/// Active DHCP leases, with **now-relative** expiries (#1321).
///
/// These were `DateTime(2024, 6, 16, ...)`, and that is how #1183's gate came to
/// sweep this card at two widths it was overflowing at. `leaseTimeFormatted`
/// returns the empty string for a lease that is both expired and still active
/// (`dhcp_client_ui_model.dart:44-46`), so every one of these rendered an
/// IP-only trailing slot — about 50px narrower than any live router's — and the
/// gate measured a row production does not have. The fixture went dead on
/// 2024-06-16 on the wall clock, with nobody touching it, and the gate was built
/// after that date, so it had never once rendered a lease string.
///
/// The offsets are width-maximal, not arbitrary. `leaseTimeFormatted` buckets
/// into `Nd Nh` / `Nh Nm` / `Nm`, and measured as an overflow delta in the
/// normal form at 300px, `23h 59m` is the widest string the getter can produce —
/// 5.0px wider than the `days` bucket's own widest (`10d 23h`) and 22.0px wider
/// than a bare `59m`. The first client carries it so the gate sweeps the worst
/// case; the other two are shorter on purpose, so a row that only breaks at the
/// maximum is still distinguishable from one that breaks everywhere.
///
/// The trailing `seconds: 59` is load-bearing: without it the few milliseconds
/// between construction and layout drop `23h 59m` to `23h 58m`, which is a
/// narrower string, and the fixture would quietly stop measuring the maximum it
/// was written to measure.
///
/// **Known consequence.** A now-relative expiry makes the rendered string change
/// with the wall clock, so the `card_dhcp_reservations` golden gains a cell that
/// churns between baseline generation and verification. This is the sibling
/// fixture's existing behaviour rather than a new class of problem —
/// `test/golden_test/page/dhcp/fixtures/dhcp_test_data.dart:27` has shipped
/// `DateTime.now().add(...)` behind a golden that renders `leaseExpiryFormatted`,
/// an absolute `yyyy-MM-dd HH:mm` stamp, which churns every minute. The systemic
/// fix is a clock seam (`clock.now()` in the model, `withClock` in the golden
/// harness) covering both files; it is deliberately not done here, because a
/// production model change is outside what this ticket measured.
final testDhcpClients = [
  DhcpClientUIModel(
    mac: 'AA:BB:CC:DD:EE:02',
    ip: '192.168.1.102',
    leaseActive: true,
    isOnline: true,
    hostName: 'iPhone-15',
    // `23h 59m` — the widest string leaseTimeFormatted can render.
    leaseExpiry:
        DateTime.now().add(const Duration(hours: 23, minutes: 59, seconds: 59)),
  ),
  DhcpClientUIModel(
    mac: 'AA:BB:CC:DD:EE:03',
    ip: '192.168.1.103',
    leaseActive: true,
    isOnline: true,
    hostName: 'MacBook-Air',
    // `10h 30m`
    leaseExpiry:
        DateTime.now().add(const Duration(hours: 10, minutes: 30, seconds: 59)),
  ),
  DhcpClientUIModel(
    mac: 'AA:BB:CC:DD:EE:04',
    ip: '192.168.1.104',
    leaseActive: true,
    isOnline: true,
    hostName: 'Smart-Speaker',
    // `6h 15m`
    leaseExpiry:
        DateTime.now().add(const Duration(hours: 6, minutes: 15, seconds: 59)),
  ),
];

final testDhcpData = DhcpData(
  reservationModels: testDhcpReservations,
  clientModels: testDhcpClients,
);

final testDhcpEmptyData = DhcpData(
  reservationModels: const [],
  clientModels: const [],
);

// ---------------------------------------------------------------------------
// WiFi Data
// ---------------------------------------------------------------------------

const testRadios = [
  WifiRadioUIModel(
    instancePath: 'Device.WiFi.Radio.1.',
    band: '2.4GHz',
    enable: true,
    transmitPower: -1,
    maxBitRate: 574,
    channel: 6,
    autoChannelEnable: false,
    channelBandwidth: '40MHz',
    supportedStandards: '802.11b/g/n/ax',
    accessPoints: [
      WifiAccessPointUIModel(
        enable: true,
        ssidName: 'HomeNetwork',
        securityMode: 'WPA2-Personal',
        encryptionMode: 'AES',
      ),
      WifiAccessPointUIModel(
        enable: true,
        ssidName: 'HomeNetwork-Guest',
        securityMode: 'WPA2-Personal',
        encryptionMode: 'AES',
        isGuest: true,
      ),
    ],
  ),
  WifiRadioUIModel(
    instancePath: 'Device.WiFi.Radio.2.',
    band: '5GHz',
    enable: true,
    transmitPower: -1,
    maxBitRate: 4804,
    channel: 36,
    autoChannelEnable: true,
    channelBandwidth: '160MHz',
    supportedStandards: '802.11a/n/ac/ax',
    accessPoints: [
      WifiAccessPointUIModel(
        enable: true,
        ssidName: 'HomeNetwork',
        securityMode: 'WPA3-Personal',
        encryptionMode: 'AES',
      ),
      WifiAccessPointUIModel(
        enable: false,
        ssidName: 'HomeNetwork-Guest',
        securityMode: 'WPA2-Personal',
        encryptionMode: 'AES',
        isGuest: true,
      ),
    ],
  ),
];

const testWifiClients = {
  'AA:BB:CC:DD:EE:02': WifiClientUIModel(
    macAddress: 'AA:BB:CC:DD:EE:02',
    signalStrength: -45,
    noise: -95,
    lastDataDownlinkRate: 866000,
    lastDataUplinkRate: 573000,
    active: true,
  ),
  'AA:BB:CC:DD:EE:03': WifiClientUIModel(
    macAddress: 'AA:BB:CC:DD:EE:03',
    signalStrength: -55,
    noise: -95,
    lastDataDownlinkRate: 720000,
    lastDataUplinkRate: 450000,
    active: true,
  ),
  'AA:BB:CC:DD:EE:04': WifiClientUIModel(
    macAddress: 'AA:BB:CC:DD:EE:04',
    signalStrength: -65,
    noise: -95,
    lastDataDownlinkRate: 144000,
    lastDataUplinkRate: 72000,
    active: true,
  ),
};

const testConnectionDetails = {
  'AA:BB:CC:DD:EE:02': ClientConnectionDetail(
    band: '5GHz',
    ssidName: 'HomeNetwork',
  ),
  'AA:BB:CC:DD:EE:03': ClientConnectionDetail(
    band: '5GHz',
    ssidName: 'HomeNetwork',
  ),
  'AA:BB:CC:DD:EE:04': ClientConnectionDetail(
    band: '2.4GHz',
    ssidName: 'HomeNetwork',
  ),
};

final testWifiData = WifiData(
  codegenContext: WifiCodegenContext.empty,
  radioModels: testRadios,
  wifiClientMap: testWifiClients,
  connectionDetailMap: testConnectionDetails,
);

final testWifiEmptyData = WifiData(
  codegenContext: WifiCodegenContext.empty,
  radioModels: const [],
  wifiClientMap: const {},
  connectionDetailMap: const {},
);

// ─── Tri-band profile (#1267) ───────────────────────────────────────────────

/// [testRadios] plus a third, tri-band radio — the gate's second data profile.
///
/// ## Why a second radio set exists at all
///
/// The gate sweeps 26 locales × every width realization × every tab against
/// **one** router shape, and [testRadios] is two radios with 2-digit channels and
/// `160MHz` as the widest bandwidth. Every "clean" verdict it issues is a verdict
/// about that shape, and the sweep's own thoroughness makes it read as broader
/// than it is: #1266 found the WiFi Performance Channels tab clean in all 26
/// locales at both widths on this profile, and overflowing on a tri-band router
/// it had no way to express (#1267).
///
/// ## Why these values
///
/// Spread out rather than derived from the 5GHz radio, because each field is the
/// widest thing a shipping router can put in the band/channel string:
///
///  - `channel: 233` with `autoChannelEnable` — 3 digits *plus* the ` (Auto)`
///    suffix `channelDisplay` appends, which is the longest form that getter can
///    produce ([WifiRadioUIModel.channelDisplay]).
///  - `channelBandwidth: '320MHz'` — 6GHz-only, and one glyph wider than the
///    `160MHz` this fixture's other radios cap out at.
///  - a third radio at all, which is what multiplies the tab's per-radio blocks
///    from two to three. On the card as #1266 measured it, that squeezed the
///    band-distribution donut below them into ~40px and it painted over the
///    block above; #1267 removed the donut, so what a third radio costs now is
///    just its own block.
///
/// Spliced onto [testRadios] rather than restating it: the two profiles must
/// differ in exactly the third radio, or a later edit to the shared two makes the
/// comparison between profiles meaningless.
final testRadiosTriBand = [
  ...testRadios,
  const WifiRadioUIModel(
    instancePath: 'Device.WiFi.Radio.3.',
    band: '6GHz',
    enable: true,
    transmitPower: -1,
    maxBitRate: 11529,
    channel: 233,
    autoChannelEnable: true,
    channelBandwidth: '320MHz',
    supportedStandards: '802.11a/n/ac/ax/be',
    accessPoints: [
      WifiAccessPointUIModel(
        enable: true,
        ssidName: 'HomeNetwork',
        securityMode: 'WPA3-Personal',
        encryptionMode: 'AES',
      ),
    ],
  ),
];

/// [testWifiData] with the tri-band radio set and **the same clients**.
///
/// The clients are deliberately unchanged, so the third radio carries none: that
/// is both the state #1266 measured and a real one (a 6GHz radio nobody has
/// joined yet), and it keeps the profile's single variable single. Since #1271
/// that radio's row reads `SNR: —` with no bar rather than `SNR: 0 dB` with an
/// empty one.
final testWifiDataTriBand = WifiData(
  codegenContext: testWifiData.codegenContext,
  radioModels: testRadiosTriBand,
  wifiClientMap: testWifiData.wifiClientMap,
  connectionDetailMap: testWifiData.connectionDetailMap,
);

// ─── Six-radio profile: the scroll net's test load (#1267) ───────────────────

/// Six radios — a router shape that exists to make the WiFi Performance Channels
/// tab taller than the card can ever be.
///
/// ## Why an unrealistic router is the right fixture here
///
/// #1267 made that tab scroll, so content taller than the card has somewhere to
/// go instead of being painted over the text above it. A mechanism with no load
/// on it is untested, and after the donut was removed nothing in the repo could
/// supply the load: three radio blocks leave roughly 120px of slack at the
/// narrowest card, so [testRadiosTriBand] now *fits*, and the test that used to
/// overflow is green for a reason that has nothing to do with scrolling.
///
/// Shipping hardware reaches four (2.4GHz + two 5GHz + 6GHz) and five with a
/// dedicated backhaul radio, so the honest description of this fixture is "one
/// past today's maximum". Five is the first count that overflows, and only by
/// ~7px — close enough to the gate's 2.0px tolerance that a font-metric change
/// could flip it, which is no basis for an assertion. Six clears the viewport by
/// ~80px, so the test measures the mechanism rather than the margin.
///
/// It is deliberately **not** in the gate's sweep list (`card_data_profiles.dart`):
/// coordinates recorded against a router nobody sells would be permanent
/// allowlist entries nobody can ever clear.
///
/// Band strings repeat (three 5GHz, two 6GHz) exactly as a quad-band router
/// reports them, and client aggregation groups by band — so of two radios both
/// labelled `5GHz`, one gets the band's clients and the other reads `0 clients` /
/// `SNR: —`. Irrelevant to a height test, and stated here so the next reader does
/// not mistake this for a per-radio-attribution fixture: that claim belongs to
/// `wifi_snr_render_parity_test.dart`, which uses distinct bands.
final testRadiosSixRadio = [
  ...testRadiosTriBand,
  for (final (i, spec) in <({String band, int channel, String bandwidth})>[
    (band: '5GHz', channel: 149, bandwidth: '160MHz'),
    (band: '6GHz', channel: 197, bandwidth: '320MHz'),
    (band: '5GHz', channel: 100, bandwidth: '80MHz'),
  ].indexed)
    WifiRadioUIModel(
      instancePath: 'Device.WiFi.Radio.${4 + i}.',
      band: spec.band,
      enable: true,
      transmitPower: -1,
      maxBitRate: 11529,
      channel: spec.channel,
      autoChannelEnable: true,
      channelBandwidth: spec.bandwidth,
      supportedStandards: '802.11a/n/ac/ax/be',
      accessPoints: const [
        WifiAccessPointUIModel(
          enable: true,
          ssidName: 'HomeNetwork',
          securityMode: 'WPA3-Personal',
          encryptionMode: 'AES',
        ),
      ],
    ),
];

/// [testWifiData] with [testRadiosSixRadio] and the same clients.
final testWifiDataSixRadio = WifiData(
  codegenContext: testWifiData.codegenContext,
  radioModels: testRadiosSixRadio,
  wifiClientMap: testWifiData.wifiClientMap,
  connectionDetailMap: testWifiData.connectionDetailMap,
);

const testRadiosOneDisabled = [
  WifiRadioUIModel(
    instancePath: 'Device.WiFi.Radio.1.',
    band: '2.4GHz',
    enable: true,
    transmitPower: -1,
    maxBitRate: 574,
    channel: 6,
    autoChannelEnable: false,
    channelBandwidth: '40MHz',
    supportedStandards: '802.11b/g/n/ax',
    accessPoints: [
      WifiAccessPointUIModel(
        enable: true,
        ssidName: 'HomeNetwork',
        securityMode: 'WPA2-Personal',
        encryptionMode: 'AES',
      ),
    ],
  ),
  WifiRadioUIModel(
    instancePath: 'Device.WiFi.Radio.2.',
    band: '5GHz',
    enable: false,
    transmitPower: -1,
    maxBitRate: 4804,
    channel: 36,
    autoChannelEnable: true,
    channelBandwidth: '160MHz',
    supportedStandards: '802.11a/n/ac/ax',
    accessPoints: [
      WifiAccessPointUIModel(
        enable: false,
        ssidName: 'HomeNetwork',
        securityMode: 'WPA3-Personal',
        encryptionMode: 'AES',
      ),
    ],
  ),
];

final testWifiOneDisabledData = WifiData(
  codegenContext: WifiCodegenContext.empty,
  radioModels: testRadiosOneDisabled,
  wifiClientMap: testWifiClients,
  connectionDetailMap: testConnectionDetails,
);

// ---------------------------------------------------------------------------
// Port Forwarding & Triggering
// ---------------------------------------------------------------------------

const testPortForwardingRules = [
  PortForwardingRuleUIModel(
    instancePath: 'Device.NAT.PortMapping.1.',
    description: 'Web Server',
    externalPort: 8080,
    internalPort: 80,
    internalClient: '192.168.1.101',
    protocol: 'TCP',
    enabled: true,
  ),
  PortForwardingRuleUIModel(
    instancePath: 'Device.NAT.PortMapping.2.',
    description: 'Game Server',
    externalPort: 27015,
    internalPort: 27015,
    internalClient: '192.168.1.105',
    protocol: 'Both',
    enabled: true,
  ),
  PortForwardingRuleUIModel(
    instancePath: 'Device.NAT.PortMapping.3.',
    description: 'SSH Access',
    externalPort: 2222,
    internalPort: 22,
    internalClient: '192.168.1.101',
    protocol: 'TCP',
    enabled: false,
  ),
];

const testPortTriggeringRules = [
  PortTriggeringRuleUIModel(
    instancePath: 'Device.NAT.PortTrigger.1.',
    enabled: true,
    description: 'FTP Trigger',
    triggerPort: 21,
    triggerProtocol: 'TCP',
  ),
];

final testPortForwardingData =
    PortForwardingData(ruleModels: testPortForwardingRules);
final testPortTriggeringData =
    PortTriggeringData(ruleModels: testPortTriggeringRules);
final testPortForwardingEmptyData = PortForwardingData(ruleModels: const []);
final testPortTriggeringEmptyData = PortTriggeringData(ruleModels: const []);

// ---------------------------------------------------------------------------
// Firewall Data
// ---------------------------------------------------------------------------

final testFirewallData = FirewallData(
  firewallModel: const FirewallUIModel(
    isIPv4FirewallEnabled: true,
    isIPv6FirewallEnabled: true,
    blockIPSec: false,
    blockPPTP: false,
    blockL2TP: false,
    blockAnonymousRequests: true,
    blockMulticast: true,
    blockIDENT: false,
  ),
  ruleContext: FirewallRuleContext.empty,
  ruleSummaries: const [
    FirewallRuleSummary(target: 'DROP', enabled: true),
    FirewallRuleSummary(target: 'DROP', enabled: true),
    FirewallRuleSummary(target: 'ACCEPT', enabled: true),
    FirewallRuleSummary(target: 'DROP', enabled: false),
    FirewallRuleSummary(target: 'REJECT', enabled: true),
  ],
  dmzModel: const DmzUIModel.disabled(),
  dmzSummaries: const [
    DmzEntrySummary(enable: true, destIp: '192.168.1.200'),
  ],
);

final testFirewallEmptyData = FirewallData(
  firewallModel: const FirewallUIModel(
    isIPv4FirewallEnabled: false,
    isIPv6FirewallEnabled: false,
    blockIPSec: false,
    blockPPTP: false,
    blockL2TP: false,
    blockAnonymousRequests: false,
    blockMulticast: false,
    blockIDENT: false,
  ),
  ruleContext: FirewallRuleContext.empty,
  ruleSummaries: const [],
  dmzModel: const DmzUIModel.disabled(),
  dmzSummaries: const [],
);

// ---------------------------------------------------------------------------
// System Monitor
// ---------------------------------------------------------------------------

/// The clock every history series here hangs off — **now-relative, truncated to
/// the hour** (#1321).
///
/// This was `DateTime(2024, 6, 15, 14, 0, 0)`, the second member of the same
/// class as [testDhcpClients]: a fixture whose renderer compares it against
/// `DateTime.now()`. `usp_device_analytics_card.dart:350-357` and `:425-431` build
/// a 24-slot axis ending at the *current* hour and look each slot up by exact
/// `DateTime` equality, so none of the 12 `hourlyHistory` entries matched any
/// slot and both the trend chart and the heatmap rendered as all-zero. The gate
/// swept four tabs of that card against an empty chart.
///
/// Unlike the lease row, this one was never a *bug* — 4 tabs × {stale fixture,
/// now-relative fixture} at 260.5px measure clean either way, because a zero bar
/// and a full bar occupy the same box. It is a coverage weakness, and it is fixed
/// here because a fixture that renders nothing is the thing #1321 is about.
///
/// **Truncating to the hour is what makes it work**, not a tidiness choice: the
/// lookup is `==` against `DateTime(now.year, now.month, now.day, now.hour)`, so
/// a `_baseTime` carrying minutes or seconds would still miss every slot and the
/// charts would stay empty while looking fixed.
///
/// This adds no churn class to the `device_analytics` golden that the card does
/// not already have. Its heatmap axis renders wall-clock hour labels — `'00'`,
/// `'06'`, `'12'`, `'18'` at slot positions derived from `DateTime.now()`
/// (`:448`) — so that image already moves once an hour on its own, regardless of
/// what this fixture holds.
final _baseTime = _currentHour();

DateTime _currentHour() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day, now.hour);
}

final testSystemMonitorWithHistory = SystemMonitorState(
  history: List.generate(
    10,
    (i) => SystemSnapshot(
      timestamp: _baseTime.add(Duration(seconds: i * 10)),
      cpuPercent: 20 + (i * 3) % 40,
      memoryPercent: 55 + (i * 2) % 20,
      totalMemoryKb: 524288,
      freeMemoryKb: 234288 - i * 5000,
      uptimeSeconds: 86400 + i * 10,
    ),
  ),
  refreshInterval: Duration(seconds: 10),
);

const testSystemMonitorEmpty = SystemMonitorState();

// ---------------------------------------------------------------------------
// Traffic Analysis
// ---------------------------------------------------------------------------

final testTrafficWithHistory = TrafficAnalysisState(
  history: List.generate(
    10,
    (i) => MultiInterfaceSnapshot(
      timestamp: _baseTime.add(Duration(seconds: i * 5)),
      interfaces: {
        TrafficInterface.wan: InterfaceTrafficSnapshot(
          uploadBytesPerSec: 50000.0 + i * 10000,
          downloadBytesPerSec: 200000.0 + i * 30000,
          totalBytesSent: 5000000 + i * 50000,
          totalBytesReceived: 20000000 + i * 200000,
          totalPacketsSent: 5000 + i * 50,
          totalPacketsReceived: 20000 + i * 200,
          uploadPacketsPerSec: 50.0 + i * 5,
          downloadPacketsPerSec: 200.0 + i * 20,
          errorsSentPerSec: i * 0.05,
          errorsReceivedPerSec: i * 0.05,
        ),
        TrafficInterface.lan: InterfaceTrafficSnapshot(
          uploadBytesPerSec: 100000.0 + i * 20000,
          downloadBytesPerSec: 150000.0 + i * 15000,
          totalBytesSent: 10000000 + i * 100000,
          totalBytesReceived: 15000000 + i * 150000,
          totalPacketsSent: 10000 + i * 100,
          totalPacketsReceived: 15000 + i * 150,
          uploadPacketsPerSec: 100.0 + i * 10,
          downloadPacketsPerSec: 150.0 + i * 15,
        ),
      },
    ),
  ),
  refreshInterval: Duration(seconds: 5),
);

const testTrafficEmpty = TrafficAnalysisState();

/// Variant of [testTrafficWithHistory] that carries a constant, non-zero WAN
/// discard rate so the Errors-tab "Discards" legend renders a formatted value
/// (avg 3.0/s) rather than the default 0. Used to cover the non-zero discards
/// path, which the base fixture leaves at 0 (#1145 review-fix).
final testTrafficWithDiscards = TrafficAnalysisState(
  history: List.generate(
    10,
    (i) => MultiInterfaceSnapshot(
      timestamp: _baseTime.add(Duration(seconds: i * 5)),
      interfaces: {
        TrafficInterface.wan: InterfaceTrafficSnapshot(
          uploadBytesPerSec: 50000.0 + i * 10000,
          downloadBytesPerSec: 200000.0 + i * 30000,
          totalBytesSent: 5000000 + i * 50000,
          totalBytesReceived: 20000000 + i * 200000,
          totalPacketsSent: 5000 + i * 50,
          totalPacketsReceived: 20000 + i * 200,
          uploadPacketsPerSec: 50.0 + i * 5,
          downloadPacketsPerSec: 200.0 + i * 20,
          errorsSentPerSec: i * 0.05,
          errorsReceivedPerSec: i * 0.05,
          discardsSentPerSec: 1.5,
          discardsReceivedPerSec: 1.5,
        ),
      },
    ),
  ),
  refreshInterval: Duration(seconds: 5),
);

// ---------------------------------------------------------------------------
// Device Analytics
// ---------------------------------------------------------------------------

final testDeviceAnalyticsWithData = DeviceAnalyticsState(
  current: DeviceDistribution(
    onlineCount: 5,
    offlineCount: 1,
    wifiCount: 3,
    wiredCount: 2,
    bandDistribution: const {'2.4GHz': 1, '5GHz': 2},
    bandSignalQuality: const {'2.4GHz': 0.6, '5GHz': 0.85, '6GHz': 0.0},
    signalLevelDistribution: const {3: 1, 2: 1, 1: 1},
  ),
  hourlyHistory: List.generate(
    12,
    (i) => HourlyAggregate(
      hour: _baseTime.subtract(Duration(hours: 11 - i)),
      wifiCount: 2 + (i % 3),
      wiredCount: 2,
      activeMacs: {'AA:BB:CC:DD:EE:02', 'AA:BB:CC:DD:EE:03'},
    ),
  ),
  allKnownMacs: const {'AA:BB:CC:DD:EE:02', 'AA:BB:CC:DD:EE:03'},
  macDisplayNames: const {
    'AA:BB:CC:DD:EE:02': 'iPhone-15',
    'AA:BB:CC:DD:EE:03': 'MacBook-Air',
  },
);

const testDeviceAnalyticsEmpty = DeviceAnalyticsState();
