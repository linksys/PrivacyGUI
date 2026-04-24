/**
 * Device.WiFi.AccessPoint.* — WiFiAccessPoints (multi-instance, 8 paths per AP)
 * AP.1 links to SSID.1 (5 GHz), AP.2 links to SSID.2 (2.4 GHz)
 */
export const wifiAccessPointsData: Record<string, string> = {
  // AP 1 — 5 GHz
  'Device.WiFi.AccessPoint.1.Enable': 'true',
  'Device.WiFi.AccessPoint.1.Status': 'Enabled',
  'Device.WiFi.AccessPoint.1.Security.ModesSupported': 'WPA2-Personal,WPA3-Personal,WPA2-WPA3-Personal',
  'Device.WiFi.AccessPoint.1.Security.ModeEnabled': 'WPA2-WPA3-Personal',
  'Device.WiFi.AccessPoint.1.Security.EncryptionMode': 'AESEncryption',
  'Device.WiFi.AccessPoint.1.Security.KeyPassphrase': 'e2e-test-pass-5g',
  'Device.WiFi.AccessPoint.1.SSIDAdvertisementEnabled': 'true',
  'Device.WiFi.AccessPoint.1.SSIDReference': 'Device.WiFi.SSID.1.',

  // AP 2 — 2.4 GHz
  'Device.WiFi.AccessPoint.2.Enable': 'true',
  'Device.WiFi.AccessPoint.2.Status': 'Enabled',
  'Device.WiFi.AccessPoint.2.Security.ModesSupported': 'WPA2-Personal,WPA3-Personal,WPA2-WPA3-Personal',
  'Device.WiFi.AccessPoint.2.Security.ModeEnabled': 'WPA2-Personal',
  'Device.WiFi.AccessPoint.2.Security.EncryptionMode': 'AESEncryption',
  'Device.WiFi.AccessPoint.2.Security.KeyPassphrase': 'e2e-test-pass-24g',
  'Device.WiFi.AccessPoint.2.SSIDAdvertisementEnabled': 'true',
  'Device.WiFi.AccessPoint.2.SSIDReference': 'Device.WiFi.SSID.2.',
};

/**
 * Device.WiFi.AccessPoint.*.AssociatedDevice.* — WiFi clients (enrichment)
 * One client connected to AP.1 (5 GHz)
 */
export const wifiClientsData: Record<string, string> = {
  'Device.WiFi.AccessPoint.1.AssociatedDevice.1.MACAddress': '11:22:33:44:55:66',
  'Device.WiFi.AccessPoint.1.AssociatedDevice.1.SignalStrength': '-45',
  'Device.WiFi.AccessPoint.1.AssociatedDevice.1.Noise': '-90',
  'Device.WiFi.AccessPoint.1.AssociatedDevice.1.LastDataDownlinkRate': '866',
  'Device.WiFi.AccessPoint.1.AssociatedDevice.1.LastDataUplinkRate': '433',
  'Device.WiFi.AccessPoint.1.AssociatedDevice.1.Active': 'true',
};
