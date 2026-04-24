import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/generated/dmz.g.dart';
import 'package:privacy_gui/page/dmz/models/dmz_settings.dart';
import 'package:privacy_gui/page/dmz/models/dmz_status.dart';
import 'package:privacy_gui/page/dmz/models/dmz_ui_model.dart';
import 'package:privacy_gui/util/network_utils.dart';

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
      final dmzData = await Dmz.fetch(_usp);
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
      final result = await Dmz.add(
        _usp,
        [
          {
            'Enable': true,
            'DestIP': model.destIp,
            'SourcePrefix': sourcePrefix,
            'Description': 'DMZ',
          }
        ],
      );
      final parsed = UspResultParser.parseAddResult(result);
      switch (parsed) {
        case UspSuccess():
          break;
        case UspPartialSuccess(:final errorSummary, :final successes, :final failures):
          throw UspPartialFailureError(
            summary: 'DMZ add partial failure: $errorSummary',
            successPaths: successes.map((s) => s.requestedPath).toList(),
            failedPaths: failures.map((f) => f.requestedPath).toList(),
          );
        case UspFailure(:final errorSummary, :final errors):
          throw UspCompleteFailureError(
            summary: 'DMZ add failed: $errorSummary',
            failedPaths: errors.map((e) => e.requestedPath).toList(),
          );
      }
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Update an existing DMZ entry.
  Future<void> update({
    required String instancePath,
    required DmzUIModel model,
  }) async {
    try {
      final sourcePrefix = model.sourceType == DmzSourceType.any
          ? '0.0.0.0/0'
          : model.sourcePrefix;
      final result = await Dmz.update(
        _usp,
        [
          DmzEntryUpdate(
            instancePath: instancePath,
            enable: model.isEnabled,
            destIp: model.destIp,
            sourcePrefix: sourcePrefix,
          )
        ],
      );
      final parsed = UspResultParser.parseSetResult(result);
      switch (parsed) {
        case UspSuccess():
          break;
        case UspPartialSuccess(:final errorSummary, :final successes, :final failures):
          throw UspPartialFailureError(
            summary: 'DMZ update partial failure: $errorSummary',
            successPaths: successes.map((s) => s.requestedPath).toList(),
            failedPaths: failures.map((f) => f.requestedPath).toList(),
          );
        case UspFailure(:final errorSummary, :final errors):
          throw UspCompleteFailureError(
            summary: 'DMZ update failed: $errorSummary',
            failedPaths: errors.map((e) => e.requestedPath).toList(),
          );
      }
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Transform
  // ---------------------------------------------------------------------------

  /// Build a [DmzUIModel] from codegen [Dmz] collection.
  DmzUIModel buildUIModel(Dmz data) {
    if (data.items.isEmpty) return const DmzUIModel.disabled();
    final entry = data.items.first;
    return DmzUIModel(
      isEnabled: entry.enable,
      destIp: entry.destIp,
      sourceType: _parseSourceType(entry.sourcePrefix),
      sourcePrefix: entry.sourcePrefix,
    );
  }

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  /// Validate DMZ form fields. Returns field-level errors (empty map = valid).
  Map<String, String> validateForm(DmzUIModel model) {
    final errors = <String, String>{};
    if (!model.isEnabled) return errors;
    if (model.destIp.isEmpty) {
      errors['destIp'] = 'Destination IP is required';
    } else if (!NetworkUtils.isValidIpAddress(model.destIp)) {
      errors['destIp'] = 'Invalid IP address';
    }
    if (model.sourceType == DmzSourceType.cidr && model.sourcePrefix.isEmpty) {
      errors['sourcePrefix'] = 'CIDR range is required';
    }
    return errors;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  DmzSourceType _parseSourceType(String prefix) {
    if (prefix.isEmpty || prefix == '0.0.0.0/0') {
      return DmzSourceType.any;
    }
    return DmzSourceType.cidr;
  }
}
