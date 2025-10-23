const internetSettingsStateData = '''
{
  "settings": {
    "original": {
      "ipv4Setting": {
        "ipv4ConnectionType": "DHCP",
        "mtu": 0
      },
      "ipv6Setting": {
        "ipv6ConnectionType": "Automatic",
        "isIPv6AutomaticEnabled": true
      },
      "macClone": false,
      "macCloneAddress": ""
    },
    "current": {
      "ipv4Setting": {
        "ipv4ConnectionType": "DHCP",
        "mtu": 0
      },
      "ipv6Setting": {
        "ipv6ConnectionType": "Automatic",
        "isIPv6AutomaticEnabled": true
      },
      "macClone": false,
      "macCloneAddress": ""
    }
  },
  "status": {
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
    "supportedIPv6ConnectionType": [
      "Automatic",
      "PPPoE",
      "Pass-through"
    ],
    "duid": "00:02:03:09:05:05:80:69:1A:13:16:0E",
    "redirection": null,
    "hostname": null
  }
}
''';

const internetSettingsStateData2 = '''
{
  "settings": {
    "original": {
      "ipv4Setting": {
        "ipv4ConnectionType": "PPPoE",
        "mtu": 0
      },
      "ipv6Setting": {
        "ipv6ConnectionType": "Automatic",
        "isIPv6AutomaticEnabled": true
      },
      "macClone": false,
      "macCloneAddress": ""
    },
    "current": {
      "ipv4Setting": {
        "ipv4ConnectionType": "PPPoE",
        "mtu": 0
      },
      "ipv6Setting": {
        "ipv6ConnectionType": "Automatic",
        "isIPv6AutomaticEnabled": true
      },
      "macClone": false,
      "macCloneAddress": ""
    }
  },
  "status": {
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
    "supportedIPv6ConnectionType": [
      "Automatic",
      "PPPoE",
      "Pass-through"
    ],
    "duid": "00:02:03:09:05:05:80:69:1A:13:16:0E",
    "redirection": null,
    "hostname": null
  }
}
''';

const internetSettingsStateDHCP = {
  "settings": {
    "original": {
      "ipv4Setting": {"ipv4ConnectionType": "DHCP", "mtu": 0},
      "ipv6Setting": {
        "ipv6ConnectionType": "Automatic",
        "isIPv6AutomaticEnabled": true
      },
      "macClone": false,
      "macCloneAddress": ""
    },
    "current": {
      "ipv4Setting": {"ipv4ConnectionType": "DHCP", "mtu": 0},
      "ipv6Setting": {
        "ipv6ConnectionType": "Automatic",
        "isIPv6AutomaticEnabled": true
      },
      "macClone": false,
      "macCloneAddress": ""
    }
  },
  "status": {
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
    "supportedIPv6ConnectionType": ["Automatic", "PPPoE", "Pass-through"],
    "duid": "00:02:03:09:05:05:80:69:1A:A7:14:FF",
    "redirection": null,
    "hostname": null
  }
};

const internetSettingsStateStatic = {
  "settings": {
    "original": {
      "ipv4Setting": {
        "ipv4ConnectionType": "Static",
        "mtu": 1500,
        "staticIpAddress": "111.222.111.123",
        "staticGateway": "111.222.111.1",
        "staticDns1": "8.8.8.8",
        "staticDns2": "8.8.4.4",
        "networkPrefixLength": 24,
        "domainName": "linksys.com"
      },
      "ipv6Setting": {
        "ipv6ConnectionType": "Automatic",
        "isIPv6AutomaticEnabled": true
      },
      "macClone": true,
      "macCloneAddress": "aa:bb:cc:11:22:33"
    },
    "current": {
      "ipv4Setting": {
        "ipv4ConnectionType": "Static",
        "mtu": 1500,
        "staticIpAddress": "111.222.111.123",
        "staticGateway": "111.222.111.1",
        "staticDns1": "8.8.8.8",
        "staticDns2": "8.8.4.4",
        "networkPrefixLength": 24,
        "domainName": "linksys.com"
      },
      "ipv6Setting": {
        "ipv6ConnectionType": "Automatic",
        "isIPv6AutomaticEnabled": true
      },
      "macClone": true,
      "macCloneAddress": "aa:bb:cc:11:22:33"
    }
  },
  "status": {
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
    "supportedIPv6ConnectionType": ["Automatic", "PPPoE", "Pass-through"],
    "duid": "00:02:03:09:05:05:80:69:1A:A7:14:FF",
    "redirection": null,
    "hostname": null
  }
};

const internetSettingsStatePppoe = {
  "settings": {
    "original": {
      "ipv4Setting": {
        "ipv4ConnectionType": "PPPoE",
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
        "serverIp": null,
        "wanTaggingSettingsEnable": false,
        "vlanId": 0
      },
      "ipv6Setting": {
        "ipv6ConnectionType": "Automatic",
        "isIPv6AutomaticEnabled": true
      },
      "macClone": false,
      "macCloneAddress": ""
    },
    "current": {
      "ipv4Setting": {
        "ipv4ConnectionType": "PPPoE",
        "mtu": 0,
        "behavior": "KeepAlive",
        "maxIdleMinutes": 15,
        "reconnectAfterSeconds": 30,
        "staticIpAddress": "111.222.111.123",
        "staticGateway": "111.222.111.1",
        "staticDns1": "8.8.8.8",
        "staticDns2": "8.8.4.4",
        "networkPrefixLength": 24,
        "domainName": null,
        "username": "user",
        "password": "pass",
        "serviceName": "",
        "serverIp": null,
        "wanTaggingSettingsEnable": false,
        "vlanId": 0
      },
      "ipv6Setting": {
        "ipv6ConnectionType": "Automatic",
        "isIPv6AutomaticEnabled": true
      },
      "macClone": false,
      "macCloneAddress": ""
    }
  },
  "status": {
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
    "supportedIPv6ConnectionType": ["Automatic", "PPPoE", "Pass-through"],
    "duid": "00:02:03:09:05:05:80:69:1A:A7:14:FF",
    "redirection": null,
    "hostname": null
  }
};

const internetSettingsStatePptp = {
  "settings": {
    "original": {
      "ipv4Setting": {
        "ipv4ConnectionType": "PPTP",
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
        "isIPv6AutomaticEnabled": true
      },
      "macClone": false,
      "macCloneAddress": ""
    },
    "current": {
      "ipv4Setting": {
        "ipv4ConnectionType": "PPTP",
        "mtu": 0,
        "behavior": "KeepAlive",
        "maxIdleMinutes": 15,
        "reconnectAfterSeconds": 30,
        "staticIpAddress": "111.222.111.123",
        "staticGateway": "111.222.111.1",
        "staticDns1": "8.8.8.8",
        "staticDns2": "8.8.4.4",
        "networkPrefixLength": 24,
        "domainName": null,
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
        "isIPv6AutomaticEnabled": true
      },
      "macClone": false,
      "macCloneAddress": ""
    }
  },
  "status": {
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
    "supportedIPv6ConnectionType": ["Automatic", "PPPoE", "Pass-through"],
    "duid": "00:02:03:09:05:05:80:69:1A:A7:14:FF",
    "redirection": null,
    "hostname": null
  }
};

const internetSettingsStatePptpWithStaticIp = {
  "settings": {
    "original": {
      "ipv4Setting": {
        "ipv4ConnectionType": "PPTP",
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
        "isIPv6AutomaticEnabled": true
      },
      "macClone": false,
      "macCloneAddress": ""
    },
    "current": {
      "ipv4Setting": {
        "ipv4ConnectionType": "PPTP",
        "mtu": 0,
        "behavior": "KeepAlive",
        "maxIdleMinutes": 15,
        "reconnectAfterSeconds": 30,
        "staticIpAddress": "111.111.111.123",
        "staticGateway": "111.111.111.1",
        "staticDns1": "8.8.8.8",
        "staticDns2": "8.8.4.4",
        "networkPrefixLength": 24,
        "domainName": null,
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
        "isIPv6AutomaticEnabled": true
      },
      "macClone": false,
      "macCloneAddress": ""
    }
  },
  "status": {
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
    "supportedIPv6ConnectionType": ["Automatic", "PPPoE", "Pass-through"],
    "duid": "00:02:03:09:05:05:80:69:1A:A7:14:FF",
    "redirection": null,
    "hostname": null
  }
};

const internetSettingsStateL2tp = {
  "settings": {
    "original": {
      "ipv4Setting": {
        "ipv4ConnectionType": "L2TP",
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
        "isIPv6AutomaticEnabled": true
      },
      "macClone": false,
      "macCloneAddress": ""
    },
    "current": {
      "ipv4Setting": {
        "ipv4ConnectionType": "L2TP",
        "mtu": 0,
        "behavior": "KeepAlive",
        "maxIdleMinutes": 15,
        "reconnectAfterSeconds": 30,
        "staticIpAddress": "111.111.111.123",
        "staticGateway": "111.111.111.1",
        "staticDns1": "8.8.8.8",
        "staticDns2": "8.8.4.4",
        "networkPrefixLength": 24,
        "domainName": null,
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
        "isIPv6AutomaticEnabled": true
      },
      "macClone": false,
      "macCloneAddress": ""
    }
  },
  "status": {
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
    "supportedIPv6ConnectionType": ["Automatic", "PPPoE", "Pass-through"],
    "duid": "00:02:03:09:05:05:80:69:1A:A7:14:FF",
    "redirection": null,
    "hostname": null
  }
};

const internetSettingsStateBridge = {
  "settings": {
    "original": {
      "ipv4Setting": {"ipv4ConnectionType": "Bridge", "mtu": 0},
      "ipv6Setting": {
        "ipv6ConnectionType": "Automatic",
        "isIPv6AutomaticEnabled": true
      },
      "macClone": false,
      "macCloneAddress": ""
    },
    "current": {
      "ipv4Setting": {"ipv4ConnectionType": "Bridge", "mtu": 0},
      "ipv6Setting": {
        "ipv6ConnectionType": "Automatic",
        "isIPv6AutomaticEnabled": true
      },
      "macClone": false,
      "macCloneAddress": ""
    }
  },
  "status": {
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
    "supportedIPv6ConnectionType": ["Automatic", "PPPoE", "Pass-through"],
    "duid": "00:02:03:09:05:05:80:69:1A:A7:14:FF",
    "redirection": null,
    "hostname": null
  }
};

const internetSettingsStateIpv6Automatic = {
  "settings": {
    "original": {
      "ipv4Setting": {"ipv4ConnectionType": "DHCP", "mtu": 0},
      "ipv6Setting": {
        "ipv6ConnectionType": "Automatic",
        "isIPv6AutomaticEnabled": true
      },
      "macClone": false,
      "macCloneAddress": ""
    },
    "current": {
      "ipv4Setting": {"ipv4ConnectionType": "DHCP", "mtu": 0},
      "ipv6Setting": {
        "ipv6ConnectionType": "Automatic",
        "isIPv6AutomaticEnabled": true
      },
      "macClone": false,
      "macCloneAddress": ""
    }
  },
  "status": {
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
    "supportedIPv6ConnectionType": ["Automatic", "PPPoE", "Pass-through"],
    "duid": "00:02:03:09:05:05:80:69:1A:A7:14:FF",
    "redirection": null,
    "hostname": null
  }
};

const internetSettingsStateIpv6PassThrough = {
  "settings": {
    "original": {
      "ipv4Setting": {"ipv4ConnectionType": "DHCP", "mtu": 0},
      "ipv6Setting": {
        "ipv6ConnectionType": "Pass-through",
        "isIPv6AutomaticEnabled": false
      },
      "macClone": false,
      "macCloneAddress": null
    },
    "current": {
      "ipv4Setting": {"ipv4ConnectionType": "DHCP", "mtu": 0},
      "ipv6Setting": {
        "ipv6ConnectionType": "Pass-through",
        "isIPv6AutomaticEnabled": false
      },
      "macClone": false,
      "macCloneAddress": null
    }
  },
  "status": {
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
    "supportedIPv6ConnectionType": ["Automatic", "PPPoE", "Pass-through"],
    "duid": "00:02:03:09:05:05:80:69:1A:BB:46:FC",
    "redirection": null,
    "hostname": null
  }
};

const internetSettingsStateIpv6PPPoE = {
  "settings": {
    "original": {
      "ipv4Setting": {"ipv4ConnectionType": "DHCP", "mtu": 0},
      "ipv6Setting": {
        "ipv6ConnectionType": "PPPoE",
        "isIPv6AutomaticEnabled": false
      },
      "macClone": false,
      "macCloneAddress": null
    },
    "current": {
      "ipv4Setting": {"ipv4ConnectionType": "DHCP", "mtu": 0},
      "ipv6Setting": {
        "ipv6ConnectionType": "PPPoE",
        "isIPv6AutomaticEnabled": false
      },
      "macClone": false,
      "macCloneAddress": null
    }
  },
  "status": {
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
    "supportedIPv6ConnectionType": ["Automatic", "PPPoE", "Pass-through"],
    "duid": "00:02:03:09:05:05:80:69:1A:BB:46:FC",
    "redirection": null,
    "hostname": null
  }
};
