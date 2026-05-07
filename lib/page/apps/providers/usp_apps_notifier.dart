import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/apps/models/app_info_ui_model.dart';
import 'package:privacy_gui/page/apps/services/usp_apps_service.dart';

final uspAppsProvider =
    AsyncNotifierProvider.autoDispose<UspAppsNotifier, UspAppsState>(
  UspAppsNotifier.new,
);

class UspAppsState {
  final List<AppInfoUIModel> apps;
  final Set<String> recentlyInstalledNames;

  const UspAppsState({
    this.apps = const [],
    this.recentlyInstalledNames = const {},
  });

  bool isNew(String appName) => recentlyInstalledNames.contains(appName);
}

class UspAppsNotifier extends AutoDisposeAsyncNotifier<UspAppsState> {
  Timer? _pollTimer;
  Set<String> _knownAppNames = {};
  final Set<String> _recentNames = {};

  @override
  Future<UspAppsState> build() async {
    ref.onDispose(() {
      _pollTimer?.cancel();
    });

    final svc = ref.read(uspAppsServiceProvider);
    final apps = await svc.fetchApps();

    // Seed known app names (first load — no NEW badges)
    if (_knownAppNames.isEmpty) {
      _knownAppNames = apps.map((a) => a.name).toSet();
    }

    // Start polling for changes
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _pollForChanges();
    });

    logger.d('[USP][Apps]: Loaded ${apps.length} apps, '
        'known=${_knownAppNames.length}, recent=${_recentNames.length}');

    return UspAppsState(
      apps: apps,
      recentlyInstalledNames: Set.from(_recentNames),
    );
  }

  /// Poll /api/apps.json directly and compare with known set.
  Future<void> _pollForChanges() async {
    try {
      final svc = ref.read(uspAppsServiceProvider);
      final freshApps = await svc.fetchApps();
      final freshNames = freshApps.map((a) => a.name).toSet();

      // Detect newly added apps
      final added = freshNames.difference(_knownAppNames);
      // Detect removed apps
      final removed = _knownAppNames.difference(freshNames);

      if (added.isEmpty && removed.isEmpty) return;

      logger.d('[USP][Apps]: Change detected — '
          'added=$added, removed=$removed');

      // Mark added apps as "NEW"
      for (final name in added) {
        _recentNames.add(name);
        // Auto-clear "NEW" badge after 60 seconds
        Future.delayed(const Duration(seconds: 60), () {
          _recentNames.remove(name);
          if (state.hasValue) {
            state = AsyncData(UspAppsState(
              apps: state.value!.apps,
              recentlyInstalledNames: Set.from(_recentNames),
            ));
          }
        });
      }

      // Remove cleared names from recent
      _recentNames.removeAll(removed);

      // Update known set
      _knownAppNames = freshNames;

      // Update state with fresh data
      state = AsyncData(UspAppsState(
        apps: freshApps,
        recentlyInstalledNames: Set.from(_recentNames),
      ));
    } catch (e) {
      // Polling failure is non-fatal — just log and continue
      logger.w('[USP][Apps]: Poll error: $e');
    }
  }
}
