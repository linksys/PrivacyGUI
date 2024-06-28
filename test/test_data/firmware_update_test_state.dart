const firmwareUpdateTestData = {
  "settings": {
    "updatePolicy": "AutomaticallyCheckAndInstall",
    "autoUpdateWindow": {"startMinute": 0, "durationMinutes": 240}
  },
  "nodesStatus": [
    {
      "lastSuccessfulCheckTime": "2024-06-14T07:26:11Z",
      "availableUpdate": null,
      "pendingOperation": null,
      "lastOperationFailure": null,
      "deviceUUID": "ef07238c-4870-46fb-a524-80691a13160e"
    }
  ],
  "isUpdating": false,
  "isChecking": false
};

const firmwareUpdateHasFirmwareTestData = {
  "settings": {
    "updatePolicy": "AutomaticallyCheckAndInstall",
    "autoUpdateWindow": {"startMinute": 0, "durationMinutes": 240}
  },
  "nodesStatus": [
    {
      "lastSuccessfulCheckTime": "2024-06-14T07:26:11Z",
      "availableUpdate": {
        "firmwareVersion": "1.23.34567",
        "firmwareDate": "2024-05-14T07:26:11Z",
        "description": ""
      },
      "pendingOperation": null,
      "lastOperationFailure": null,
      "deviceUUID": "ef07238c-4870-46fb-a524-80691a13160e"
    }
  ],
  "isUpdating": false,
  "isChecking": false
};
