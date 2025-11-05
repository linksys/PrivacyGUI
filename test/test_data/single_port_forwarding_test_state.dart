const singlePortForwardingListTestState = {
  "settings": {
    "original": {
      "rules": [
        {
          "isEnabled": false,
          "externalPort": 999,
          "protocol": "Both",
          "internalServerIPAddress": "10.137.1.123",
          "internalPort": 9999,
          "description": "XBOX"
        },
        {
          "isEnabled": true,
          "externalPort": 22,
          "protocol": "Both",
          "internalServerIPAddress": "10.137.1.33",
          "internalPort": 3333,
          "description": "tt123"
        }
      ]
    },
    "current": {
      "rules": [
        {
          "isEnabled": false,
          "externalPort": 999,
          "protocol": "Both",
          "internalServerIPAddress": "10.137.1.123",
          "internalPort": 9999,
          "description": "XBOX"
        },
        {
          "isEnabled": true,
          "externalPort": 22,
          "protocol": "Both",
          "internalServerIPAddress": "10.137.1.33",
          "internalPort": 3333,
          "description": "tt123"
        }
      ]
    }
  },
  "status": {
    "maxRules": 50,
    "maxDescriptionLength": 32,
    "routerIp": "192.168.1.1",
    "subnetMask": "255.255.255.0"
  }
};

const singlePortForwardingEmptyListTestState = {
  "settings": {
    "original": {
      "rules": []
    },
    "current": {
      "rules": []
    }
  },
  "status": {
    "maxRules": 50,
    "maxDescriptionLength": 32,
    "routerIp": "192.168.1.1",
    "subnetMask": "255.255.255.0"
  }
};
