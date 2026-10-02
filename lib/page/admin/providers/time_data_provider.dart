import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/_shared/models/time_settings_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/timezone_definitions.dart';
import 'package:privacy_gui/page/_shared/models/timezone_info.dart';
import 'package:privacy_gui/page/admin/services/usp_time_data_service.dart';

// ---------------------------------------------------------------------------
// Data Model (Layer 1 — UI model only)
// ---------------------------------------------------------------------------

class TimeData extends Equatable with DiagnosticLoggable {
  final TimeSettingsUIModel model;
  final DateTime fetchedAt;

  TimeData({required this.model}) : fetchedAt = DateTime.now();

  @override
  String get diagnosticName => 'TimeData';

  @override
  Map<String, Object?> get namedProps => {
        'model': model,
        'fetchedAt': fetchedAt,
      };
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final timeDataProvider = AsyncNotifierProvider<TimeDataNotifier, TimeData>(
  TimeDataNotifier.new,
);

/// The device's zone catalogue (linksys/FWDEV#198): the list the timezone edit
/// dialog offers, and the list the cards resolve the current zone against — one
/// list for all three, so they cannot disagree.
///
/// Not autoDispose, like the other L1 providers here: the catalogue is fixed at
/// firmware build time, so it is read once and reused. Never errors — the
/// service falls back to the built-in table on an empty or failed read, and so
/// does this provider when the service itself cannot be built — so a consumer
/// needs no error path of its own.
final timeZoneCatalogueProvider = FutureProvider<List<TimeZoneInfo>>((ref) {
  try {
    return ref.read(uspTimeDataServiceProvider).fetchZones();
  } on ServiceError {
    return kTimeZoneDefinitions;
  }
});

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

    return TimeData(model: model);
  }
}
