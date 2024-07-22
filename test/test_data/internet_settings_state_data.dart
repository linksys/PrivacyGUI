const internetSettingsStateData = '''
{
  "ipv4Setting": {
    "ipv4ConnectionType": "DHCP",
    "supportedIPv4ConnectionType": [
      "DHCP",
      "Static",
      "PPPoE",
      "PPTP",
      "L2TP",
      "Bridge"
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
    "mtu": 0
  },
  "ipv6Setting": {
    "ipv6ConnectionType": "Automatic",
    "supportedIPv6ConnectionType": [
      "Automatic",
      "PPPoE",
      "Pass-through"
    ],
    "duid": "00:02:03:09:05:05:80:69:1A:13:16:0E",
    "isIPv6AutomaticEnabled": true
  },
  "macClone": false,
  "macCloneAddress": ""
}
''';

const internetSettingsStateData2 = '''
{
  "ipv4Setting": {
    "ipv4ConnectionType": "PPPoE",
    "supportedIPv4ConnectionType": [
      "DHCP",
      "Static",
      "PPPoE",
      "PPTP",
      "L2TP",
      "Bridge"
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
    "mtu": 0
  },
  "ipv6Setting": {
    "ipv6ConnectionType": "Automatic",
    "supportedIPv6ConnectionType": [
      "Automatic",
      "PPPoE",
      "Pass-through"
    ],
    "duid": "00:02:03:09:05:05:80:69:1A:13:16:0E",
    "isIPv6AutomaticEnabled": true
  },
  "macClone": false,
  "macCloneAddress": ""
}
''';

const internetSettingsStateDHCP = {
  "ipv4Setting": {
    "ipv4ConnectionType": "DHCP",
    "supportedIPv4ConnectionType": [
      "DHCP",
      "Static",
      "PPPoE",
      "PPTP",
      "L2TP",
      "Bridge"
    ],
    "supportedWANCombinations": [
      {"wanType": "DHCP", "wanIPv6Type": "Automatic"},
      {"wanType": "Static", "wanIPv6Type": "Automatic"},
      {"wanType": "PPPoE", "wanIPv6Type": "Automatic"},
      {"wanType": "L2TP", "wanIPv6Type": "Automatic"},
      {"wanType": "PPTP", "wanIPv6Type": "Automatic"},
      {"wanType": "Bridge", "wanIPv6Type": "Automatic"},
      {"wanType": "DHCP", "wanIPv6Type": "Pass-through"},
      {"wanType": "PPPoE", "wanIPv6Type": "PPPoE"}
    ],
    "mtu": 0
  },
  "ipv6Setting": {
    "ipv6ConnectionType": "Automatic",
    "supportedIPv6ConnectionType": ["Automatic", "PPPoE", "Pass-through"],
    "duid": "00:02:03:09:05:05:80:69:1A:A7:14:FF",
    "isIPv6AutomaticEnabled": true
  },
  "macClone": false,
  "macCloneAddress": ""
};

const internetSettingsStateStatic = {
  "ipv4Setting": {
    "ipv4ConnectionType": "Static",
    "supportedIPv4ConnectionType": [
      "DHCP",
      "Static",
      "PPPoE",
      "PPTP",
      "L2TP",
      "Bridge"
    ],
    "supportedWANCombinations": [
      {"wanType": "DHCP", "wanIPv6Type": "Automatic"},
      {"wanType": "Static", "wanIPv6Type": "Automatic"},
      {"wanType": "PPPoE", "wanIPv6Type": "Automatic"},
      {"wanType": "L2TP", "wanIPv6Type": "Automatic"},
      {"wanType": "PPTP", "wanIPv6Type": "Automatic"},
      {"wanType": "Bridge", "wanIPv6Type": "Automatic"},
      {"wanType": "DHCP", "wanIPv6Type": "Pass-through"},
      {"wanType": "PPPoE", "wanIPv6Type": "PPPoE"}
    ],
    "mtu": 0,
    "staticIpAddress": "111.222.111.123",
    "staticGateway": "111.222.111.1",
    "staticDns1": "8.8.8.8",
    "staticDns2": "8.8.4.4",
    "networkPrefixLength": 24
  },
  "ipv6Setting": {
    "ipv6ConnectionType": "Automatic",
    "supportedIPv6ConnectionType": ["Automatic", "PPPoE", "Pass-through"],
    "duid": "00:02:03:09:05:05:80:69:1A:A7:14:FF",
    "isIPv6AutomaticEnabled": true
  },
  "macClone": false,
  "macCloneAddress": ""
};

const internetSettingsStatePppoe = {
  "ipv4Setting": {
    "ipv4ConnectionType": "PPPoE",
    "supportedIPv4ConnectionType": [
      "DHCP",
      "Static",
      "PPPoE",
      "PPTP",
      "L2TP",
      "Bridge"
    ],
    "supportedWANCombinations": [
      {"wanType": "DHCP", "wanIPv6Type": "Automatic"},
      {"wanType": "Static", "wanIPv6Type": "Automatic"},
      {"wanType": "PPPoE", "wanIPv6Type": "Automatic"},
      {"wanType": "L2TP", "wanIPv6Type": "Automatic"},
      {"wanType": "PPTP", "wanIPv6Type": "Automatic"},
      {"wanType": "Bridge", "wanIPv6Type": "Automatic"},
      {"wanType": "DHCP", "wanIPv6Type": "Pass-through"},
      {"wanType": "PPPoE", "wanIPv6Type": "PPPoE"}
    ],
    "mtu": 0,
    "behavior": "KeepAlive",
    "maxIdleMinutes": 15,
    "reconnectAfterSeconds": 30,
    "staticIpAddress": "111.222.111.123",
    "staticGateway": "111.222.111.1",
    "staticDns1": "8.8.8.8",
    "staticDns2": "8.8.4.4",
    "networkPrefixLength": 24,
    "username": "user",
    "password": "pass",
    "serviceName": "",
    "wanTaggingSettingsEnable": false,
    "vlanId": 0
  },
  "ipv6Setting": {
    "ipv6ConnectionType": "Automatic",
    "supportedIPv6ConnectionType": ["Automatic", "PPPoE", "Pass-through"],
    "duid": "00:02:03:09:05:05:80:69:1A:A7:14:FF",
    "isIPv6AutomaticEnabled": true
  },
  "macClone": false,
  "macCloneAddress": ""
};

const internetSettingsStatePptp = {
  "ipv4Setting": {
    "ipv4ConnectionType": "PPTP",
    "supportedIPv4ConnectionType": [
      "DHCP",
      "Static",
      "PPPoE",
      "PPTP",
      "L2TP",
      "Bridge"
    ],
    "supportedWANCombinations": [
      {"wanType": "DHCP", "wanIPv6Type": "Automatic"},
      {"wanType": "Static", "wanIPv6Type": "Automatic"},
      {"wanType": "PPPoE", "wanIPv6Type": "Automatic"},
      {"wanType": "L2TP", "wanIPv6Type": "Automatic"},
      {"wanType": "PPTP", "wanIPv6Type": "Automatic"},
      {"wanType": "Bridge", "wanIPv6Type": "Automatic"},
      {"wanType": "DHCP", "wanIPv6Type": "Pass-through"},
      {"wanType": "PPPoE", "wanIPv6Type": "PPPoE"}
    ],
    "mtu": 0,
    "behavior": "KeepAlive",
    "maxIdleMinutes": 15,
    "reconnectAfterSeconds": 30,
    "staticIpAddress": "111.222.111.123",
    "staticGateway": "111.222.111.1",
    "staticDns1": "8.8.8.8",
    "staticDns2": "8.8.4.4",
    "networkPrefixLength": 24,
    "username": "user",
    "password": "pass",
    "serviceName": "",
    "serverIp": "111.222.111.1",
    "useStaticSettings": false,
    "wanTaggingSettingsEnable": false,
    "vlanId": 0
  },
  "ipv6Setting": {
    "ipv6ConnectionType": "Automatic",
    "supportedIPv6ConnectionType": ["Automatic", "PPPoE", "Pass-through"],
    "duid": "00:02:03:09:05:05:80:69:1A:A7:14:FF",
    "isIPv6AutomaticEnabled": true
  },
  "macClone": false,
  "macCloneAddress": ""
};

const internetSettingsStatePptpWithStaticIp = {
  "ipv4Setting": {
    "ipv4ConnectionType": "PPTP",
    "supportedIPv4ConnectionType": [
      "DHCP",
      "Static",
      "PPPoE",
      "PPTP",
      "L2TP",
      "Bridge"
    ],
    "supportedWANCombinations": [
      {"wanType": "DHCP", "wanIPv6Type": "Automatic"},
      {"wanType": "Static", "wanIPv6Type": "Automatic"},
      {"wanType": "PPPoE", "wanIPv6Type": "Automatic"},
      {"wanType": "L2TP", "wanIPv6Type": "Automatic"},
      {"wanType": "PPTP", "wanIPv6Type": "Automatic"},
      {"wanType": "Bridge", "wanIPv6Type": "Automatic"},
      {"wanType": "DHCP", "wanIPv6Type": "Pass-through"},
      {"wanType": "PPPoE", "wanIPv6Type": "PPPoE"}
    ],
    "mtu": 0,
    "behavior": "KeepAlive",
    "maxIdleMinutes": 15,
    "reconnectAfterSeconds": 30,
    "staticIpAddress": "111.111.111.123",
    "staticGateway": "111.111.111.1",
    "staticDns1": "8.8.8.8",
    "staticDns2": "8.8.4.4",
    "networkPrefixLength": 24,
    "username": "user",
    "password": "pass",
    "serviceName": "",
    "serverIp": "111.222.111.1",
    "useStaticSettings": true,
    "wanTaggingSettingsEnable": false,
    "vlanId": 0
  },
  "ipv6Setting": {
    "ipv6ConnectionType": "Automatic",
    "supportedIPv6ConnectionType": ["Automatic", "PPPoE", "Pass-through"],
    "duid": "00:02:03:09:05:05:80:69:1A:A7:14:FF",
    "isIPv6AutomaticEnabled": true
  },
  "macClone": false,
  "macCloneAddress": ""
};

const internetSettingsStateL2tp = {
  "ipv4Setting": {
    "ipv4ConnectionType": "L2TP",
    "supportedIPv4ConnectionType": [
      "DHCP",
      "Static",
      "PPPoE",
      "PPTP",
      "L2TP",
      "Bridge"
    ],
    "supportedWANCombinations": [
      {"wanType": "DHCP", "wanIPv6Type": "Automatic"},
      {"wanType": "Static", "wanIPv6Type": "Automatic"},
      {"wanType": "PPPoE", "wanIPv6Type": "Automatic"},
      {"wanType": "L2TP", "wanIPv6Type": "Automatic"},
      {"wanType": "PPTP", "wanIPv6Type": "Automatic"},
      {"wanType": "Bridge", "wanIPv6Type": "Automatic"},
      {"wanType": "DHCP", "wanIPv6Type": "Pass-through"},
      {"wanType": "PPPoE", "wanIPv6Type": "PPPoE"}
    ],
    "mtu": 0,
    "behavior": "KeepAlive",
    "maxIdleMinutes": 15,
    "reconnectAfterSeconds": 30,
    "staticIpAddress": "111.111.111.123",
    "staticGateway": "111.111.111.1",
    "staticDns1": "8.8.8.8",
    "staticDns2": "8.8.4.4",
    "networkPrefixLength": 24,
    "username": "user",
    "password": "pass",
    "serviceName": "",
    "serverIp": "111.222.111.1",
    "useStaticSettings": false,
    "wanTaggingSettingsEnable": false,
    "vlanId": 0
  },
  "ipv6Setting": {
    "ipv6ConnectionType": "Automatic",
    "supportedIPv6ConnectionType": ["Automatic", "PPPoE", "Pass-through"],
    "duid": "00:02:03:09:05:05:80:69:1A:A7:14:FF",
    "isIPv6AutomaticEnabled": true
  },
  "macClone": false,
  "macCloneAddress": ""
};

const internetSettingsStateBridge = {
  "ipv4Setting": {
    "ipv4ConnectionType": "Bridge",
    "supportedIPv4ConnectionType": [
      "DHCP",
      "Static",
      "PPPoE",
      "PPTP",
      "L2TP",
      "Bridge"
    ],
    "supportedWANCombinations": [
      {"wanType": "DHCP", "wanIPv6Type": "Automatic"},
      {"wanType": "Static", "wanIPv6Type": "Automatic"},
      {"wanType": "PPPoE", "wanIPv6Type": "Automatic"},
      {"wanType": "L2TP", "wanIPv6Type": "Automatic"},
      {"wanType": "PPTP", "wanIPv6Type": "Automatic"},
      {"wanType": "Bridge", "wanIPv6Type": "Automatic"},
      {"wanType": "DHCP", "wanIPv6Type": "Pass-through"},
      {"wanType": "PPPoE", "wanIPv6Type": "PPPoE"}
    ],
    "mtu": 0
  },
  "ipv6Setting": {
    "ipv6ConnectionType": "Automatic",
    "supportedIPv6ConnectionType": ["Automatic", "PPPoE", "Pass-through"],
    "duid": "00:02:03:09:05:05:80:69:1A:A7:14:FF",
    "isIPv6AutomaticEnabled": true
  },
  "macClone": false,
  "macCloneAddress": ""
};

const internetSettingsStateIpv6Automatic = {
  "ipv4Setting": {
    "ipv4ConnectionType": "DHCP",
    "supportedIPv4ConnectionType": [
      "DHCP",
      "Static",
      "PPPoE",
      "PPTP",
      "L2TP",
      "Bridge"
    ],
    "supportedWANCombinations": [
      {"wanType": "DHCP", "wanIPv6Type": "Automatic"},
      {"wanType": "Static", "wanIPv6Type": "Automatic"},
      {"wanType": "PPPoE", "wanIPv6Type": "Automatic"},
      {"wanType": "L2TP", "wanIPv6Type": "Automatic"},
      {"wanType": "PPTP", "wanIPv6Type": "Automatic"},
      {"wanType": "Bridge", "wanIPv6Type": "Automatic"},
      {"wanType": "DHCP", "wanIPv6Type": "Pass-through"},
      {"wanType": "PPPoE", "wanIPv6Type": "PPPoE"}
    ],
    "mtu": 0
  },
  "ipv6Setting": {
    "ipv6ConnectionType": "Automatic",
    "supportedIPv6ConnectionType": ["Automatic", "PPPoE", "Pass-through"],
    "duid": "00:02:03:09:05:05:80:69:1A:A7:14:FF",
    "isIPv6AutomaticEnabled": true
  },
  "macClone": false,
  "macCloneAddress": ""
};