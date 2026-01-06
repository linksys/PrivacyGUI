import 'package:privacy_gui/core/jnap/models/firmware_update_status_nodes.dart';
import 'package:privacy_gui/core/data/providers/device_manager_state.dart';

// Objects of LinksysDevice
const _firmwareUpdateNodeMaster = '''
{
  "connections": [
    {
      "macAddress": "80:69:1A:BB:47:08",
      "ipAddress": "10.203.1.1",
      "ipv6Address": null,
      "parentDeviceID": null,
      "isGuest": null
    }
  ],
  "properties": [],
  "unit": {
    "serialNumber": "65G10M27E03056",
    "firmwareVersion": "1.0.3.216308",
    "firmwareDate": "2024-11-25T06:10:04Z",
    "operatingSystem": null
  },
  "deviceID": "5eb6538b-c5f6-40d3-bda9-80691abb4708",
  "maxAllowedProperties": 16,
  "model": {
    "deviceType": "Infrastructure",
    "manufacturer": "Linksys",
    "modelNumber": "LN16",
    "hardwareVersion": "1",
    "modelDescription": null
  },
  "isAuthority": true,
  "lastChangeRevision": 954,
  "friendlyName": "Linksys03056",
  "knownInterfaces": [
    {
      "macAddress": "80:69:1A:BB:47:08",
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
          "ipAddress": "10.203.1.39",
          "ipv6Address": null,
          "parentDeviceID": "5eb6538b-c5f6-40d3-bda9-80691abb4708",
          "isGuest": null
        }
      ],
      "properties": [],
      "unit": {
        "serialNumber": "65G10M27E03056",
        "firmwareVersion": "1.0.3.216308",
        "firmwareDate": "2024-11-25T06:10:04Z",
        "operatingSystem": "macOS"
      },
      "deviceID": "9d526a53-6635-417f-866d-4f381eb60565",
      "maxAllowedProperties": 16,
      "model": {
        "deviceType": "Infrastructure",
        "manufacturer": "Linksys",
        "modelNumber": "LN16",
        "hardwareVersion": "1",
        "modelDescription": null
      },
      "isAuthority": false,
      "lastChangeRevision": 960,
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
      "signalDecibels": -40,
      "connectionType": "wired",
      "speedMbps": "--"
    }
  ],
  "connectedWifiType": "main",
  "connectionType": "wired",
  "speedMbps": "--"
}
''';

const _firmwareUpdateNodeSlave = '''
{
  "connections": [
    {
      "macAddress": "80:69:1A:BB:46:94",
      "ipAddress": "10.203.1.166",
      "ipv6Address": "fe80:0000:0000:0000:8269:1aff:febb:4694",
      "parentDeviceID": null,
      "isGuest": null
    }
  ],
  "properties": [],
  "unit": {
    "serialNumber": "65G10M27E03027",
    "firmwareVersion": "1.0.3.216252",
    "firmwareDate": "2024-10-14T04:56:56Z",
    "operatingSystem": null
  },
  "deviceID": "0217b8a4-1082-4532-8345-80691abb4694",
  "maxAllowedProperties": 16,
  "model": {
    "deviceType": "Infrastructure",
    "manufacturer": "Linksys",
    "modelNumber": "LN16",
    "hardwareVersion": "1",
    "modelDescription": null
  },
  "isAuthority": false,
  "lastChangeRevision": 1109,
  "friendlyName": "Linksys03027",
  "knownInterfaces": [
    {
      "macAddress": "86:69:1A:BB:46:96",
      "interfaceType": "Wireless",
      "band": "5GHz"
    },
    {
      "macAddress": "80:69:1A:BB:46:94",
      "interfaceType": "Unknown",
      "band": null
    }
  ],
  "nodeType": "Slave",
  "connectedDevices": [],
  "connectedWifiType": "main",
  "signalDecibels": -43,
  "upstream": {
    "connections": [
      {
        "macAddress": "80:69:1A:BB:47:08",
        "ipAddress": "10.203.1.1",
        "ipv6Address": null,
        "parentDeviceID": null,
        "isGuest": null
      }
    ],
    "properties": [],
    "unit": {
      "serialNumber": "65G10M27E03056",
      "firmwareVersion": "1.0.3.216308",
      "firmwareDate": "2024-11-25T06:10:04Z",
      "operatingSystem": null
    },
    "deviceID": "5eb6538b-c5f6-40d3-bda9-80691abb4708",
    "maxAllowedProperties": 16,
    "model": {
      "deviceType": "Infrastructure",
      "manufacturer": "Linksys",
      "modelNumber": "LN16",
      "hardwareVersion": "1",
      "modelDescription": null
    },
    "isAuthority": true,
    "lastChangeRevision": 954,
    "friendlyName": "Linksys03056",
    "knownInterfaces": [
      {
        "macAddress": "80:69:1A:BB:47:08",
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
            "ipAddress": "10.203.1.39",
            "ipv6Address": null,
            "parentDeviceID": "5eb6538b-c5f6-40d3-bda9-80691abb4708",
            "isGuest": null
          }
        ],
        "properties": [],
        "unit": {
          "serialNumber": "65G10M27E03056",
          "firmwareVersion": "1.0.3.216308",
          "firmwareDate": "2024-12-02T03:19:32Z",
          "operatingSystem": "macOS"
        },
        "deviceID": "9d526a53-6635-417f-866d-4f381eb60565",
        "maxAllowedProperties": 16,
        "model": {
          "deviceType": "Infrastructure",
          "manufacturer": "Linksys",
          "modelNumber": "LN16",
          "hardwareVersion": "1",
          "modelDescription": null
        },
        "isAuthority": false,
        "lastChangeRevision": 960,
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
        "signalDecibels": -40,
        "connectionType": "wired",
        "speedMbps": "--"
      }
    ],
    "connectedWifiType": "main",
    "connectionType": "wired",
    "speedMbps": "--"
  },
  "connectionType": "Wireless",
  "wirelessConnectionInfo": {
    "radioID": "5GL",
    "channel": 40,
    "apRSSI": -61,
    "stationRSSI": -43,
    "apBSSID": "80:69:1A:BB:47:0A",
    "stationBSSID": "86:69:1A:BB:46:96",
    "txRate": 1786101,
    "rxRate": 1163916,
    "isMultiLinkOperation": false
  },
  "speedMbps": "137.938"
}
''';

const _firmwareUpdateStatusMaster = '''
{
  "lastSuccessfulCheckTime": "2024-12-27T03:49:53Z",
  "availableUpdate": {
    "firmwareVersion": "1.0.4.216394",
    "firmwareDate": "2024-11-26T01:06:25Z",
    "description": ""
  },
  "pendingOperation": null,
  "lastOperationFailure": null,
  "deviceUUID": "5eb6538b-c5f6-40d3-bda9-80691abb4708"
}
''';

const _firmwareUpdateStatusMasterNoAvailable = '''
{
  "lastSuccessfulCheckTime": "2024-12-27T03:49:53Z",
  "availableUpdate": null,
  "pendingOperation": null,
  "lastOperationFailure": null,
  "deviceUUID": "5eb6538b-c5f6-40d3-bda9-80691abb4708"
}
''';

const _firmwareUpdateStatusSlaveNoAvailable = '''
{
  "lastSuccessfulCheckTime": "2024-12-27T03:49:53Z",
  "availableUpdate": null,
  "pendingOperation": null,
  "lastOperationFailure": null,
  "deviceUUID": "0217b8a4-1082-4532-8345-80691abb4694"
}
''';

const _firmwareUpdateStatusSlaveHasAvailable = '''
{
  "lastSuccessfulCheckTime": "2024-07-16T09:01:55Z",
  "availableUpdate": {
    "firmwareVersion": "1.0.4.216394",
    "firmwareDate": "2024-11-26T01:06:25Z",
    "description": ""
  },
  "pendingOperation": null,
  "lastOperationFailure": null,
  "deviceUUID": "0217b8a4-1082-4532-8345-80691abb4694"
}
''';

const _firmwareUpdateStatusSlaveInDownloading = '''
{
  "lastSuccessfulCheckTime": "2024-07-16T09:01:55Z",
  "availableUpdate": {
    "firmwareVersion": "1.0.4.216394",
    "firmwareDate": "2024-11-26T01:06:25Z",
    "description": ""
  },
  "pendingOperation": {
    "operation": "Downloading",
    "progressPercent": 95
  },
  "lastOperationFailure": null,
  "deviceUUID": "0217b8a4-1082-4532-8345-80691abb4694"
}
''';

const _firmwareUpdateStatusMasterInChecking = '''
{
  "lastSuccessfulCheckTime": "2024-07-16T03:43:35Z",
  "availableUpdate": {
    "firmwareVersion": "1.0.4.216394",
    "firmwareDate": "2024-11-26T01:06:25Z",
    "description": ""
  },
  "pendingOperation": {
    "operation": "Checking",
    "progressPercent": 45
  },
  "lastOperationFailure": null,
  "deviceUUID": "5eb6538b-c5f6-40d3-bda9-80691abb4708"
}
''';

const _firmwareUpdateStatusMasterInInstalling = '''
{
  "lastSuccessfulCheckTime": "2024-07-16T03:43:35Z",
  "availableUpdate": {
    "firmwareVersion": "1.0.4.216394",
    "firmwareDate": "2024-11-26T01:06:25Z",
    "description": ""
  },
  "pendingOperation": {
    "operation": "Installing",
    "progressPercent": 70
  },
  "lastOperationFailure": null,
  "deviceUUID": "5eb6538b-c5f6-40d3-bda9-80691abb4708"
}
''';

const _firmwareUpdateStatusMasterInRebooting = '''
{
  "lastSuccessfulCheckTime": "2024-07-16T03:43:35Z",
  "availableUpdate": {
    "firmwareVersion": "1.0.4.216394",
    "firmwareDate": "2024-11-26T01:06:25Z",
    "description": ""
  },
  "pendingOperation": {
    "operation": "Rebooting",
    "progressPercent": 90
  },
  "lastOperationFailure": null,
  "deviceUUID": "5eb6538b-c5f6-40d3-bda9-80691abb4708"
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

final testFirmwareUpdateStatusRecords10 = [
  (
    LinksysDevice.fromJson(_firmwareUpdateNodeMaster),
    NodesFirmwareUpdateStatus.fromJson(_firmwareUpdateStatusMasterNoAvailable),
  ),
  (
    LinksysDevice.fromJson(_firmwareUpdateNodeSlave),
    NodesFirmwareUpdateStatus.fromJson(_firmwareUpdateStatusSlaveNoAvailable),
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
  "isRetryMaxReached": false,
  "isWaitingChildrenAfterUpdating": false
};

const firmwareUpdateHasFirmwarePinnacleTestState = {
  "settings": {
    "updatePolicy": "AutomaticallyCheckAndInstall",
    "autoUpdateWindow": {"startMinute": 0, "durationMinutes": 240}
  },
  "nodesStatus": [
    {
      "lastSuccessfulCheckTime": "2025-11-16T08:16:06Z",
      "availableUpdate": {
        "firmwareVersion": "1.0.6.25110918",
        "firmwareDate": "2025-11-10T02:30:41Z",
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
