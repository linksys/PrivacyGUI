final staticRoutingEmptyState = {
  "setting": {
    "isNATEnabled": true,
    "isDynamicRoutingEnabled": false,
    "maxStaticRouteEntries": 20,
    "entries": []
  }
};

final staticRoutingState1 = {
  "setting": {
    "isNATEnabled": true,
    "isDynamicRoutingEnabled": false,
    "maxStaticRouteEntries": 20,
    "entries": [
      {
        "name": "test",
        "settings": {
          "destinationLAN": "10.137.1.177",
          "gateway": "10.137.1.1",
          "interface": "LAN",
          "networkPrefixLength": 24
        }
      }
    ]
  }
};

final staticRoutingState2 = {
  "setting": {
    "isNATEnabled": false,
    "isDynamicRoutingEnabled": true,
    "maxStaticRouteEntries": 20,
    "entries": [
      {
        "name": "test",
        "settings": {
          "destinationLAN": "10.137.1.177",
          "gateway": "10.137.1.1",
          "interface": "LAN",
          "networkPrefixLength": 24
        }
      }
    ]
  }
};

final staticRoutingState3 = {
  "setting": {
    "isNATEnabled": false,
    "isDynamicRoutingEnabled": true,
    "maxStaticRouteEntries": 20,
    "entries": [
      {
        "name": "test",
        "settings": {
          "destinationLAN": "10.137.1.177",
          "gateway": "10.137.1.1",
          "interface": "LAN",
          "networkPrefixLength": 24
        }
      },
      {
        "name": "test2",
        "settings": {
          "destinationLAN": "32.32.32.32",
          "gateway": "192.123.123.22",
          "interface": "Internet",
          "networkPrefixLength": 24
        }
      }
    ]
  }
};

final staticRoutingItem1 = {
  "name": "test",
  "settings": {
    "destinationLAN": "10.137.1.177",
    "gateway": "10.137.1.1",
    "interface": "LAN",
    "networkPrefixLength": 24
  }
};

final staticRoutingItem2 = {
  "name": "test2",
  "settings": {
    "destinationLAN": "32.32.32.32",
    "gateway": "192.123.123.22",
    "interface": "Internet",
    "networkPrefixLength": 24
  }
};