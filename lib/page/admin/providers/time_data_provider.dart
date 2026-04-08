import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/generated/time_settings.g.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/page/_shared/models/time_settings_ui_model.dart';

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
    final usp = ref.read(uspServiceProvider);
    if (usp == null) {
      throw const ServiceNotInitializedError(
          message: 'USP service not available');
    }

    try {
      final ts = await TimeSettings.fetch(usp);

      logger.d('[USP][TimeData] Fetched — '
          'enable: ${ts.enable}, status: ${ts.status}');

      return TimeData(
        model: TimeSettingsUIModel(
          enable: ts.enable,
          status: ts.status,
          currentLocalTime: ts.currentLocalTime,
          localTimeZone: ts.localTimeZone,
          ntpServer1: ts.ntpServer1,
          ntpServer2: ts.ntpServer2,
        ),
      );
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Mutations (atomic — dialog submit → save → re-fetch)
  // ---------------------------------------------------------------------------

  /// Update time settings (enable toggle, NTP servers).
  /// Used by both dashboard card and admin page.
  Future<void> updateTimeSettings({
    bool? enable,
    String? ntpServer1,
    String? ntpServer2,
  }) async {
    final usp = ref.read(uspServiceProvider);
    if (usp == null) {
      throw const ServiceNotInitializedError(
          message: 'USP service not available');
    }

    try {
      await ref.read(uspMutationLockProvider).withLock(() async {
        await TimeSettings.save(
          usp,
          enable: enable,
          ntpServer1: ntpServer1,
          ntpServer2: ntpServer2,
        );
      });
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }

    ref.invalidateSelf();
  }

  /// Update timezone (used by admin timezone edit dialog).
  Future<void> updateTimezone({
    String? localTimeZone,
    String? ntpServer1,
    String? ntpServer2,
    bool? enable,
  }) async {
    final usp = ref.read(uspServiceProvider);
    if (usp == null) {
      throw const ServiceNotInitializedError(
          message: 'USP service not available');
    }

    try {
      await ref.read(uspMutationLockProvider).withLock(() async {
        await TimeSettings.save(
          usp,
          localTimeZone: localTimeZone,
          ntpServer1: ntpServer1,
          ntpServer2: ntpServer2,
          enable: enable,
        );
      });
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }

    ref.invalidateSelf();
  }
}
