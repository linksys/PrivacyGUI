import 'package:privacy_gui/page/dual/models/balance_ratio.dart';
import 'package:privacy_gui/page/dual/models/connection.dart';
import 'package:privacy_gui/page/dual/models/connection_status.dart';
import 'package:privacy_gui/page/dual/models/logging_option.dart';
import 'package:privacy_gui/page/dual/models/mode.dart';
import 'package:privacy_gui/page/dual/models/port.dart';
import 'package:privacy_gui/page/dual/models/port_type.dart';
import 'package:privacy_gui/page/dual/models/speed_status.dart';
import 'package:privacy_gui/page/dual/models/wan_configuration.dart';
import 'package:privacy_gui/page/dual/providers/dual_wan_settings_state.dart';

final testDualWANSettingsStateDisabled = DualWANSettingsState.init();

const testDualWANSettingsState = DualWANSettingsState(
  settings: DualWANSettings(
    enable: true,
    mode: DualWANMode.failover,
    balanceRatio: DualWANBalanceRatio.equalDistribution,
    primaryWAN: DualWANConfiguration(
        wanType: 'DHCP',
        supportedWANType: ['DHCP', 'Static', 'PPPoE', 'PPTP'],
        mtu: 0),
    secondaryWAN: DualWANConfiguration(
        wanType: 'DHCP',
        supportedWANType: ['DHCP', 'Static', 'PPPoE', 'PPTP'],
        mtu: 0),
    loggingOptions: LoggingOptions(
      failoverEvents: true,
      wanUptime: true,
      speedChecks: false,
      throughputData: false,
    ),
  ),
  status: DualWANStatus(
    connectionStatus: DualWANConnectionStatus(
      primaryStatus: DualWANConnection.connected,
      secondaryStatus: DualWANConnection.active,
      primaryUptime: 123,
      secondaryUptime: 123,
      primaryWANIPAddress: '203.0.113.10',
      secondaryWANIPAddress: '198.51.100.25',
    ),
    speedStatus: SpeedStatus(
      primaryDownloadSpeed: 1234567890,
      primaryUploadSpeed: 1234567890,
      secondaryDownloadSpeed: 1234567890,
      secondaryUploadSpeed: 1234567890,
    ),
    ports: [
      DualWANPort(
        type: PortType.wan1,
        speed: '10Gbps',
      ),
      DualWANPort(
        type: PortType.wan2,
        speed: '2.5Gbps',
      ),
      DualWANPort(
        type: PortType.lan,
        portNumber: 1,
        speed: '1Gbps',
      ),
      DualWANPort(
        type: PortType.lan,
        portNumber: 2,
        speed: '1Gbps',
      ),
    ],
  ),
);
