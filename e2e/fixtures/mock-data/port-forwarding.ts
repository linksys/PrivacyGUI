/**
 * Device.NAT.PortMapping.* — Port Forwarding rules (multi-instance)
 * 2 single-port rules + 1 port-range rule
 *
 * Single port: ExternalPortEndRange == 0 or == ExternalPort
 * Port range:  ExternalPortEndRange > ExternalPort
 */
export const portForwardingData: Record<string, string> = {
  // Rule 1 — single port: HTTP server
  'Device.NAT.PortMapping.1.Enable': 'true',
  'Device.NAT.PortMapping.1.ExternalPort': '8080',
  'Device.NAT.PortMapping.1.ExternalPortEndRange': '0',
  'Device.NAT.PortMapping.1.InternalPort': '80',
  'Device.NAT.PortMapping.1.InternalClient': '192.168.1.100',
  'Device.NAT.PortMapping.1.Protocol': 'TCP',
  'Device.NAT.PortMapping.1.Description': 'Web Server',

  // Rule 2 — single port: SSH
  'Device.NAT.PortMapping.2.Enable': 'false',
  'Device.NAT.PortMapping.2.ExternalPort': '2222',
  'Device.NAT.PortMapping.2.ExternalPortEndRange': '0',
  'Device.NAT.PortMapping.2.InternalPort': '22',
  'Device.NAT.PortMapping.2.InternalClient': '192.168.1.100',
  'Device.NAT.PortMapping.2.Protocol': 'TCP',
  'Device.NAT.PortMapping.2.Description': 'SSH Access',

  // Rule 3 — port range: Game ports
  'Device.NAT.PortMapping.3.Enable': 'true',
  'Device.NAT.PortMapping.3.ExternalPort': '27015',
  'Device.NAT.PortMapping.3.ExternalPortEndRange': '27030',
  'Device.NAT.PortMapping.3.InternalPort': '27015',
  'Device.NAT.PortMapping.3.InternalClient': '192.168.1.101',
  'Device.NAT.PortMapping.3.Protocol': 'Both',
  'Device.NAT.PortMapping.3.Description': 'Game Server',
};
