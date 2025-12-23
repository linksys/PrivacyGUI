const staticRoutingTestState = {
  "settings": {
    "original": {
      "isNATEnabled": true,
      "isDynamicRoutingEnabled": false,
      "entries": [
        {
          "name": "test",
          "destinationIP": "10.137.1.177",
          "subnetMask": "255.255.255.0",
          "gateway": "10.137.1.1",
          "interface": "LAN"
        }
      ]
    },
    "current": {
      "isNATEnabled": true,
      "isDynamicRoutingEnabled": false,
      "entries": [
        {
          "name": "test",
          "destinationIP": "10.137.1.177",
          "subnetMask": "255.255.255.0",
          "gateway": "10.137.1.1",
          "interface": "LAN"
        }
      ]
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
      "entries": []
    },
    "current": {
      "isNATEnabled": true,
      "isDynamicRoutingEnabled": false,
      "entries": []
    }
  },
  "status": {
    "maxStaticRouteEntries": 20,
    "routerIp": "10.137.1.1",
    "subnetMask": "255.255.255.0"
  }
};
