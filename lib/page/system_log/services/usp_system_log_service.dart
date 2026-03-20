import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/generated/vendor_log_files.g.dart';
import 'package:privacy_gui/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/usp/services/usp_service.dart';
import 'package:privacy_gui/page/system_log/models/log_file_ui_model.dart';

final uspSystemLogServiceProvider = Provider<UspSystemLogService>(
  (ref) => UspSystemLogService(ref.read(uspServiceProvider)!),
);

/// Service layer for System Log — encapsulates codegen fetch + transform.
class UspSystemLogService {
  final UspService _usp;

  UspSystemLogService(this._usp);

  /// Fetch vendor log files and transform to UI models.
  Future<List<LogFileUIModel>> fetch() async {
    final data = await VendorLogFiles.fetch(_usp);
    return _buildLogFileUIModels(data);
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
