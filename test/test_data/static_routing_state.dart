const staticRoutingTestState = {
  "settings": {
    "original": {
      "isNATEnabled": true,
      "isDynamicRoutingEnabled": false,
      "entries": {
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
    },
    "current": {
      "isNATEnabled": true,
      "isDynamicRoutingEnabled": false,
      "entries": {
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
    }
  },
  "status": {
    "maxStaticRouteEntries": 20,
    "routerIp": "10.137.1.1",
    "subnetMask": "255.255.255.0"
  }
};

const staticRoutingTestStateEmpty = {
  "settings": {
    "original": {
      "isNATEnabled": true,
      "isDynamicRoutingEnabled": false,
      "entries": {"entries": [
          
        ]
      }
    },
    "current": {
      "isNATEnabled": true,
      "isDynamicRoutingEnabled": false,
      "entries": {"entries": [
          
        ]
      }
    }
  },
  "status": {
    "maxStaticRouteEntries": 20,
    "routerIp": "10.137.1.1",
    "subnetMask": "255.255.255.0"
  }
};
