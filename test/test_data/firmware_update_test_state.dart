import 'package:privacy_gui/core/jnap/models/firmware_update_status_nodes.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';

// Objects of LinksysDevice
const _firmwareUpdateNodeMaster = '''
{
  "connections": [
    {
      "macAddress": "80:69:1A:13:16:1A",
      "ipAddress": "10.79.1.1",
      "ipv6Address": null,
      "parentDeviceID": null,
      "isGuest": null
    }
  ],
  "properties": [],
  "unit": {
    "serialNumber": "59A10M23D00062",
    "firmwareVersion": "1.0.11.215518",
    "firmwareDate": "2024-03-21T17:56:13Z",
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
  "lastChangeRevision": 50,
  "friendlyName": "Linksys00062",
  "knownInterfaces": [
    {
      "macAddress": "80:69:1A:13:16:1A",
      "interfaceType": "Unknown",
      "band": null
    }
  ],
  "nodeType": "Master",
  "connectedDevices": [
    {
      "connections": [
        {
          "macAddress": "A4:83:E7:36:4C:22",
          "ipAddress": "10.79.1.39",
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
      "deviceID": "f94dc5b4-5d86-4ce0-918c-cba67cf17525",
      "maxAllowedProperties": 16,
      "model": {
        "deviceType": "Computer",
        "manufacturer": "Apple Inc.",
        "modelNumber": "MacBook Pro",
        "hardwareVersion": null,
        "modelDescription": null
      },
      "isAuthority": false,
      "lastChangeRevision": 43,
      "friendlyName": "ASTWP-028292",
      "knownInterfaces": [
        {
          "macAddress": "A4:83:E7:36:4C:22",
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
''';

const _firmwareUpdateNodeSlave1 = '''
{
  "connections": [
    {
      "macAddress": "80:69:1A:13:14:FA",
      "ipAddress": "10.79.1.74",
      "ipv6Address": "fe80:0000:0000:0000:8269:1aff:fe13:14fa",
      "parentDeviceID": null,
      "isGuest": null
    }
  ],
  "properties": [],
  "unit": {
    "serialNumber": "59A10M23D00014",
    "firmwareVersion": "1.0.11.215518",
    "firmwareDate": "2024-03-21T17:56:13Z",
    "operatingSystem": null
  },
  "deviceID": "a55ccc01-1c72-419a-855d-80691a1314fa",
  "maxAllowedProperties": 16,
  "model": {
    "deviceType": "Infrastructure",
    "manufacturer": "Linksys",
    "modelNumber": "MBE70",
    "hardwareVersion": "1",
    "modelDescription": null
  },
  "isAuthority": false,
  "lastChangeRevision": 152,
  "friendlyName": "Linksys00014",
  "knownInterfaces": [
    {
      "macAddress": "80:69:1A:13:14:FD",
      "interfaceType": "Wireless",
      "band": null
    },
    {
      "macAddress": "80:69:1A:13:14:FA",
      "interfaceType": "Unknown",
      "band": null
    }
  ],
  "nodeType": "Slave",
  "connectedDevices": [],
  "connectedWifiType": "main",
  "signalDecibels": -55,
  "upstream": {
    "connections": [
      {
        "macAddress": "80:69:1A:13:16:1A",
        "ipAddress": "10.79.1.1",
        "ipv6Address": null,
        "parentDeviceID": null,
        "isGuest": null
      }
    ],
    "properties": [],
    "unit": {
      "serialNumber": "59A10M23D00062",
      "firmwareVersion": "1.0.11.215518",
      "firmwareDate": "2024-03-21T17:56:13Z",
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
    "lastChangeRevision": 50,
    "friendlyName": "Linksys00062",
    "knownInterfaces": [
      {
        "macAddress": "80:69:1A:13:16:1A",
        "interfaceType": "Unknown",
        "band": null
      }
    ],
    "nodeType": "Master",
    "connectedDevices": [
      {
        "connections": [
          {
            "macAddress": "A4:83:E7:36:4C:22",
            "ipAddress": "10.79.1.39",
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
        "deviceID": "f94dc5b4-5d86-4ce0-918c-cba67cf17525",
        "maxAllowedProperties": 16,
        "model": {
          "deviceType": "Computer",
          "manufacturer": "Apple Inc.",
          "modelNumber": "MacBook Pro",
          "hardwareVersion": null,
          "modelDescription": null
        },
        "isAuthority": false,
        "lastChangeRevision": 43,
        "friendlyName": "ASTWP-028292",
        "knownInterfaces": [
          {
            "macAddress": "A4:83:E7:36:4C:22",
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
''';

const _firmwareUpdateNodeSlave2 = '''
{
  "connections": [
    {
      "macAddress": "80:69:1A:A0:B1:0E",
      "ipAddress": "10.79.1.166",
      "ipv6Address": "fe80:0000:0000:0000:8269:1aff:fea0:b10e",
      "parentDeviceID": null,
      "isGuest": null
    },
    {
      "macAddress": "80:69:1A:A0:B1:0D",
      "ipAddress": "10.79.1.166",
      "ipv6Address": null,
      "parentDeviceID": null,
      "isGuest": null
    }
  ],
  "properties": [],
  "unit": {
    "serialNumber": "60D20M21E00027",
    "firmwareVersion": "2.0.4.215745",
    "firmwareDate": null,
    "operatingSystem": null
  },
  "deviceID": "8ab6e1d2-aa51-41b8-8396-80691aa0b10d",
  "maxAllowedProperties": 16,
  "model": {
    "deviceType": "Infrastructure",
    "manufacturer": "Linksys",
    "modelNumber": "LN12",
    "hardwareVersion": null,
    "modelDescription": null
  },
  "isAuthority": false,
  "lastChangeRevision": 182,
  "friendlyName": "Linksys00027",
  "knownInterfaces": [
    {
      "macAddress": "86:69:1A:A0:B1:10",
      "interfaceType": "Wireless",
      "band": "5GHz"
    },
    {
      "macAddress": "80:69:1A:A0:B1:0E",
      "interfaceType": "Unknown",
      "band": null
    },
    {
      "macAddress": "80:69:1A:A0:B1:0D",
      "interfaceType": "Unknown",
      "band": null
    }
  ],
  "nodeType": "Slave",
  "connectedDevices": [],
  "connectedWifiType": "main",
  "signalDecibels": -23,
  "upstream": {
    "connections": [
      {
        "macAddress": "80:69:1A:13:16:1A",
        "ipAddress": "10.79.1.1",
        "ipv6Address": null,
        "parentDeviceID": null,
        "isGuest": null
      }
    ],
    "properties": [],
    "unit": {
      "serialNumber": "59A10M23D00062",
      "firmwareVersion": "1.0.11.215518",
      "firmwareDate": "2024-03-21T17:56:13Z",
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
    "lastChangeRevision": 50,
    "friendlyName": "Linksys00062",
    "knownInterfaces": [
      {
        "macAddress": "80:69:1A:13:16:1A",
        "interfaceType": "Unknown",
        "band": null
      }
    ],
    "nodeType": "Master",
    "connectedDevices": [
      {
        "connections": [
          {
            "macAddress": "A4:83:E7:36:4C:22",
            "ipAddress": "10.79.1.39",
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
        "deviceID": "f94dc5b4-5d86-4ce0-918c-cba67cf17525",
        "maxAllowedProperties": 16,
        "model": {
          "deviceType": "Computer",
          "manufacturer": "Apple Inc.",
          "modelNumber": "MacBook Pro",
          "hardwareVersion": null,
          "modelDescription": null
        },
        "isAuthority": false,
        "lastChangeRevision": 43,
        "friendlyName": "ASTWP-028292",
        "knownInterfaces": [
          {
            "macAddress": "A4:83:E7:36:4C:22",
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
''';

const _firmwareUpdateStatusMaster = '''
{
  "lastSuccessfulCheckTime": "2024-06-27T08:38:59Z",
  "availableUpdate": {
    "firmwareVersion": "1.0.11.215726",
    "firmwareDate": "2024-05-08T00:44:58Z",
    "description": ""
  },
  "pendingOperation": null,
  "lastOperationFailure": null,
  "deviceUUID": "095aca62-3759-4249-88aa-80691a13161a"
}
''';

const _firmwareUpdateStatusSlave1 = '''
{
  "lastSuccessfulCheckTime": "2024-06-27T08:38:59Z",
  "availableUpdate": {
    "firmwareVersion": "1.0.11.215726",
    "firmwareDate": "2024-05-08T00:44:58Z",
    "description": ""
  },
  "pendingOperation": null,
  "lastOperationFailure": "CheckFailed",
  "deviceUUID": "a55ccc01-1c72-419a-855d-80691a1314fa"
}
''';

const _firmwareUpdateStatusSlave2 = '''
{
  "lastSuccessfulCheckTime": "1970-01-01T00:00:00Z",
  "availableUpdate": null,
  "pendingOperation": null,
  "lastOperationFailure": "CheckFailed",
  "deviceUUID": "8ab6e1d2-aa51-41b8-8396-80691aa0b10d"
}
''';

final testFirmwareUpdateStatusRecords1 = [
  (
    LinksysDevice.fromJson(_firmwareUpdateNodeMaster),
    NodesFirmwareUpdateStatus.fromJson(_firmwareUpdateStatusMaster),
  )
];

final testFirmwareUpdateStatusRecords2 = [
  (
    LinksysDevice.fromJson(_firmwareUpdateNodeMaster),
    NodesFirmwareUpdateStatus.fromJson(_firmwareUpdateStatusMaster),
  ),
  (
    LinksysDevice.fromJson(_firmwareUpdateNodeSlave1),
    NodesFirmwareUpdateStatus.fromJson(_firmwareUpdateStatusSlave1),
  ),
  (
    LinksysDevice.fromJson(_firmwareUpdateNodeSlave2),
    NodesFirmwareUpdateStatus.fromJson(_firmwareUpdateStatusSlave2),
  ),
];

// const testFirmwareUpdateState1 = '''
// {
//   "settings": {
//     "updatePolicy": "Manual",
//     "autoUpdateWindow": {
//       "startMinute": 0,
//       "durationMinutes": 240
//     }
//   },
//   "nodesStatus": [
//     {
//       "lastSuccessfulCheckTime": "2024-06-27T08:38:59Z",
//       "availableUpdate": {
//         "firmwareVersion": "1.0.11.215726",
//         "firmwareDate": "2024-05-08T00:44:58Z",
//         "description": ""
//       },
//       "pendingOperation": null,
//       "lastOperationFailure": null,
//       "deviceUUID": "095aca62-3759-4249-88aa-80691a13161a"
//     }
//   ],
//   "isUpdating": false,
//   "isChecking": false
// }
// ''';

// const testFirmwareUpdateState2 = '''
// {
//   "settings": {
//     "updatePolicy": "Manual",
//     "autoUpdateWindow": {
//       "startMinute": 0,
//       "durationMinutes": 240
//     }
//   },
//   "nodesStatus": [
//     {
//       "lastSuccessfulCheckTime": "2024-06-27T08:38:59Z",
//       "availableUpdate": {
//         "firmwareVersion": "1.0.11.215726",
//         "firmwareDate": "2024-05-08T00:44:58Z",
//         "description": ""
//       },
//       "pendingOperation": null,
//       "lastOperationFailure": null,
//       "deviceUUID": "095aca62-3759-4249-88aa-80691a13161a"
//     }
//   ],
//   "isUpdating": false,
//   "isChecking": false
// }
// ''';

const firmwareUpdateTestData = {
  "settings": {
    "updatePolicy": "AutomaticallyCheckAndInstall",
    "autoUpdateWindow": {"startMinute": 0, "durationMinutes": 240}
  },
  "nodesStatus": [
    {
      "lastSuccessfulCheckTime": "2024-06-14T07:26:11Z",
      "availableUpdate": null,
      "pendingOperation": null,
      "lastOperationFailure": null,
      "deviceUUID": "ef07238c-4870-46fb-a524-80691a13160e"
    }
  ],
  "isUpdating": false,
  "isChecking": false
};

const firmwareUpdateHasFirmwareTestData = {
  "settings": {
    "updatePolicy": "AutomaticallyCheckAndInstall",
    "autoUpdateWindow": {"startMinute": 0, "durationMinutes": 240}
  },
  "nodesStatus": [
    {
      "lastSuccessfulCheckTime": "2024-06-14T07:26:11Z",
      "availableUpdate": {
        "firmwareVersion": "1.23.34567",
        "firmwareDate": "2024-05-14T07:26:11Z",
        "description": ""
      },
      "pendingOperation": null,
      "lastOperationFailure": null,
      "deviceUUID": "ef07238c-4870-46fb-a524-80691a13160e"
    }
  ],
  "isUpdating": false,
  "isChecking": false
};
