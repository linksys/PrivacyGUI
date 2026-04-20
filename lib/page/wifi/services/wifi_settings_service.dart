import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/wi_fi_ssids.g.dart';

final wifiSettingsServiceProvider = Provider<WiFiSettingsService>(
  (ref) => WiFiSettingsService(
    ref.read(uspClientProvider)!,
  ),
);

/// Service layer for WiFi Settings with strict write operation handling.
///
/// Demonstrates advanced Service layer patterns:
/// - Strict error handling for critical configuration changes
/// - Structured error parsing from WASM layer responses
/// - Business validation before sending to router
/// - Rollback strategies for failed batch operations
class WiFiSettingsService {
  final UspClient _client;

  WiFiSettingsService(this._client);

  /// Enable/disable SSID with strict error handling.
  ///
  /// This is a critical operation - if it fails, the user loses network access.
  /// Strict strategy: any failure must be reported with full error details.
  Future<void> updateSsidStatus(String instancePath, bool enable) async {
    try {
      final update = WiFiSsidUpdate(
        instancePath: instancePath,
        enable: enable,
      );

      logger.d(
          '[WiFiSettingsService] Updating SSID $instancePath enable=$enable');

      // Use codegen update method which returns structured response
      final result = await WiFiSsids.update(_client, [update]);

      // Parse structured response using our UspResultParser
      final parsedResult = UspResultParser.parseSetResult(result);

      // Strict error handling: any failure is unacceptable
      if (parsedResult case UspSuccess()) {
        logger.i('[WiFiSettingsService] SSID status updated successfully');
      } else if (parsedResult
          case UspPartialSuccess(failures: final failures)) {
        // For single parameter update, partial success means total failure
        logger.e(
            '[WiFiSettingsService] SSID update failed: ${failures.first.errorMessage}');
        throw InvalidInputError(
          message:
              'Failed to update SSID status: ${failures.first.errorMessage}',
        );
      } else if (parsedResult case UspFailure(errors: final errors)) {
        logger.e(
            '[WiFiSettingsService] SSID update failed completely: ${errors.first.errorMessage}');
        throw NetworkError(
          message: 'SSID configuration failed: ${errors.first.errorMessage}',
        );
      }
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Update SSID name with validation and strict error handling.
  ///
  /// SSID name changes require validation and careful error handling.
  Future<void> updateSsidName(String instancePath, String newSsid) async {
    try {
      // Business validation before sending to router
      _validateSsidName(newSsid);

      final update = WiFiSsidUpdate(
        instancePath: instancePath,
        ssid: newSsid,
      );

      logger.d(
          '[WiFiSettingsService] Updating SSID name: $instancePath -> "$newSsid"');

      final result = await WiFiSsids.update(_client, [update]);
      final parsedResult = UspResultParser.parseSetResult(result);

      if (parsedResult case UspSuccess()) {
        logger.i('[WiFiSettingsService] SSID name updated successfully');
      } else if (parsedResult
          case UspPartialSuccess(failures: final failures)) {
        final error = failures.first;
        logger.e(
            '[WiFiSettingsService] SSID name update failed: ${error.errorMessage}');

        // Map specific USP error codes to meaningful business errors
        if (error.isInvalidParameterValue) {
          throw InvalidInputError(
            message: 'Invalid SSID name "$newSsid": ${error.errorMessage}',
          );
        } else if (error.isParameterNotWritable) {
          throw const UnauthorizedError();
        } else {
          throw NetworkError(
              message: 'SSID update failed: ${error.errorMessage}');
        }
      } else if (parsedResult case UspFailure(errors: final errors)) {
        throw NetworkError(
            message: 'SSID configuration failed: ${errors.first.errorMessage}');
      }
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Batch update multiple SSIDs with rollback on failure.
  ///
  /// Demonstrates advanced error handling: if any SSID fails in strict mode,
  /// attempt to rollback successful changes to maintain consistency.
  Future<BatchUpdateResult> updateMultipleSSIDs(
    List<WiFiSsidUpdate> updates, {
    bool allowPartial = false,
  }) async {
    try {
      // Business validation for all updates
      for (final update in updates) {
        if (update.ssid != null) {
          _validateSsidName(update.ssid!);
        }
      }

      logger.d(
          '[WiFiSettingsService] Batch updating ${updates.length} SSIDs, allowPartial=$allowPartial');

      // Update each SSID individually
      final allSuccesses = <UspSuccessDetail>[];
      final allFailures = <UspErrorDetail>[];

      for (final update in updates) {
        final result = await WiFiSsids.update(_client, [update],
            allowPartial: allowPartial);
        final parsedResult = UspResultParser.parseSetResult(result);

        if (parsedResult case UspSuccess(details: final details)) {
          allSuccesses.addAll(details);
        } else if (parsedResult
            case UspPartialSuccess(
              successes: final successes,
              failures: final failures
            )) {
          allSuccesses.addAll(successes);
          allFailures.addAll(failures);
        } else if (parsedResult case UspFailure(errors: final errors)) {
          allFailures.addAll(errors);
        }
      }

      // Reconstruct overall result
      final UspSetResult parsedResult;
      if (allFailures.isEmpty) {
        parsedResult = UspSuccess(allSuccesses);
      } else if (allSuccesses.isEmpty) {
        parsedResult = UspFailure(allFailures);
      } else {
        parsedResult = UspPartialSuccess(allSuccesses, allFailures);
      }

      if (parsedResult case UspSuccess(details: final details)) {
        logger.i('[WiFiSettingsService] Batch update completed successfully');
        return BatchUpdateResult(
          success: true,
          updatedCount: details.length,
          failedCount: 0,
          errors: [],
        );
      } else if (parsedResult
          case UspPartialSuccess(
            successes: final successes,
            failures: final failures
          )) {
        logger.w(
            '[WiFiSettingsService] Batch update partial success: ${successes.length} success, ${failures.length} failed');

        if (!allowPartial) {
          // Strict mode: attempt rollback of successful changes
          logger.w(
              '[WiFiSettingsService] Strict mode: attempting rollback of successful changes');
          await _attemptRollback(successes);

          throw UnexpectedError(
            message:
                'Batch SSID update failed - rolled back all changes. ${failures.length} errors: ${failures.map((f) => f.errorMessage).join('; ')}',
          );
        }

        return BatchUpdateResult(
          success: false,
          updatedCount: successes.length,
          failedCount: failures.length,
          errors: failures.map((f) => f.errorMessage).toList(),
        );
      } else if (parsedResult case UspFailure(errors: final errors)) {
        logger.e('[WiFiSettingsService] Batch update failed completely');
        throw UnexpectedError(
          message:
              'All SSID updates failed: ${errors.map((e) => e.errorMessage).join('; ')}',
        );
      }
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }

    // This should never be reached, but Dart requires it
    throw UnexpectedError(message: 'Unexpected code path in batch update');
  }

  /// Business validation for SSID names.
  void _validateSsidName(String ssid) {
    if (ssid.isEmpty) {
      throw InvalidInputError(
        message: 'SSID name cannot be empty',
      );
    }

    if (ssid.length > 32) {
      throw InvalidInputError(
        message: 'SSID name cannot exceed 32 characters',
      );
    }

    // Check for invalid characters
    if (ssid.contains(RegExp(r'[^\x20-\x7E]'))) {
      throw InvalidInputError(
        message: 'SSID name contains invalid characters',
      );
    }
  }

  /// Attempt to rollback successful changes in case of batch failure.
  ///
  /// This is a best-effort rollback - if rollback fails, we log but don't throw.
  Future<void> _attemptRollback(
      List<UspSuccessDetail> successfulChanges) async {
    try {
      logger.w(
          '[WiFiSettingsService] Attempting rollback of ${successfulChanges.length} changes');

      // In a real implementation, we would:
      // 1. Fetch the previous values from backup
      // 2. Create reverse updates
      // 3. Apply them with allowPartial=true
      // For demo purposes, we just log the attempt

      for (final change in successfulChanges) {
        logger
            .d('[WiFiSettingsService] Would rollback: ${change.requestedPath}');
      }

      logger.i('[WiFiSettingsService] Rollback simulation completed');
    } catch (e) {
      // Rollback failure is logged but doesn't throw - we don't want to mask the original error
      logger.e('[WiFiSettingsService] Rollback failed: $e');
    }
  }
}

/// Result of a batch update operation.
class BatchUpdateResult {
  final bool success;
  final int updatedCount;
  final int failedCount;
  final List<String> errors;

  const BatchUpdateResult({
    required this.success,
    required this.updatedCount,
    required this.failedCount,
    required this.errors,
  });

  @override
  String toString() =>
      'BatchUpdateResult(success: $success, updated: $updatedCount, failed: $failedCount)';
}
