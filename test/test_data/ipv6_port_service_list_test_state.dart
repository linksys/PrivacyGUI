const ipv6PortServiceListTestState = {
  "rules": [
    {
      "description": "222",
      "ipv6Address": "1111:1111:1111:1111:1111:1111:1111:ffff",
      "isEnabled": true,
      "portRanges": [
        {"protocol": "Both", "firstPort": 1223, "lastPort": 1235}
      ]
    },
    {
      "description": "777",
      "ipv6Address": "2223:3333:3333:3333:2222:2233:3333:ffff",
      "isEnabled": true,
      "portRanges": [
        {"protocol": "Both", "firstPort": 1, "lastPort": 2}
      ]
    }
  ],
  "maxRules": 15,
  "maxDescriptionLength": 64
};

const ipv6PortServiceEmptyListTestState = {
  "rules": [
    
  ],
  "maxRules": 15,
  "maxDescriptionLength": 64
};