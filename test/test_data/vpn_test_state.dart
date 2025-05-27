import 'package:privacy_gui/page/vpn/models/vpn_models.dart';
import 'package:privacy_gui/page/vpn/providers/vpn_state.dart';

/// Test data for VPN state testing
class VPNTestState {
  /// Default VPN state with all fields initialized
  static VPNState get defaultState => VPNState(
        settings: VPNSettings(
          userCredentials: VPNUserCredentials(
            username: 'testuser',
            authMode: AuthMode.psk,
            secret: 'testsecret',
          ),
          gatewaySettings: VPNGatewaySettings(
            gatewayAddress: '192.168.1.1',
            dnsName: 'vpn.example.com',
            ikeMode: IKEMode.ikev2,
            ikeProposal: 'aes256-sha2_256-modp2048',
            espProposal: 'aes256-sha2_256',
          ),
          serviceSettings: VPNServiceSetSettings(
            enabled: true,
            autoConnect: true,
          ),
          tunneledUserIP: '10.0.0.2',
          isEditingCredentials: false,
        ),
        status: VPNStatus(
          statistics: VPNStatistics(
            uptime: 3600,
            packetsSent: 1000,
            packetsReceived: 1000,
            bytesSent: 1000000,
            bytesReceived: 1000000,
            currentBandwidth: 1000,
            activeSAs: 1,
            rekeyCount: 0,
          ),
          tunnelStatus: IPsecStatus.connected,
          testResult: null,
        ),
      );

  /// VPN state with disconnected status
  static VPNState get disconnectedState => defaultState.copyWith(
        status: defaultState.status.copyWith(
          tunnelStatus: IPsecStatus.disconnected,
          statistics: null,
        ),
      );

  /// VPN state with failed connection
  static VPNState get failedState => defaultState.copyWith(
        status: defaultState.status.copyWith(
          tunnelStatus: IPsecStatus.failed,
          statistics: null,
        ),
      );

  /// VPN state with connecting status
  static VPNState get connectingState => defaultState.copyWith(
        status: defaultState.status.copyWith(
          tunnelStatus: IPsecStatus.connecting,
          statistics: null,
        ),
      );

  /// VPN state with test result
  static VPNState get testResultState => defaultState.copyWith(
        status: defaultState.status.copyWith(
          testResult: VPNTestResult(
            success: true,
            statusMessage: 'Connection test successful',
            latency: 50,
          ),
        ),
      );

  /// VPN state with failed test result
  static VPNState get failedTestResultState => disconnectedState.copyWith(
        status: disconnectedState.status.copyWith(
          testResult: VPNTestResult(
            success: false,
            statusMessage: 'Connection test failed: Unable to reach VPN server',
            latency: null,
          ),
        ),
      );

  /// VPN state with certificate authentication
  static VPNState get certificateAuthState => defaultState.copyWith(
        settings: defaultState.settings.copyWith(
          userCredentials: VPNUserCredentials(
            username: 'certuser',
            authMode: AuthMode.certificate,
            secret: null,
          ),
        ),
      );

  /// VPN state with EAP authentication
  static VPNState get eapAuthState => defaultState.copyWith(
        settings: defaultState.settings.copyWith(
          userCredentials: VPNUserCredentials(
            username: 'eapuser',
            authMode: AuthMode.eap,
            secret: 'eapsecret',
          ),
        ),
      );

  /// VPN state with IKEv1 mode
  static VPNState get ikev1State => defaultState.copyWith(
        settings: defaultState.settings.copyWith(
          gatewaySettings: VPNGatewaySettings(
            gatewayAddress: '192.168.1.1',
            dnsName: 'vpn.example.com',
            ikeMode: IKEMode.ikev1,
            ikeProposal: 'aes256-sha2_256-modp2048',
            espProposal: 'aes256-sha2_256',
          ),
        ),
      );

  /// VPN state with service disabled
  static VPNState get serviceDisabledState => disconnectedState.copyWith(
        settings: disconnectedState.settings.copyWith(
          serviceSettings: VPNServiceSetSettings(
            enabled: false,
            autoConnect: false,
          ),
        ),
      );
}
