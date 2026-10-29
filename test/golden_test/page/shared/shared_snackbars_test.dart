import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/models/usp_operation_result.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/firmware_update/localizations/firmware_failure_localizations.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_auto_update_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_failure.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_wan_connection_type.dart';
import 'package:privacy_gui/page/internet_settings/views/helpers/wan_field_error_localization.dart';

import '../../golden_framework/golden_runner.dart';
import '../../golden_framework/golden_test_config.dart';

/// Every message shown through `showSuccessSnackBar` / `showFailedSnackBar`,
/// one golden each (#905).
///
/// ## Why one test for all of them, and not one per page
///
/// A snackbar is a single string in a fixed frame. The frame is
/// `showSimpleSnackBar`'s and does not vary by page, so the only thing a page's
/// own golden could add is the page behind it, which the snackbar covers part of
/// and says nothing about. What does vary is the string, and the reason to have a
/// picture of it is the translation: 26 locales, and a long sentence in one of
/// them is how a snackbar grows to three lines. Capturing them here gives each
/// locale run a picture of every snackbar in one place.
///
/// ## How the table is kept honest
///
/// Each row names the helper its call site uses and builds its message through
/// the same localizer that call site uses: `loc(context)` for a fixed string,
/// `localizeServiceError` for a caught `ServiceError`, `localizeFirmwareFailure`
/// for a firmware validation or router-reported failure. A row never holds a
/// pre-written English string, because then it would be a picture of the test,
/// not of the app. When a call site gains a message, it gains a row here.
///
/// The messages come from four places, and a new one in any of them needs a
/// row: direct calls in the views, and the `successMessage` that
/// `performUspMutation`, `showRecoveryDialog` (once the router is back) and
/// `runWifiWriteWithRecovery` each forward.
///
/// Not in the table:
/// - The hard-coded English strings in `package_widget_renderer.dart` and the
///   log-export snackbar. They read the same in every locale, so a per-locale
///   golden of them adds nothing until they are localized.
/// - Snackbars built directly with `ScaffoldMessenger.of(context).showSnackBar`
///   (the dashboard layout actions, Remote Assistance's PIN copy and session
///   notices). Each builds its own `SnackBar`, not this frame, so it belongs to
///   the page that owns it.
void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'shared_snackbars',
      view: () => const Scaffold(body: SizedBox.expand()),
      shell: ShellType.custom,
      states: const {},
      interactions: {
        for (final row in _rows)
          row.key: Interaction(
            setup: (overrides) {},
            steps: (tester) async {
              final context = tester.element(find.byType(Scaffold));
              row.show(context, row.message(context));
              await pumpOverlayIn(tester);
            },
          ),
      },
    ),
  );
}

typedef _Show = void Function(BuildContext context, String message);

class _Row {
  final String key;
  final _Show show;
  final String Function(BuildContext context) message;

  const _Row.success(this.key, this.message) : show = showSuccessSnackBar;
  const _Row.failed(this.key, this.message) : show = showFailedSnackBar;
}

String _serviceError(BuildContext context, ServiceError error) =>
    localizeServiceError(context, error);

String _firmware(BuildContext context, FirmwareFailure failure) =>
    localizeFirmwareFailure(context, failure);

/// What the Internet Settings save shows for a refusal netmngr named.
String _wanRefusal(BuildContext context, String name) =>
    localizeWanSaveError(context, InvalidInputError(field: name, code: 7012));

final _rows = <_Row>[
  // --- Success: a save or an action that completed ---
  _Row.success('success_changes_saved', (c) => loc(c).changesSaved),
  _Row.success('success_local_network_settings_saved',
      (c) => loc(c).localNetworkSettingsSaved),
  _Row.success('success_timezone_updated', (c) => loc(c).timezoneUpdated),
  _Row.success('success_password_updated', (c) => loc(c).passwwordUpdated),
  _Row.success(
      'success_firewall_settings_saved', (c) => loc(c).firewallSettingsSaved),
  _Row.success('success_safe_browsing_settings_saved',
      (c) => loc(c).safeBrowsingSettingsSaved),
  _Row.success('success_port_forwarding_settings_saved',
      (c) => loc(c).portForwardingSettingsSaved),
  _Row.success(
      'success_dhcp_reservations_saved', (c) => loc(c).dhcpReservationsSaved),
  _Row.success('success_static_routes_saved', (c) => loc(c).staticRoutesSaved),
  _Row.success(
      'success_ipv6_port_rules_saved', (c) => loc(c).ipv6PortRulesSaved),
  _Row.success('success_dmz_settings_saved', (c) => loc(c).dmzSettingsSaved),
  // `leaseRenewed` takes the protocol label, and the three callers pass three
  // different ones: the IPv4 and IPv6 renew buttons pass the localized protocol
  // name, the DHCP card passes the literal 'DHCP'.
  _Row.success(
      'success_lease_renewed_ipv4', (c) => loc(c).leaseRenewed(loc(c).ipv4)),
  _Row.success(
      'success_lease_renewed_ipv6', (c) => loc(c).leaseRenewed(loc(c).ipv6)),
  _Row.success(
      'success_lease_renewed_dhcp', (c) => loc(c).leaseRenewed('DHCP')),
  _Row.success('success_ip_address_reserved', (c) => loc(c).ipAddressReserved),
  _Row.success('success_reservation_added', (c) => loc(c).reservationAdded),
  _Row.success('success_rule_added', (c) => loc(c).ruleAdded),
  _Row.success('success_channel_updated', (c) => loc(c).channelUpdated),
  _Row.success('success_reservation_deleted', (c) => loc(c).reservationDeleted),
  _Row.success(
      'success_reservation_released', (c) => loc(c).reservationReleased),
  _Row.success('success_time_settings_saved', (c) => loc(c).timeSettingsSaved),
  _Row.success(
      'success_reconnected_to_router', (c) => loc(c).reconnectedToRouter),
  _Row.success(
      'success_router_reboot_complete', (c) => loc(c).routerRebootComplete),
  _Row.success('success_wifi_settings_saved', (c) => loc(c).wifiSettingsSaved),

  // --- Service errors: every distinct string `localizeServiceError` returns ---
  _Row.failed('error_not_authenticated',
      (c) => _serviceError(c, const NotAuthenticatedError())),
  _Row.failed('error_invalid_credentials',
      (c) => _serviceError(c, const InvalidCredentialsError())),
  _Row.failed('error_session_expired',
      (c) => _serviceError(c, const SessionTokenExpiredError())),
  _Row.failed('error_invalid_session_token',
      (c) => _serviceError(c, const InvalidSessionTokenError())),
  _Row.failed(
      'error_unauthorized', (c) => _serviceError(c, const UnauthorizedError())),
  _Row.failed('error_resource_not_found',
      (c) => _serviceError(c, const ResourceNotFoundError())),
  _Row.failed('error_invalid_input',
      (c) => _serviceError(c, const InvalidInputError())),
  _Row.failed('error_network', (c) => _serviceError(c, const NetworkError())),
  _Row.failed(
      'error_connectivity', (c) => _serviceError(c, const ConnectivityError())),
  _Row.failed('error_timeout', (c) => _serviceError(c, const TimeoutError())),
  _Row.failed('error_service_not_ready',
      (c) => _serviceError(c, const ServiceNotInitializedError())),
  // Only reachable through a batch failure: the router's fault 7022 has no
  // `ServiceError` type of its own, so it is the batch localizer that names it.
  _Row.failed(
    'error_command_refused',
    (c) => _serviceError(
      c,
      const UspCompleteFailureError(
        summary: '1 of 1 failed',
        failures: [
          UspErrorDetail(
            requestedPath: 'Device.WiFi.SSID.1.SSID',
            errorCode: 7022,
            errorMessage: 'Command failure',
          ),
        ],
      ),
    ),
  ),
  _Row.failed(
      'error_unexpected', (c) => _serviceError(c, const UnexpectedError())),
  // `UnexpectedError` surfaces its `detail` verbatim when it has one. That
  // string comes from wherever the error was raised and is not localized, but it
  // is what the user reads, so it is captured once at a realistic length.
  _Row.failed(
    'error_unexpected_with_detail',
    (c) => _serviceError(
      c,
      const UnexpectedError(
        detail: 'Device.WiFi.Radio.2.Channel: value 165 is not allowed '
            'for the current regulatory domain',
      ),
    ),
  ),

  // --- Firmware failures that reach a snackbar ---
  // The file picker's four validation failures (`_onPickFile`).
  _Row.failed('firmware_file_empty',
      (c) => _firmware(c, const FirmwareFailure.fileEmpty())),
  // Just under `FirmwareValidationService.minBytes` (1 MB) and just over
  // `maxBytes` (256 MB), so the sizes read as a user would actually see them.
  _Row.failed(
      'firmware_file_too_small',
      (c) => _firmware(
          c, const FirmwareFailure.fileTooSmall(sizeBytes: 512 * 1024))),
  _Row.failed(
      'firmware_file_too_large',
      (c) => _firmware(
          c, const FirmwareFailure.fileTooLarge(sizeBytes: 300 * 1024 * 1024))),
  _Row.failed('firmware_file_type_unsupported',
      (c) => _firmware(c, const FirmwareFailure.fileTypeUnsupported())),
  // A check for updates the router itself reported as failed
  // (`_onCheckForUpdates`). `checkForUpdate` maps a missing code to
  // `routerUnspecified`, and `routerReported` asserts against the three codes
  // that mean "no failure", so these seven are every code that can arrive.
  for (final code in const [
    FirmwareUpdateErrorCode.serverUnreachable,
    FirmwareUpdateErrorCode.serverResponse,
    FirmwareUpdateErrorCode.download,
    FirmwareUpdateErrorCode.flash,
    FirmwareUpdateErrorCode.signature,
    FirmwareUpdateErrorCode.routerUnspecified,
    FirmwareUpdateErrorCode.interrupted,
  ])
    _Row.failed('firmware_router_${_snake(code.name)}',
        (c) => _firmware(c, FirmwareFailure.routerReported(code))),

  // --- WAN save refusals: every distinct string `localizeWanSaveError` gives
  // a netmngr message (linksys/FWDEV#212) ---
  _Row.failed('error_wan_invalid_server',
      (c) => _wanRefusal(c, WanRefusalNames.invalidServer)),
  _Row.failed('error_wan_invalid_subnet_mask',
      (c) => _wanRefusal(c, WanRefusalNames.invalidPrefixLength)),
  _Row.failed('error_wan_invalid_gateway',
      (c) => _wanRefusal(c, WanRefusalNames.invalidGateway)),
  _Row.failed('error_wan_invalid_dns',
      (c) => _wanRefusal(c, WanRefusalNames.invalidDns)),
  _Row.failed('error_wan_invalid_mtu',
      (c) => _wanRefusal(c, WanRefusalNames.invalidMtu)),

  // --- Other fixed failure messages ---
  _Row.failed(
      'failed_no_target_bank_available', (c) => loc(c).noTargetBankAvailable),
  _Row.failed(
      'failed_to_start_ota_update', (c) => loc(c).failedToStartOtaUpdate),
  // `failedToRenew` interpolates the caught error's `toString()`. A
  // `NetworkError` with a detail is what a renew that loses the router throws.
  _Row.failed(
      'failed_to_renew',
      (c) => loc(c).failedToRenew(
          const NetworkError(detail: 'connection closed').toString())),

  // --- Wrapping ---
  // Instant Setup passes the caught exception's `toString()` straight through
  // (`pnp_notifier.dart`'s `errorMessage: '$e'`). Unbounded and unlocalized, it
  // is the longest text a snackbar can be handed, so it is the one picture of
  // the snackbar wrapping across several lines.
  _Row.failed(
      'failed_raw_exception_long',
      (c) => const UspCompleteFailureError(
            summary: 'Set failed for 3 of 3 parameters: '
                'Device.IP.Interface.1.IPv4Address.1.IPAddress, '
                'Device.IP.Interface.1.IPv4Address.1.SubnetMask, '
                'Device.DHCPv4.Server.Pool.1.MinAddress',
            failures: [],
          ).toString()),
];

/// `serverUnreachable` -> `server_unreachable`, because golden keys must be
/// snake_case and enum names are lowerCamelCase.
String _snake(String camel) => camel.replaceAllMapped(
    RegExp('[A-Z]'), (m) => '_${m.group(0)!.toLowerCase()}');
