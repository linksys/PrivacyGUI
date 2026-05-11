import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/_shared/models/time_settings_ui_model.dart';
import 'package:privacy_gui/page/admin/services/usp_time_data_service.dart';

// ---------------------------------------------------------------------------
// Data Model (Layer 1 — UI model only)
// ---------------------------------------------------------------------------

class TimeData extends Equatable {
  final TimeSettingsUIModel model;
  final DateTime fetchedAt;

  TimeData({required this.model}) : fetchedAt = DateTime.now();

  @override
  List<Object?> get props => [model, fetchedAt];
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final timeDataProvider = AsyncNotifierProvider<TimeDataNotifier, TimeData>(
  TimeDataNotifier.new,
);

// ---------------------------------------------------------------------------
// Notifier (NOT autoDispose — dashboard card stays mounted across tab switches)
// ---------------------------------------------------------------------------

class TimeDataNotifier extends AsyncNotifier<TimeData> {
  @override
  Future<TimeData> build() async {
    return _fetch();
  }

  Future<TimeData> _fetch() async {
    final svc = ref.read(uspTimeDataServiceProvider);
    final model = await svc.fetch();

    logger.d('[USP][TimeData]: Fetched — '
        'enable: ${model.enable}, status: ${model.status}');

    return TimeData(model: model);
  }
}
