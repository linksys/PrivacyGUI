import 'package:privacy_gui/core/jnap/models/firmware_update_status_nodes.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';

// Objects of LinksysDevice
const _firmwareUpdateNodeMaster = '''
{
  "connections": [
    {
      "macAddress": "80:69:1A:13:16:1A",
      "ipAddress": "10.11.1.1",
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
  "lastChangeRevision": 178,
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
          "macAddress": "A4:83:E7:36:4C:22",
          "ipAddress": "10.11.1.39",
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
      "deviceID": "620808b2-2a1e-4836-97ae-d2eade9a6e51",
      "maxAllowedProperties": 16,
      "model": {
        "deviceType": "Computer",
        "manufacturer": "Apple Inc.",
        "modelNumber": "MacBook Pro",
        "hardwareVersion": null,
        "modelDescription": null
      },
      "isAuthority": false,
      "lastChangeRevision": 188,
      "friendlyName": "ASTWP-028292",
      "knownInterfaces": [
        {
          "macAddress": "A4:83:E7:36:4C:22",
          "interfaceType": "Wireless",
          "band": "5GHz"
        }
      ],
      "connectedDevices": [],
      "connectedWifiType": "main",
      "signalDecibels": -26,
      "connectionType": "wireless",
      "speedMbps": "--"
    }
  ],
  "connectedWifiType": "main",
  "signalDecibels": -1,
  "connectionType": "wireless",
  "speedMbps": "--"
}
''';

const _firmwareUpdateNodeSlave = '''
{
  "connections": [
    {
      "macAddress": "80:69:1A:13:0B:B3",
      "ipAddress": "10.11.1.62",
      "ipv6Address": "fe80:0000:0000:0000:8269:1aff:fe13:0bb3",
      "parentDeviceID": null,
      "isGuest": null
    },
    {
      "macAddress": "80:69:1A:13:0B:B2",
      "ipAddress": "10.11.1.62",
      "ipv6Address": null,
      "parentDeviceID": null,
      "isGuest": null
    }
  ],
  "properties": [],
  "unit": {
    "serialNumber": "54H10M2BC00113",
    "firmwareVersion": "1.0.10.215969",
    "firmwareDate": null,
    "operatingSystem": null
  },
  "deviceID": "293f7622-3fca-47ff-9c02-80691a130bb2",
  "maxAllowedProperties": 16,
  "model": {
    "deviceType": "Infrastructure",
    "manufacturer": "Linksys",
    "modelNumber": "MX62",
    "hardwareVersion": null,
    "modelDescription": null
  },
  "isAuthority": false,
  "lastChangeRevision": 189,
  "friendlyName": "Linksys00113",
  "knownInterfaces": [
    {
      "macAddress": "80:69:1A:13:0B:B6",
      "interfaceType": "Wireless",
      "band": null
    },
    {
      "macAddress": "80:69:1A:13:0B:B3",
      "interfaceType": "Unknown",
      "band": null
    },
    {
      "macAddress": "80:69:1A:13:0B:B2",
      "interfaceType": "Unknown",
      "band": null
    }
  ],
  "nodeType": "Slave",
  "connectedDevices": [],
  "connectedWifiType": "main",
  "signalDecibels": -50,
  "upstream": {
    "connections": [
      {
        "macAddress": "80:69:1A:13:16:1A",
        "ipAddress": "10.11.1.1",
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
    "lastChangeRevision": 178,
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
            "macAddress": "A4:83:E7:36:4C:22",
            "ipAddress": "10.11.1.39",
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
        "deviceID": "620808b2-2a1e-4836-97ae-d2eade9a6e51",
        "maxAllowedProperties": 16,
        "model": {
          "deviceType": "Computer",
          "manufacturer": "Apple Inc.",
          "modelNumber": "MacBook Pro",
          "hardwareVersion": null,
          "modelDescription": null
        },
        "isAuthority": false,
        "lastChangeRevision": 188,
        "friendlyName": "ASTWP-028292",
        "knownInterfaces": [
          {
            "macAddress": "A4:83:E7:36:4C:22",
            "interfaceType": "Wireless",
            "band": "5GHz"
          }
        ],
        "connectedDevices": [],
        "connectedWifiType": "main",
        "signalDecibels": -26,
        "connectionType": "wireless",
        "speedMbps": "--"
      }
    ],
    "connectedWifiType": "main",
    "signalDecibels": -1,
    "connectionType": "wireless",
    "speedMbps": "--"
  },
  "connectionType": "Wireless",
  "wirelessConnectionInfo": {
    "radioID": "6G",
    "channel": 189,
    "apRSSI": -19,
    "stationRSSI": -50,
    "apBSSID": "82:69:1A:13:16:1D",
    "stationBSSID": "80:69:1A:13:0B:B6"
  },
  "speedMbps": "138.836"
}
''';

const _firmwareUpdateStatusMaster = '''
{
  "lastSuccessfulCheckTime": "2024-07-16T03:43:35Z",
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

const _firmwareUpdateStatusSlaveNoAvailable = '''
{
  "lastSuccessfulCheckTime": "1970-01-01T00:00:00Z",
  "availableUpdate": null,
  "pendingOperation": null,
  "lastOperationFailure": "CheckFailed",
  "deviceUUID": "293f7622-3fca-47ff-9c02-80691a130bb2"
}
''';

const _firmwareUpdateStatusSlaveHasAvailable = '''
{
  "lastSuccessfulCheckTime": "2024-07-16T09:01:55Z",
  "availableUpdate": {
    "firmwareVersion": "1.0.10.215967",
    "firmwareDate": "2024-06-28T06:48:38Z",
    "description": ""
  },
  "pendingOperation": null,
  "lastOperationFailure": null,
  "deviceUUID": "293f7622-3fca-47ff-9c02-80691a130bb2"
}
''';

const _firmwareUpdateStatusSlaveInDownloading = '''
{
  "lastSuccessfulCheckTime": "2024-07-16T09:01:55Z",
  "availableUpdate": {
    "firmwareVersion": "1.0.10.215967",
    "firmwareDate": "2024-06-28T06:48:38Z",
    "description": ""
  },
  "pendingOperation": {
    "operation": "Downloading",
    "progressPercent": 95
  },
  "lastOperationFailure": null,
  "deviceUUID": "293f7622-3fca-47ff-9c02-80691a130bb2"
}
''';

const _firmwareUpdateStatusMasterInChecking = '''
{
  "lastSuccessfulCheckTime": "2024-07-16T03:43:35Z",
  "availableUpdate": {
    "firmwareVersion": "1.0.11.215726",
    "firmwareDate": "2024-05-08T00:44:58Z",
    "description": ""
  },
  "pendingOperation": {
    "operation": "Checking",
    "progressPercent": 45
  },
  "lastOperationFailure": null,
  "deviceUUID": "095aca62-3759-4249-88aa-80691a13161a"
}
''';

const _firmwareUpdateStatusMasterInInstalling = '''
{
  "lastSuccessfulCheckTime": "2024-07-16T03:43:35Z",
  "availableUpdate": {
    "firmwareVersion": "1.0.11.215726",
    "firmwareDate": "2024-05-08T00:44:58Z",
    "description": ""
  },
  "pendingOperation": {
    "operation": "Installing",
    "progressPercent": 70
  },
  "lastOperationFailure": null,
  "deviceUUID": "095aca62-3759-4249-88aa-80691a13161a"
}
''';

const _firmwareUpdateStatusMasterInRebooting = '''
{
  "lastSuccessfulCheckTime": "2024-07-16T03:43:35Z",
  "availableUpdate": {
    "firmwareVersion": "1.0.11.215726",
    "firmwareDate": "2024-05-08T00:44:58Z",
    "description": ""
  },
  "pendingOperation": {
    "operation": "Rebooting",
    "progressPercent": 90
  },
  "lastOperationFailure": null,
  "deviceUUID": "095aca62-3759-4249-88aa-80691a13161a"
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
    LinksysDevice.fromJson(_firmwareUpdateNodeSlave),
    NodesFirmwareUpdateStatus.fromJson(_firmwareUpdateStatusSlaveNoAvailable),
  ),
];

final testFirmwareUpdateStatusRecords3 = [
  (
    LinksysDevice.fromJson(_firmwareUpdateNodeMaster),
    NodesFirmwareUpdateStatus.fromJson(_firmwareUpdateStatusMasterInChecking),
  ),
  (
    LinksysDevice.fromJson(_firmwareUpdateNodeSlave),
    NodesFirmwareUpdateStatus.fromJson(_firmwareUpdateStatusSlaveNoAvailable),
  ),
];

final testFirmwareUpdateStatusRecords4 = [
  (
    LinksysDevice.fromJson(_firmwareUpdateNodeMaster),
    NodesFirmwareUpdateStatus.fromJson(_firmwareUpdateStatusMasterInInstalling),
  ),
  (
    LinksysDevice.fromJson(_firmwareUpdateNodeSlave),
    NodesFirmwareUpdateStatus.fromJson(_firmwareUpdateStatusSlaveNoAvailable),
  ),
];

final testFirmwareUpdateStatusRecords5 = [
  (
    LinksysDevice.fromJson(_firmwareUpdateNodeMaster),
    NodesFirmwareUpdateStatus.fromJson(_firmwareUpdateStatusMasterInRebooting),
  ),
  (
    LinksysDevice.fromJson(_firmwareUpdateNodeSlave),
    NodesFirmwareUpdateStatus.fromJson(_firmwareUpdateStatusSlaveNoAvailable),
  ),
];

final testFirmwareUpdateStatusRecords6 = [
  (
    LinksysDevice.fromJson(_firmwareUpdateNodeMaster),
    NodesFirmwareUpdateStatus.fromJson(_firmwareUpdateStatusMaster),
  ),
  (
    LinksysDevice.fromJson(_firmwareUpdateNodeSlave),
    NodesFirmwareUpdateStatus.fromJson(_firmwareUpdateStatusSlaveHasAvailable),
  ),
];

final testFirmwareUpdateStatusRecords7 = [
  (
    LinksysDevice.fromJson(_firmwareUpdateNodeMaster),
    NodesFirmwareUpdateStatus.fromJson(_firmwareUpdateStatusMasterInChecking),
  ),
  (
    LinksysDevice.fromJson(_firmwareUpdateNodeSlave),
    NodesFirmwareUpdateStatus.fromJson(_firmwareUpdateStatusSlaveInDownloading),
  ),
];

final testFirmwareUpdateStatusRecords8 = [
  (
    LinksysDevice.fromJson(_firmwareUpdateNodeMaster),
    NodesFirmwareUpdateStatus.fromJson(_firmwareUpdateStatusMasterInChecking),
  ),
  (
    LinksysDevice.fromJson(_firmwareUpdateNodeSlave),
    NodesFirmwareUpdateStatus.fromJson(_firmwareUpdateStatusSlaveInDownloading),
  ),
  (
    LinksysDevice.fromJson(_firmwareUpdateNodeSlave),
    NodesFirmwareUpdateStatus.fromJson(_firmwareUpdateStatusSlaveInDownloading),
  ),
];

final testFirmwareUpdateStatusRecords9 = [
  (
    LinksysDevice.fromJson(_firmwareUpdateNodeMaster),
    NodesFirmwareUpdateStatus.fromJson(_firmwareUpdateStatusMasterInChecking),
  ),
  (
    LinksysDevice.fromJson(_firmwareUpdateNodeSlave),
    NodesFirmwareUpdateStatus.fromJson(_firmwareUpdateStatusSlaveInDownloading),
  ),
  (
    LinksysDevice.fromJson(_firmwareUpdateNodeSlave),
    NodesFirmwareUpdateStatus.fromJson(_firmwareUpdateStatusSlaveInDownloading),
  ),
  (
    LinksysDevice.fromJson(_firmwareUpdateNodeSlave),
    NodesFirmwareUpdateStatus.fromJson(_firmwareUpdateStatusSlaveInDownloading),
  ),
];

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

const firmwareUpdateHasFirmwareCherry7TestState = {
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
      "deviceUUID": "6c73112b-b6d1-4bfd-9a8c-80691abb46cc"
    }
  ],
  "isUpdating": false,
  "isRetryMaxReached": false,
  "isWaitingChildrenAfterUpdating": false
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
  "isRetryMaxReached": false,
  "isWaitingChildrenAfterUpdating": false
};
