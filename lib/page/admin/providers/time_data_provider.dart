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

  const TimeData({required this.model});

  @override
  List<Object?> get props => [model];
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final timeDataProvider = AsyncNotifierProvider<TimeDataNotifier, TimeData>(
  TimeDataNotifier.new,
);

// ---------------------------------------------------------------------------
// Notifier (NOT autoDispose — shared between dashboard card & admin page)
// ---------------------------------------------------------------------------

class TimeDataNotifier extends AsyncNotifier<TimeData> {
  @override
  Future<TimeData> build() async {
    // No SSE invalidation domain for time settings.
    return _fetch();
  }

  Future<TimeData> _fetch() async {
    final svc = ref.read(uspTimeDataServiceProvider);
    final model = await svc.fetch();

    logger.d('[USP][TimeData] Fetched — '
        'enable: ${model.enable}, status: ${model.status}');

    return TimeData(model: model);
  }
}
