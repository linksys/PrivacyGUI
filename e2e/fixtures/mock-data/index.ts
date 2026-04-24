/**
 * Mock data index — merges all fixture files into a single flat map.
 *
 * Supports scenario switching via window.__mockScenario:
 *   - 'default': full realistic data (all pages render)
 *   - 'empty': minimal data (empty lists, providers succeed but show nothing)
 *   - 'wifi-only': only WiFi + system data (for focused WiFi tests)
 */
import { systemInfoData } from './system-info';
import { wifiRadiosData } from './wifi-radios';
import { wifiSsidsData } from './wifi-ssids';
import { wifiAccessPointsData, wifiClientsData } from './wifi-access-points';
import { connectedDevicesData } from './connected-devices';
import { wanStatusData } from './wan-status';
import { lanNetworkData } from './lan-network';
import { timeSettingsData } from './time-settings';
import { ethernetData } from './ethernet';
import { firewallData } from './firewall';
import { dhcpReservationsData, dhcpClientsData } from './dhcp';
import { portForwardingData } from './port-forwarding';
import { portTriggeringData } from './port-triggering';

/** All fixture data merged into one flat map (default scenario). */
const defaultData: Record<string, string> = {
  ...systemInfoData,
  ...wifiRadiosData,
  ...wifiSsidsData,
  ...wifiAccessPointsData,
  ...wifiClientsData,
  ...connectedDevicesData,
  ...wanStatusData,
  ...lanNetworkData,
  ...timeSettingsData,
  ...ethernetData,
  ...firewallData,
  ...dhcpReservationsData,
  ...dhcpClientsData,
  ...portForwardingData,
  ...portTriggeringData,
};

/** Empty scenario — providers succeed but return no list items. */
const emptyData: Record<string, string> = {
  ...systemInfoData,
  ...timeSettingsData,
  // No WiFi, no devices, no WAN — pages show empty/error state
};

/** WiFi-only scenario — system + WiFi data, nothing else. */
const wifiOnlyData: Record<string, string> = {
  ...systemInfoData,
  ...wifiRadiosData,
  ...wifiSsidsData,
  ...wifiAccessPointsData,
  ...timeSettingsData,
};

const scenarios: Record<string, Record<string, string>> = {
  default: defaultData,
  empty: emptyData,
  'wifi-only': wifiOnlyData,
};

/**
 * Returns fixture data for the active scenario.
 * Called from within addInitScript context (browser window).
 */
export function getFixtureData(scenario: string = 'default'): Record<string, string> {
  return scenarios[scenario] ?? defaultData;
}

/**
 * Serializable snapshot of all scenarios — injected into the browser
 * via addInitScript so MockUspClient.get() can access it.
 */
export function getAllScenariosJson(): string {
  return JSON.stringify(scenarios);
}

export {
  systemInfoData,
  wifiRadiosData,
  wifiSsidsData,
  wifiAccessPointsData,
  wifiClientsData,
  connectedDevicesData,
  wanStatusData,
  lanNetworkData,
  timeSettingsData,
  ethernetData,
  firewallData,
  dhcpReservationsData,
  dhcpClientsData,
  portForwardingData,
  portTriggeringData,
};
