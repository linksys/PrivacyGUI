import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/generated/vendor_log_files.g.dart';
import 'package:privacy_gui/usp_page/system_log/models/log_file_ui_model.dart';

final uspSystemLogServiceProvider = Provider<UspSystemLogService>(
  (ref) => UspSystemLogService(),
);

/// Transforms codegen VendorLogFiles data into presentation-layer UI Models.
class UspSystemLogService {
  List<LogFileUIModel> buildLogFileUIModels(VendorLogFiles data) {
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
