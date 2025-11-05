const appsAndGamingTestState = {
  "settings": {
    "original": {
      "ddnsSettings": {
        "provider": {"name": "None"}
      },
      "singlePortForwardingList": {
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
      "portRangeForwardingList": {
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
      "portRangeTriggeringList": {
        "rules": [
          {
            "isEnabled": true,
            "firstTriggerPort": 6000,
            "lastTriggerPort": 6001,
            "firstForwardedPort": 7000,
            "lastForwardedPort": 7001,
            "description": "Triggering 1"
          }
        ]
      }
    },
    "current": {
      "ddnsSettings": {
        "provider": {"name": "None"}
      },
      "singlePortForwardingList": {
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
      "portRangeForwardingList": {
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
      "portRangeTriggeringList": {
        "rules": [
          {
            "isEnabled": true,
            "firstTriggerPort": 6000,
            "lastTriggerPort": 6001,
            "firstForwardedPort": 7000,
            "lastForwardedPort": 7001,
            "description": "Triggering 1"
          }
        ]
      }
    }
  },
  "status": <String, dynamic>{}
};