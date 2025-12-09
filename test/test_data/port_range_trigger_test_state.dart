const portRangeTriggerListTestState = {
  "settings": {
    "original": {
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
    },
    "current": {
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
  "status": {
    "maxRules": 25,
    "maxDescriptionLength": 32
  }
};

const portRangeTriggerEmptyListTestState = {
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
    "maxDescriptionLength": 32
  }
};
