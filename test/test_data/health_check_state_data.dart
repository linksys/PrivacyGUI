const healthCheckInitState = '''{"status": "IDLE", 
    "meterValue": 0.0,
    "randomValue": 0.0,
     "step":"latency","result":[]}''';
const healthCheckStatePingInit =
    '''{"status": "RUNNING", 
    "meterValue": 0.0,
    "randomValue": 0.0,
     "step":"latency","result":[{"resultID":30736,"timestamp":"","healthCheckModulesRequested":["SpeedTest"],"speedTestResult":{"resultID":30736,"exitCode":"Unavailable","serverID":"3967","latency":0,"uploadBandwidth":0,"downloadBandwidth":0}}]}''';
const healthCheckStatePing =
    '''{"status": "RUNNING", 
    "meterValue": 0.0,
    "randomValue": 0.0,
     "step":"downloadBandwidth","result":[{"resultID":30736,"timestamp":"","healthCheckModulesRequested":["SpeedTest"],"speedTestResult":{"resultID":30736,"exitCode":"Unavailable","serverID":"3967","latency":10,"uploadBandwidth":0,"downloadBandwidth":0}}]}''';
const healthCheckStateDownload =
    '''{"status": "RUNNING", 
    "meterValue": 0.0,
    "randomValue": 0.0,
     "step":"downloadBandwidth","result":[{"resultID":30736,"timestamp":"","healthCheckModulesRequested":["SpeedTest"],"speedTestResult":{"resultID":30736,"exitCode":"Unavailable","serverID":"3967","latency":1,"uploadBandwidth":0,"downloadBandwidth":317412}}]}''';
const healthCheckStateUpload =
    '''{"status": "RUNNING", 
    "meterValue": 0.0,
    "randomValue": 0.0,
     "step":"uploadBandwidth","result":[{"resultID":30736,"timestamp":"","healthCheckModulesRequested":["SpeedTest"],"speedTestResult":{"resultID":30736,"exitCode":"Success","serverID":"3967","latency":1,"uploadBandwidth":321267,"downloadBandwidth":317412}}]}''';
const healthCheckStateSuccessUltra =
    '''{"status": "COMPLETE", 
    "meterValue": 0.0,
    "randomValue": 0.0,
     "step":"uploadBandwidth","timestamp":"2024-06-24T09:20:09Z","result":[{"resultID":30736,"timestamp":"2024-06-24T09:20:09Z","healthCheckModulesRequested":["SpeedTest"],"speedTestResult":{"resultID":30736,"exitCode":"Success","serverID":"3967","latency":1,"uploadBandwidth":321267,"downloadBandwidth":317412}}]}''';
const healthCheckStateSuccessOptimal =
    '''{"status": "COMPLETE", 
    "meterValue": 0.0,
    "randomValue": 0.0,
     "step":"uploadBandwidth","timestamp":"2024-06-24T09:20:09Z","result":[{"resultID":30736,"timestamp":"2024-06-24T09:20:09Z","healthCheckModulesRequested":["SpeedTest"],"speedTestResult":{"resultID":30736,"exitCode":"Success","serverID":"3967","latency":1,"uploadBandwidth":121267,"downloadBandwidth":117412}}]}''';
const healthCheckStateSuccessGood =
    '''{"status": "COMPLETE", 
    "meterValue": 0.0,
    "randomValue": 0.0,
     "step":"uploadBandwidth","timestamp":"2024-06-24T09:20:09Z","result":[{"resultID":30736,"timestamp":"2024-06-24T09:20:09Z","healthCheckModulesRequested":["SpeedTest"],"speedTestResult":{"resultID":30736,"exitCode":"Success","serverID":"3967","latency":1,"uploadBandwidth":91267,"downloadBandwidth":97412}}]}''';
const healthCheckStateSuccessOkay =
    '''{"status": "COMPLETE", 
    "meterValue": 0.0,
    "randomValue": 0.0,
     "step":"uploadBandwidth","timestamp":"2024-06-24T09:20:09Z","result":[{"resultID":30736,"timestamp":"2024-06-24T09:20:09Z","healthCheckModulesRequested":["SpeedTest"],"speedTestResult":{"resultID":30736,"exitCode":"Success","serverID":"3967","latency":1,"uploadBandwidth":21267,"downloadBandwidth":17412}}]}''';
const healthCheckStateError =
    '''{"status": "COMPLETE", 
    "meterValue": 0.0,
    "randomValue": 0.0,
     "step":"error","result":[],"error":{"result":"Empty resultID","error":null}}''';
