const portRangeForwardingListTestState = {
  "settings": {
    "original": {
      "rules": [
        {
          "isEnabled": true,
          "firstExternalPort": 5003,
          "protocol": "Both",
          "internalServerIPAddress": "10.137.1.230",
          "lastExternalPort": 5004,
          "description": "Rule 2222"
        }
      ]
    },
    "current": {
      "rules": [
        {
          "isEnabled": true,
          "firstExternalPort": 5003,
          "protocol": "Both",
          "internalServerIPAddress": "10.137.1.230",
          "lastExternalPort": 5004,
          "description": "Rule 2222"
        }
      ]
    }
  },
  "status": {
    "maxRules": 25,
    "maxDescriptionLength": 32,
    "routerIp": "192.168.1.1",
    "subnetMask": "255.255.255.0"
  }
};

const portRangeForwardingEmptyListTestState = {
  "settings": {
    "original": {
      "rules": []
    },
    "current": {
      "rules": []
    }
  },
  "status": {
    "maxRules": 25,
    "maxDescriptionLength": 32,
    "routerIp": "192.168.1.1",
    "subnetMask": "255.255.255.0"
  }
};
