const instantPrivacyTestState = {
  "settings": {
    "original": {
      "mode": "disabled",
      "macAddresses": [],
      "denyMacAddresses": [],
      "maxMacAddresses": 56,
      "bssids": [
        "8A:69:1A:BB:46:96",
        "86:69:1A:BB:46:96",
        "8E:69:1A:BB:46:95",
        "8A:69:1A:BB:46:95"
      ],
      "myMac": "3C:22:FB:E4:4F:18"
    },
    "current": {
      "mode": "disabled",
      "macAddresses": [],
      "denyMacAddresses": [],
      "maxMacAddresses": 56,
      "bssids": [
        "8A:69:1A:BB:46:96",
        "86:69:1A:BB:46:96",
        "8E:69:1A:BB:46:95",
        "8A:69:1A:BB:46:95"
      ],
      "myMac": "3C:22:FB:E4:4F:18"
    }
  },
  "status": {"mode": "disabled"}
};

const instantPrivacyEnabledTestState = {
  "settings": {
    "original": {
      "mode": "allow",
      "denyMacAddresses": [],
      "macAddresses": [
        "AA:07:17:16:09:33",
        "3C:22:FB:E4:4F:18",
        "80:69:1A:BB:46:CC",
        "86:69:1A:BB:46:96",
        "8A:69:1A:BB:46:96",
        "8E:69:1A:BB:46:95",
        "8A:69:1A:BB:46:95"
      ],
      "maxMacAddresses": 56,
      "bssids": [
        "8A:69:1A:BB:46:96",
        "86:69:1A:BB:46:96",
        "8E:69:1A:BB:46:95",
        "8A:69:1A:BB:46:95"
      ],
      "myMac": "3C:22:FB:E4:4F:18"
    },
    "current": {
      "mode": "allow",
      "denyMacAddresses": [],
      "macAddresses": [
        "AA:07:17:16:09:33",
        "3C:22:FB:E4:4F:18",
        "80:69:1A:BB:46:CC",
        "86:69:1A:BB:46:96",
        "8A:69:1A:BB:46:96",
        "8E:69:1A:BB:46:95",
        "8A:69:1A:BB:46:95"
      ],
      "maxMacAddresses": 56,
      "bssids": [
        "8A:69:1A:BB:46:96",
        "86:69:1A:BB:46:96",
        "8E:69:1A:BB:46:95",
        "8A:69:1A:BB:46:95"
      ],
      "myMac": "3C:22:FB:E4:4F:18"
    }
  },
  "status": {"mode": "allow"}
};

const instantPrivacyDenyTestState = {
  "settings": {
    "original": {
      "mode": "deny",
      "macAddresses": [],
      "denyMacAddresses": [
        "3C:22:FB:E4:4F:18",
      ],
      "maxMacAddresses": 56,
      "bssids": [
        "8A:69:1A:BB:46:96",
        "86:69:1A:BB:46:96",
        "8E:69:1A:BB:46:95",
        "8A:69:1A:BB:46:95"
      ],
      "myMac": "3C:22:FB:E4:4F:18"
    },
    "current": {
      "mode": "deny",
      "macAddresses": [],
      "denyMacAddresses": [
        "3C:22:FB:E4:4F:18",
      ],
      "maxMacAddresses": 56,
      "bssids": [
        "8A:69:1A:BB:46:96",
        "86:69:1A:BB:46:96",
        "8E:69:1A:BB:46:95",
        "8A:69:1A:BB:46:95"
      ],
      "myMac": "3C:22:FB:E4:4F:18"
    }
  },
  "status": {"mode": "deny"}
};
