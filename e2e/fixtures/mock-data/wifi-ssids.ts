/**
 * Device.WiFi.SSID.* — WiFiSsids (multi-instance, 5 paths per SSID)
 * SSID.1 = 5 GHz network, SSID.2 = 2.4 GHz network
 * LowerLayers links to corresponding Radio
 */
export const wifiSsidsData: Record<string, string> = {
  // SSID 1 — 5 GHz
  'Device.WiFi.SSID.1.SSID': 'E2E-TestNet-5G',
  'Device.WiFi.SSID.1.Enable': 'true',
  'Device.WiFi.SSID.1.Status': 'Up',
  'Device.WiFi.SSID.1.BSSID': 'AA:BB:CC:DD:EE:01',
  'Device.WiFi.SSID.1.LowerLayers': 'Device.WiFi.Radio.1.',

  // SSID 2 — 2.4 GHz
  'Device.WiFi.SSID.2.SSID': 'E2E-TestNet-2.4G',
  'Device.WiFi.SSID.2.Enable': 'true',
  'Device.WiFi.SSID.2.Status': 'Up',
  'Device.WiFi.SSID.2.BSSID': 'AA:BB:CC:DD:EE:02',
  'Device.WiFi.SSID.2.LowerLayers': 'Device.WiFi.Radio.2.',
};
