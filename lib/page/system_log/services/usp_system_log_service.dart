import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/generated/vendor_log_files.g.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/system_log/models/log_file_ui_model.dart';

final uspSystemLogServiceProvider = Provider<UspSystemLogService>(
  (ref) => UspSystemLogService(ref.read(uspClientProvider)!),
);

/// Service layer for System Log — encapsulates codegen fetch + transform.
class UspSystemLogService {
  final UspClient _usp;

  UspSystemLogService(this._usp);

  /// Fetch vendor log files and transform to UI models.
  Future<List<LogFileUIModel>> fetch() async {
    try {
      final data = await VendorLogFiles.fetch(_usp);
      return _buildLogFileUIModels(data);
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  List<LogFileUIModel> _buildLogFileUIModels(VendorLogFiles data) {
    return data.items
        .map(
          (f) => LogFileUIModel(
            instancePath: f.instancePath,
            name: f.name,
            maximumSize: f.maximumSize,
            persistent: f.persistent,
          ),
        )
        .toList();
  }
}
