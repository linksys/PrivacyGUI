const rawCoreTransaction = '''
{
"result": "OK",
"responses": [
{
"result": "OK",
"output": {
"manufacturer": "Linksys",
"modelNumber": "WHW03",
"hardwareVersion": "2",
"description": "Velop",
"serialNumber": "20J2060A839173",
"firmwareVersion": "2.1.20.213195",
"firmwareDate": "2023-07-25T07:27:06Z",
"services": [
"http://linksys.com/jnap/core/Core",
"http://linksys.com/jnap/core/Core2",
"http://linksys.com/jnap/core/Core3",
"http://linksys.com/jnap/core/Core4",
"http://linksys.com/jnap/core/Core5",
"http://linksys.com/jnap/core/Core6",
"http://linksys.com/jnap/core/Core7",
"http://linksys.com/jnap/ddns/DDNS",
"http://linksys.com/jnap/ddns/DDNS2",
"http://linksys.com/jnap/ddns/DDNS3",
"http://linksys.com/jnap/ddns/DDNS4",
"http://linksys.com/jnap/debug/Debug",
"http://linksys.com/jnap/debug/Debug2",
"http://linksys.com/jnap/devicelist/DeviceList",
"http://linksys.com/jnap/devicelist/DeviceList2",
"http://linksys.com/jnap/devicelist/DeviceList4",
"http://linksys.com/jnap/devicelist/DeviceList5",
"http://linksys.com/jnap/devicelist/DeviceList6",
"http://linksys.com/jnap/devicelist/DeviceList7",
"http://linksys.com/jnap/devicepreauthorization/DevicePreauthorization",
"http://linksys.com/jnap/diagnostics/Diagnostics",
"http://linksys.com/jnap/diagnostics/Diagnostics2",
"http://linksys.com/jnap/diagnostics/Diagnostics3",
"http://linksys.com/jnap/diagnostics/Diagnostics6",
"http://linksys.com/jnap/diagnostics/Diagnostics7",
"http://linksys.com/jnap/diagnostics/Diagnostics8",
"http://linksys.com/jnap/diagnostics/Reliability",
"http://linksys.com/jnap/diagnostics/ScheduledReboot",
"http://linksys.com/jnap/dynamicportforwarding/DynamicPortForwarding",
"http://linksys.com/jnap/dynamicportforwarding/DynamicPortForwarding2",
"http://linksys.com/jnap/dynamicsession/DynamicSession",
"http://linksys.com/jnap/dynamicsession/DynamicSession2",
"http://linksys.com/jnap/firewall/Firewall",
"http://linksys.com/jnap/firewall/Firewall2",
"http://linksys.com/jnap/firmwareupdate/FirmwareUpdate",
"http://linksys.com/jnap/firmwareupdate/FirmwareUpdate2",
"http://linksys.com/jnap/guestnetwork/GuestNetwork",
"http://linksys.com/jnap/guestnetwork/GuestNetwork2",
"http://linksys.com/jnap/guestnetwork/GuestNetwork3",
"http://linksys.com/jnap/guestnetwork/GuestNetwork4",
"http://linksys.com/jnap/guestnetwork/GuestNetwork5",
"http://linksys.com/jnap/guestnetwork/GuestNetworkAuthentication",
"http://linksys.com/jnap/healthcheck/HealthCheckManager",
"http://linksys.com/jnap/homekit/HomeKit",
"http://linksys.com/jnap/homekit/ProofOfOwnership",
"http://linksys.com/jnap/homekit/SetupPayload",
"http://linksys.com/jnap/httpproxy/HttpProxy",
"http://linksys.com/jnap/httpproxy/HttpProxy2",
"http://linksys.com/jnap/iptv/IPTV",
"http://linksys.com/jnap/locale/Locale",
"http://linksys.com/jnap/locale/Locale2",
"http://linksys.com/jnap/locale/Locale3",
"http://linksys.com/jnap/macfilter/MACFilter",
"http://linksys.com/jnap/motionsensing/MotionSensing",
"http://linksys.com/jnap/motionsensing/MotionSensing2",
"http://linksys.com/jnap/networkconnections/NetworkConnections",
"http://linksys.com/jnap/networkconnections/NetworkConnections2",
"http://linksys.com/jnap/networkconnections/NetworkConnections3",
"http://linksys.com/jnap/networksecurity/ConfigVersion1",
"http://linksys.com/jnap/networksecurity/NetworkSecurity",
"http://linksys.com/jnap/networksecurity/NetworkSecurity2",
"http://linksys.com/jnap/networksecurity/NetworkSecurity3",
"http://linksys.com/jnap/nodes/autoonboarding/AutoOnboarding",
"http://linksys.com/jnap/nodes/bluetooth/Bluetooth",
"http://linksys.com/jnap/nodes/bluetooth/Bluetooth2",
"http://linksys.com/jnap/nodes/btsmartconnect/BTSmartConnect",
"http://linksys.com/jnap/nodes/btsmartconnect/BTSmartConnect2",
"http://linksys.com/jnap/nodes/btsmartconnect/BTSmartConnect3",
"http://linksys.com/jnap/nodes/cognitivemesh/CognitiveMesh",
"http://linksys.com/jnap/nodes/diagnostics/Diagnostics",
"http://linksys.com/jnap/nodes/diagnostics/Diagnostics2",
"http://linksys.com/jnap/nodes/diagnostics/Diagnostics3",
"http://linksys.com/jnap/nodes/diagnostics/Diagnostics5",
"http://linksys.com/jnap/nodes/firmwareupdate/FirmwareUpdate",
"http://linksys.com/jnap/nodes/networkconnections/NodesNetworkConnections",
"http://linksys.com/jnap/nodes/notification/Notification",
"http://linksys.com/jnap/nodes/setup/SelectableWAN",
"http://linksys.com/jnap/nodes/setup/Setup",
"http://linksys.com/jnap/nodes/setup/Setup2",
"http://linksys.com/jnap/nodes/setup/Setup3",
"http://linksys.com/jnap/nodes/setup/Setup4",
"http://linksys.com/jnap/nodes/setup/Setup5",
"http://linksys.com/jnap/nodes/setup/Setup6",
"http://linksys.com/jnap/nodes/setup/Setup7",
"http://linksys.com/jnap/nodes/setup/Setup8",
"http://linksys.com/jnap/nodes/smartconnect/SmartConnect",
"http://linksys.com/jnap/nodes/smartconnect/SmartConnect2",
"http://linksys.com/jnap/nodes/smartconnect/SmartConnect3",
"http://linksys.com/jnap/nodes/smartconnect/SmartConnect4",
"http://linksys.com/jnap/nodes/smartmode/SmartMode",
"http://linksys.com/jnap/nodes/smartmode/SmartMode2",
"http://linksys.com/jnap/nodes/topologyoptimization/TopologyOptimization",
"http://linksys.com/jnap/nodes/topologyoptimization/TopologyOptimization2",
"http://linksys.com/jnap/ownednetwork/OwnedNetwork",
"http://linksys.com/jnap/ownednetwork/OwnedNetwork2",
"http://linksys.com/jnap/parentalcontrol/ParentalControl",
"http://linksys.com/jnap/parentalcontrol/ParentalControl2",
"http://linksys.com/jnap/powertable/PowerTable",
"http://linksys.com/jnap/product/Product",
"http://linksys.com/jnap/qos/QoS",
"http://linksys.com/jnap/qos/QoS2",
"http://linksys.com/jnap/qos/QoS3",
"http://linksys.com/jnap/qos/calibration/Calibration",
"http://linksys.com/jnap/router/Router",
"http://linksys.com/jnap/router/Router10",
"http://linksys.com/jnap/router/Router11",
"http://linksys.com/jnap/router/Router3",
"http://linksys.com/jnap/router/Router4",
"http://linksys.com/jnap/router/Router5",
"http://linksys.com/jnap/router/Router6",
"http://linksys.com/jnap/router/Router7",
"http://linksys.com/jnap/router/Router8",
"http://linksys.com/jnap/router/Router9",
"http://linksys.com/jnap/routerleds/RouterLEDs",
"http://linksys.com/jnap/routerleds/RouterLEDs2",
"http://linksys.com/jnap/routerlog/RouterLog",
"http://linksys.com/jnap/routerlog/RouterLog2",
"http://linksys.com/jnap/routermanagement/RouterManagement",
"http://linksys.com/jnap/routermanagement/RouterManagement2",
"http://linksys.com/jnap/routermanagement/RouterManagement3",
"http://linksys.com/jnap/routerstatus/RouterStatus",
"http://linksys.com/jnap/routerstatus/RouterStatus2",
"http://linksys.com/jnap/routerupnp/RouterUPnP",
"http://linksys.com/jnap/routerupnp/RouterUPnP2",
"http://linksys.com/jnap/ui/Settings",
"http://linksys.com/jnap/ui/Settings2",
"http://linksys.com/jnap/ui/Settings3",
"http://linksys.com/jnap/wirelessap/AdvancedWirelessAP",
"http://linksys.com/jnap/wirelessap/AdvancedWirelessAP2",
"http://linksys.com/jnap/wirelessap/AirtimeFairness",
"http://linksys.com/jnap/wirelessap/DynamicFrequencySelection",
"http://linksys.com/jnap/wirelessap/WPSServer",
"http://linksys.com/jnap/wirelessap/WPSServer2",
"http://linksys.com/jnap/wirelessap/WPSServer3",
"http://linksys.com/jnap/wirelessap/WPSServer4",
"http://linksys.com/jnap/wirelessap/WPSServer5",
"http://linksys.com/jnap/wirelessap/WirelessAP",
"http://linksys.com/jnap/wirelessap/WirelessAP2",
"http://linksys.com/jnap/wirelessap/WirelessAP4",
"http://linksys.com/jnap/wirelessap/qualcomm/AdvancedQualcomm",
"http://linksys.com/jnap/wirelessscheduler/WirelessScheduler",
"http://linksys.com/jnap/wirelessscheduler/WirelessScheduler2",
"http://linksys.com/jnap/xconnect/XConnect"
]
}
},
{
"result": "OK",
"output": {
"supportedWANTypes": [
"DHCP",
"Static",
"PPPoE",
"PPTP",
"L2TP",
"Bridge"
],
"supportedIPv6WANTypes": [
"Automatic",
"PPPoE",
"Pass-through"
],
"supportedWANCombinations": [
{
"wanType": "DHCP",
"wanIPv6Type": "Automatic"
},
{
"wanType": "Static",
"wanIPv6Type": "Automatic"
},
{
"wanType": "PPPoE",
"wanIPv6Type": "Automatic"
},
{
"wanType": "L2TP",
"wanIPv6Type": "Automatic"
},
{
"wanType": "PPTP",
"wanIPv6Type": "Automatic"
},
{
"wanType": "Bridge",
"wanIPv6Type": "Automatic"
},
{
"wanType": "DHCP",
"wanIPv6Type": "Pass-through"
},
{
"wanType": "PPPoE",
"wanIPv6Type": "PPPoE"
}
],
"isDetectingWANType": false,
"detectedWANType": "DHCP",
"wanStatus": "Connected",
"wanConnection": {
"wanType": "DHCP",
"ipAddress": "192.168.2.101",
"networkPrefixLength": 24,
"gateway": "192.168.2.1",
"mtu": 0,
"dhcpLeaseMinutes": 5256000,
"dnsServer1": "192.168.2.1"
},
"wanIPv6Status": "Connecting",
"linkLocalIPv6Address": "fe80:0000:0000:0000:3223:03ff:fe2e:afee",
"macAddress": "30:23:03:2E:AF:EE"
}
},
{
"result": "OK",
"output": {
"lastTriggered": "2023-09-22T05:02:15Z",
"nodeWirelessConnections": [
{
"deviceID": "0b447477-5693-2b7e-8bbd-3023032eafee",
"connections": [
{
"macAddress": "12:7D:2A:77:4A:0D",
"negotiatedMbps": 6,
"timestamp": "2023-09-22T03:19:56Z",
"wireless": {
"bssid": "36:23:03:2E:AF:F0",
"isGuest": true,
"radioID": "RADIO_5GHz",
"band": "5GHz",
"signalDecibels": -50
}
},
{
"macAddress": "D2:60:CB:A0:3D:17",
"negotiatedMbps": 780,
"timestamp": "2023-09-23T03:21:47Z",
"wireless": {
"bssid": "36:23:03:2E:AF:F0",
"isGuest": true,
"radioID": "RADIO_5GHz",
"band": "5GHz",
"signalDecibels": -45
}
}
]
},
{
"deviceID": "5391a1d4-12fa-95c6-0b68-30230335e007",
"connections": [
{
"macAddress": "4A:2D:59:25:67:D7",
"negotiatedMbps": 6,
"timestamp": "2023-09-04T02:34:37Z",
"wireless": {
"bssid": "30:23:03:35:E0:09",
"isGuest": false,
"radioID": "RADIO_5GHz",
"band": "5GHz",
"signalDecibels": -84
}
}
]
}
]
}
},
{
"result": "OK",
"output": {
"connections": [
{
"macAddress": "12:7D:2A:77:4A:0D",
"negotiatedMbps": 390,
"wireless": {
"bssid": "36:23:03:2E:AF:F0",
"isGuest": true,
"radioID": "RADIO_5GHz",
"band": "5GHz",
"signalDecibels": 50
}
},
{
"macAddress": "3A:23:03:2E:A4:EC",
"negotiatedMbps": 866,
"wireless": {
"bssid": "30:23:03:2E:AF:F0",
"isGuest": false,
"radioID": "RADIO_5GHz",
"band": "5GHz",
"signalDecibels": 71
}
},
{
"macAddress": "80:1F:02:73:C5:D4",
"negotiatedMbps": 100
},
{
"macAddress": "D2:60:CB:A0:3D:17",
"negotiatedMbps": 780,
"wireless": {
"bssid": "36:23:03:2E:AF:F0",
"isGuest": true,
"radioID": "RADIO_5GHz",
"band": "5GHz",
"signalDecibels": 47
}
}
]
}
},
{
"result": "OK",
"output": {
"isBandSteeringSupported": false,
"radios": [
{
"radioID": "RADIO_2.4GHz",
"physicalRadioID": "ath0",
"bssid": "30:23:03:2E:AF:EF",
"band": "2.4GHz",
"supportedModes": [
"802.11mixed"
],
"supportedChannelsForChannelWidths": [
{
"channelWidth": "Auto",
"channels": [
0,
1,
2,
3,
4,
5,
6,
7,
8,
9,
10,
11
]
},
{
"channelWidth": "Standard",
"channels": [
0,
1,
2,
3,
4,
5,
6,
7,
8,
9,
10,
11
]
}
],
"supportedSecurityTypes": [
"None",
"WPA-Mixed-Personal",
"WPA2-Personal"
],
"maxRADIUSSharedKeyLength": 64,
"settings": {
"isEnabled": true,
"mode": "802.11mixed",
"ssid": "fee_qa_velop",
"broadcastSSID": true,
"channelWidth": "Auto",
"channel": 0,
"security": "WPA2-Personal",
"wpaPersonalSettings": {
"passphrase": "Belkin123!"
}
}
},
{
"radioID": "RADIO_5GHz",
"physicalRadioID": "ath1",
"bssid": "30:23:03:2E:AF:F0",
"band": "5GHz",
"supportedModes": [
"802.11mixed"
],
"supportedChannelsForChannelWidths": [
{
"channelWidth": "Auto",
"channels": [
0,
36,
40,
44,
48
]
},
{
"channelWidth": "Standard",
"channels": [
0,
36,
40,
44,
48
]
},
{
"channelWidth": "Wide",
"channels": [
0,
36,
40,
44,
48
]
}
],
"supportedSecurityTypes": [
"None",
"WPA-Mixed-Personal",
"WPA2-Personal"
],
"maxRADIUSSharedKeyLength": 64,
"settings": {
"isEnabled": true,
"mode": "802.11mixed",
"ssid": "fee_qa_velop",
"broadcastSSID": true,
"channelWidth": "Auto",
"channel": 0,
"security": "WPA2-Personal",
"wpaPersonalSettings": {
"passphrase": "Belkin123!"
}
}
},
{
"radioID": "RADIO_5GHz_2",
"physicalRadioID": "ath10",
"bssid": "30:23:03:2E:AF:F1",
"band": "5GHz",
"supportedModes": [
"802.11mixed"
],
"supportedChannelsForChannelWidths": [
{
"channelWidth": "Auto",
"channels": [
0,
149,
153,
157,
161,
165
]
},
{
"channelWidth": "Standard",
"channels": [
0,
149,
153,
157,
161,
165
]
},
{
"channelWidth": "Wide",
"channels": [
0,
149,
153,
157,
161
]
}
],
"supportedSecurityTypes": [
"None",
"WPA-Mixed-Personal",
"WPA2-Personal"
],
"maxRADIUSSharedKeyLength": 64,
"settings": {
"isEnabled": true,
"mode": "802.11mixed",
"ssid": "fee_qa_velop",
"broadcastSSID": true,
"channelWidth": "Auto",
"channel": 0,
"security": "WPA2-Personal",
"wpaPersonalSettings": {
"passphrase": "Belkin123!"
}
}
}
]
}
},
{
"result": "OK",
"output": {
"isGuestNetworkACaptivePortal": false,
"isGuestNetworkEnabled": true,
"radios": [
{
"radioID": "RADIO_2.4GHz",
"isEnabled": true,
"broadcastGuestSSID": true,
"guestSSID": "fee_guest_qa_velop",
"guestWPAPassphrase": "Belkin123!",
"canEnableRadio": true
},
{
"radioID": "RADIO_5GHz",
"isEnabled": true,
"broadcastGuestSSID": true,
"guestSSID": "fee_guest_qa_velop",
"guestWPAPassphrase": "Belkin123!",
"canEnableRadio": true
}
]
}
},
{
"result": "OK",
"output": {
"revision": 6077,
"devices": [
{
"deviceID": "0b447477-5693-2b7e-8bbd-3023032eafee",
"lastChangeRevision": 6022,
"model": {
"deviceType": "Infrastructure",
"manufacturer": "Linksys",
"modelNumber": "WHW03",
"hardwareVersion": "2",
"description": "Velop"
},
"unit": {
"serialNumber": "20J2060A839173",
"firmwareVersion": "2.1.20.213195",
"firmwareDate": "2023-07-25T07:27:06Z"
},
"isAuthority": true,
"nodeType": "Master",
"isHomeKitSupported": true,
"friendlyName": "Linksys39173",
"knownInterfaces": [
{
"macAddress": "30:23:03:2E:AF:EE",
"interfaceType": "Wired"
}
],
"connections": [
{
"macAddress": "30:23:03:2E:AF:EE",
"ipAddress": "192.168.1.1"
}
],
"properties": [
{
"name": "userDeviceLocation",
"value": "Hank Table Test"
},
{
"name": "userDeviceName",
"value": "Hank Table Test"
}
],
"maxAllowedProperties": 16
},
{
"deviceID": "cca5422a-8390-4bfb-84de-f0993f866b4f",
"lastChangeRevision": 5776,
"model": {
"deviceType": "Mobile"
},
"unit": {
"operatingSystem": "Android"
},
"isAuthority": false,
"friendlyName": "192-168-1-249",
"knownInterfaces": [
{
"macAddress": "0E:A9:5B:A3:C0:72",
"interfaceType": "Wireless",
"band": "5GHz"
}
],
"connections": [],
"properties": [
{
"name": "userDeviceOS",
"value": "Android 13"
},
{
"name": "userDeviceManufacturer",
"value": "Samsung"
},
{
"name": "userDeviceModelNumber",
"value": "SM-S9010"
}
],
"maxAllowedProperties": 16
},
{
"deviceID": "4dfda198-47f4-4eea-9162-588b7beb0322",
"lastChangeRevision": 5787,
"model": {
"deviceType": "Phone",
"manufacturer": "Apple Inc.",
"modelNumber": "iPhone 8 Plus"
},
"unit": {
"operatingSystem": "iOS"
},
"isAuthority": false,
"friendlyName": "Taiwan-Linksys-Peter-iPhone 8 Plus-7B5C8",
"knownInterfaces": [
{
"macAddress": "4A:2D:59:25:67:D7",
"interfaceType": "Wireless",
"band": "5GHz"
}
],
"connections": [],
"properties": [
{
"name": "userDeviceOS",
"value": "iOS 15.1"
},
{
"name": "userDeviceManufacturer",
"value": "Apple"
},
{
"name": "userDeviceModelNumber",
"value": "iPhone 8 Plus"
}
],
"maxAllowedProperties": 16
},
{
"deviceID": "d5cd132a-cdd0-45e9-8642-21c7ea70e7a3",
"lastChangeRevision": 3129,
"model": {
"deviceType": "Computer",
"manufacturer": "Apple Inc.",
"modelNumber": "MacBook Pro"
},
"unit": {
"operatingSystem": "macOS"
},
"isAuthority": false,
"friendlyName": "ASTWP-29134",
"knownInterfaces": [
{
"macAddress": "3C:22:FB:E4:4F:18",
"interfaceType": "Wireless",
"band": "5GHz"
}
],
"connections": [],
"properties": [],
"maxAllowedProperties": 16
},
{
"deviceID": "277ef2d8-6bce-49d9-9013-9532fefd3220",
"lastChangeRevision": 5114,
"model": {
"deviceType": ""
},
"unit": {},
"isAuthority": false,
"friendlyName": "ASTWP-028310",
"knownInterfaces": [
{
"macAddress": "3C:22:FB:F0:4C:18",
"interfaceType": "Wireless",
"band": "5GHz"
}
],
"connections": [],
"properties": [],
"maxAllowedProperties": 16
},
{
"deviceID": "4c9758b6-33c8-401e-b85e-b3c38a24c202",
"lastChangeRevision": 1771,
"model": {
"deviceType": "Phone",
"manufacturer": "Apple Inc.",
"modelNumber": "iPhone"
},
"unit": {
"operatingSystem": "iOS"
},
"isAuthority": false,
"friendlyName": "Taiwan-Linksys-Hank-iPhone 13-7801E",
"knownInterfaces": [
{
"macAddress": "F6:5B:A4:1D:CA:BA",
"interfaceType": "Wireless",
"band": "5GHz"
}
],
"connections": [],
"properties": [],
"maxAllowedProperties": 16
},
{
"deviceID": "2507ecc4-dd18-4017-b7cc-589d4f684f00",
"lastChangeRevision": 2544,
"model": {
"deviceType": "Phone",
"manufacturer": "Apple Inc.",
"modelNumber": "iPhone XR"
},
"unit": {
"operatingSystem": "iOS"
},
"isAuthority": false,
"friendlyName": "Taiwan-Linksys-Hank-iPhone XR-9002E",
"knownInterfaces": [
{
"macAddress": "72:B0:3E:F8:BE:66",
"interfaceType": "Wireless",
"band": "5GHz"
}
],
"connections": [],
"properties": [
{
"name": "userDeviceOS",
"value": "iOS 15.0.2"
},
{
"name": "userDeviceManufacturer",
"value": "Apple"
},
{
"name": "userDeviceModelNumber",
"value": "iPhone XR"
}
],
"maxAllowedProperties": 16
},
{
"deviceID": "667f4f5b-8b9a-4724-9171-97e01952a740",
"lastChangeRevision": 4883,
"model": {
"deviceType": "Phone",
"manufacturer": "Apple Inc.",
"modelNumber": "iPhone"
},
"unit": {
"operatingSystem": "iOS"
},
"isAuthority": false,
"friendlyName": "Austins-iPhone",
"knownInterfaces": [
{
"macAddress": "F2:B7:56:06:DD:D9",
"interfaceType": "Wireless",
"band": "5GHz"
}
],
"connections": [],
"properties": [
{
"name": "userDeviceName",
"value": "Austins-iPhone 123"
}
],
"maxAllowedProperties": 16
},
{
"deviceID": "2fce469a-2d48-6cf2-8b86-3023032ea4ea",
"lastChangeRevision": 6011,
"model": {
"deviceType": "Infrastructure",
"manufacturer": "Linksys",
"modelNumber": "WHW03",
"description": "Velop"
},
"unit": {
"serialNumber": "20J2060A838609",
"firmwareVersion": "2.1.20.213195"
},
"isAuthority": false,
"nodeType": "Slave",
"isHomeKitSupported": true,
"friendlyName": "LINKSYS38609",
"knownInterfaces": [
{
"macAddress": "36:23:03:2E:A4:ED",
"interfaceType": "Unknown"
},
{
"macAddress": "30:23:03:2E:A4:EA",
"interfaceType": "Unknown"
},
{
"macAddress": "36:23:03:2E:A4:EC",
"interfaceType": "Unknown"
},
{
"macAddress": "3A:23:03:2E:A4:EC",
"interfaceType": "Wireless",
"band": "5GHz"
}
],
"connections": [
{
"macAddress": "30:23:03:2E:A4:EA",
"ipAddress": "192.168.1.194",
"ipv6Address": "fe80:0000:0000:0000:3223:03ff:fe2e:a4ea"
}
],
"properties": [
{
"name": "userDeviceLocation",
"value": "Behind Hank"
},
{
"name": "userDeviceName",
"value": "Behind Hank"
}
],
"maxAllowedProperties": 16
},
{
"deviceID": "032206c5-cdd0-4b7e-9a4c-629958736046",
"lastChangeRevision": 5310,
"model": {
"deviceType": "Phone",
"manufacturer": "Apple Inc.",
"modelNumber": "iPhone"
},
"unit": {
"operatingSystem": "iOS"
},
"isAuthority": false,
"friendlyName": "Taiwan-Linksys-Hank-iPhone 13-7801E",
"knownInterfaces": [
{
"macAddress": "AA:FE:6F:3C:25:31",
"interfaceType": "Wireless",
"band": "5GHz"
}
],
"connections": [],
"properties": [
{
"name": "userDeviceName",
"value": "Taiwan-Linksys-Hank-iPhone 13-7801E"
},
{
"name": "userDeviceOS",
"value": "iOS 16.6"
},
{
"name": "userDeviceManufacturer",
"value": "Apple"
},
{
"name": "userDeviceModelNumber",
"value": "iPhone 13"
}
],
"maxAllowedProperties": 16
},
{
"deviceID": "b33c8e19-b4a5-40e7-888d-b669d2a2d6fa",
"lastChangeRevision": 5187,
"model": {
"deviceType": "Mobile"
},
"unit": {
"operatingSystem": "Android"
},
"isAuthority": false,
"knownInterfaces": [
{
"macAddress": "1E:40:07:7A:EF:F1",
"interfaceType": "Unknown"
}
],
"connections": [],
"properties": [],
"maxAllowedProperties": 16
},
{
"deviceID": "c5bb67a3-ad3a-4344-ade2-f487487af1f4",
"lastChangeRevision": 6077,
"model": {
"deviceType": "Phone",
"manufacturer": "Apple Inc.",
"modelNumber": "iPhone XR"
},
"unit": {},
"isAuthority": false,
"knownInterfaces": [
{
"macAddress": "D2:60:CB:A0:3D:17",
"interfaceType": "Wireless",
"band": "5GHz"
}
],
"connections": [
{
"macAddress": "D2:60:CB:A0:3D:17",
"ipAddress": "192.168.3.113",
"parentDeviceID": "0b447477-5693-2b7e-8bbd-3023032eafee",
"isGuest": true
}
],
"properties": [],
"maxAllowedProperties": 16
},
{
"deviceID": "989dfbe0-a171-4a6b-89e8-9b27915b2d39",
"lastChangeRevision": 5305,
"model": {
"deviceType": ""
},
"unit": {},
"isAuthority": false,
"friendlyName": "TaiwanLSE23802E",
"knownInterfaces": [
{
"macAddress": "16:F1:B6:95:5F:68",
"interfaceType": "Wireless",
"band": "5GHz"
}
],
"connections": [],
"properties": [],
"maxAllowedProperties": 16
},
{
"deviceID": "a5bba640-54ed-4913-ad59-8a5c8edfbf9f",
"lastChangeRevision": 5777,
"model": {
"deviceType": "Phone",
"manufacturer": "Apple Inc.",
"modelNumber": "iPhone"
},
"unit": {
"operatingSystem": "iOS"
},
"isAuthority": false,
"friendlyName": "Matt-Youngs-iPhone",
"knownInterfaces": [
{
"macAddress": "62:0E:4C:64:AA:C0",
"interfaceType": "Wireless",
"band": "5GHz"
}
],
"connections": [],
"properties": [],
"maxAllowedProperties": 16
},
{
"deviceID": "589331b2-3092-408f-9563-343b3af1d835",
"lastChangeRevision": 5775,
"model": {
"deviceType": ""
},
"unit": {},
"isAuthority": false,
"knownInterfaces": [
{
"macAddress": "92:BF:1B:A0:81:5A",
"interfaceType": "Wireless",
"band": "5GHz"
}
],
"connections": [],
"properties": [],
"maxAllowedProperties": 16
},
{
"deviceID": "1131fdd5-585a-44e1-9dea-92c1c5051143",
"lastChangeRevision": 5416,
"model": {
"deviceType": "Mobile"
},
"unit": {
"operatingSystem": "Android"
},
"isAuthority": false,
"friendlyName": "unknown",
"knownInterfaces": [
{
"macAddress": "B2:C1:FF:00:74:DE",
"interfaceType": "Wireless",
"band": "5GHz"
}
],
"connections": [],
"properties": [
{
"name": "userDeviceOS",
"value": "Android 12"
},
{
"name": "userDeviceManufacturer",
"value": "Samsung"
},
{
"name": "userDeviceModelNumber",
"value": "SM-G973F"
}
],
"maxAllowedProperties": 16
},
{
"deviceID": "b1a9901c-6d13-4c1a-93a9-c51ac506bce9",
"lastChangeRevision": 4885,
"model": {
"deviceType": "Computer",
"manufacturer": "Apple, Inc.",
"modelNumber": "MacBook Pro"
},
"unit": {
"operatingSystem": "macOS"
},
"isAuthority": false,
"friendlyName": "ASTWP-028292",
"knownInterfaces": [
{
"macAddress": "A4:83:E7:36:4C:22",
"interfaceType": "Wireless",
"band": "5GHz"
}
],
"connections": [],
"properties": [],
"maxAllowedProperties": 16
},
{
"deviceID": "bbe96f42-39cf-4678-ae53-b4272c78644e",
"lastChangeRevision": 5347,
"model": {
"deviceType": "Phone",
"manufacturer": "Apple Inc.",
"modelNumber": "iPhone"
},
"unit": {
"operatingSystem": "iOS"
},
"isAuthority": false,
"friendlyName": "Hank’s iPhone12 Pro Max",
"knownInterfaces": [
{
"macAddress": "76:22:1D:CE:DA:59",
"interfaceType": "Wireless",
"band": "5GHz"
}
],
"connections": [],
"properties": [],
"maxAllowedProperties": 16
},
{
"deviceID": "bc18eb9f-13b6-4bd0-8d84-4950d273fefd",
"lastChangeRevision": 5678,
"model": {
"deviceType": "Phone",
"manufacturer": "Apple Inc.",
"modelNumber": "iPhone 7"
},
"unit": {
"operatingSystem": "iOS"
},
"isAuthority": false,
"friendlyName": "Kate’s iPhone",
"knownInterfaces": [
{
"macAddress": "B6:A8:06:2A:69:91",
"interfaceType": "Wireless",
"band": "5GHz"
}
],
"connections": [],
"properties": [
{
"name": "userDeviceOS",
"value": "iOS 15.7.9"
},
{
"name": "userDeviceManufacturer",
"value": "Apple"
},
{
"name": "userDeviceModelNumber",
"value": "iPhone 7"
}
],
"maxAllowedProperties": 16
},
{
"deviceID": "c7e5993c-10ef-4133-bc67-d27861cdf9a9",
"lastChangeRevision": 5669,
"model": {
"deviceType": "Mobile"
},
"unit": {
"operatingSystem": "Android"
},
"isAuthority": false,
"friendlyName": "unknown",
"knownInterfaces": [
{
"macAddress": "6E:34:C2:5D:46:CA",
"interfaceType": "Wireless",
"band": "5GHz"
}
],
"connections": [],
"properties": [],
"maxAllowedProperties": 16
},
{
"deviceID": "574fe1ee-b5dd-4bbc-8a9d-0c183cecd5b3",
"lastChangeRevision": 6069,
"model": {
"deviceType": ""
},
"unit": {},
"isAuthority": false,
"knownInterfaces": [
{
"macAddress": "12:7D:2A:77:4A:0D",
"interfaceType": "Wireless",
"band": "5GHz"
}
],
"connections": [
{
"macAddress": "12:7D:2A:77:4A:0D",
"ipAddress": "192.168.3.103",
"parentDeviceID": "0b447477-5693-2b7e-8bbd-3023032eafee",
"isGuest": true
}
],
"properties": [],
"maxAllowedProperties": 16
},
{
"deviceID": "ac77eb3f-10b5-41cb-bcb7-d2a506127ac4",
"lastChangeRevision": 5726,
"model": {
"deviceType": ""
},
"unit": {},
"isAuthority": false,
"knownInterfaces": [
{
"macAddress": "16:0F:B6:EE:17:B3",
"interfaceType": "Unknown"
}
],
"connections": [],
"properties": [],
"maxAllowedProperties": 16
}
]
}
},
{
"result": "OK",
"output": {
"lastSuccessfulCheckTime": "2023-09-22T16:17:09Z"
}
},
{
"result": "OK",
"output": {
"healthCheckResults": [
{
"resultID": 16557,
"timestamp": "2023-08-07T08:36:12Z",
"healthCheckModulesRequested": [
"SpeedTest"
],
"speedTestResult": {
"resultID": 16557,
"exitCode": "Success",
"serverID": "38330",
"latency": 2,
"uploadBandwidth": 44559,
"downloadBandwidth": 93356
}
},
{
"resultID": 27479,
"timestamp": "2023-08-04T06:36:19Z",
"healthCheckModulesRequested": [
"SpeedTest"
],
"speedTestResult": {
"resultID": 27479,
"exitCode": "Success",
"serverID": "38330",
"latency": 2,
"uploadBandwidth": 43875,
"downloadBandwidth": 91690
}
},
{
"resultID": 63397,
"timestamp": "2023-08-04T06:35:43Z",
"healthCheckModulesRequested": [
"SpeedTest"
],
"speedTestResult": {
"resultID": 63397,
"exitCode": "Success",
"serverID": "38330",
"latency": 2,
"uploadBandwidth": 44556,
"downloadBandwidth": 92401
}
}
]
}
},
{
"result": "OK",
"output": {
"supportedHealthCheckModules": [
"SpeedTest"
]
}
},
{
"result": "OK",
"output": {
"backhaulDevices": [
{
"deviceUUID": "2fce469a-2d48-6cf2-8b86-3023032ea4ea",
"ipAddress": "192.168.1.194",
"parentIPAddress": "192.168.1.1",
"connectionType": "Wireless",
"wirelessConnectionInfo": {
"radioID": "5GL",
"channel": 44,
"apRSSI": -23,
"stationRSSI": -14,
"apBSSID": "30:23:03:2E:AF:F0",
"stationBSSID": "3A:23:03:2E:A4:EC"
},
"speedMbps": "143.553",
"timestamp": "2023-09-23T05:13:09Z"
}
]
}
}
]
}
''';
