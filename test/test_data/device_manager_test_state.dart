const deviceManagerTestData = {
  "wirelessConnections": {
    "02:27:5B:F0:B5:EF": {
      "bssid": "80:69:1A:13:16:10",
      "isGuest": false,
      "radioID": "RADIO_5GHz",
      "band": "5GHz",
      "signalDecibels": -43
    },
    "3C:22:FB:E4:4F:18": {
      "bssid": "80:69:1A:13:16:10",
      "isGuest": false,
      "radioID": "RADIO_5GHz",
      "band": "5GHz",
      "signalDecibels": -35
    }
  },
  "radioInfos": {
    "RADIO_2.4GHz": {
      "radioID": "RADIO_2.4GHz",
      "physicalRadioID": "ath0",
      "bssid": "80:69:1A:13:16:0F",
      "band": "2.4GHz",
      "supportedModes": ["802.11bg", "802.11bgn", "802.11bgnax"],
      "defaultMixedMode": "802.11bgnax",
      "supportedChannelsForChannelWidths": [
        {
          "channelWidth": "Auto",
          "channels": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
        },
        {
          "channelWidth": "Standard",
          "channels": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
        }
      ],
      "supportedSecurityTypes": [
        "Enhanced-Open+None",
        "Enhanced-Open-Only",
        "None",
        "WPA2-Personal",
        "WPA2/WPA3-Mixed-Personal",
        "WPA3-Personal"
      ],
      "maxRADIUSSharedKeyLength": 64,
      "settings": {
        "isEnabled": true,
        "mode": "802.11bgnax",
        "ssid": "_VelopSetup60E",
        "broadcastSSID": true,
        "channelWidth": "Auto",
        "channel": 0,
        "security": "WPA2/WPA3-Mixed-Personal",
        "wpaPersonalSettings": {"passphrase": "05a63mipt3"}
      }
    },
    "RADIO_5GHz": {
      "radioID": "RADIO_5GHz",
      "physicalRadioID": "ath10",
      "bssid": "80:69:1A:13:16:10",
      "band": "5GHz",
      "supportedModes": [
        "802.11a",
        "802.11an",
        "802.11anac",
        "802.11anacax",
        "802.11anacaxbe"
      ],
      "defaultMixedMode": "802.11anacaxbe",
      "supportedChannelsForChannelWidths": [
        {
          "channelWidth": "Auto",
          "channels": [0, 36, 40, 44, 48, 149, 153, 157, 161, 165]
        },
        {
          "channelWidth": "Standard",
          "channels": [0, 36, 40, 44, 48, 149, 153, 157, 161, 165]
        },
        {
          "channelWidth": "Wide",
          "channels": [0, 36, 40, 44, 48, 149, 153, 157, 161]
        }
      ],
      "supportedSecurityTypes": [
        "Enhanced-Open+None",
        "Enhanced-Open-Only",
        "None",
        "WPA2-Personal",
        "WPA2/WPA3-Mixed-Personal",
        "WPA3-Personal"
      ],
      "maxRADIUSSharedKeyLength": 64,
      "settings": {
        "isEnabled": true,
        "mode": "802.11anacaxbe",
        "ssid": "_VelopSetup60E",
        "broadcastSSID": true,
        "channelWidth": "Auto",
        "channel": 0,
        "security": "WPA2/WPA3-Mixed-Personal",
        "wpaPersonalSettings": {"passphrase": "05a63mipt3"}
      }
    },
    "RADIO_6GHz": {
      "radioID": "RADIO_6GHz",
      "physicalRadioID": "ath30",
      "bssid": "82:69:1A:13:16:11",
      "band": "6GHz",
      "supportedModes": ["802.11ax", "802.11axbe"],
      "defaultMixedMode": "802.11axbe",
      "supportedChannelsForChannelWidths": [
        {
          "channelWidth": "Auto",
          "channels": [
            0,
            1,
            5,
            9,
            13,
            17,
            21,
            25,
            29,
            33,
            37,
            41,
            45,
            49,
            53,
            57,
            61,
            65,
            69,
            73,
            77,
            81,
            85,
            89,
            93,
            97,
            101,
            105,
            109,
            113,
            117,
            121,
            125,
            129,
            133,
            137,
            141,
            145,
            149,
            153,
            157,
            161,
            165,
            169,
            173,
            177,
            181,
            185,
            189,
            193,
            197,
            201,
            205,
            209,
            213,
            217,
            221,
            225,
            229
          ]
        },
        {
          "channelWidth": "Standard",
          "channels": [
            0,
            1,
            5,
            9,
            13,
            17,
            21,
            25,
            29,
            33,
            37,
            41,
            45,
            49,
            53,
            57,
            61,
            65,
            69,
            73,
            77,
            81,
            85,
            89,
            93,
            97,
            101,
            105,
            109,
            113,
            117,
            121,
            125,
            129,
            133,
            137,
            141,
            145,
            149,
            153,
            157,
            161,
            165,
            169,
            173,
            177,
            181,
            185,
            189,
            193,
            197,
            201,
            205,
            209,
            213,
            217,
            221,
            225,
            229
          ]
        },
        {
          "channelWidth": "Wide",
          "channels": [
            0,
            1,
            5,
            9,
            13,
            17,
            21,
            25,
            29,
            33,
            37,
            41,
            45,
            49,
            53,
            57,
            61,
            65,
            69,
            73,
            77,
            81,
            85,
            89,
            93,
            97,
            101,
            105,
            109,
            113,
            117,
            121,
            125,
            129,
            133,
            137,
            141,
            145,
            149,
            153,
            157,
            161,
            165,
            169,
            173,
            177,
            181,
            185,
            189,
            193,
            197,
            201,
            205,
            209,
            213,
            217,
            221,
            225,
            229
          ]
        },
        {
          "channelWidth": "Wide80",
          "channels": [
            0,
            1,
            5,
            9,
            13,
            17,
            21,
            25,
            29,
            33,
            37,
            41,
            45,
            49,
            53,
            57,
            61,
            65,
            69,
            73,
            77,
            81,
            85,
            89,
            93,
            97,
            101,
            105,
            109,
            113,
            117,
            121,
            125,
            129,
            133,
            137,
            141,
            145,
            149,
            153,
            157,
            161,
            165,
            169,
            173,
            177,
            181,
            185,
            189,
            193,
            197,
            201,
            205,
            209,
            213,
            217,
            221
          ]
        },
        {
          "channelWidth": "Wide160c",
          "channels": [
            0,
            1,
            5,
            9,
            13,
            17,
            21,
            25,
            29,
            33,
            37,
            41,
            45,
            49,
            53,
            57,
            61,
            65,
            69,
            73,
            77,
            81,
            85,
            89,
            93,
            97,
            101,
            105,
            109,
            113,
            117,
            121,
            125,
            129,
            133,
            137,
            141,
            145,
            149,
            153,
            157,
            161,
            165,
            169,
            173,
            177,
            181,
            185,
            189,
            193,
            197,
            201,
            205,
            209,
            213,
            217,
            221
          ]
        }
      ],
      "supportedSecurityTypes": ["Enhanced-Open-Only", "WPA3-Personal"],
      "maxRADIUSSharedKeyLength": 64,
      "settings": {
        "isEnabled": true,
        "mode": "802.11axbe",
        "ssid": "_VelopSetup60E",
        "broadcastSSID": true,
        "channelWidth": "Auto",
        "channel": 0,
        "security": "WPA3-Personal",
        "wpaPersonalSettings": {"passphrase": "05a63mipt3"}
      }
    }
  },
  "deviceList": [
    {
      "connections": [
        {
          "macAddress": "80:69:1A:13:16:0E",
          "ipAddress": "10.205.1.1",
          "ipv6Address": null,
          "parentDeviceID": null,
          "isGuest": null
        }
      ],
      "properties": [],
      "unit": {
        "serialNumber": "59A10M23D00060",
        "firmwareVersion": "1.0.11.215918",
        "firmwareDate": "2024-06-14T03:50:41Z",
        "operatingSystem": null
      },
      "deviceID": "ef07238c-4870-46fb-a524-80691a13160e",
      "maxAllowedProperties": 16,
      "model": {
        "deviceType": "Infrastructure",
        "manufacturer": "Linksys",
        "modelNumber": "MBE70",
        "hardwareVersion": "1",
        "modelDescription": null
      },
      "isAuthority": true,
      "lastChangeRevision": 32,
      "friendlyName": "Linksys00060",
      "knownInterfaces": [
        {
          "macAddress": "80:69:1A:13:16:0E",
          "interfaceType": "Unknown",
          "band": null
        }
      ],
      "nodeType": "Master",
      "connectedDevices": [
        {
          "connections": [
            {
              "macAddress": "3C:22:FB:E4:4F:18",
              "ipAddress": "10.205.1.30",
              "ipv6Address": null,
              "parentDeviceID": "ef07238c-4870-46fb-a524-80691a13160e",
              "isGuest": null
            }
          ],
          "properties": [],
          "unit": {
            "serialNumber": "59A10M23D00060",
            "firmwareVersion": "1.0.11.215918",
            "firmwareDate": "2024-06-14T03:50:41Z",
            "operatingSystem": "macOS"
          },
          "deviceID": "28461643-58d4-4a5b-bada-3dc652d93c3e",
          "maxAllowedProperties": 16,
          "model": {
            "deviceType": "Infrastructure",
            "manufacturer": "Linksys",
            "modelNumber": "MBE70",
            "hardwareVersion": "1",
            "modelDescription": null
          },
          "isAuthority": false,
          "lastChangeRevision": 44,
          "friendlyName": "ASTWP-29134",
          "knownInterfaces": [
            {
              "macAddress": "3C:22:FB:E4:4F:18",
              "interfaceType": "Wireless",
              "band": "5GHz"
            }
          ],
          "connectedDevices": [],
          "connectedWifiType": "main"
        },
        {
          "connections": [
            {
              "macAddress": "02:27:5B:F0:B5:EF",
              "ipAddress": "10.205.1.223",
              "ipv6Address": null,
              "parentDeviceID": "ef07238c-4870-46fb-a524-80691a13160e",
              "isGuest": null
            }
          ],
          "properties": [],
          "unit": {
            "serialNumber": null,
            "firmwareVersion": null,
            "firmwareDate": null,
            "operatingSystem": "Android"
          },
          "deviceID": "5c0bd66f-3784-4e61-beca-64a034d2e9fa",
          "maxAllowedProperties": 16,
          "model": {
            "deviceType": "Mobile",
            "manufacturer": null,
            "modelNumber": null,
            "hardwareVersion": null,
            "modelDescription": null
          },
          "isAuthority": false,
          "lastChangeRevision": 58,
          "friendlyName": "Pixel-8",
          "knownInterfaces": [
            {
              "macAddress": "02:27:5B:F0:B5:EF",
              "interfaceType": "Wireless",
              "band": "5GHz"
            }
          ],
          "connectedDevices": [],
          "connectedWifiType": "main"
        }
      ],
      "connectedWifiType": "main",
      "signalDecibels": -1
    },
    {
      "connections": [
        {
          "macAddress": "3C:22:FB:E4:4F:18",
          "ipAddress": "10.205.1.30",
          "ipv6Address": null,
          "parentDeviceID": "ef07238c-4870-46fb-a524-80691a13160e",
          "isGuest": null
        }
      ],
      "properties": [],
      "unit": {
        "serialNumber": "59A10M23D00060",
        "firmwareVersion": "1.0.11.215918",
        "firmwareDate": "2024-06-14T03:50:41Z",
        "operatingSystem": "macOS"
      },
      "deviceID": "28461643-58d4-4a5b-bada-3dc652d93c3e",
      "maxAllowedProperties": 16,
      "model": {
        "deviceType": "Infrastructure",
        "manufacturer": "Linksys",
        "modelNumber": "MBE70",
        "hardwareVersion": "1",
        "modelDescription": null
      },
      "isAuthority": false,
      "lastChangeRevision": 44,
      "friendlyName": "ASTWP-29134",
      "knownInterfaces": [
        {
          "macAddress": "3C:22:FB:E4:4F:18",
          "interfaceType": "Wireless",
          "band": "5GHz"
        }
      ],
      "connectedDevices": [],
      "connectedWifiType": "main",
      "signalDecibels": -35,
      "upstream": {
        "connections": [
          {
            "macAddress": "80:69:1A:13:16:0E",
            "ipAddress": "10.205.1.1",
            "ipv6Address": null,
            "parentDeviceID": null,
            "isGuest": null
          }
        ],
        "properties": [],
        "unit": {
          "serialNumber": "59A10M23D00060",
          "firmwareVersion": "1.0.11.215918",
          "firmwareDate": "2024-06-14T03:50:41Z",
          "operatingSystem": null
        },
        "deviceID": "ef07238c-4870-46fb-a524-80691a13160e",
        "maxAllowedProperties": 16,
        "model": {
          "deviceType": "Infrastructure",
          "manufacturer": "Linksys",
          "modelNumber": "MBE70",
          "hardwareVersion": "1",
          "modelDescription": null
        },
        "isAuthority": true,
        "lastChangeRevision": 32,
        "friendlyName": "Linksys00060",
        "knownInterfaces": [
          {
            "macAddress": "80:69:1A:13:16:0E",
            "interfaceType": "Unknown",
            "band": null
          }
        ],
        "nodeType": "Master",
        "connectedDevices": [
          {
            "connections": [
              {
                "macAddress": "3C:22:FB:E4:4F:18",
                "ipAddress": "10.205.1.30",
                "ipv6Address": null,
                "parentDeviceID": "ef07238c-4870-46fb-a524-80691a13160e",
                "isGuest": null
              }
            ],
            "properties": [],
            "unit": {
              "serialNumber": "59A10M23D00060",
              "firmwareVersion": "1.0.11.215918",
              "firmwareDate": "2024-06-14T03:50:41Z",
              "operatingSystem": "macOS"
            },
            "deviceID": "28461643-58d4-4a5b-bada-3dc652d93c3e",
            "maxAllowedProperties": 16,
            "model": {
              "deviceType": "Infrastructure",
              "manufacturer": "Linksys",
              "modelNumber": "MBE70",
              "hardwareVersion": "1",
              "modelDescription": null
            },
            "isAuthority": false,
            "lastChangeRevision": 44,
            "friendlyName": "ASTWP-29134",
            "knownInterfaces": [
              {
                "macAddress": "3C:22:FB:E4:4F:18",
                "interfaceType": "Wireless",
                "band": "5GHz"
              }
            ],
            "connectedDevices": [],
            "connectedWifiType": "main"
          },
          {
            "connections": [
              {
                "macAddress": "02:27:5B:F0:B5:EF",
                "ipAddress": "10.205.1.223",
                "ipv6Address": null,
                "parentDeviceID": "ef07238c-4870-46fb-a524-80691a13160e",
                "isGuest": null
              }
            ],
            "properties": [],
            "unit": {
              "serialNumber": null,
              "firmwareVersion": null,
              "firmwareDate": null,
              "operatingSystem": "Android"
            },
            "deviceID": "5c0bd66f-3784-4e61-beca-64a034d2e9fa",
            "maxAllowedProperties": 16,
            "model": {
              "deviceType": "Mobile",
              "manufacturer": null,
              "modelNumber": null,
              "hardwareVersion": null,
              "modelDescription": null
            },
            "isAuthority": false,
            "lastChangeRevision": 58,
            "friendlyName": "Pixel-8",
            "knownInterfaces": [
              {
                "macAddress": "02:27:5B:F0:B5:EF",
                "interfaceType": "Wireless",
                "band": "5GHz"
              }
            ],
            "connectedDevices": [],
            "connectedWifiType": "main"
          }
        ],
        "connectedWifiType": "main",
        "signalDecibels": -1
      }
    },
    {
      "connections": [
        {
          "macAddress": "02:27:5B:F0:B5:EF",
          "ipAddress": "10.205.1.223",
          "ipv6Address": null,
          "parentDeviceID": "ef07238c-4870-46fb-a524-80691a13160e",
          "isGuest": null
        }
      ],
      "properties": [],
      "unit": {
        "serialNumber": null,
        "firmwareVersion": null,
        "firmwareDate": null,
        "operatingSystem": "Android"
      },
      "deviceID": "5c0bd66f-3784-4e61-beca-64a034d2e9fa",
      "maxAllowedProperties": 16,
      "model": {
        "deviceType": "Mobile",
        "manufacturer": null,
        "modelNumber": null,
        "hardwareVersion": null,
        "modelDescription": null
      },
      "isAuthority": false,
      "lastChangeRevision": 58,
      "friendlyName": "Pixel-8",
      "knownInterfaces": [
        {
          "macAddress": "02:27:5B:F0:B5:EF",
          "interfaceType": "Wireless",
          "band": "5GHz"
        }
      ],
      "connectedDevices": [],
      "connectedWifiType": "main",
      "signalDecibels": -43,
      "upstream": {
        "connections": [
          {
            "macAddress": "80:69:1A:13:16:0E",
            "ipAddress": "10.205.1.1",
            "ipv6Address": null,
            "parentDeviceID": null,
            "isGuest": null
          }
        ],
        "properties": [],
        "unit": {
          "serialNumber": "59A10M23D00060",
          "firmwareVersion": "1.0.11.215918",
          "firmwareDate": "2024-06-14T03:50:41Z",
          "operatingSystem": null
        },
        "deviceID": "ef07238c-4870-46fb-a524-80691a13160e",
        "maxAllowedProperties": 16,
        "model": {
          "deviceType": "Infrastructure",
          "manufacturer": "Linksys",
          "modelNumber": "MBE70",
          "hardwareVersion": "1",
          "modelDescription": null
        },
        "isAuthority": true,
        "lastChangeRevision": 32,
        "friendlyName": "Linksys00060",
        "knownInterfaces": [
          {
            "macAddress": "80:69:1A:13:16:0E",
            "interfaceType": "Unknown",
            "band": null
          }
        ],
        "nodeType": "Master",
        "connectedDevices": [
          {
            "connections": [
              {
                "macAddress": "3C:22:FB:E4:4F:18",
                "ipAddress": "10.205.1.30",
                "ipv6Address": null,
                "parentDeviceID": "ef07238c-4870-46fb-a524-80691a13160e",
                "isGuest": null
              }
            ],
            "properties": [],
            "unit": {
              "serialNumber": "59A10M23D00060",
              "firmwareVersion": "1.0.11.215918",
              "firmwareDate": "2024-06-14T03:50:41Z",
              "operatingSystem": "macOS"
            },
            "deviceID": "28461643-58d4-4a5b-bada-3dc652d93c3e",
            "maxAllowedProperties": 16,
            "model": {
              "deviceType": "Infrastructure",
              "manufacturer": "Linksys",
              "modelNumber": "MBE70",
              "hardwareVersion": "1",
              "modelDescription": null
            },
            "isAuthority": false,
            "lastChangeRevision": 44,
            "friendlyName": "ASTWP-29134",
            "knownInterfaces": [
              {
                "macAddress": "3C:22:FB:E4:4F:18",
                "interfaceType": "Wireless",
                "band": "5GHz"
              }
            ],
            "connectedDevices": [],
            "connectedWifiType": "main"
          },
          {
            "connections": [
              {
                "macAddress": "02:27:5B:F0:B5:EF",
                "ipAddress": "10.205.1.223",
                "ipv6Address": null,
                "parentDeviceID": "ef07238c-4870-46fb-a524-80691a13160e",
                "isGuest": null
              }
            ],
            "properties": [],
            "unit": {
              "serialNumber": null,
              "firmwareVersion": null,
              "firmwareDate": null,
              "operatingSystem": "Android"
            },
            "deviceID": "5c0bd66f-3784-4e61-beca-64a034d2e9fa",
            "maxAllowedProperties": 16,
            "model": {
              "deviceType": "Mobile",
              "manufacturer": null,
              "modelNumber": null,
              "hardwareVersion": null,
              "modelDescription": null
            },
            "isAuthority": false,
            "lastChangeRevision": 58,
            "friendlyName": "Pixel-8",
            "knownInterfaces": [
              {
                "macAddress": "02:27:5B:F0:B5:EF",
                "interfaceType": "Wireless",
                "band": "5GHz"
              }
            ],
            "connectedDevices": [],
            "connectedWifiType": "main"
          }
        ],
        "connectedWifiType": "main",
        "signalDecibels": -1
      }
    }
  ],
  "wanStatus": {
    "macAddress": "80:69:1A:13:16:0E",
    "detectedWANType": "DHCP",
    "wanStatus": "Connected",
    "wanIPv6Status": "Connecting",
    "wanConnection": {
      "wanType": "DHCP",
      "ipAddress": "192.168.1.98",
      "networkPrefixLength": 24,
      "gateway": "192.168.1.1",
      "mtu": 0,
      "dhcpLeaseMinutes": 120,
      "dnsServer1": "192.168.1.1"
    },
    "supportedWANTypes": ["DHCP", "Static", "PPPoE", "PPTP", "L2TP", "Bridge"],
    "supportedIPv6WANTypes": ["Automatic", "PPPoE", "Pass-through"],
    "supportedWANCombinations": [
      {"wanType": "DHCP", "wanIPv6Type": "Automatic"},
      {"wanType": "Static", "wanIPv6Type": "Automatic"},
      {"wanType": "PPPoE", "wanIPv6Type": "Automatic"},
      {"wanType": "L2TP", "wanIPv6Type": "Automatic"},
      {"wanType": "PPTP", "wanIPv6Type": "Automatic"},
      {"wanType": "Bridge", "wanIPv6Type": "Automatic"},
      {"wanType": "DHCP", "wanIPv6Type": "Pass-through"},
      {"wanType": "PPPoE", "wanIPv6Type": "PPPoE"}
    ]
  },
  "backhaulInfoData": [],
  "lastUpdateTime": 1719382126981
};
