import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/dmz.g.dart';
import 'package:privacy_gui/generated/firewall_chain_rules.g.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/core/usp/providers/usp_service_provider.dart';

// ---------------------------------------------------------------------------
// Data Model (Layer 1 — raw codegen data)
// ---------------------------------------------------------------------------

class FirewallData extends Equatable {
  final FirewallChainRules chainRules;
  final Dmz dmzEntries;

  const FirewallData({
    required this.chainRules,
    required this.dmzEntries,
  });

  const FirewallData.empty()
      : chainRules = const FirewallChainRules(items: []),
        dmzEntries = const Dmz(items: []);

  @override
  List<Object?> get props => [chainRules, dmzEntries];
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final firewallDataProvider =
    AsyncNotifierProvider<FirewallDataNotifier, FirewallData>(
  FirewallDataNotifier.new,
);

// ---------------------------------------------------------------------------
// Notifier (NOT autoDispose — persists for dashboard card lifetime)
// ---------------------------------------------------------------------------

class FirewallDataNotifier extends AsyncNotifier<FirewallData> {
  Timer? _debounce;

  @override
  Future<FirewallData> build() async {
    // SSE: listen for firewall / DMZ domain changes → debounce → re-fetch
    ref.listen(sseInvalidationProvider, (prev, next) {
      final domain = next.valueOrNull;
      if (domain == InvalidationDomain.firewallRules ||
          domain == InvalidationDomain.dmz) {
        _debouncedInvalidate();
      }
    });

    ref.onDispose(() => _debounce?.cancel());

    return _fetch();
  }

  Future<FirewallData> _fetch() async {
    final usp = ref.read(uspServiceProvider);
    if (usp == null) throw StateError('USP service not available');

    final results = await Future.wait([
      FirewallChainRules.fetch(usp),
      Dmz.fetch(usp),
    ]);

    final data = FirewallData(
      chainRules: results[0] as FirewallChainRules,
      dmzEntries: results[1] as Dmz,
    );

    logger.d('[USP][FirewallData] Fetched — '
        'rules: ${data.chainRules.items.length}, '
        'dmz: ${data.dmzEntries.items.length}');

    return data;
  }

  void _debouncedInvalidate() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.invalidateSelf();
    });
  }
}
