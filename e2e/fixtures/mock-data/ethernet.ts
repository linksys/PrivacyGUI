/**
 * Device.Ethernet.Interface.* — EthernetInterfaces (multi-instance, 4 paths)
 * Interface.1 = LAN (eth1), Interface.2 = WAN (eth0)
 * Note: Upstream flag is inverted on M60TB (Interface.1 Upstream=true is LAN)
 */
export const ethernetData: Record<string, string> = {
  // Interface 1 — LAN
  'Device.Ethernet.Interface.1.Name': 'eth1',
  'Device.Ethernet.Interface.1.Status': 'Up',
  'Device.Ethernet.Interface.1.Upstream': 'true',
  'Device.Ethernet.Interface.1.CurrentBitRate': '1000',

  // Interface 2 — WAN
  'Device.Ethernet.Interface.2.Name': 'eth0',
  'Device.Ethernet.Interface.2.Status': 'Up',
  'Device.Ethernet.Interface.2.Upstream': 'false',
  'Device.Ethernet.Interface.2.CurrentBitRate': '1000',
};
