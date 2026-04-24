/**
 * Device.WiFi.Radio.* — WiFiRadios (multi-instance, 13 paths per radio)
 * Radio.1 = 5 GHz, Radio.2 = 2.4 GHz
 */
export const wifiRadiosData: Record<string, string> = {
  // Radio 1 — 5 GHz
  'Device.WiFi.Radio.1.Enable': 'true',
  'Device.WiFi.Radio.1.Status': 'Up',
  'Device.WiFi.Radio.1.Channel': '36',
  'Device.WiFi.Radio.1.OperatingFrequencyBand': '5GHz',
  'Device.WiFi.Radio.1.OperatingChannelBandwidth': '80MHz',
  'Device.WiFi.Radio.1.PossibleChannels': '36,40,44,48,149,153,157,161,165',
  'Device.WiFi.Radio.1.OperatingStandards': 'ax',
  'Device.WiFi.Radio.1.SupportedStandards': 'a,n,ac,ax',
  'Device.WiFi.Radio.1.TransmitPower': '100',
  'Device.WiFi.Radio.1.MaxBitRate': '4804',
  'Device.WiFi.Radio.1.AutoChannelEnable': 'true',
  'Device.WiFi.Radio.1.IEEE80211hEnabled': 'true',
  'Device.WiFi.Radio.1.SupportedOperatingChannelBandwidths': '20MHz,40MHz,80MHz,160MHz',

  // Radio 2 — 2.4 GHz
  'Device.WiFi.Radio.2.Enable': 'true',
  'Device.WiFi.Radio.2.Status': 'Up',
  'Device.WiFi.Radio.2.Channel': '6',
  'Device.WiFi.Radio.2.OperatingFrequencyBand': '2.4GHz',
  'Device.WiFi.Radio.2.OperatingChannelBandwidth': '40MHz',
  'Device.WiFi.Radio.2.PossibleChannels': '1,2,3,4,5,6,7,8,9,10,11',
  'Device.WiFi.Radio.2.OperatingStandards': 'ax',
  'Device.WiFi.Radio.2.SupportedStandards': 'b,g,n,ax',
  'Device.WiFi.Radio.2.TransmitPower': '100',
  'Device.WiFi.Radio.2.MaxBitRate': '574',
  'Device.WiFi.Radio.2.AutoChannelEnable': 'true',
  'Device.WiFi.Radio.2.IEEE80211hEnabled': 'false',
  'Device.WiFi.Radio.2.SupportedOperatingChannelBandwidths': '20MHz,40MHz',
};
