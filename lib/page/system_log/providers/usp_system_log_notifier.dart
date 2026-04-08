import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
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
    try {
      final svc = ref.read(uspSystemLogServiceProvider);
      return await svc.fetch();
    } on ServiceError catch (e) {
      logger.e('[USP][SystemLog] Fetch failed', error: e);
      rethrow;
    }
  }
}
