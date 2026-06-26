import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/generated/time_settings.g.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/_shared/models/time_settings_ui_model.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final uspTimeDataServiceProvider = Provider<UspTimeDataService>(
  (ref) {
    final usp = ref.read(uspClientProvider);
    if (usp == null) {
      throw const ServiceNotInitializedError(
          detail: 'USP service not available');
    }
    return UspTimeDataService(usp);
  },
);

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Stateless L1 Service for fetching time settings data.
///
/// Owns the codegen call and error mapping for [timeDataProvider].
class UspTimeDataService {
  final UspClient _usp;

  UspTimeDataService(this._usp);

  /// Fetches time settings and returns a [TimeSettingsUIModel].
  Future<TimeSettingsUIModel> fetch() async {
    try {
      final ts = await TimeSettings.fetch(_usp);
      return TimeSettingsUIModel(
        enable: ts.enable,
        status: ts.status,
        currentLocalTime: ts.currentLocalTime,
        localTimeZone: ts.localTimeZone,
        ntpServer1: ts.ntpServer1,
        ntpServer2: ts.ntpServer2,
      );
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }
}
