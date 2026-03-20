import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/system_log/models/log_file_ui_model.dart';
import 'package:privacy_gui/page/system_log/services/usp_system_log_service.dart';

final uspSystemLogProvider = AsyncNotifierProvider.autoDispose<
    UspSystemLogNotifier, List<LogFileUIModel>>(
  UspSystemLogNotifier.new,
);

class UspSystemLogNotifier
    extends AutoDisposeAsyncNotifier<List<LogFileUIModel>> {
  @override
  Future<List<LogFileUIModel>> build() async {
    final svc = ref.read(uspSystemLogServiceProvider);
    return svc.fetch();
  }
}
