# PrivacyGUI JNAP Commands 實際使用清單

**版本:** v1.2.0
**最後更新:** 2026-02-25
**來源:** 專案程式碼實際呼叫分析 (`lib/` 目錄，排除 `lib/core/jnap/actions/` 定義檔)

---

## 概述

本文件列出 PrivacyGUI 專案中**實際被程式碼呼叫**的 JNAP commands。
透過搜尋 `JNAPAction.` 在整個專案中的使用位置（排除定義檔）統計而來。

- **總定義 Actions 數量:** 184
- **實際使用的 Actions 數量:** 140
- **僅在映射檔案中 (未實際呼叫):** 44

---

## 1. Core (核心服務) - 13 個

| Action | Endpoint | 使用位置 |
|--------|----------|----------|
| transaction | `http://linksys.com/jnap/core/Transaction` | jnap_spec.dart (批次交易) |
| checkAdminPassword | `http://linksys.com/jnap/core/CheckAdminPassword` | auth_service.dart |
| pnpCheckAdminPassword | `http://linksys.com/jnap/core/CheckAdminPassword2` | auth_service.dart |
| coreSetAdminPassword | `http://linksys.com/jnap/core/SetAdminPassword` | router_password_service.dart |
| pnpSetAdminPassword | `http://linksys.com/jnap/core/SetAdminPassword2` | pnp_service.dart |
| getAdminPasswordHint | `http://linksys.com/jnap/core/GetAdminPasswordHint` | auth_service.dart, router_password_service.dart |
| getAdminPasswordAuthStatus | `http://linksys.com/jnap/core/GetAdminPasswordAuthStatus` | auth_service.dart |
| getDeviceInfo | `http://linksys.com/jnap/core/GetDeviceInfo` | session_service.dart, polling_service.dart, pnp_service.dart |
| isAdminPasswordDefault | `http://linksys.com/jnap/core/IsAdminPasswordDefault` | connectivity_service.dart, pnp_service.dart |
| reboot | `http://linksys.com/jnap/core/Reboot` | instant_topology_service.dart, jnap_command_provider.dart |
| reboot2 | `http://linksys.com/jnap/core/Reboot2` | instant_topology_service.dart |
| factoryReset | `http://linksys.com/jnap/core/FactoryReset` | instant_topology_service.dart |
| factoryReset2 | `http://linksys.com/jnap/core/FactoryReset2` | instant_topology_service.dart |

---

## 2. Auto Onboarding (自動加入網路) - 6 個

| Action | Endpoint | 使用位置 |
|--------|----------|----------|
| startBlueboothAutoOnboarding | `http://linksys.com/jnap/nodes/autoonboarding/StartBluetoothAutoOnboarding` | add_nodes_service.dart |
| getBluetoothAutoOnboardingStatus | `http://linksys.com/jnap/nodes/autoonboarding/GetBluetoothAutoOnboardingStatus` | add_nodes_service.dart |
| getBluetoothAutoOnboardingSettings | `http://linksys.com/jnap/nodes/autoonboarding/GetBluetoothAutoOnboardingSettings` | add_nodes_service.dart, pnp_service.dart |
| setBluetoothAutoOnboardingSettings | `http://linksys.com/jnap/nodes/autoonboarding/SetBluetoothAutoOnboardingSettings` | add_nodes_service.dart |
| getWiredAutoOnboardingSettings | `http://linksys.com/jnap/nodes/autoonboarding/GetWiredAutoOnboardingSettings` | add_wired_nodes_service.dart |
| setWiredAutoOnboardingSettings | `http://linksys.com/jnap/nodes/autoonboarding/SetWiredAutoOnboardingSettings` | add_wired_nodes_service.dart |

---

## 3. DDNS (動態 DNS) - 4 個

| Action | Endpoint | 使用位置 |
|--------|----------|----------|
| getDDNSSettings | `http://linksys.com/jnap/ddns/GetDDNSSettings` | ddns_service.dart |
| getDDNSStatus | `http://linksys.com/jnap/ddns/GetDDNSStatus` | ddns_service.dart |
| getSupportedDDNSProviders | `http://linksys.com/jnap/ddns/GetSupportedDDNSProviders` | ddns_service.dart |
| setDDNSSetting | `http://linksys.com/jnap/ddns/SetDDNSSettings` | ddns_service.dart |

---

## 4. Device List (裝置列表) - 4 個

| Action | Endpoint | 使用位置 |
|--------|----------|----------|
| getDevices | `http://linksys.com/jnap/devicelist/GetDevices` | device_manager_service.dart, polling_service.dart, pnp_service.dart |
| getLocalDevice | `http://linksys.com/jnap/devicelist/GetLocalDevice` | internet_settings_service.dart, instant_privacy_service.dart |
| setDeviceProperties | `http://linksys.com/jnap/devicelist/SetDeviceProperties` | device_manager_service.dart, jnap_command_provider.dart |
| deleteDevice | `http://linksys.com/jnap/devicelist/DeleteDevice` | batch_extension.dart |

---

## 5. Diagnostics (診斷) - 7 個

| Action | Endpoint | 使用位置 |
|--------|----------|----------|
| getPingStatus | `http://linksys.com/jnap/diagnostics/GetPingStatus` | instant_verify_service.dart |
| getSystemStats | `http://linksys.com/jnap/diagnostics/GetSystemStats` | polling_service.dart, system_stats_provider.dart |
| getTracerouteStatus | `http://linksys.com/jnap/diagnostics/GetTracerouteStatus` | instant_verify_service.dart |
| startPing | `http://linksys.com/jnap/diagnostics/StartPing` | instant_verify_service.dart |
| startTracroute | `http://linksys.com/jnap/diagnostics/StartTraceroute` | instant_verify_service.dart |
| stopPing | `http://linksys.com/jnap/diagnostics/StopPing` | instant_verify_service.dart |
| stopTracroute | `http://linksys.com/jnap/diagnostics/StopTraceroute` | instant_verify_service.dart |

---

## 6. Firewall (防火牆) - 14 個

| Action | Endpoint | 使用位置 |
|--------|----------|----------|
| getPortRangeForwardingRules | `http://linksys.com/jnap/firewall/GetPortRangeForwardingRules` | port_range_forwarding_service.dart |
| getPortRangeTriggeringRules | `http://linksys.com/jnap/firewall/GetPortRangeTriggeringRules` | port_range_triggering_service.dart |
| getSinglePortForwardingRules | `http://linksys.com/jnap/firewall/GetSinglePortForwardingRules` | single_port_forwarding_service.dart |
| setPortRangeForwardingRules | `http://linksys.com/jnap/firewall/SetPortRangeForwardingRules` | port_range_forwarding_service.dart |
| setPortRangeTriggeringRules | `http://linksys.com/jnap/firewall/SetPortRangeTriggeringRules` | port_range_triggering_service.dart |
| setSinglePortForwardingRules | `http://linksys.com/jnap/firewall/SetSinglePortForwardingRules` | single_port_forwarding_service.dart |
| getIPv6FirewallRules | `http://linksys.com/jnap/firewall/GetIPv6FirewallRules` | ipv6_port_service_list_service.dart |
| setIPv6FirewallRules | `http://linksys.com/jnap/firewall/SetIPv6FirewallRules` | ipv6_port_service_list_service.dart |
| getFirewallSettings | `http://linksys.com/jnap/firewall/GetFirewallSettings` | firewall_settings_service.dart, jnap_command_provider.dart |
| setFirewallSettings | `http://linksys.com/jnap/firewall/SetFirewallSettings` | firewall_settings_service.dart |
| getDMZSettings | `http://linksys.com/jnap/firewall/GetDMZSettings` | dmz_settings_service.dart |
| setDMZSettings | `http://linksys.com/jnap/firewall/SetDMZSettings` | dmz_settings_service.dart |
| getALGSettings | `http://linksys.com/jnap/firewall/GetALGSettings` | administration_settings_service.dart |
| setALGSettings | `http://linksys.com/jnap/firewall/SetALGSettings` | administration_settings_service.dart |

---

## 7. Firmware Update (韌體更新) - 6 個

| Action | Endpoint | 使用位置 |
|--------|----------|----------|
| getFirmwareUpdateStatus | `http://linksys.com/jnap/firmwareupdate/GetFirmwareUpdateStatus` | firmware_update_service.dart, polling_service.dart |
| getNodesFirmwareUpdateStatus | `http://linksys.com/jnap/nodes/firmwareupdate/GetFirmwareUpdateStatus` | firmware_update_service.dart, polling_service.dart |
| getFirmwareUpdateSettings | `http://linksys.com/jnap/firmwareupdate/GetFirmwareUpdateSettings` | firmware_update_service.dart, polling_service.dart, pnp_service.dart |
| setFirmwareUpdateSettings | `http://linksys.com/jnap/firmwareupdate/SetFirmwareUpdateSettings` | firmware_update_service.dart, pnp_service.dart |
| updateFirmwareNow | `http://linksys.com/jnap/nodes/firmwareupdate/UpdateFirmwareNow` | firmware_update_service.dart |
| nodesUpdateFirmwareNow | `http://linksys.com/jnap/nodes/firmwareupdate/UpdateFirmwareNow` | firmware_update_service.dart |

---

## 8. Guest Network (訪客網路) - 5 個

| Action | Endpoint | 使用位置 |
|--------|----------|----------|
| getGuestNetworkClients | `http://linksys.com/jnap/guestnetwork/GetGuestNetworkClients` | jnap_command_provider.dart |
| getGuestNetworkSettings | `http://linksys.com/jnap/guestnetwork/GetGuestNetworkSettings` | jnap_command_provider.dart |
| getGuestRadioSettings | `http://linksys.com/jnap/guestnetwork/GetGuestRadioSettings` | device_manager_service.dart, polling_service.dart, pnp_service.dart |
| setGuestNetworkSettings | `http://linksys.com/jnap/guestnetwork/SetGuestNetworkSettings` | jnap_command_provider.dart |
| setGuestRadioSettings | `http://linksys.com/jnap/guestnetwork/SetGuestRadioSettings` | pnp_service.dart, wifi_settings_service.dart |

---

## 9. Health Check (健康檢查) - 6 個

| Action | Endpoint | 使用位置 |
|--------|----------|----------|
| getCloseHealthCheckServers | `http://linksys.com/jnap/healthcheck/GetCloseHealthCheckServers` | health_check_service.dart, polling_service.dart |
| getHealthCheckResults | `http://linksys.com/jnap/healthcheck/GetHealthCheckResults` | health_check_service.dart, polling_service.dart |
| getHealthCheckStatus | `http://linksys.com/jnap/healthcheck/GetHealthCheckStatus` | health_check_service.dart |
| getSupportedHealthCheckModules | `http://linksys.com/jnap/healthcheck/GetSupportedHealthCheckModules` | health_check_service.dart, polling_service.dart |
| runHealthCheck | `http://linksys.com/jnap/healthcheck/RunHealthCheck` | health_check_service.dart |
| stopHealthCheck | `http://linksys.com/jnap/healthcheck/StopHealthCheck` | health_check_service.dart |

---

## 10. Locale (地區設定) - 3 個

| Action | Endpoint | 使用位置 |
|--------|----------|----------|
| getLocalTime | `http://linksys.com/jnap/locale/GetLocalTime` | polling_service.dart, router_time_provider.dart |
| getTimeSettings | `http://linksys.com/jnap/locale/GetTimeSettings` | timezone_service.dart |
| setTimeSettings | `http://linksys.com/jnap/locale/SetTimeSettings` | timezone_service.dart |

---

## 11. MAC Filter (MAC 過濾) - 3 個

| Action | Endpoint | 使用位置 |
|--------|----------|----------|
| getMACFilterSettings | `http://linksys.com/jnap/macfilter/GetMACFilterSettings` | polling_service.dart, instant_privacy_service.dart, wifi_settings_service.dart |
| setMACFilterSettings | `http://linksys.com/jnap/macfilter/SetMACFilterSettings` | instant_privacy_service.dart, wifi_settings_service.dart |
| getSTABSSIDs | `http://linksys.com/jnap/macfilter/GetSTABSSIDS` | instant_privacy_service.dart, wifi_settings_service.dart |

---

## 12. Network Connections (網路連線) - 1 個

| Action | Endpoint | 使用位置 |
|--------|----------|----------|
| getNetworkConnections | `http://linksys.com/jnap/networkconnections/GetNetworkConnections` | device_manager_service.dart, polling_service.dart |

---

## 13. Nodes Diagnostics (節點診斷) - 1 個

| Action | Endpoint | 使用位置 |
|--------|----------|----------|
| getBackhaulInfo | `http://linksys.com/jnap/nodes/diagnostics/GetBackhaulInfo` | device_manager_service.dart, polling_service.dart, add_nodes_service.dart |

---

## 14. Nodes Network Connections (節點網路連線) - 1 個

| Action | Endpoint | 使用位置 |
|--------|----------|----------|
| getNodesWirelessNetworkConnections | `http://linksys.com/jnap/nodes/networkconnections/GetNodesWirelessNetworkConnections` | device_manager_service.dart, polling_service.dart |

---

## 15. Nodes Topology Optimization (節點拓撲優化) - 2 個

| Action | Endpoint | 使用位置 |
|--------|----------|----------|
| getTopologyOptimizationSettings | `http://linksys.com/jnap/nodes/topologyoptimization/GetTopologyOptimizationSettings` | wifi_settings_service.dart |
| setTopologyOptimizationSettings | `http://linksys.com/jnap/nodes/topologyoptimization/SetTopologyOptimizationSettings` | wifi_settings_service.dart |

---

## 16. Power Table (電源表) - 2 個

| Action | Endpoint | 使用位置 |
|--------|----------|----------|
| getPowerTableSettings | `http://linksys.com/jnap/powertable/GetPowerTableSettings` | polling_service.dart, power_table_service.dart |
| setPowerTableSettings | `http://linksys.com/jnap/powertable/SetPowerTableSettings` | power_table_service.dart |

---

## 17. Product (產品) - 1 個

| Action | Endpoint | 使用位置 |
|--------|----------|----------|
| getSoftSKUSettings | `http://linksys.com/jnap/product/GetSoftSKUSettings` | polling_service.dart, device_info_provider.dart |

---

## 18. QoS (服務品質) - 1 個

| Action | Endpoint | 使用位置 |
|--------|----------|----------|
| getQoSSettings | `http://linksys.com/jnap/qos/GetQoSSettings` | jnap_command_provider.dart |

---

## 19. Router (路由器) - 17 個

| Action | Endpoint | 使用位置 |
|--------|----------|----------|
| getIPv6Settings | `http://linksys.com/jnap/router/GetIPv6Settings` | internet_settings_service.dart, batch_extension.dart |
| getLANSettings | `http://linksys.com/jnap/router/GetLANSettings` | instant_safety_service.dart, local_network_settings_service.dart, static_routing_service.dart, internet_settings_service.dart |
| getMACAddressCloneSettings | `http://linksys.com/jnap/router/GetMACAddressCloneSettings` | internet_settings_service.dart, batch_extension.dart |
| getWANSettings | `http://linksys.com/jnap/router/GetWANSettings` | pnp_service.dart, internet_settings_service.dart, batch_extension.dart |
| getWANStatus | `http://linksys.com/jnap/router/GetWANStatus` | device_manager_service.dart, polling_service.dart, pnp_isp_service.dart |
| getRoutingSettings | `http://linksys.com/jnap/router/GetRoutingSettings` | static_routing_service.dart |
| setIPv6Settings | `http://linksys.com/jnap/router/SetIPv6Settings` | internet_settings_service.dart |
| setMACAddressCloneSettings | `http://linksys.com/jnap/router/SetMACAddressCloneSettings` | internet_settings_service.dart |
| setWANSettings | `http://linksys.com/jnap/router/SetWANSettings` | internet_settings_service.dart |
| setLANSettings | `http://linksys.com/jnap/router/SetLANSettings` | instant_safety_service.dart, local_network_settings_service.dart |
| setRoutingSettings | `http://linksys.com/jnap/router/SetRoutingSettings` | static_routing_service.dart |
| renewDHCPWANLease | `http://linksys.com/jnap/router/RenewDHCPWANLease` | internet_settings_service.dart |
| renewDHCPIPv6WANLease | `http://linksys.com/jnap/router/RenewDHCPIPv6WANLease` | internet_settings_service.dart |
| getEthernetPortConnections | `http://linksys.com/jnap/router/GetEthernetPortConnections` | polling_service.dart, ethernet_ports_provider.dart |
| getExpressForwardingSettings | `http://linksys.com/jnap/router/GetExpressForwardingSettings` | administration_settings_service.dart |
| setExpressForwardingSettings | `http://linksys.com/jnap/router/SetExpressForwardingSettings` | administration_settings_service.dart |
| getWANExternal | `http://linksys.com/jnap/router/GetWANExternal` | wan_external_service.dart |

---

## 20. Router Management (路由器管理) - 2 個

| Action | Endpoint | 使用位置 |
|--------|----------|----------|
| getManagementSettings | `http://linksys.com/jnap/routermanagement/GetManagementSettings` | administration_settings_service.dart |
| setManagementSettings | `http://linksys.com/jnap/routermanagement/SetManagementSettings` | administration_settings_service.dart |

---

## 21. Router UPnP - 2 個

| Action | Endpoint | 使用位置 |
|--------|----------|----------|
| getUPnPSettings | `http://linksys.com/jnap/routerupnp/GetUPnPSettings` | administration_settings_service.dart |
| setUPnPSettings | `http://linksys.com/jnap/routerupnp/SetUPnPSettings` | administration_settings_service.dart |

---

## 22. Router LEDs (路由器 LED) - 2 個

| Action | Endpoint | 使用位置 |
|--------|----------|----------|
| getLedNightModeSetting | `http://linksys.com/jnap/routerleds/GetLedNightModeSetting` | polling_service.dart, pnp_service.dart, node_light_settings_service.dart |
| setLedNightModeSetting | `http://linksys.com/jnap/routerleds/SetLedNightModeSetting` | pnp_service.dart, node_light_settings_service.dart |

---

## 23. Setup (設定) - 13 個

| Action | Endpoint | 使用位置 |
|--------|----------|----------|
| isAdminPasswordSetByUser | `http://linksys.com/jnap/nodes/setup/IsAdminPasswordSetByUser` | router_password_service.dart, pnp_service.dart |
| getAutoConfigurationSettings | `http://linksys.com/jnap/nodes/setup/GetAutoConfigurationSettings` | pnp_service.dart |
| setupSetAdminPassword | `http://linksys.com/jnap/nodes/setup/SetAdminPassword` | router_password_service.dart |
| verifyRouterResetCode | `http://linksys.com/jnap/nodes/setup/VerifyRouterResetCode` | router_password_service.dart |
| getInternetConnectionStatus | `http://linksys.com/jnap/nodes/setup/GetInternetConnectionStatus` | polling_service.dart, pnp_service.dart, auto_parent_first_login_service.dart |
| getSimpleWiFiSettings | `http://linksys.com/jnap/nodes/setup/GetSimpleWiFiSettings` | pnp_service.dart, jnap_command_provider.dart |
| setSimpleWiFiSettings | `http://linksys.com/jnap/nodes/setup/SetSimpleWiFiSettings` | pnp_service.dart, jnap_command_provider.dart |
| getMACAddress | `http://linksys.com/jnap/nodes/setup/GetMACAddress` | internet_settings_service.dart, batch_extension.dart |
| startBlinkNodeLed | `http://linksys.com/jnap/nodes/setup/StartBlinkingNodeLed` | instant_topology_service.dart, node_detail_service.dart |
| stopBlinkNodeLed | `http://linksys.com/jnap/nodes/setup/StopBlinkingNodeLed` | instant_topology_service.dart, node_detail_service.dart |
| setUserAcknowledgedAutoConfiguration | `http://linksys.com/jnap/nodes/setup/SetUserAcknowledgedAutoConfiguration` | pnp_service.dart, auto_parent_first_login_service.dart |
| getSelectedChannels | `http://linksys.com/jnap/nodes/setup/GetSelectedChannels` | channel_finder_service.dart |
| startAutoChannelSelection | `http://linksys.com/jnap/nodes/setup/StartAutoChannelSelection` | channel_finder_service.dart |

---

## 24. Smart Mode (智慧模式) - 2 個

| Action | Endpoint | 使用位置 |
|--------|----------|----------|
| getDeviceMode | `http://linksys.com/jnap/nodes/smartmode/GetDeviceMode` | polling_service.dart, pnp_service.dart |
| setDeviceMode | `http://linksys.com/jnap/nodes/smartmode/SetDeviceMode` | pnp_service.dart |

---

## 25. VPN - 10 個

| Action | Endpoint | 使用位置 |
|--------|----------|----------|
| getVPNUser | `http://linksys.com/jnap/vpn/GetVPNUser` | vpn_service.dart |
| setVPNUser | `http://linksys.com/jnap/vpn/SetVPNUser` | vpn_service.dart |
| getVPNGateway | `http://linksys.com/jnap/vpn/GetVPNGateway` | vpn_service.dart |
| setVPNGateway | `http://linksys.com/jnap/vpn/SetVPNGateway` | vpn_service.dart |
| getVPNService | `http://linksys.com/jnap/vpn/GetVPNService` | vpn_service.dart |
| setVPNService | `http://linksys.com/jnap/vpn/SetVPNService` | vpn_service.dart |
| testVPNConnection | `http://linksys.com/jnap/vpn/TestVPNConnection` | vpn_service.dart |
| getTunneledUser | `http://linksys.com/jnap/vpn/GetTunneledUser` | vpn_service.dart |
| setTunneledUser | `http://linksys.com/jnap/vpn/SetTunneledUser` | vpn_service.dart |
| setVPNApply | `http://linksys.com/jnap/vpn/SetVPNApply` | vpn_service.dart |

---

## 26. Wireless AP (無線 AP) - 3 個

| Action | Endpoint | 使用位置 |
|--------|----------|----------|
| getRadioInfo | `http://linksys.com/jnap/wirelessap/GetRadioInfo` | device_manager_service.dart, polling_service.dart, pnp_service.dart, wifi_settings_service.dart |
| setRadioSettings | `http://linksys.com/jnap/wirelessap/SetRadioSettings` | wifi_settings_service.dart, jnap_command_provider.dart |
| clientDeauth | `http://linksys.com/jnap/wirelessap/ClientDeauth` | device_manager_service.dart |

---

## 27. IPTV - 2 個

| Action | Endpoint | 使用位置 |
|--------|----------|----------|
| getIptvSettings | `http://linksys.com/jnap/iptv/GetIPTVSettings` | wifi_settings_service.dart |
| setIptvSettings | `http://linksys.com/jnap/iptv/SetIPTVSettings` | wifi_settings_service.dart |

---

## 28. MLO (Multi-Link Operation) - 2 個

| Action | Endpoint | 使用位置 |
|--------|----------|----------|
| getMLOSettings | `http://linksys.com/jnap/wirelessap/GetMLOSettings` | wifi_settings_service.dart |
| setMLOSettings | `http://linksys.com/jnap/wirelessap/SetMLOSettings` | wifi_settings_service.dart |

---

## 29. DFS (Dynamic Frequency Selection) - 2 個

| Action | Endpoint | 使用位置 |
|--------|----------|----------|
| getDFSSettings | `http://linksys.com/jnap/wirelessap/GetDFSSettings` | wifi_settings_service.dart |
| setDFSSettings | `http://linksys.com/jnap/wirelessap/SetDFSSettings` | wifi_settings_service.dart |

---

## 30. Airtime Fairness - 2 個

| Action | Endpoint | 使用位置 |
|--------|----------|----------|
| getAirtimeFairnessSettings | `http://linksys.com/jnap/wirelessap/GetAirtimeFairnessSettings` | wifi_settings_service.dart |
| setAirtimeFairnessSettings | `http://linksys.com/jnap/wirelessap/SetAirtimeFairnessSettings` | wifi_settings_service.dart |

---

## 31. UI Settings (UI 設定) - 1 個

| Action | Endpoint | 使用位置 |
|--------|----------|----------|
| setRemoteSetting | `http://linksys.com/jnap/ui/SetRemoteSetting` | bridge_converter.dart |

---

## 未使用的 Actions (僅在映射檔案中，未實際呼叫) - 44 個

以下 actions 在 `jnap_action.dart` 和 `better_action.dart` 中定義/映射，但未在業務邏輯程式碼中被實際呼叫：

| Action | 說明 |
|--------|------|
| btGetScanUnconfiguredResult | 藍牙掃描未配置裝置結果 |
| btRequestScanUnconfigured | 請求藍牙掃描未配置裝置 |
| clearHealthCheckHistory | 清除健康檢查歷史 |
| execSysCommand | 執行系統命令 |
| getActiveMotionSensingBots | 動態感測機器人 |
| getDHCPClientLeases | DHCP Client 租約 |
| getDataUploadUserConsent | 資料上傳同意 |
| getGamingPrioritizationSettings | 遊戲優先設定 (GET) |
| getLocale | 取得地區設定 |
| getMotionSensingSettings | 動態感測設定 |
| getNetworkSecuritySettings | 網路安全設定 (GET) |
| getNodeNeighborInfo | 節點鄰居資訊 |
| getOwnedNetworkID | 網路所有權 ID |
| getParentalControlSettings | 家長控制設定 |
| getPortConnectionStatus | Port 連線狀態 |
| getRemoteSetting | 遠端設定 (GET) |
| getSlaveBackhaulStatus | Slave Backhaul 狀態 |
| getSmartConnectPin | Smart Connect PIN |
| getSmartConnectStatus | Smart Connect 狀態 |
| getSupportedDeviceMode | 支援的裝置模式 |
| getSysInfoData | 系統資訊資料 |
| getUnsecuredWiFiWarning | WiFi 安全警告 (GET) |
| getVLANTaggingSettings | VLAN Tagging (GET) |
| getVersionInfo | 版本資訊 |
| getWANDetectionStatus | WAN 偵測狀態 |
| getWANPort | WAN Port (GET) |
| getWPSServerSessionStatus | WPS 伺服器狀態 |
| getWirelessSchedulerSettings | 無線排程設定 |
| isOwnedNetwork | 檢查網路所有權 |
| isServiceSupported | 服務支援檢查 |
| refreshSlaveBackhaulData | 刷新 Backhaul 資料 |
| releaseDHCPIPv6WANLease | 釋放 DHCP IPv6 WAN 租約 |
| releaseDHCPWANLease | 釋放 DHCP WAN 租約 |
| restorePreviousFirmware | 還原韌體 |
| sendSysinfoEmail | 發送系統資訊 Email |
| setGamingPrioritizationSettings | 遊戲優先設定 (SET) |
| setLocale | 設定地區 |
| setNetworkOwner | 設定網路擁有者 |
| setNetworkSecuritySettings | 網路安全設定 (SET) |
| setUnsecuredWiFiWarning | WiFi 安全警告 (SET) |
| setVLANTaggingSettings | VLAN Tagging (SET) |
| setWANPort | WAN Port (SET) |
| startBlinkingNodeLed | 開始閃爍 LED (另一版本) |
| stopBlinkingNodeLed | 停止閃爍 LED (另一版本) |

---

## 統計摘要

| 分類 | 使用數量 | 說明 |
|------|----------|------|
| Core | 13 | 認證、裝置資訊、重啟、重置、交易 |
| Auto Onboarding | 6 | 藍牙/有線自動加入 |
| DDNS | 4 | 動態 DNS |
| Device List | 4 | 裝置管理 |
| Diagnostics | 7 | Ping/Traceroute 診斷 |
| Firewall | 14 | Port 轉發、DMZ、ALG |
| Firmware Update | 6 | 韌體更新 |
| Guest Network | 5 | 訪客網路 |
| Health Check | 6 | 健康檢查 |
| Locale | 3 | 時間設定 |
| MAC Filter | 3 | MAC 過濾 |
| Network Connections | 1 | 網路連線 |
| Nodes Diagnostics | 1 | Backhaul 資訊 |
| Nodes Network Connections | 1 | 節點無線連線 |
| Nodes Topology | 2 | 拓撲優化 |
| Power Table | 2 | 電源管理 |
| Product | 1 | 產品設定 |
| QoS | 1 | 服務品質 |
| Router | 17 | WAN/LAN/IPv6/DHCP |
| Router Management | 2 | 管理設定 |
| Router UPnP | 2 | UPnP 設定 |
| Router LEDs | 2 | LED 控制 |
| Setup | 13 | 初始設定、WiFi、通道、MAC |
| Smart Mode | 2 | 裝置模式 |
| VPN | 10 | VPN 設定 |
| Wireless AP | 3 | Radio 設定 |
| IPTV | 2 | IPTV 設定 |
| MLO | 2 | Multi-Link Operation |
| DFS | 2 | Dynamic Frequency Selection |
| Airtime Fairness | 2 | 公平使用時間 |
| UI Settings | 1 | UI 設定 |
| **總計** | **140** | |

---

## 來源檔案

本清單透過以下方式分析產生：
```bash
grep -r "JNAPAction\." lib/ --include="*.dart" | grep -v "lib/core/jnap/actions/"
```

排除的定義檔案：
- `lib/core/jnap/actions/jnap_action.dart` - JNAPAction enum 定義
- `lib/core/jnap/actions/jnap_service.dart` - JNAPService enum 定義
- `lib/core/jnap/actions/jnap_action_value.dart` - HTTP endpoint 對應
- `lib/core/jnap/actions/better_action.dart` - Service 版本對應邏輯
