import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/generated/vendor_log_files.g.dart';
import 'package:privacy_gui/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/usp_page/system_log/models/log_file_ui_model.dart';
import 'package:privacy_gui/usp_page/system_log/services/usp_system_log_service.dart';

final uspSystemLogProvider = AsyncNotifierProvider.autoDispose<
    UspSystemLogNotifier, List<LogFileUIModel>>(
  UspSystemLogNotifier.new,
);

class UspSystemLogNotifier
    extends AutoDisposeAsyncNotifier<List<LogFileUIModel>> {
  @override
  Future<List<LogFileUIModel>> build() async {
    final usp = ref.watch(uspServiceProvider);
    if (usp == null) throw StateError('USP service not available');

    final data = await VendorLogFiles.fetch(usp);
    final svc = ref.read(uspSystemLogServiceProvider);
    return svc.buildLogFileUIModels(data);
  }
}
