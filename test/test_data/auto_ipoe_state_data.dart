// Router-shaped AutoIPoE payloads. The keys are the ones `AutoIPoEState.fromMap`
// reads, which is the JNAP response shape, so these double as a record of what
// the four AutoIPoE Get actions are expected to return.

// Auto mode: the router picks the VNE itself, so the section has no parameters
// to show beyond what it detected.
const autoIPoEStateAuto = {
  "capabilities": {
    "isSupported": true,
    "supportedModes": [
      "Auto",
      "BIGLOBEStaticIP",
      "StandardIPIP",
      "V6PlusStaticIP",
      "OCNVirtualConnectStaticIP",
      "TransixStaticIP",
      "AsahiNetStaticIP",
      "XpassStaticIP",
      "OCXHikariV6IXStaticIP"
    ],
    "blocksManualIPv6Configuration": true,
    "requiresResetOnExit": true
  },
  "settings": {"isEnabled": true, "selectedMode": "Auto"},
  "status": {
    "isEnabled": true,
    "isCurrentWANType": true,
    "selectedMode": "Auto",
    "applyState": "Active",
    "runtimeType": "MAPE",
    "currentVNE": "v6plus",
    // True is the interesting case: it is what locks the IPv6 tab and adds the
    // "managed by" row, so the screenshot shows AutoIPoE taking IPv6 over.
    "blockIPv6ManualConfiguration": true,
    "isBusy": false,
    "needsResetBeforeLeaving": true
  },
  "log": {"content": "", "isComplete": false}
};

// A static-IP mode, which is where the bulk of the new UI lives: five operator
// -supplied fields instead of none. The password arrives as hasStoredValue with
// no value, the way the router reports an already-configured secret.
const autoIPoEStateV6Plus = {
  "capabilities": {
    "isSupported": true,
    "supportedModes": [
      "Auto",
      "BIGLOBEStaticIP",
      "StandardIPIP",
      "V6PlusStaticIP",
      "OCNVirtualConnectStaticIP",
      "TransixStaticIP",
      "AsahiNetStaticIP",
      "XpassStaticIP",
      "OCXHikariV6IXStaticIP"
    ],
    "blocksManualIPv6Configuration": true,
    "requiresResetOnExit": true
  },
  "settings": {
    "isEnabled": true,
    "selectedMode": "V6PlusStaticIP",
    "v6PlusStaticIpSettings": {
      "ipv6Remote": "2404:8e00::feed:100",
      "ipv6InterfaceId": "0:0:0:1",
      "ipv4Address": "203.0.113.45",
      "userId": "v6plus-user@example.ne.jp",
      "userPassword": {"hasStoredValue": true}
    }
  },
  "status": {
    "isEnabled": true,
    "isCurrentWANType": true,
    "selectedMode": "V6PlusStaticIP",
    "applyState": "Active",
    "runtimeType": "MAPE",
    "currentVNE": "v6plus",
    "blockIPv6ManualConfiguration": true,
    "isBusy": false,
    "needsResetBeforeLeaving": true
  },
  "log": {"content": "", "isComplete": false}
};
