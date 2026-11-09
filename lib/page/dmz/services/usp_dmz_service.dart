import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/generated/dmz.g.dart';
import 'package:privacy_gui/page/_shared/services/empty_row.dart';
import 'package:privacy_gui/page/dmz/models/dmz_settings.dart';
import 'package:privacy_gui/page/dmz/models/dmz_status.dart';
import 'package:privacy_gui/page/dmz/models/dmz_ui_model.dart';
import 'package:privacy_gui/util/network_utils.dart';
import 'package:privacy_gui/page/_shared/services/refused_add_service.dart';
import 'package:privacy_gui/validator_rules/rules.dart';

final uspDmzServiceProvider = Provider<UspDmzService>(
  (ref) => UspDmzService(ref.read(uspClientProvider)!),
);

/// Service layer for DMZ — encapsulates codegen CRUD + transform + validation.
///
/// DMZ is multi-instance on the router but practically only 0-1 entries.
/// This service treats the first entry as "the" DMZ configuration.
class UspDmzService {
  final UspClient _usp;

  UspDmzService(this._usp);

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  /// Fetch DMZ data from the router and transform into UI types.
  Future<(DmzSettings, DmzStatus)> fetch() async {
    try {
      // A row with every value blank is no DMZ entry (usp-codegen 0.17 dropped
      // it): a save adds one rather than writing to it.
      final dmzData = Dmz(
          items: (await Dmz.fetch(_usp))
              .items
              .where((d) => !isEmptyDmzEntry(d))
              .toList());
      final uiModel = buildUIModel(dmzData);
      final instancePath =
          dmzData.items.isNotEmpty ? dmzData.items.first.instancePath : null;
      return (
        DmzSettings(model: uiModel, instancePath: instancePath),
        const DmzStatus(isLoading: false),
      );
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Add a new DMZ entry.
  Future<void> add({required DmzUIModel model}) async {
    try {
      final sourcePrefix = model.sourceType == DmzSourceType.any
          ? '0.0.0.0/0'
          : model.sourcePrefix;
      // Only the leaf that names the host: the new row has neither set, and
      // FWDEV#204 refuses a row with both.
      final result = await Dmz.add(
        _usp,
        [
          {
            'Enable': true,
            if (model.destinationType == DmzDestinationType.ip)
              'DestIP': model.destIp
            else
              'X_LINKSYS_DestMACAddress': _wireMac(model.destMac),
            'SourcePrefix': sourcePrefix,
            'Description': 'DMZ',
          }
        ],
      );
      final parsed = await parseAddRemovingRefusedRows(_usp, result,
          tag: '[USP][Firewall][DMZ]');
      switch (parsed) {
        case UspSuccess():
          break;
        case UspPartialSuccess(
            :final errorSummary,
            :final successes,
            :final failures
          ):
          throw UspPartialFailureError(
            summary: 'DMZ add partial failure: $errorSummary',
            successPaths: successes.map((s) => s.requestedPath).toList(),
            failures: failures,
          );
        case UspFailure(:final errorSummary, :final errors):
          throw UspCompleteFailureError(
            summary: 'DMZ add failed: $errorSummary',
            failures: errors,
          );
      }
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Update an existing DMZ entry.
  ///
  /// [savedType] is how the router holds the host now. When [model] gives it
  /// the other way, the router's leaf is first set to "" in a Set of its own
  /// (FWDEV#204: only one of `DestIP` and `X_LINKSYS_DestMACAddress` may be
  /// set, and the checks run per field in write order), and only once that is
  /// accepted is the new host written. A refused clear writes nothing more.
  ///
  /// A new host refused after an accepted clear leaves the router with no
  /// host at all, so it throws [UspPartialFailureError]: the save wrote part
  /// of itself, and the page reads the router again.
  Future<void> update({
    required String instancePath,
    required DmzDestinationType savedType,
    required DmzUIModel model,
  }) async {
    try {
      final byIp = model.destinationType == DmzDestinationType.ip;
      final switching = model.destinationType != savedType;
      if (switching) {
        await _setOnce(
          DmzEntryUpdate(
            instancePath: instancePath,
            destIp: byIp ? null : '',
            destMacAddress: byIp ? '' : null,
          ),
          summaryPrefix: 'DMZ clear ${savedType.name}',
        );
      }
      final sourcePrefix = model.sourceType == DmzSourceType.any
          ? '0.0.0.0/0'
          : model.sourcePrefix;
      try {
        await _setOnce(
          DmzEntryUpdate(
            instancePath: instancePath,
            enable: model.isEnabled,
            destIp: byIp ? model.destIp : null,
            destMacAddress: byIp ? null : _wireMac(model.destMac),
            sourcePrefix: sourcePrefix,
          ),
          summaryPrefix: 'DMZ update',
        );
      } on UspCompleteFailureError catch (e) {
        if (!switching) rethrow;
        throw UspPartialFailureError(
          summary: 'DMZ ${savedType.name} cleared, new host refused: '
              '${e.summary}',
          successPaths: [
            '$instancePath${byIp ? 'X_LINKSYS_DestMACAddress' : 'DestIP'}',
          ],
          failures: e.failures,
        );
      }
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }

  /// One Set of [entry]; any refusal throws, with the router's failures.
  Future<void> _setOnce(
    DmzEntryUpdate entry, {
    required String summaryPrefix,
  }) async {
    final result = await Dmz.update(_usp, [entry]);
    final parsed = UspResultParser.parseSetResult(result);
    switch (parsed) {
      case UspSuccess():
        break;
      case UspPartialSuccess(
          :final errorSummary,
          :final successes,
          :final failures
        ):
        throw UspPartialFailureError(
          summary: '$summaryPrefix partial failure: $errorSummary',
          successPaths: successes.map((s) => s.requestedPath).toList(),
          failures: failures,
        );
      case UspFailure(:final errorSummary, :final errors):
        throw UspCompleteFailureError(
          summary: '$summaryPrefix failed: $errorSummary',
          failures: errors,
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Transform
  // ---------------------------------------------------------------------------

  /// Build a [DmzUIModel] from codegen [Dmz] collection.
  DmzUIModel buildUIModel(Dmz data) => uiModelOf(data);

  /// [buildUIModel] without a service: the Firewall data service builds the
  /// same model for the dashboard and the PDF report.
  static DmzUIModel uiModelOf(Dmz data) {
    if (data.items.isEmpty) return const DmzUIModel.disabled();
    final entry = data.items.first;
    // FWDEV#204: one of the two is set, and the non-empty one is the host.
    final destMac = entry.destMacAddress ?? '';
    return DmzUIModel(
      isEnabled: entry.enable,
      destinationType:
          destMac.isNotEmpty ? DmzDestinationType.mac : DmzDestinationType.ip,
      destIp: entry.destIp,
      destMac: destMac,
      sourceType: _parseSourceType(entry.sourcePrefix),
      sourcePrefix: entry.sourcePrefix,
    );
  }

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  /// Validate DMZ form fields. Returns field-level [DmzErrorKeys] by field
  /// (empty map = valid).
  ///
  /// Only the field [DmzUIModel.destinationType] names is checked: the other
  /// is not saved. The MAC check also runs before a first save, which is an
  /// Add: a refused Add creates the row with the refused field emptied
  /// (FWDEV#204, bench 2026-10-12). Since usp-client 0.14.0 the reason
  /// arrives and the row is deleted again ([add]); this check saves that
  /// round trip.
  Map<String, String> validateForm(DmzUIModel model) {
    final errors = <String, String>{};
    if (!model.isEnabled) return errors;
    switch (model.destinationType) {
      case DmzDestinationType.ip:
        if (model.destIp.isEmpty) {
          errors['destIp'] = DmzErrorKeys.destIpRequired;
        } else if (!NetworkUtils.isValidIpAddress(model.destIp)) {
          errors['destIp'] = DmzErrorKeys.invalidIpAddress;
        }
      case DmzDestinationType.mac:
        final mac = model.destMac.trim();
        if (mac.isEmpty) {
          errors['destMac'] = DmzErrorKeys.destMacRequired;
        } else if (!MACAddressRule().validate(mac) || _isGroupMac(mac)) {
          errors['destMac'] = DmzErrorKeys.invalidMacAddress;
        }
    }
    if (model.sourceType == DmzSourceType.cidr && model.sourcePrefix.isEmpty) {
      errors['sourcePrefix'] = DmzErrorKeys.cidrRequired;
    }
    return errors;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Whether a well-formed [mac] names a group (broadcast or multicast): the
  /// lowest bit of its first octet is set. A DMZ host is one device; FW
  /// refuses a group MAC with ErrorInvalidDestinationMACAddress on a Set and
  /// empties it on an Add (bench 2.0.4.26103108, 2026-11-09, measured with
  /// usp-client 0.13.0, which dropped an Add's refusals). So it is checked
  /// before anything is written.
  static bool _isGroupMac(String mac) =>
      int.parse(mac.substring(0, 2), radix: 16) & 1 == 1;

  /// [mac] as it is written: `-` separators become `:`, the form the router
  /// reports. Case is kept, so a MAC picked from the device list is written
  /// exactly as the router listed it.
  static String _wireMac(String mac) => mac.trim().replaceAll('-', ':');

  static DmzSourceType _parseSourceType(String prefix) {
    if (prefix.isEmpty || prefix == '0.0.0.0/0') {
      return DmzSourceType.any;
    }
    return DmzSourceType.cidr;
  }
}
