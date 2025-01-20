const instantPrivacyTestState = {
  "status": "disabled",
  "macAddresses": [],
  "denyMacAddresses": [],
  "maxMacAddresses": 56,
  "bssids": [
    "8A:69:1A:BB:46:96",
    "86:69:1A:BB:46:96",
    "8E:69:1A:BB:46:95",
    "8A:69:1A:BB:46:95"
  ]
};

const instantPrivacyEnabledTestState = {
  "status": "allow",
  "denyMacAddresses": [],
  "macAddresses": [
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
};

const instantPrivacyDenyTestState = {
  "status": "deny",
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
  ]
};
