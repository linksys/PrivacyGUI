const deviceManagerTestData = {
  "wirelessConnections": {
    "E2:56:F2:73:C2:38": {
      "bssid": "80:69:1A:13:16:1C",
      "isGuest": false,
      "radioID": "RADIO_5GHz",
      "band": "5GHz",
      "signalDecibels": -84
    },
    "A4:83:E7:11:8A:19": {
      "bssid": "80:69:1A:13:16:1C",
      "isGuest": false,
      "radioID": "RADIO_5GHz",
      "band": "5GHz",
      "signalDecibels": -55
    }
  },
  "radioInfos": {
    "RADIO_2.4GHz": {
      "radioID": "RADIO_2.4GHz",
      "physicalRadioID": "ath0",
      "bssid": "80:69:1A:13:16:1B",
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
        "ssid": "_VelopSetup61A",
        "broadcastSSID": true,
        "channelWidth": "Auto",
        "channel": 0,
        "security": "WPA2/WPA3-Mixed-Personal",
        "wpaPersonalSettings": {"passphrase": "nj4qnpwanm"}
      }
    },
    "RADIO_5GHz": {
      "radioID": "RADIO_5GHz",
      "physicalRadioID": "ath10",
      "bssid": "80:69:1A:13:16:1C",
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
        "ssid": "_VelopSetup61A",
        "broadcastSSID": true,
        "channelWidth": "Auto",
        "channel": 0,
        "security": "WPA2/WPA3-Mixed-Personal",
        "wpaPersonalSettings": {"passphrase": "nj4qnpwanm"}
      }
    },
    "RADIO_6GHz": {
      "radioID": "RADIO_6GHz",
      "physicalRadioID": "ath30",
      "bssid": "82:69:1A:13:16:1D",
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
        "ssid": "_VelopSetup61A",
        "broadcastSSID": true,
        "channelWidth": "Auto",
        "channel": 0,
        "security": "WPA3-Personal",
        "wpaPersonalSettings": {"passphrase": "nj4qnpwanm"}
      }
    }
  },
  "guestRadioSettings": {
    "isGuestNetworkACaptivePortal": false,
    "isGuestNetworkEnabled": false,
    "radios": [
      {
        "radioID": "RADIO_5GHz",
        "isEnabled": true,
        "broadcastGuestSSID": true,
        "guestSSID": "_VelopSetup61A-guest",
        "guestWPAPassphrase": "BeMyGuest",
        "canEnableRadio": true
      },
      {
        "radioID": "RADIO_2.4GHz",
        "isEnabled": true,
        "broadcastGuestSSID": true,
        "guestSSID": "_VelopSetup61A-guest",
        "guestWPAPassphrase": "BeMyGuest",
        "canEnableRadio": true
      },
      {
        "radioID": "RADIO_6GHz",
        "isEnabled": true,
        "broadcastGuestSSID": true,
        "guestSSID": "_VelopSetup61A-guest",
        "guestWPAPassphrase": "BeMyGuest",
        "canEnableRadio": true
      }
    ]
  },
  "deviceList": [
    {
      "connections": [
        {
          "macAddress": "80:69:1A:13:16:1A",
          "ipAddress": "10.110.1.1",
          "ipv6Address": null,
          "parentDeviceID": null,
          "isGuest": null
        }
      ],
      "properties": [],
      "unit": {
        "serialNumber": "59A10M23D00062",
        "firmwareVersion": "1.0.12.216221",
        "firmwareDate": "2024-09-30T07:39:28Z",
        "operatingSystem": null
      },
      "deviceID": "095aca62-3759-4249-88aa-80691a13161a",
      "maxAllowedProperties": 16,
      "model": {
        "deviceType": "Infrastructure",
        "manufacturer": "Linksys",
        "modelNumber": "MBE70",
        "hardwareVersion": "1",
        "modelDescription": null
      },
      "isAuthority": true,
      "lastChangeRevision": 298,
      "friendlyName": "Linksys00062",
      "knownInterfaces": [
        {
          "macAddress": "80:69:1A:13:16:1A",
          "interfaceType": "Wired",
          "band": null
        }
      ],
      "nodeType": "Master",
      "connectedDevices": [
        {
          "connections": [
            {
              "macAddress": "E2:56:F2:73:C2:38",
              "ipAddress": "10.110.1.209",
              "ipv6Address": null,
              "parentDeviceID": "095aca62-3759-4249-88aa-80691a13161a",
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
          "deviceID": "1ac7a1f2-5e29-4881-946b-c3d7ec3ecadd",
          "maxAllowedProperties": 16,
          "model": {
            "deviceType": "Mobile",
            "manufacturer": null,
            "modelNumber": null,
            "hardwareVersion": null,
            "modelDescription": null
          },
          "isAuthority": false,
          "lastChangeRevision": 332,
          "friendlyName": "Pixel-4a",
          "knownInterfaces": [
            {
              "macAddress": "E2:56:F2:73:C2:38",
              "interfaceType": "Wireless",
              "band": "5GHz"
            }
          ],
          "connectedDevices": [],
          "connectedWifiType": "main",
          "signalDecibels": -84,
          "connectionType": "wireless",
          "speedMbps": "--"
        },
        {
          "connections": [
            {
              "macAddress": "A4:83:E7:11:8A:19",
              "ipAddress": "10.110.1.144",
              "ipv6Address": null,
              "parentDeviceID": "095aca62-3759-4249-88aa-80691a13161a",
              "isGuest": null
            }
          ],
          "properties": [],
          "unit": {
            "serialNumber": null,
            "firmwareVersion": null,
            "firmwareDate": null,
            "operatingSystem": "macOS"
          },
          "deviceID": "a6d4e519-2eda-48a4-8588-3652394397e8",
          "maxAllowedProperties": 16,
          "model": {
            "deviceType": "Computer",
            "manufacturer": "Apple Inc.",
            "modelNumber": "MacBook Pro",
            "hardwareVersion": null,
            "modelDescription": null
          },
          "isAuthority": false,
          "lastChangeRevision": 315,
          "friendlyName": "ASTWP-028279",
          "knownInterfaces": [
            {
              "macAddress": "A4:83:E7:11:8A:19",
              "interfaceType": "Wireless",
              "band": "5GHz"
            }
          ],
          "connectedDevices": [],
          "connectedWifiType": "main",
          "signalDecibels": -55,
          "connectionType": "wireless",
          "speedMbps": "--"
        }
      ],
      "connectedWifiType": "main",
      "connectionType": "wireless",
      "speedMbps": "--"
    },
    {
      "connections": [],
      "properties": [],
      "unit": {
        "serialNumber": null,
        "firmwareVersion": null,
        "firmwareDate": null,
        "operatingSystem": "Android"
      },
      "deviceID": "efa201a1-c8c3-42d7-93e6-00b8fd2b1d41",
      "maxAllowedProperties": 16,
      "model": {
        "deviceType": "Mobile",
        "manufacturer": null,
        "modelNumber": null,
        "hardwareVersion": null,
        "modelDescription": null
      },
      "isAuthority": false,
      "lastChangeRevision": 284,
      "friendlyName": "Pixel-8",
      "knownInterfaces": [
        {
          "macAddress": "32:10:A6:A5:4E:A8",
          "interfaceType": "Unknown",
          "band": null
        }
      ],
      "connectedDevices": [],
      "connectedWifiType": "main",
      "upstream": {
        "connections": [
          {
            "macAddress": "80:69:1A:13:16:1A",
            "ipAddress": "10.110.1.1",
            "ipv6Address": null,
            "parentDeviceID": null,
            "isGuest": null
          }
        ],
        "properties": [],
        "unit": {
          "serialNumber": "59A10M23D00062",
          "firmwareVersion": "1.0.12.216221",
          "firmwareDate": "2024-09-30T07:39:28Z",
          "operatingSystem": null
        },
        "deviceID": "095aca62-3759-4249-88aa-80691a13161a",
        "maxAllowedProperties": 16,
        "model": {
          "deviceType": "Infrastructure",
          "manufacturer": "Linksys",
          "modelNumber": "MBE70",
          "hardwareVersion": "1",
          "modelDescription": null
        },
        "isAuthority": true,
        "lastChangeRevision": 298,
        "friendlyName": "Linksys00062",
        "knownInterfaces": [
          {
            "macAddress": "80:69:1A:13:16:1A",
            "interfaceType": "Wired",
            "band": null
          }
        ],
        "nodeType": "Master",
        "connectedDevices": [
          {
            "connections": [
              {
                "macAddress": "E2:56:F2:73:C2:38",
                "ipAddress": "10.110.1.209",
                "ipv6Address": null,
                "parentDeviceID": "095aca62-3759-4249-88aa-80691a13161a",
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
            "deviceID": "1ac7a1f2-5e29-4881-946b-c3d7ec3ecadd",
            "maxAllowedProperties": 16,
            "model": {
              "deviceType": "Mobile",
              "manufacturer": null,
              "modelNumber": null,
              "hardwareVersion": null,
              "modelDescription": null
            },
            "isAuthority": false,
            "lastChangeRevision": 332,
            "friendlyName": "Pixel-4a",
            "knownInterfaces": [
              {
                "macAddress": "E2:56:F2:73:C2:38",
                "interfaceType": "Wireless",
                "band": "5GHz"
              }
            ],
            "connectedDevices": [],
            "connectedWifiType": "main",
            "signalDecibels": -84,
            "connectionType": "wireless",
            "speedMbps": "--"
          },
          {
            "connections": [
              {
                "macAddress": "A4:83:E7:11:8A:19",
                "ipAddress": "10.110.1.144",
                "ipv6Address": null,
                "parentDeviceID": "095aca62-3759-4249-88aa-80691a13161a",
                "isGuest": null
              }
            ],
            "properties": [],
            "unit": {
              "serialNumber": null,
              "firmwareVersion": null,
              "firmwareDate": null,
              "operatingSystem": "macOS"
            },
            "deviceID": "a6d4e519-2eda-48a4-8588-3652394397e8",
            "maxAllowedProperties": 16,
            "model": {
              "deviceType": "Computer",
              "manufacturer": "Apple Inc.",
              "modelNumber": "MacBook Pro",
              "hardwareVersion": null,
              "modelDescription": null
            },
            "isAuthority": false,
            "lastChangeRevision": 315,
            "friendlyName": "ASTWP-028279",
            "knownInterfaces": [
              {
                "macAddress": "A4:83:E7:11:8A:19",
                "interfaceType": "Wireless",
                "band": "5GHz"
              }
            ],
            "connectedDevices": [],
            "connectedWifiType": "main",
            "signalDecibels": -55,
            "connectionType": "wireless",
            "speedMbps": "--"
          }
        ],
        "connectedWifiType": "main",
        "connectionType": "wireless",
        "speedMbps": "--"
      },
      "connectionType": "wireless",
      "speedMbps": "--"
    },
    {
      "connections": [
        {
          "macAddress": "E2:56:F2:73:C2:38",
          "ipAddress": "10.110.1.209",
          "ipv6Address": null,
          "parentDeviceID": "095aca62-3759-4249-88aa-80691a13161a",
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
      "deviceID": "1ac7a1f2-5e29-4881-946b-c3d7ec3ecadd",
      "maxAllowedProperties": 16,
      "model": {
        "deviceType": "Mobile",
        "manufacturer": null,
        "modelNumber": null,
        "hardwareVersion": null,
        "modelDescription": null
      },
      "isAuthority": false,
      "lastChangeRevision": 332,
      "friendlyName": "Pixel-4a",
      "knownInterfaces": [
        {
          "macAddress": "E2:56:F2:73:C2:38",
          "interfaceType": "Wireless",
          "band": "5GHz"
        }
      ],
      "connectedDevices": [],
      "connectedWifiType": "main",
      "signalDecibels": -84,
      "upstream": {
        "connections": [
          {
            "macAddress": "80:69:1A:13:16:1A",
            "ipAddress": "10.110.1.1",
            "ipv6Address": null,
            "parentDeviceID": null,
            "isGuest": null
          }
        ],
        "properties": [],
        "unit": {
          "serialNumber": "59A10M23D00062",
          "firmwareVersion": "1.0.12.216221",
          "firmwareDate": "2024-09-30T07:39:28Z",
          "operatingSystem": null
        },
        "deviceID": "095aca62-3759-4249-88aa-80691a13161a",
        "maxAllowedProperties": 16,
        "model": {
          "deviceType": "Infrastructure",
          "manufacturer": "Linksys",
          "modelNumber": "MBE70",
          "hardwareVersion": "1",
          "modelDescription": null
        },
        "isAuthority": true,
        "lastChangeRevision": 298,
        "friendlyName": "Linksys00062",
        "knownInterfaces": [
          {
            "macAddress": "80:69:1A:13:16:1A",
            "interfaceType": "Wired",
            "band": null
          }
        ],
        "nodeType": "Master",
        "connectedDevices": [
          {
            "connections": [
              {
                "macAddress": "E2:56:F2:73:C2:38",
                "ipAddress": "10.110.1.209",
                "ipv6Address": null,
                "parentDeviceID": "095aca62-3759-4249-88aa-80691a13161a",
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
            "deviceID": "1ac7a1f2-5e29-4881-946b-c3d7ec3ecadd",
            "maxAllowedProperties": 16,
            "model": {
              "deviceType": "Mobile",
              "manufacturer": null,
              "modelNumber": null,
              "hardwareVersion": null,
              "modelDescription": null
            },
            "isAuthority": false,
            "lastChangeRevision": 332,
            "friendlyName": "Pixel-4a",
            "knownInterfaces": [
              {
                "macAddress": "E2:56:F2:73:C2:38",
                "interfaceType": "Wireless",
                "band": "5GHz"
              }
            ],
            "connectedDevices": [],
            "connectedWifiType": "main",
            "signalDecibels": -84,
            "connectionType": "wireless",
            "speedMbps": "--"
          },
          {
            "connections": [
              {
                "macAddress": "A4:83:E7:11:8A:19",
                "ipAddress": "10.110.1.144",
                "ipv6Address": null,
                "parentDeviceID": "095aca62-3759-4249-88aa-80691a13161a",
                "isGuest": null
              }
            ],
            "properties": [],
            "unit": {
              "serialNumber": null,
              "firmwareVersion": null,
              "firmwareDate": null,
              "operatingSystem": "macOS"
            },
            "deviceID": "a6d4e519-2eda-48a4-8588-3652394397e8",
            "maxAllowedProperties": 16,
            "model": {
              "deviceType": "Computer",
              "manufacturer": "Apple Inc.",
              "modelNumber": "MacBook Pro",
              "hardwareVersion": null,
              "modelDescription": null
            },
            "isAuthority": false,
            "lastChangeRevision": 315,
            "friendlyName": "ASTWP-028279",
            "knownInterfaces": [
              {
                "macAddress": "A4:83:E7:11:8A:19",
                "interfaceType": "Wireless",
                "band": "5GHz"
              }
            ],
            "connectedDevices": [],
            "connectedWifiType": "main",
            "signalDecibels": -55,
            "connectionType": "wireless",
            "speedMbps": "--"
          }
        ],
        "connectedWifiType": "main",
        "connectionType": "wireless",
        "speedMbps": "--"
      },
      "connectionType": "wireless",
      "speedMbps": "--"
    },
    {
      "connections": [
        {
          "macAddress": "A4:83:E7:11:8A:19",
          "ipAddress": "10.110.1.144",
          "ipv6Address": null,
          "parentDeviceID": "095aca62-3759-4249-88aa-80691a13161a",
          "isGuest": null
        }
      ],
      "properties": [],
      "unit": {
        "serialNumber": null,
        "firmwareVersion": null,
        "firmwareDate": null,
        "operatingSystem": "macOS"
      },
      "deviceID": "a6d4e519-2eda-48a4-8588-3652394397e8",
      "maxAllowedProperties": 16,
      "model": {
        "deviceType": "Computer",
        "manufacturer": "Apple Inc.",
        "modelNumber": "MacBook Pro",
        "hardwareVersion": null,
        "modelDescription": null
      },
      "isAuthority": false,
      "lastChangeRevision": 315,
      "friendlyName": "ASTWP-028279",
      "knownInterfaces": [
        {
          "macAddress": "A4:83:E7:11:8A:19",
          "interfaceType": "Wireless",
          "band": "5GHz"
        }
      ],
      "connectedDevices": [],
      "connectedWifiType": "main",
      "signalDecibels": -55,
      "upstream": {
        "connections": [
          {
            "macAddress": "80:69:1A:13:16:1A",
            "ipAddress": "10.110.1.1",
            "ipv6Address": null,
            "parentDeviceID": null,
            "isGuest": null
          }
        ],
        "properties": [],
        "unit": {
          "serialNumber": "59A10M23D00062",
          "firmwareVersion": "1.0.12.216221",
          "firmwareDate": "2024-09-30T07:39:28Z",
          "operatingSystem": null
        },
        "deviceID": "095aca62-3759-4249-88aa-80691a13161a",
        "maxAllowedProperties": 16,
        "model": {
          "deviceType": "Infrastructure",
          "manufacturer": "Linksys",
          "modelNumber": "MBE70",
          "hardwareVersion": "1",
          "modelDescription": null
        },
        "isAuthority": true,
        "lastChangeRevision": 298,
        "friendlyName": "Linksys00062",
        "knownInterfaces": [
          {
            "macAddress": "80:69:1A:13:16:1A",
            "interfaceType": "Wired",
            "band": null
          }
        ],
        "nodeType": "Master",
        "connectedDevices": [
          {
            "connections": [
              {
                "macAddress": "E2:56:F2:73:C2:38",
                "ipAddress": "10.110.1.209",
                "ipv6Address": null,
                "parentDeviceID": "095aca62-3759-4249-88aa-80691a13161a",
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
            "deviceID": "1ac7a1f2-5e29-4881-946b-c3d7ec3ecadd",
            "maxAllowedProperties": 16,
            "model": {
              "deviceType": "Mobile",
              "manufacturer": null,
              "modelNumber": null,
              "hardwareVersion": null,
              "modelDescription": null
            },
            "isAuthority": false,
            "lastChangeRevision": 332,
            "friendlyName": "Pixel-4a",
            "knownInterfaces": [
              {
                "macAddress": "E2:56:F2:73:C2:38",
                "interfaceType": "Wireless",
                "band": "5GHz"
              }
            ],
            "connectedDevices": [],
            "connectedWifiType": "main",
            "signalDecibels": -84,
            "connectionType": "wireless",
            "speedMbps": "--"
          },
          {
            "connections": [
              {
                "macAddress": "A4:83:E7:11:8A:19",
                "ipAddress": "10.110.1.144",
                "ipv6Address": null,
                "parentDeviceID": "095aca62-3759-4249-88aa-80691a13161a",
                "isGuest": null
              }
            ],
            "properties": [],
            "unit": {
              "serialNumber": null,
              "firmwareVersion": null,
              "firmwareDate": null,
              "operatingSystem": "macOS"
            },
            "deviceID": "a6d4e519-2eda-48a4-8588-3652394397e8",
            "maxAllowedProperties": 16,
            "model": {
              "deviceType": "Computer",
              "manufacturer": "Apple Inc.",
              "modelNumber": "MacBook Pro",
              "hardwareVersion": null,
              "modelDescription": null
            },
            "isAuthority": false,
            "lastChangeRevision": 315,
            "friendlyName": "ASTWP-028279",
            "knownInterfaces": [
              {
                "macAddress": "A4:83:E7:11:8A:19",
                "interfaceType": "Wireless",
                "band": "5GHz"
              }
            ],
            "connectedDevices": [],
            "connectedWifiType": "main",
            "signalDecibels": -55,
            "connectionType": "wireless",
            "speedMbps": "--"
          }
        ],
        "connectedWifiType": "main",
        "connectionType": "wireless",
        "speedMbps": "--"
      },
      "connectionType": "wireless",
      "speedMbps": "--"
    }
  ],
  "wanStatus": {
    "macAddress": "80:69:1A:13:16:1A",
    "detectedWANType": "DHCP",
    "wanStatus": "Connected",
    "wanIPv6Status": "Connecting",
    "wanConnection": {
      "wanType": "DHCP",
      "ipAddress": "192.168.1.84",
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
  "lastUpdateTime": 1728376454469
};
