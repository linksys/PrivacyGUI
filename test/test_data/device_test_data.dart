const singleDeviceData = '''
{
"deviceID": "0b447477-5693-2b7e-8bbd-3023032eafee",
"lastChangeRevision": 6022,
"model": {
"deviceType": "Infrastructure",
"manufacturer": "Linksys",
"modelNumber": "MBE70",
"hardwareVersion": "1",
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
"value": "Linksys39173"
},
{
"name": "userDeviceName",
"value": "Linksys39173"
}
],
"maxAllowedProperties": 16
}
''';

const slaveCherry7TestData1 = {
  "connections": [
    {
      "macAddress": "80:69:1A:BB:46:CC",
      "ipAddress": "10.138.1.1",
      "ipv6Address": null,
      "parentDeviceID": null,
      "isGuest": null
    }
  ],
  "properties": [],
  "unit": {
    "serialNumber": "65G10M27E03041",
    "firmwareVersion": "1.0.4.216421",
    "firmwareDate": "2024-12-17T04:56:56Z",
    "operatingSystem": null
  },
  "deviceID": "6c73112b-b6d1-4bfd-9a8c-80691abb46cc",
  "maxAllowedProperties": 16,
  "model": {
    "deviceType": "Infrastructure",
    "manufacturer": "Linksys",
    "modelNumber": "LN16",
    "hardwareVersion": "1",
    "modelDescription": null
  },
  "isAuthority": false,
  "lastChangeRevision": 48,
  "friendlyName": "Linksys03041",
  "knownInterfaces": [
    {
      "macAddress": "80:69:1A:BB:46:CC",
      "interfaceType": "Wireless",
      "band": "5GHz"
    }
  ],
  "nodeType": "Slave",
  "connectedDevices": [],
  "connectedWifiType": "main",
  "connectionType": "Wireless",
  "speedMbps": "--",
  "signalDecibels": -31,
  "wirelessConnectionInfo": {
    "radioID": "5GL",
    "channel": 40,
    "apRSSI": -67,
    "stationRSSI": -18,
    "apBSSID": "80:69:1A:BB:46:CE",
    "stationBSSID": "80:69:1A:BB:46:CC",
    "txRate": 2168673,
    "rxRate": 2494972,
    "isMultiLinkOperation": false
  },
};

const slaveCherry7TestData2 = {
  "connections": [
    {
      "macAddress": "80:69:1A:BB:46:94",
      "ipAddress": "10.138.1.166",
      "ipv6Address": "fe80:0000:0000:0000:8269:1aff:febb:4694",
      "parentDeviceID": null,
      "isGuest": null
    }
  ],
  "properties": [],
  "unit": {
    "serialNumber": "65G10M27E03027",
    "firmwareVersion": "1.0.4.216421",
    "firmwareDate": null,
    "operatingSystem": null
  },
  "deviceID": "0217b8a4-1082-4532-8345-80691abb4694",
  "maxAllowedProperties": 16,
  "model": {
    "deviceType": "Infrastructure",
    "manufacturer": "Linksys",
    "modelNumber": "LN16",
    "hardwareVersion": null,
    "modelDescription": null
  },
  "isAuthority": false,
  "lastChangeRevision": 218,
  "friendlyName": "Linksys03027",
  "knownInterfaces": [
    {
      "macAddress": "8A:69:1A:BB:46:95",
      "interfaceType": "Unknown",
      "band": null
    },
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
  "signalDecibels": -68,
  "connectionType": "Wireless",
  "wirelessConnectionInfo": {
    "radioID": "5GL",
    "channel": 40,
    "apRSSI": -67,
    "stationRSSI": -18,
    "apBSSID": "80:69:1A:BB:46:CE",
    "stationBSSID": "86:69:1A:BB:46:96",
    "txRate": 2168673,
    "rxRate": 2494972,
    "isMultiLinkOperation": false
  },
  "speedMbps": "176.239"
};

const slaveCherry7TestData3 = {
  "connections": [
    {
      "macAddress": "80:69:1A:BB:46:94",
      "ipAddress": "10.138.1.166",
      "ipv6Address": "fe80:0000:0000:0000:8269:1aff:febb:4694",
      "parentDeviceID": null,
      "isGuest": null
    }
  ],
  "properties": [],
  "unit": {
    "serialNumber": "65G10M27E03027",
    "firmwareVersion": "1.0.4.216421",
    "firmwareDate": null,
    "operatingSystem": null
  },
  "deviceID": "0217b8a4-1082-4532-8345-80691abb4694",
  "maxAllowedProperties": 16,
  "model": {
    "deviceType": "Infrastructure",
    "manufacturer": "Linksys",
    "modelNumber": "LN16",
    "hardwareVersion": null,
    "modelDescription": null
  },
  "isAuthority": false,
  "lastChangeRevision": 218,
  "friendlyName": "Linksys03099",
  "knownInterfaces": [
    {
      "macAddress": "8A:69:1A:BB:46:95",
      "interfaceType": "Unknown",
      "band": null
    },
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
  "signalDecibels": -71,
  "connectionType": "Wireless",
  "wirelessConnectionInfo": {
    "radioID": "5GL",
    "channel": 40,
    "apRSSI": -67,
    "stationRSSI": -18,
    "apBSSID": "80:69:1A:BB:46:CE",
    "stationBSSID": "86:69:1A:BB:46:96",
    "txRate": 2168673,
    "rxRate": 2494972,
    "isMultiLinkOperation": false
  },
  "speedMbps": "176.239"
};

const slaveCherry7TestData4 = {
  "connections": [
    {
      "macAddress": "80:69:1A:BB:46:94",
      "ipAddress": "10.138.1.166",
      "ipv6Address": "fe80:0000:0000:0000:8269:1aff:febb:4694",
      "parentDeviceID": null,
      "isGuest": null
    }
  ],
  "properties": [],
  "unit": {
    "serialNumber": "65G10M27E03027",
    "firmwareVersion": "1.0.4.216421",
    "firmwareDate": null,
    "operatingSystem": null
  },
  "deviceID": "0217b8a4-1082-4532-8345-80691abb4694",
  "maxAllowedProperties": 16,
  "model": {
    "deviceType": "Infrastructure",
    "manufacturer": "Linksys",
    "modelNumber": "LN16",
    "hardwareVersion": null,
    "modelDescription": null
  },
  "isAuthority": false,
  "lastChangeRevision": 218,
  "friendlyName": "Linksys03076",
  "knownInterfaces": [
    {
      "macAddress": "8A:69:1A:BB:46:95",
      "interfaceType": "Unknown",
      "band": null
    },
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
  "signalDecibels": -84,
  "connectionType": "Wireless",
  "wirelessConnectionInfo": {
    "radioID": "5GL",
    "channel": 40,
    "apRSSI": -67,
    "stationRSSI": -18,
    "apBSSID": "80:69:1A:BB:46:CE",
    "stationBSSID": "86:69:1A:BB:46:96",
    "txRate": 2168673,
    "rxRate": 2494972,
    "isMultiLinkOperation": false
  },
  "speedMbps": "176.239"
};
