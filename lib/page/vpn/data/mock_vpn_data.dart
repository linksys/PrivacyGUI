const Map<String, dynamic> mockVPNData = {
  'userCredentials': {
    'username': 'user@example.com',
    'authMode': 'eap',
    'secret': 'mockSecret123'
  },
  'gatewaySettings': {
    'gatewayAddress': 'vpn.example.com',
    'dnsName': 'fortisase.example.com',
    'ikeMode': 'ikev2',
    'ikeProposal': 'aes256-sha256-modp2048',
    'espProposal': 'aes256-sha256'
  },
  'serviceSettings': {
    'enabled': true,
    'tunnelStatus': 'connected',
    'autoConnect': true,
    'statistics': {
      'uptime': 3600,
      'packetsSent': 1024,
      'packetsReceived': 2048,
      'bytesSent': 1048576,
      'bytesReceived': 2097152,
      'currentBandwidth': 51200,
      'activeSAs': 2,
      'rekeyCount': 1
    }
  },
  'tunneledUserIP': '192.168.1.100',
  'testResult': {
    'success': true,
    'statusMessage': 'IPsec SA established',
    'latency': 42
  }
};
