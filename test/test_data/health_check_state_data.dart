const healthCheckInitState = '''{"status": "idle", 
    "meterValue": 0.0,
    "randomValue": 0.0,
     "step":"latency",
     "result": null
}''';
const healthCheckStatePingInit = '''{"status": "running", 
    "meterValue": 0.0,
    "randomValue": 0.0,
     "step":"latency",
     "result":{
        "latency": "0",
        "serverId": "3967"
     }
}''';
const healthCheckStatePing = '''{"status": "running", 
    "meterValue": 0.0,
    "randomValue": 0.0,
     "step":"downloadBandwidth",
     "result":{
        "downloadSpeed": "0.0",
        "downloadUnit": "Mbps",
        "uploadSpeed": "0.0",
        "uploadUnit": "Mbps",
        "latency": "13",
        "timestamp": "",
        "serverId": "3967"
     }
}''';
const healthCheckStateDownload = '''{"status": "running", 
    "meterValue": 0.0,
    "randomValue": 0.0,
     "step":"downloadBandwidth",
     "result":{
        "downloadSpeed": "567.8",
        "latency": "1",
        "serverId": "3967"
     }
}''';
const healthCheckStateUpload = '''{"status": "running", 
    "meterValue": 0.0,
    "randomValue": 0.0,
     "step":"uploadBandwidth",
     "result":{
        "downloadSpeed": "567.8",
        "uploadSpeed": "12.3",
        "latency": "1",
        "serverId": "3967"
     }
}''';
const healthCheckStateSuccessUltra = '''{"status": "complete", 
    "meterValue": 0.0,
    "randomValue": 0.0,
     "step":"success",
     "timestamp":"2024-06-24T09:20:09Z",
     "result":{
        "downloadSpeed": "567.8",
        "uploadSpeed": "12.3",
        "latency": "1",
        "timestamp": "2024-06-24T09:20:09Z",
        "serverId": "3967"
     }
}''';
const healthCheckStateSuccessOptimal = '''{"status": "complete", 
    "meterValue": 0.0,
    "randomValue": 0.0,
     "step":"success",
     "timestamp":"2024-06-24T09:20:09Z",
     "result":{
        "downloadSpeed": "117.4",
        "uploadSpeed": "121.2",
        "latency": "1",
        "timestamp": "2024-06-24T09:20:09Z",
        "serverId": "3967"
     }
}''';
const healthCheckStateSuccessGood = '''{"status": "complete", 
    "meterValue": 0.0,
    "randomValue": 0.0,
     "step":"success",
     "timestamp":"2024-06-24T09:20:09Z",
     "result":{
        "downloadSpeed": "97.4",
        "uploadSpeed": "91.2",
        "latency": "1",
        "timestamp": "2024-06-24T09:20:09Z",
        "serverId": "3967"
     }
}''';
const healthCheckStateSuccessOkay = '''{"status": "complete", 
    "meterValue": 0.0,
    "randomValue": 0.0,
     "step":"success",
     "timestamp":"2024-06-24T09:20:09Z",
     "result":{
        "downloadSpeed": "17.4",
        "uploadSpeed": "21.2",
        "latency": "1",
        "timestamp": "2024-06-24T09:20:09Z",
        "serverId": "3967"
     }
}''';
const healthCheckStateError = '''{"status": "complete", 
    "meterValue": 0.0,
    "randomValue": 0.0,
     "step":"error",
     "result":null,
     "error":{"result":"Empty resultID","error":null}
}''';
