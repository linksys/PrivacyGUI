import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/_shared/models/wan_status_ui_model.dart';
import 'package:privacy_gui/page/internet_settings/services/usp_wan_data_service.dart';

// ── Data Model ──

class WanData extends Equatable {
  final WanStatusUIModel model;

  const WanData({required this.model});

  @override
  List<Object?> get props => [model];
}

// ── Provider ──

/// Layer 1 data provider for WAN status.
///
/// No SSE invalidation domain for WAN — manual refresh only.
final wanDataProvider =
    AsyncNotifierProvider<WanDataNotifier, WanData>(WanDataNotifier.new);

// ── Notifier (NOT autoDispose) ──

class WanDataNotifier extends AsyncNotifier<WanData> {
  @override
  Future<WanData> build() async {
    return _fetch();
  }

  Future<WanData> _fetch() async {
    final svc = ref.read(uspWanDataServiceProvider);
    final model = await svc.fetch();

    logger.d('[USP][WanData] Fetched — ip=${model.ipAddress}, '
        'isUp=${model.isUp}, gateway=${model.gateway}');
    return WanData(model: model);
  }
}
