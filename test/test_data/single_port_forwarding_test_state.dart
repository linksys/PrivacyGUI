const singlePortForwardingListTestState = {
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
  ],
  "maxRules": 50,
  "maxDescriptionLength": 32
};

const singlePortForwardingEmptyListTestState = {
  "rules": [
    
  ],
  "maxRules": 50,
  "maxDescriptionLength": 32
};
