import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/_shared/models/lan_info_ui_model.dart';
import 'package:privacy_gui/page/local_network/services/usp_lan_data_service.dart';

// ── Data Model ──

class LanData extends Equatable {
  final LanInfoUIModel model;

  const LanData({required this.model});

  const LanData.empty()
      : model = const LanInfoUIModel(
          ipAddress: '',
          subnetMask: '',
          dhcpEnabled: false,
          minAddress: '',
          maxAddress: '',
        );

  @override
  List<Object?> get props => [model];
}

// ── Provider ──

final lanDataProvider =
    AsyncNotifierProvider<LanDataNotifier, LanData>(LanDataNotifier.new);

// ── Notifier (NOT autoDispose) ──

class LanDataNotifier extends AsyncNotifier<LanData> {
  @override
  Future<LanData> build() async {
    // No SSE invalidation domain for LAN info.
    return _fetch();
  }

  Future<LanData> _fetch() async {
    final svc = ref.read(uspLanDataServiceProvider);
    final model = await svc.fetch();

    logger.d('[USP][LanData]: Fetched — ip=${model.ipAddress}, '
        'dhcp=${model.dhcpEnabled}, ipv6=${model.ipv6Enabled}');
    return LanData(model: model);
  }
}
