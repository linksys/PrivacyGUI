final mockLocalNetworkSettings = {
  "hostName": "Linksys03041",
  "ipAddress": "10.216.1.1",
  "subnetMask": "255.255.255.0",
  "isDHCPEnabled": true,
  "firstIPAddress": "10.216.1.10",
  "lastIPAddress": "10.216.1.254",
  "maxUserAllowed": 245,
  "clientLeaseTime": 1440,
  "dns1": null,
  "dns2": null,
  "dns3": null,
  "wins": null,
};

final mockLocalNetworkSettings2 = {
  "hostName": "Linksys03041",
  "ipAddress": "10.216.1.1",
  "subnetMask": "255.255.255.0",
  "isDHCPEnabled": true,
  "firstIPAddress": "10.216.100.10",
  "lastIPAddress": "10.216.100.254",
  "maxUserAllowed": 245,
  "clientLeaseTime": 1440,
  "dns1": null,
  "dns2": null,
  "dns3": null,
  "wins": null,
};

final mockLocalNetworkStatus = {
  "maxUserLimit": 245,
  "minAllowDHCPLeaseMinutes": 1,
  "maxAllowDHCPLeaseMinutes": 525600,
  "minNetworkPrefixLength": 16,
  "maxNetworkPrefixLength": 30,
  "dhcpReservationList": [
    {
      "macAddress": "A4:83:E7:36:4C:22",
      "ipAddress": "10.11.1.39",
      "description": "ASTWP-028292"
    },
    {
      "macAddress": "A4:83:E7:36:4C:33",
      "ipAddress": "10.11.1.33",
      "description": "Test-iPhone-15-Pro"
    }
  ],
  "errorTextMap": {},
  "hasErrorOnHostNameTab": false,
  "hasErrorOnIPAddressTab": false,
  "hasErrorOnDhcpServerTab": false,
};

final mockLocalNetworkSettingsState = {
  "settings": {
    "original": mockLocalNetworkSettings,
    "current": mockLocalNetworkSettings2,
  },
  "status": mockLocalNetworkStatus,
};

final mockLocalNetworkErrorSettings = {
  "hostName": "",
  "ipAddress": "10.175.1.1",
  "subnetMask": "255.255.25.0",
  "isDHCPEnabled": true,
  "firstIPAddress": "10.175.1.1",
  "lastIPAddress": "10.175.1.254",
  "maxUserAllowed": 245,
  "clientLeaseTime": 1440,
  "dns1": null,
  "dns2": null,
  "dns3": null,
  "wins": null,
};

final mockLocalNetworkErrorStatus = {
  "maxUserLimit": 245,
  "minAllowDHCPLeaseMinutes": 1,
  "maxAllowDHCPLeaseMinutes": 525600,
  "minNetworkPrefixLength": 16,
  "maxNetworkPrefixLength": 30,
  "dhcpReservationList": [],
  "errorTextMap": {
    "hostName": "hostName",
    "ipAddress": "ipAddress",
    "subnetMask": "subnetMask",
    "startIpAddress": "startIpAddress",
    "dns1": "dns1",
    "dns2": "dns2",
    "dns3": "dns3",
    "wins": "wins"
  },
  "hasErrorOnHostNameTab": false,
  "hasErrorOnIPAddressTab": false,
  "hasErrorOnDhcpServerTab": false,
};

final mockLocalNetworkSettingsErrorState = {
  "settings": {
    "original": mockLocalNetworkErrorSettings,
    "current": mockLocalNetworkErrorSettings,
  },
  "status": mockLocalNetworkErrorStatus,
};