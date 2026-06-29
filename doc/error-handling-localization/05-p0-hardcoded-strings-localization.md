# Hardcoded Strings Localization 追蹤紀錄

> #919 的一部分 — i18n Hardcoded Strings

---

## A. 直接重用現有 key

| Hardcoded String | ARB Key |
|------------------|---------|
| `'Add'` | `add` |
| `'Administration'` | `administration` |
| `'Advanced'` | `advanced` |
| `'Advanced Settings'` | `advancedSettings` |
| `'Automatically adjust for Daylight Savings Time'` | `daylightSavingsTime` |
| `'Cancel'` | `cancel` |
| `'Connected via'` | `connectedVia` |
| `'Connection'` | `connection` |
| `'Description is required'` | `descriptionRequired` |
| `'Devices'` | `devices` |
| `'Enabled'` | `enabled` |
| `'Ethernet'` | `ethernet` |
| `'Excellent'` | `excellent` |
| `'External Port'` | `externalPort` |
| `'External port is required'` | `externalPortRequired` |
| `'Fair'` | `fair` |
| `'Filters'` | `filters` |
| `'Firmware Update'` | `firmwareUpdate` |
| `'Good'` | `good` |
| `'Instant Privacy'` | `instantPrivacy` |
| `'Instant Safety'` | `instantSafety` |
| `'Internal Port'` | `internalPort` |
| `'Internal port is required'` | `internalPortRequired` |
| `'Invalid IPv4 address format'` | `invalidIpv4Format` |
| `'Must be 32 characters or less'` | `mustBe32CharsOrLess` |
| `'No leading or trailing spaces'` | `noLeadingTrailingSpaces` |
| `'Node'` | `node` |
| `'Offline'` | `offline` |
| `'Online'` | `online` |
| `'Poor'` | `poor` |
| `'Port must be 1-65535'` | `portMustBe1To65535` |
| `'Protocol'` | `protocol` |
| `'Reserved IP address is not allowed'` | `reservedIpNotAllowed` |
| `'SSID'` | `ssid` |
| `'Save'` | `save` |
| `'Speed Test'` | `speedTest` |
| `'TCP'` | `tcp` |
| `'Topology'` | `topology` |
| `'Try again'` | `tryAgain` |
| `'UDP'` | `udp` |
| `'Unknown error'` | `unknownError` |
| `'Update'` | `update` |
| `'Update Firmware'` | `updateFirmware` |
| `'Update available'` | `updateAvailable` |
| `'Uptime'` | `uptime` |
| `'WiFi'` | `wifi` |
| `'Wired'` | `wired` |
| `'Active'` | `active` |
| `'Avg: {value}%'` | `avg` |
| `'Avg: {avg}%  Peak: {peak}%'` | `avgPeak` |
| `'Channel'` | `channel` |
| `'Collecting activity data...'` | `collectingActivityData` |
| `'Collecting data...'` | `collectingData` |
| `'Collecting hourly data...'` | `collectingHourlyData` |
| `'Correlation'` | `correlation` |
| `'CPU'` | `cpu` |
| `'CPU: {percent}%'` | `cpuPercent` |
| `'CPU usage samples: {count}'` | `cpuUsageSamples` |
| `'Distribution'` | `distribution` |
| `'DMZ'` | `dmz` |
| `'Download'` | `download` |
| `'Enable traffic monitor for correlation data'` | `enableTrafficMonitorForCorrelation` |
| `'Enable traffic monitor for health data'` | `enableTrafficMonitorForHealthData` |
| `'Loading...'` | `loading` |
| `'Memory'` | `memory` |
| `'{used} / {total} used'` | `memoryUsed` |
| `'Memory: {percent}%'` | `memoryPercent` |
| `'Monitor'` | `monitor` |
| `'{count} offline'` | `nOffline` |
| `'No WiFi signal data...'` | `noWifiSignalData` |
| `'Signal'` | `signal` |
| `'Signal Quality'` | `signalQuality` |
| `'Statistics'` | `statistics` |
| `'System'` | `system` |
| `'Traffic rate'` | `trafficRate` |
| `'Trend'` | `trend` |
| `'Trends'` | `trends` |
| `'Upload'` | `upload` |
| `'Waiting for data...'` | `waitingForData` |
| `'Waiting for device data...'` | `waitingForDeviceData` |
| `'WAN'` | `wan` |
| `'WiFi: {count}'` | `wifiCount` |
| `'Wired: {count}'` | `wiredCount` |

---

## B. 部分符合（決定重用）

| Hardcoded String | 重用 Key | 符合度 | 決策理由 |
|------------------|----------|--------|----------|
| `'Factory Reset'` | `factoryResetTitle` | ~80% | 較長但語意完全相同 |
| `'Lock network to currently connected devices'` | `instantPrivacyDesc` | ~70% | 較簡短但核心動作相同 |
| `'Password updated'` | `passwwordUpdated` | ~85% | 更具體說明是 router password |
| `'Reboot'` | `restart` | ~75% | Reboot/Restart 同義 |
| `'Signal'` | `signal` | ~100% | 已存在 |
| `'Signal strength'` | `signalStrength` | ~85% | filter label 用 signal，詳細用 signalStrength |
| `'This will erase all settings...'` | `factoryResetDesc` | ~70% | 現有版本較詳細，語意相近 |
| `'View and manage connected devices'` | `instantDevicesDesc` | ~80% | 省略 "View and"，核心語意相同 |
| | | | |
| **unified_diagnostics** | | | |
| `'Logout'` | `logout` | ~95% | ARB 為 "Log out"（有空格），語意相同 |
| `'Ping'` (tab label) | `ping` | ~100% | 重用既有 key |
| `'Traceroute'` (tab label) | `traceroute` | ~100% | 重用既有 key |
| `'Latency'` (step label) | `latency` | ~100% | 重用既有 key |
| `'Download'` / `'Upload'` | `download` / `upload` | ~100% | 重用既有 speed test keys |
| `'Retry'` | `retry` | ~100% | 重用既有 key |
| `'Done'` | `done` | ~100% | 重用既有 key |
| `'Cancel'` | `cancel` | ~100% | 重用既有 key |
| `'Start'` | `start` | ~100% | 重用既有 key |
| `'OK'` | `ok` | ~100% | 重用既有 key（大小寫差異） |
| `'DHCP'` | `dhcp` | ~100% | 重用既有 key |
| `'DHCP Pool'` | `dhcpPool` | ~100% | 重用既有 key |
| `'WiFi Signal'` | `wifiSignal` | ~100% | 重用既有 key |
| `'Connected Devices'` | `connectedDevices` | ~100% | 重用既有 key |
| `'Gateway Ping'` | `gatewayPing` | ~90% | 組合重用 |
| `'DNS Ping'` | `dnsPing` | ~90% | 組合重用 |
| `'DNS Lookup Step'` | `dnsLookupStep` | ~85% | 較短版本 |
| `'Mesh Backhaul Step'` | `meshBackhaulStep` | ~85% | 較短版本 |
| | | | |
| **dashboard** | | | |
| `'Errors'` (chart series) | `errors` | ~100% | 重用既有 key |
| `'Discards'` (chart series) | `discards` | ~100% | 重用既有 key |
| `'Loss'` (tab/series) | `loss` | ~100% | 重用既有 key |
| `'WAN'` / `'LAN'` | `wan` / `lan` | ~100% | 重用既有 key |
| `'CPU'` (chart series) | `cpu` | ~100% | 重用既有 key |
| `'Memory'` (chart series) | `memory` | ~100% | 重用既有 key |
| `'Devices'` (stat label) | `devices` | ~100% | 重用既有 key |
| `'Auto Channel'` | `autoChannel` | ~100% | 重用既有 key |
| `'Apply'` | `apply` | ~100% | 重用既有 key |
| `'Dashboard Style'` | `dashboardStyle` | ~100% | 重用既有 key |
| `'Available Widgets'` | `availableWidgets` | ~100% | 重用既有 key |
| `'No preset selected'` | `noPresetSelected` | ~100% | 重用既有 key |
| `'Layout reset to defaults'` | `layoutResetToDefaults` | ~100% | 重用既有 key |
| `'Layout optimized'` | `layoutOptimized` | ~100% | 重用既有 key |

---

## C. 必須新增

| Hardcoded String | 新增 Key |
|------------------|----------|
| `'{count} offline'` | `nOffline` |
| `'{used} / {total} used'` | `memoryUsed` |
| `'Active'` | `active` |
| `'Activity'` | `activity` |
| `'Add Port Forwarding'` | `addPortForwarding` |
| `'Additional filters are only available for online devices.'` | `additionalFiltersOnlineOnly` |
| `'All'` | `all` |
| `'Available: ${info.version}'` | `availableVersionLabel` |
| `'Avg: {avg}%  Peak: {peak}%'` | `avgPeak` |
| `'Avg: {value}%'` | `avg` |
| `'Band'` | `band` |
| `'Both'` | `both` |
| `'CPU'` | `cpu` |
| `'CPU usage samples: {count}'` | `cpuUsageSamples` |
| `'CPU: {percent}%'` | `cpuPercent` |
| `'Check for Updates'` | `checkForUpdates` |
| `'Checking...'` | `checking` |
| `'Checking…'` | `checkingEllipsis` |
| `'Choose another file'` | `chooseAnotherFile` |
| `'Choose firmware file'` | `chooseFirmwareFile` |
| `'Clear'` | `clear` |
| `'Collecting activity data...'` | `collectingActivityData` |
| `'Collecting hourly data...'` | `collectingHourlyData` |
| `'Confirming the new firmware is running…'` | `confirmingNewFirmware` |
| `'Connection restored'` | `connectionRestored` |
| `'Correlation'` | `correlation` |
| `'Current Version'` | `currentVersionShort` |
| `'Current: $currentVersion'` | `currentVersionLabel` |
| `'Description'` | `description` |
| `'Device Analytics'` | `deviceAnalytics` |
| `'Distribution'` | `distribution` |
| `'Do you want to update now?'` | `doYouWantToUpdateNow` |
| `'Edit Port Forwarding'` | `editPortForwarding` |
| `'Edit Timezone'` | `editTimezone` |
| `'Enable traffic monitor for correlation data'` | `enableTrafficMonitorForCorrelation` |
| `'Estimated time remaining: ${time}'` | `estimatedTimeRemaining` |
| `'Factory reset in progress'` | `factoryResetInProgress` |
| `'Failed to start OTA update'` | `failedToStartOtaUpdate` |
| `'Firewall, local network, DMZ, port forwarding, routing'` | `menuAdvancedSettingsDesc` |
| `'Firmware Banks'` | `firmwareBanks` |
| `'Firmware Image'` | `firmwareImage` |
| `'IP address is required'` | `ipAddressRequired` |
| `'Installing firmware'` | `installingFirmware` |
| `'Internal IP (e.g. 192.168.1.100)'` | `internalIpHint` |
| `'Last check: router not yet responding (attempt ${attempt})'` | `routerNotYetResponding` |
| `'Loading firmware info…'` | `loadingFirmwareInfo` |
| `'Loading…'` | `loading` |
| `'Location'` | `location` |
| `'MD5: ${hash}'` | `md5Label` |
| `'Memory'` | `memory` |
| `'Memory: {percent}%'` | `memoryPercent` |
| `'Monitor'` | `monitor` |
| `'NTP Server'` | `ntpServer` |
| `'Network Diagnostics'` | `networkDiagnostics` |
| `'Network, device, and system analytics'` | `menuStatisticsDesc` |
| `'Networks, security, MAC filtering'` | `menuWifiSettingsDesc` |
| `'No WiFi signal data...'` | `noWifiSignalData` |
| `'No firmware banks reported by router'` | `noFirmwareBanksReported` |
| `'No firmware image selected. Choose a .img or .bin file to begin.'` | `noFirmwareImageSelected` |
| `'No response from your router...'` | `wifiSwitchWarning` |
| `'No target bank available'` | `noTargetBankAvailable` |
| `'No timezones found'` | `noTimezonesFound` |
| `'Not applicable for Ethernet devices'` | `notApplicableForEthernetDevices` |
| `'Not available'` | `notAvailable` |
| `'Now running firmware version $newVersion.'` | `nowRunningVersion` |
| `'OTA Update'` | `otaUpdate` |
| `'Password, timezone, reboot'` | `menuAdministrationDesc` |
| `'Port Forwarding'` | `portForwarding` |
| `'Preparing to install'` | `preparingToInstall` |
| `'Reboot Router'` | `rebootRouter` |
| `'Rebooting router'` | `rebootingRouter` |
| `'Reset'` | `reset` |
| `'Retry now'` | `retryNow` |
| `'Return to login page'` | `returnToLoginPage` |
| `'Router identity mismatch'` | `routerIdentityMismatch` |
| `'Router is rebooting'` | `routerIsRebooting` |
| `'Router reboot complete'` | `routerRebootComplete` |
| `'Run guided checks and manual ping/traceroute tools'` | `menuNetworkDiagnosticsDesc` |
| `'Safe browsing with OpenDNS'` | `menuInstantSafetyDesc` |
| `'Search timezone...'` | `searchTimezone` |
| `'Selecting file…'` | `selectingFile` |
| `'Signal Quality'` | `signalQuality` |
| `'Size: $size bytes ($mib MiB)'` | `sizeBytes` |
| `'Standby'` | `standby` |
| `'Statistics'` | `statistics` |
| `'Still waiting — this can take a little longer than expected'` | `stillWaitingLongerThanExpected` |
| `'System Status'` | `systemStatus` |
| `'Test your internet connection speed'` | `menuSpeedTestDesc` |
| `'The router is restoring to factory defaults...'` | `factoryResetWaitMessage` |
| `'The router is writing the new image. Do not power off.'` | `routerWritingImage` |
| `'The router will install the new firmware and reboot...'` | `firmwareInstallConfirmMessage` |
| `'The router will restart...'` | `rebootRouterMessage` |
| `'The update will take approximately 5–8 minutes...'` | `firmwareUpdateWarning` |
| `'Timezone updated'` | `timezoneUpdated` |
| `'Traffic rate'` | `trafficRate` |
| `'Trend'` | `trend` |
| `'Trends'` | `trends` |
| `'Type'` | `type` |
| `'Unable to gather device information'` | `unableToGatherDeviceInfo` |
| `'Update complete'` | `updateComplete` |
| `'Update failed'` | `updateFailed` |
| `'Uploading firmware'` | `uploadingFirmware` |
| `'Validating image…'` | `validatingImage` |
| `'Verifying firmware'` | `verifyingFirmware` |
| `'Verifying firmware image and preparing flash…'` | `verifyingFirmwareImage` |
| `'View network topology and mesh nodes'` | `menuTopologyDesc` |
| `'WiFi Settings'` | `menuWifiSettings` |
| `'WiFi: {count}'` | `wifiCount` |
| `'Waiting for data...'` | `waitingForData` |
| `'Waiting for device data...'` | `waitingForDeviceData` |
| `'Waiting for first connection check'` | `waitingForFirstConnectionCheck` |
| `'Waiting for the router to come back online…'` | `waitingForRouterOnline` |
| `'Wired: {count}'` | `wiredCount` |
| `'Your firmware is up to date'` | `firmwareUpToDate` |
| `'$percent% complete'` | `percentComplete` |
| `'All connected devices will be temporarily disconnected. Please wait.'` | `rebootWaitMessage` |
| `'Activity Heatmap'` | `activityHeatmap` |
| `'24-hour per-device activity matrix'` | `activityHeatmapSubtitle` |
| `'Bytes/s'` | `bytesPerSec` |
| `'{count} clients'` | `clientsCount` |
| `'Connection Trends'` | `connectionTrends` |
| `'24-hour device count by connection type'` | `connectionTrendsSubtitle` |
| `'CPU & Memory'` | `cpuAndMemory` |
| `'CPU Distribution'` | `cpuDistribution` |
| `'CPU usage sample distribution'` | `cpuDistributionSubtitle` |
| `'CPU %'` | `cpuPercentLabel` |
| `'CPU-Traffic Correlation'` | `cpuTrafficCorrelation` |
| `'CPU usage vs WAN traffic rate'` | `cpuUsageVsWanTrafficRate` |
| `'Current resource utilization'` | `currentResourceUtilization` |
| `'Device Distribution'` | `deviceDistribution` |
| `'WiFi vs Wired device breakdown'` | `deviceDistributionSubtitle` |
| `'Discards'` | `discards` |
| `'Downlink'` | `downlink` |
| `'Enable traffic monitor for error data'` | `enableTrafficMonitorForErrorData` |
| `'Enable traffic monitor for loss data'` | `enableTrafficMonitorForLossData` |
| `'Errors'` | `errors` |
| `'Firewall Rules'` | `firewallRules` |
| `'Rule target distribution and security overview'` | `firewallRulesSubtitle` |
| `'FW Rules'` | `fwRules` |
| `'Inactive'` | `inactive` |
| `'LAN'` | `lan` |
| `'LAN: {speed}'` | `lanSpeed` |
| `'Loss'` | `loss` |
| `'Network'` | `network` |
| `'Network Error Rates'` | `networkErrorRates` |
| `'WAN error and discard rates over time'` | `networkErrorRatesSubtitle` |
| `'Network Health Score'` | `networkHealthScore` |
| `'Overall network health based on error/loss metrics'` | `networkHealthSubtitle` |
| `'No device activity recorded'` | `noDeviceActivityRecorded` |
| `'No firewall rules configured'` | `noFirewallRulesConfigured` |
| `'No port mappings configured'` | `noPortMappingsConfigured` |
| `'No WiFi clients connected'` | `noWifiClientsConnected` |
| `'No WiFi radios available'` | `noWifiRadiosAvailable` |
| `'Other'` | `other` |
| `'Packet Loss'` | `packetLoss` |
| `'Pkts/s'` | `packetsPerSec` |
| `'Per-client signal strength (RSSI)'` | `perClientSignalStrengthRssi` |
| `'Port Fwd'` | `portFwd` |
| `'Port Forwarding ({count})'` | `portForwardingWithCount` |
| `'Port Mapping'` | `portMapping` |
| `'Port forwarding rules and DMZ configuration'` | `portMappingSubtitle` |
| `'Resource Trends'` | `resourceTrends` |
| `'CPU and memory usage over time'` | `resourceTrendsSubtitle` |
| `'Rules'` | `rules` |
| `'WiFi signal quality by frequency band'` | `signalQualitySubtitle` |
| `'SNR: {value} dB'` | `snrValue` |
| `'Target: {ip}'` | `targetIp` |
| `'Traffic Comparison'` | `trafficComparison` |
| `'WAN vs LAN throughput over time'` | `trafficComparisonSubtitle` |
| `'Traffic Distribution'` | `trafficDistribution` |
| `'Cumulative traffic proportion by interface'` | `trafficDistributionSubtitle` |
| `'Traffic Monitor'` | `trafficMonitor` |
| `'Real-time WAN upload/download speeds'` | `trafficMonitorSubtitle` |
| `'Traffic Trends'` | `trafficTrends` |
| `'Bytes/s and Packets/s dual-axis view'` | `trafficTrendsSubtitle` |
| `'Uplink'` | `uplink` |
| `'WAN packet loss percentage over time'` | `wanPacketLossOverTime` |
| `'WAN: {speed}'` | `wanSpeed` |
| `'Waiting for traffic data...'` | `waitingForTrafficData` |
| `'Weak'` | `weak` |
| `'WiFi Channels'` | `wifiChannels` |
| `'Radio channel allocation and client distribution'` | `wifiChannelsSubtitle` |
| `'WiFi Client Speed'` | `wifiClientSpeed` |
| `'Downlink/Uplink rates per client'` | `wifiClientSpeedSubtitle` |
| `'WiFi Signal Strength'` | `wifiSignalStrength` |
| | |
| **unified_diagnostics 新增** | |
| `'Run Full Diagnostic'` | `runFullDiagnostic` |
| `'Automatically check every...'` | `runFullDiagnosticDesc` |
| `'Choose Specific Issue'` | `chooseSpecificIssue` |
| `'Experiencing a specific...'` | `chooseSpecificIssueDesc` |
| `'Manual Tools'` | `manualTools` |
| `'Run ping, traceroute...'` | `manualToolsDesc` |
| `'Start Now'` | `startNow` |
| `'OR'` | `or` |
| `'What issue are you experiencing?'` | `whatIssueExperiencing` |
| `'Network issue detected: WAN...'` | `networkIssueDetectedWanDown` |
| `'Network issue detected: DNS...'` | `networkIssueDetectedDnsNotResponding` |
| `'High latency detected...'` | `highLatencyDetected` |
| `'Check connectivity and speed'` | `checkConnectivityAndSpeed` |
| `'WiFi Coverage'` | `wifiCoverage` |
| `'Weak signal in certain areas'` | `weakSignalInAreas` |
| `'Mesh / Backhaul'` | `meshBackhaul` |
| `'Check node-to-node link quality'` | `checkNodeLinkQuality` |
| `'Device Issues'` | `deviceIssues` |
| `'Specific device has connection...'` | `specificDeviceConnectionProblems` |
| `'Intermittent Connection'` | `intermittentConnection` |
| `'Connection drops on and off'` | `connectionDropsOnOff` |
| `'Checking connection...'` | `checkingConnection` |
| `'Running quick network check'` | `runningQuickNetworkCheck` |
| `'Diagnostics Complete'` | `diagnosticsComplete` |
| `'Return to Dashboard'` | `returnToDashboard` |
| `'Run Again'` | `runAgain` |
| `'Export Diagnostics Report'` | `exportDiagnosticsReport` |
| `'Issues Found'` | `issuesFound` |
| `'Potential Issues'` | `potentialIssues` |
| `'All Systems OK'` | `allSystemsOk` |
| `'Recommended Actions'` | `recommendedActions` |
| `'Cancel Diagnostics'` | `cancelDiagnostics` |
| `'Diagnosing your network path...'` | `diagnosingNetworkPath` |
| `'Internet Diagnostics'` | `internetDiagnostics` |
| `'Device Issues Diagnostics'` | `deviceIssuesDiagnostics` |
| `'WiFi Coverage Diagnostics'` | `wifiCoverageDiagnostics` |
| `'Mesh Backhaul Diagnostics'` | `meshBackhaulDiagnostics` |
| `'Intermittent Connection Diagnostics'` | `intermittentConnectionDiagnostics` |
| `'Full Diagnostic'` | `fullDiagnostic` |
| `'WAN Status'` | `wanStatus` |
| `'DHCP Lease'` | `dhcpLease` |
| `'DHCP Pool Usage'` | `dhcpPoolUsage` |
| `'Gateway Connection'` | `gatewayConnection` |
| `'DNS Connection'` | `dnsConnection` |
| `'Internet Connectivity'` | `internetConnectivity` |
| `'DNS Resolution'` | `dnsResolution` |
| `'WiFi Signal Analysis'` | `wifiSignalAnalysis` |
| `'Network Path Analysis'` | `networkPathAnalysis` |
| `'Analyzing Results...'` | `analyzingResults` |
| `'Skipped'` | `skipped` |
| `'Issue detected'` | `issueDetected` |
| `'Passed'` | `passed` |
| `'Failed'` | `failed` |
| `'Warning'` | `warning` |
| `'Completed'` | `completed` |
| `'Server'` | `server` |
| `'Target Host'` | `targetHost` |
| `'Target Host Hint'` | `targetHostHint` |
| `'Host Name Hint'` | `hostNameHint` |
| `'NS Lookup'` | `nsLookup` |
| `'Run Ping'` | `runPing` |
| `'Run Traceroute'` | `runTraceroute` |
| `'Run NS Lookup'` | `runNsLookup` |
| `'Pinging {host}...'` | `pingingHost` |
| `'Tracing route to {host}...'` | `tracingRouteTo` |
| `'Resolving {host}...'` | `resolvingHost` |
| `'Packet Count'` | `packetCount` |
| `'Max Hops'` | `maxHops` |
| `'Avg'` (short) | `avgShort` |
| `'Min'` (short) | `minShort` |
| `'Max'` (short) | `maxShort` |
| `'Success'` | `successLabel` |
| `'Ping {host}'` | `pingHost` |
| `'Traceroute to {host}'` | `tracerouteTo` |
| `'{count} hops'` | `nHops` |
| `'Host'` (column) | `hostColumn` |
| `'IP'` (column) | `ipColumn` |
| `'Avg RTT'` | `avgRtt` |
| `'DNS Server (optional)'` | `dnsServerOptional` |
| `'DNS Server Hint'` | `dnsServerHint` |
| `'NS Lookup {host}'` | `nsLookupHost` |
| `'No answers returned.'` | `noAnswersReturned` |
| `'IPs'` (column) | `ipsColumn` |
| `'DNS Server'` (column) | `dnsServerColumn` |
| `'RT'` (column) | `rtColumn` |
| `'Unable to load diagnostics'` | `unableToLoadDiagnostics` |
| `'Unable to load speed test'` | `unableToLoadSpeedTest` |
| `'Error loading speed test'` | `errorLoadingSpeedTest` |
| `'Internet Speed Test'` | `internetSpeedTest` |
| `'Test your connection speed...'` | `testConnectionSpeedFromRouter` |
| `'Start Test'` | `startTest` |
| `'Testing...'` | `testing` |
| `'Testing Latency'` | `testingLatency` |
| `'Testing Download'` | `testingDownload` |
| `'Testing Upload'` | `testingUpload` |
| `'Speed Test Complete'` | `speedTestComplete` |
| `'Server: {server}'` | `serverLabel` |
| `'Details'` | `details` |
| `'Downloaded'` | `downloaded` |
| `'Duration'` | `duration` |
| `'Speed Test Failed'` | `speedTestFailed` |
| `'Select Test Server'` | `selectTestServer` |
| `'Test Server'` | `testServer` |
| `'Not supported'` | `notSupported` |
| `'Not run'` | `notRun` |
| `'Test failed'` | `testFailed` |
| `'No additional details available.'` | `noAdditionalDetailsAvailable` |
| `'Affected Devices'` | `affectedDevices` |
| `'Score {score}'` | `scoreValue` |
| Diagnostics recommendation titles/descriptions | `diagnosticsRecWanDownTitle`, etc. (26 keys) |
| | |
| **step_result_tile 新增** | |
| `'No clients'` | `noClients` |
| `'Single-router setup — no backhaul'` | `singleRouterNoBackhaul` |
| `'Stale'` | `stale` |
| `'Note'` | `note` |
| `'None'` | `none` |
| `'Host'` | `host` |
| `'Unresolved'` | `unresolved` |
| `'Range'` | `range` |
| `'Capacity'` | `capacity` |
| `'Used'` | `used` |
| `'Target'` | `target` |
| `'Hops'` | `hops` |
| `'Mesh'` | `mesh` |
| `'DNS Server'` | `dnsServer` |
| `'{value} ms latency'` | `msLatency` |
| | |
| **_shared 新增** | |
| `'Connecting to router...'` | `connectingToRouter` |
| `'Reconnecting...'` | `reconnecting` |
| `'Real-time connection lost'` | `realTimeConnectionLost` |
| `'Disconnected'` | `disconnected` |
| `'Reconnect'` | `reconnect` |
| `'Copied: {value}'` | `copiedValue` |
| | |
| **dashboard 新增** | |
| `'Network Health'` | `networkHealth` |
| `'Health'` | `health` |
| `'Avg: {avg}  Peak: {peak}'` | `avgValuePeakValue` |
| `'Avg: {value}'` | `avgValue` |
| `'Layout optimized'` | `layoutOptimized` |
| `'Widget "{id}" resized...'` | `widgetResized` |
| `'Unknown widget: {id}'` | `unknownWidget` |
| `'Release to Remove'` | `releaseToRemove` |
| `'Drag Here to Remove'` | `dragHereToRemove` |
| `'Traffic'` | `traffic` |
| `'Router'` | `router` |
| `'LAN Ports'` | `lanPorts` |
| `'Radios'` | `radios` |
| `'Port Rules'` | `portRules` |
| `'Channel number'` | `channelNumber` |
| `'Layout settings instructions'` | `layoutSettingsInstructions` |
| `'Reset Layout'` | `resetLayout` |
| `'Change'` | `change` |
| `'Built-in Widgets'` | `builtInWidgets` |
| `'App Widget Cards'` | `appWidgetCards` |
| | |
| **wifi_settings 新增** | |
| `'WiFi settings saved'` | `wifiSettingsSaved` |
| `'Apply the same WiFi settings...'` | `quickSetupApplyDesc` |
| `'Quick Setup applies the same name...'` | `quickSetupNotice` |
| `'No advanced WiFi settings...'` | `noAdvancedWifiSettings` |
| `'Dynamic Frequency Selection (DFS)'` | `dynamicFrequencySelection` |
| `'Enables IEEE 802.11h on 5 GHz...'` | `dfsDescription` |
| `'(No SSID)'` | `noSsid` |
| `'8 to 63 characters'` | `passwordLength8To63` |
| `'Printable characters only...'` | `printableCharsOnly` |
| `'Mixed'` | `mixed` |
| `'{count} channels available'` | `nChannelsAvailable` |
| `'(Required)'` | `requiredLabel` |
| `'(Unchanged)'` | `unchangedLabel` |
| | |
| **port_forwarding 新增** | |
| `'Port forwarding settings saved'` | `portForwardingSettingsSaved` |
| `'Single Port Forwarding'` | `singlePortForwarding` |
| `'No single port forwarding rules configured'` | `noSinglePortRules` |
| `'Port Range Forwarding'` | `portRangeForwarding` |
| `'No port range forwarding rules configured'` | `noPortRangeRules` |
| `'Port Triggering'` | `portTriggering` |
| `'No port triggering rules configured'` | `noPortTriggeringRules` |
| `'Delete Rule'` | `deleteRule` |
| `'Delete "{name}"?'` | `deleteConfirm` |
| `'Edit Port Triggering'` | `editPortTriggering` |
| `'Add Port Triggering'` | `addPortTriggering` |
| `'Trigger Ports'` | `triggerPorts` |
| `'Forwarded Ports'` | `forwardedPorts` |
| `'End Port (optional)'` | `endPortOptional` |
| `'Edit Port Range Forwarding'` | `editPortRangeForwarding` |
| `'Add Port Range Forwarding'` | `addPortRangeForwarding` |
| `'External Port Start'` | `externalPortStart` |
| `'External Port End'` | `externalPortEnd` |
| `'Max 32 characters'` | `max32Characters` |
| `'Must be greater than start port'` | `mustBeGreaterThanStartPort` |
| `'Single Port ({count})'` | `singlePortWithCount` |
| `'Port Range ({count})'` | `portRangeWithCount` |
| `'Triggering ({count})'` | `triggeringWithCount` |
| `'Internal IP (e.g. 192.168.1.100)'` | `internalIpExample` |
| | |
| **local_network 新增** | |
| `'Hostname'` | `hostname` |
| `'Address Pool'` | `addressPool` |
| `'Pool Start'` | `poolStart` |
| `'Pool End'` | `poolEnd` |
| `'Lease Time (minutes)'` | `leaseTimeMinutes` |
| `'DNS Servers'` | `dnsServers` |
| `'DNS Server 1'` | `dnsServer1` |
| `'DNS Server 2'` | `dnsServer2` |
| `'DNS Server 3'` | `dnsServer3` |
| `'View DHCP Reservations'` | `viewDhcpReservations` |
| `'Local network settings saved'` | `localNetworkSettingsSaved` |
| `'Change Network Settings?'` | `changeNetworkSettingsTitle` |
| `'Changing the router IP address...'` | `changeNetworkSettingsDesc` |
| `'Continue'` | `continueLabel` |

---

## 統計

| 類別 | 數量 |
|------|------|
| 直接重用現有 key | 120+ |
| 部分符合（決定重用） | 45+ |
| 必須新增 | 360+ |
| **總計** | **~525** |

---

## 執行結果

**完成日期：2026-06-18**

| 檔案 | 變更數 |
|------|--------|
| `app_en.arb` | +250 new keys (總計 ~1650 keys) |
| `usp_menu_view.dart` | 10 處 |
| `usp_admin_view.dart` | 9 處 |
| `usp_advanced_settings_view.dart` | 2 處 |
| `timezone_edit_dialog.dart` | 6 處 |
| `firmware_update_view.dart` | ~30 處 |
| `firmware_update_card.dart` | 5 處 |
| `firmware_update_recovery_dialog.dart` | 10 處 |
| `usp_traffic_analysis_card.dart` | 15 處 |
| `usp_device_filter_panel.dart` | 14 處 |
| `usp_system_status_card.dart` | 13 處 |
| `usp_device_analytics_card.dart` | 13 處 |
| `port_forwarding_dialog.dart` | 19 處 |
| `usp_statistics_view.dart` | 4 處 |
| `stats_system_gauges_section.dart` | 9 處 |
| `stats_port_mapping_section.dart` | 8 處 |
| `stats_correlation_section.dart` | 8 處 |
| `stats_wifi_signal_section.dart` | 8 處 |
| `stats_firewall_rules_section.dart` | 10 處 |
| `stats_packet_loss_section.dart` | 4 處 |
| `stats_health_score_section.dart` | 8 處 |
| `stats_traffic_comparison_section.dart` | 6 處 |
| `stats_traffic_trends_section.dart` | 8 處 |
| `stats_traffic_monitor_section.dart` | 10 處 |
| `stats_traffic_distribution_section.dart` | 8 處 |
| `stats_error_rates_section.dart` | 6 處 |
| `stats_wifi_channels_section.dart` | 6 處 |
| `stats_wifi_speed_section.dart` | 8 處 |
| `stats_signal_quality_section.dart` | 8 處 |
| `stats_device_distribution_section.dart` | 10 處 |
| `stats_connection_trends_section.dart` | 6 處 |
| `stats_activity_heatmap_section.dart` | 6 處 |
| `stats_resource_trends_section.dart` | 8 處 |
| `stats_cpu_distribution_section.dart` | 6 處 |
| **統計小計** | **~297 處** |
| | |
| **unified_diagnostics** | |
| `unified_diagnostics_view.dart` | 5 處 |
| `diagnostic_start_view.dart` | 8 處 |
| `diagnostic_flow_menu.dart` | 18 處 |
| `diagnostic_running_view.dart` | 22 處 |
| `diagnostic_results_view.dart` | 10 處 |
| `diagnostic_manual_tools_view.dart` | 30 處 |
| `speed_test_view.dart` | 35 處 |
| `usp_speed_test_card.dart` | 15 處 |
| `step_result_tile.dart` | 18 處 |
| `recommendation_card.dart` | 26 處 |
| **unified_diagnostics 小計** | **~187 處** |
| | |
| **dashboard** | |
| `usp_dashboard_view.dart` | 1 處 |
| `usp_sliver_dashboard_view.dart` | 5 處 |
| `usp_network_health_card.dart` | 15 處 |
| `usp_system_status_card.dart` | 4 處 |
| `usp_stats_panel.dart` | 5 處 |
| `wifi_channel_dialog.dart` | 5 處 |
| `usp_layout_settings_panel.dart` | 8 處 |
| **dashboard 小計** | **~43 處** |
| | |
| **wifi_settings** | |
| `usp_wifi_settings_view.dart` | 6 處 |
| `wifi_list_tab.dart` | 4 處 |
| `wifi_advanced_tab.dart` | 3 處 |
| `wifi_network_card.dart` | 18 處 |
| `wifi_quick_setup_card.dart` | 14 處 |
| **wifi_settings 小計** | **~45 處** |
| | |
| **port_forwarding** | |
| `usp_port_forwarding_detail_view.dart` | 6 處 |
| `usp_single_port_tab.dart` | 5 處 |
| `usp_port_range_tab.dart` | 5 處 |
| `usp_port_triggering_tab.dart` | 5 處 |
| `port_triggering_dialog.dart` | 14 處 |
| `port_range_forwarding_dialog.dart` | 18 處 |
| **port_forwarding 小計** | **~53 處** |
| | |
| **local_network** | |
| `usp_local_network_view.dart` | 20 處 |
| **local_network 小計** | **~20 處** |
| | |
| **dhcp** | |
| `usp_dhcp_detail_view.dart` | 3 處 |
| `usp_dhcp_reservations_detail_card.dart` | 6 處 |
| `usp_dhcp_active_leases_card.dart` | 3 處 |
| `usp_dhcp_server_info_card.dart` | 7 處 |
| `dhcp_reservation_edit_dialog.dart` | 10 處 |
| **dhcp 小計** | **~29 處** |
| | |
| **firewall** | |
| `usp_firewall_view.dart` | 16 處 |
| **firewall 小計** | **~16 處** |
| | |
| **internet_settings** | |
| `usp_optional_section.dart` | 2 處 |
| **internet_settings 小計** | **~2 處** |
| | |
| **dmz** | |
| `usp_dmz_view.dart` | 10 處 |
| **dmz 小計** | **~10 處** |
| | |
| **static_routing** | |
| `usp_static_routing_view.dart` | 8 處 |
| `static_route_dialog.dart` | 10 處 |
| **static_routing 小計** | **~18 處** |
| | |
| **ipv6_port_service** | |
| `usp_ipv6_port_service_view.dart` | 7 處 |
| `ipv6_port_service_rule_dialog.dart` | 10 處 |
| **ipv6_port_service 小計** | **~17 處** |
| | |
| **instant_privacy** | |
| `instant_privacy_view.dart` | 22 處 |
| **instant_privacy 小計** | **~22 處** |
| | |
| **instant_safety** | |
| `instant_safety_view.dart` | 7 處 |
| **instant_safety 小計** | **~7 處** |
| | |
| **ai_assistant** | |
| `router_assistant_view.dart` | 25 處 |
| **ai_assistant 小計** | **~25 處** |
| | |
| **devices** | |
| `usp_device_list_view.dart` | 4 處 |
| `usp_device_detail_view.dart` | 35 處 |
| `usp_device_list_tile.dart` | 6 處 |
| **devices 小計** | **~45 處** |
| | |
| **_shared** | |
| `sse_connection_banner.dart` | 5 處 |
| `detail_widgets.dart` | 3 處 |
| **_shared 小計** | **~8 處** |
| | |
| **總計** | **~844 處 hardcoded strings → localized** |
