import 'package:privacy_gui/generated/admin_users.g.dart';
import 'package:privacy_gui/generated/connected_devices.g.dart';
import 'package:privacy_gui/generated/data_elements_interfaces.g.dart';
import 'package:privacy_gui/generated/data_elements_network.g.dart';
import 'package:privacy_gui/generated/dhcp_clients.g.dart';
import 'package:privacy_gui/generated/dhcp_reservations.g.dart';
import 'package:privacy_gui/generated/dmz.g.dart';
import 'package:privacy_gui/generated/ethernet_interfaces.g.dart';
import 'package:privacy_gui/generated/firewall_chain_rules.g.dart';
import 'package:privacy_gui/generated/firmware_images.g.dart';
import 'package:privacy_gui/generated/port_forwarding.g.dart';
import 'package:privacy_gui/generated/port_triggering.g.dart';
import 'package:privacy_gui/generated/time_zones.g.dart';
import 'package:privacy_gui/generated/vendor_log_files.g.dart';
import 'package:privacy_gui/generated/wi_fi_access_points.g.dart';
import 'package:privacy_gui/generated/wi_fi_radios.g.dart';
import 'package:privacy_gui/generated/wi_fi_ssids.g.dart';
import 'package:privacy_gui/generated/wifi_clients.g.dart';

// Rows whose every value is blank, which usp-codegen 0.17 dropped as phantoms
// and 0.18 returns like any other row (#1654). Each check reads the same
// fields the 0.17 skip read, so filtering on it shows what 0.17 showed.
//
// Every such check lives here, so a table's check is found by its row type.
// It lives under services/ because only services filter generated rows.

/// Whether [value] is what a blank TR-181 leaf parses to: null, '', '0',
/// 'false', 0, false, or the epoch a missing dateTime parses to.
bool isBlank(Object? value) => switch (value) {
      null => true,
      final String s => s.isEmpty || s == '0' || s == 'false',
      final num n => n == 0,
      final bool b => !b,
      final DateTime d => d.millisecondsSinceEpoch == 0,
      _ => false,
    };

/// A DHCP lease row with no client address, state or lease.
bool isEmptyDhcpClient(DhcpClient c) {
  final v4 = c.ipv4Addresses.firstOrNull;
  return [c.chaddr, c.active, v4?.ipAddress, v4?.leaseTimeRemaining]
      .every(isBlank);
}

/// A DHCP reservation row with no MAC, address or state.
bool isEmptyDhcpReservation(DhcpReservation r) =>
    [r.enable, r.chaddr, r.yiaddr].every(isBlank);

/// A DMZ row with no host, source, interface or state. Its MAC is new in
/// usp-codegen 0.18 and was not read.
bool isEmptyDmzEntry(DmzEntry d) => [
      d.enable,
      d.destIp,
      d.sourcePrefix,
      d.interface_,
      d.description,
      d.status,
    ].every(isBlank);

/// A firmware bank row with no image, version or state.
bool isEmptyFirmwareImage(FirmwareImage f) =>
    [f.alias, f.name, f.version, f.status, f.available].every(isBlank);

/// A firewall rule row with no name, target or state.
bool isEmptyFirewallChainRule(FirewallChainRule r) =>
    [r.enable, r.description, r.target].every(isBlank);

/// A Wi-Fi SSID row with no name, state, BSSID or radio.
bool isEmptyWiFiSsid(WiFiSsid s) => [
      s.alias,
      s.ssid,
      s.enable,
      s.status,
      s.bssid,
      s.lowerLayers
    ].every(isBlank);

/// A Wi-Fi access point row with no SSID, state or security.
bool isEmptyWiFiAccessPoint(WiFiAccessPoint a) => [
      a.alias,
      a.enable,
      a.status,
      a.modesSupported,
      a.securityModeEnabled,
      a.encryptionMode,
      a.keyPassphrase,
      a.ssidAdvertisementEnabled,
      a.ssidReference,
    ].every(isBlank);

/// A Wi-Fi radio row with no band, channel or capability.
bool isEmptyWiFiRadio(WiFiRadio r) => [
      r.alias,
      r.enable,
      r.status,
      r.channel,
      r.operatingFrequencyBand,
      r.operatingChannelBandwidth,
      r.possibleChannels,
      r.operatingStandards,
      r.supportedStandards,
      r.transmitPower,
      r.maxBitRate,
      r.autoChannelEnable,
      r.ieee80211hEnabled,
      r.supportedOperatingChannelBandwidths,
    ].every(isBlank);

/// A mesh node row with no ID, identity or backhaul. Its radios are not
/// read, as 0.17 did not read them.
bool isEmptyMeshNode(MeshNode n) => [
      n.id,
      n.manufacturerModel,
      n.manufacturer,
      n.serialNumber,
      n.softwareVersion,
      n.collectionInterval,
      n.multiApLastContactTime,
      n.multiApEasyMeshAgentOperationMode,
      n.backhaulLinkType,
      n.backhaulBackhaulDeviceId,
      n.backhaulBackhaulMacAddress,
      n.backhaulMacAddressMultiAp,
      n.prplServingBssid,
      n.prplBackhaulRadioUid,
      n.backhaulStatsLastDataDownlinkRate,
      n.backhaulStatsLastDataUplinkRate,
      n.backhaulStatsSignalStrengthRcpi,
      n.backhaulStatsPacketsSent,
      n.backhaulStatsPacketsReceived,
      n.backhaulStatsErrorsSent,
      n.backhaulStatsErrorsReceived,
      n.backhaulStatsTimeStamp,
    ].every(isBlank);

/// A mesh node row from the interfaces read with no ID. Its interface MACs are
/// not the mesh's own.
bool isEmptyMeshInterfaceNode(MeshNodeInterfaces n) => isBlank(n.id);

/// A `Hosts.Host` row with every value blank. Its address lists are not read,
/// as 0.17 did not read them.
bool isEmptyConnectedDevice(ConnectedDevice d) => [
      d.macAddress,
      d.ipAddress,
      d.hostName,
      d.isActive,
      d.activeLastChange,
      d.interface_,
      d.layer3Interface,
      d.interfaceType,
      d.addressSource,
      d.dhcpClient,
      d.associatedDevice,
      d.deviceId,
      d.deviceRole,
      d.friendlyName,
      d.manufacturer,
      d.modelName,
      d.operatingSystem,
      d.parentNodeId,
      d.signalStrength,
      d.lastDataDownlinkRate,
      d.lastDataUplinkRate,
      d.linksysManufacturer,
      d.linksysModelName,
      d.linksysOperatingSystem,
      d.linksysDeviceType,
      d.linksysFriendlyName,
      d.linksysUserDeviceName,
      d.linksysUserDeviceLocation,
      d.linksysUserDeviceType,
    ].every(isBlank);

/// A Wi-Fi client row with no MAC, signal, rate or state.
bool isEmptyWifiClient(WifiClient c) => [
      c.macAddress,
      c.signalStrength,
      c.noise,
      c.lastDataDownlinkRate,
      c.lastDataUplinkRate,
      c.active,
    ].every(isBlank);

/// An Ethernet port row with no name, state or speed.
bool isEmptyEthernetInterface(EthernetInterface i) => [
      i.alias,
      i.name,
      i.status,
      i.upstream,
      i.currentBitRate,
    ].every(isBlank);

/// A port forwarding rule row with no ports, client, protocol or state.
bool isEmptyPortForwardingRule(PortForwardingRule r) => [
      r.enabled,
      r.externalPort,
      r.externalPortEndRange,
      r.internalPort,
      r.internalClient,
      r.protocol,
      r.description,
    ].every(isBlank);

/// A port trigger row with no trigger port, protocol or state. Its forward
/// rules are not read, as 0.17 did not read them.
bool isEmptyPortTrigger(PortTrigger t) => [
      t.enabled,
      t.description,
      t.triggerPort,
      t.triggerPortEndRange,
      t.triggerProtocol,
    ].every(isBlank);

/// A vendor log file row with no name, size or persistence.
bool isEmptyVendorLogFile(VendorLogFile f) =>
    [f.name, f.maximumSize, f.persistent].every(isBlank);

/// A time zone row with no ID, offset, DST flag or label.
bool isEmptyTimeZone(TimeZoneEntry z) => [
      z.timeZoneId,
      z.utcOffsetMinutes,
      z.observesDst,
      z.description,
    ].every(isBlank);

/// An admin user row with no name, password or state.
bool isEmptyAdminUser(AdminUser u) =>
    [u.username, u.password, u.enable].every(isBlank);
