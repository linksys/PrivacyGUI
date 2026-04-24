/**
 * Device.NAT.PortTrigger.* — Port Triggering rules (multi-instance + children)
 * 1 trigger rule with 1 forward sub-rule
 *
 * Parent: Device.NAT.PortTrigger.{i}  (trigger ports)
 * Child:  Device.NAT.PortTrigger.{i}.Rule.{i}  (forwarded ports)
 */
export const portTriggeringData: Record<string, string> = {
  // Rule 1 — FTP trigger: port 21 TCP → forward 1024-1030 TCP
  'Device.NAT.PortTrigger.1.Enable': 'true',
  'Device.NAT.PortTrigger.1.Description': 'FTP Trigger',
  'Device.NAT.PortTrigger.1.Port': '21',
  'Device.NAT.PortTrigger.1.PortEndRange': '0',
  'Device.NAT.PortTrigger.1.Protocol': 'TCP',

  // Forward sub-rule 1
  'Device.NAT.PortTrigger.1.Rule.1.Port': '1024',
  'Device.NAT.PortTrigger.1.Rule.1.PortEndRange': '1030',
  'Device.NAT.PortTrigger.1.Rule.1.Protocol': 'TCP',
};
