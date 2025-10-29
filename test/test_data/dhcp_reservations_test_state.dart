final _dhcpReservationsSettingsEmpty = {
  "reservations": [],
};

final _dhcpReservationsStatusEmpty = {
  "additionalReservations": [],
  "devices": []
};

final dhcpReservationTestStateEmpty = {
  "settings": {
    "original": _dhcpReservationsSettingsEmpty,
    "current": _dhcpReservationsSettingsEmpty,
  },
  "status": _dhcpReservationsStatusEmpty,
};

final _dhcpReservationsSettings = {
  "reservations": [
    {
      "reserved": false,
      "data": {
        "macAddress": "E6:9C:B4:4A:9E:6E",
        "ipAddress": "10.175.1.72",
        "description": "a837a914-38b0-4d2a-b612-387510d36407"
      }
    },
    {
      "reserved": false,
      "data": {
        "macAddress": "A4:83:E7:11:8A:19",
        "ipAddress": "10.175.1.144",
        "description": "ASTWP-028279"
      }
    },
    {
      "reserved": false,
      "data": {
        "macAddress": "A4:83:E7:11:88:88",
        "ipAddress": "10.175.1.150",
        "description": "ASTWP-028200"
      }
    }
  ],
};

final _dhcpReservationsStatus = {
  "additionalReservations": [],
  "devices": [
    {
      "reserved": false,
      "data": {
        "macAddress": "E6:9C:B4:4A:9E:6E",
        "ipAddress": "10.175.1.72",
        "description": "a837a914-38b0-4d2a-b612-387510d36407"
      }
    },
    {
      "reserved": false,
      "data": {
        "macAddress": "A4:83:E7:11:8A:19",
        "ipAddress": "10.175.1.144",
        "description": "ASTWP-028279"
      }
    },
    {
      "reserved": false,
      "data": {
        "macAddress": "A4:83:E7:11:88:88",
        "ipAddress": "10.175.1.150",
        "description": "ASTWP-028200"
      }
    }
  ]
};

final dhcpReservationTestState = {
  "settings": {
    "original": _dhcpReservationsSettings,
    "current": _dhcpReservationsSettings,
  },
  "status": _dhcpReservationsStatus,
};
