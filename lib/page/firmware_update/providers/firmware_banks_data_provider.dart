import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/firmware_images.g.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_image_ui_model.dart';

// ── Data Model ──

class FirmwareBanksData extends Equatable {
  final List<FirmwareImageUIModel> banks;

  const FirmwareBanksData({required this.banks});

  /// Active bank (status == 'Active').
  FirmwareImageUIModel? get activeBank =>
      banks.where((b) => b.isActive).firstOrNull;

  /// Available bank for flashing (available && !isActive).
  FirmwareImageUIModel? get availableBank =>
      banks.where((b) => b.available && !b.isActive).firstOrNull;

  @override
  List<Object?> get props => [banks];
}

// ── Provider ──

/// Layer 1 data provider for firmware banks (FirmwareImages).
///
/// This is the **single source of truth** for FirmwareImages data.
/// [systemInfoDataProvider] listens to this provider and uses its data
/// rather than fetching FirmwareImages independently.
final firmwareBanksDataProvider =
    AsyncNotifierProvider<FirmwareBanksDataNotifier, FirmwareBanksData>(
  FirmwareBanksDataNotifier.new,
);

// ── Notifier (NOT autoDispose) ──

class FirmwareBanksDataNotifier extends AsyncNotifier<FirmwareBanksData> {
  @override
  Future<FirmwareBanksData> build() async => _fetch();

  /// Force refetch and update state. Returns fresh data.
  Future<FirmwareBanksData> refresh() async {
    logger.d('[FirmwareUpdate] banks: refresh() called, setting AsyncLoading');
    state = const AsyncLoading();
    final data = await _fetch();
    logger.d(
        '[FirmwareUpdate] banks: refresh() fetch complete, setting AsyncData');
    state = AsyncData(data);
    return data;
  }

  Future<FirmwareBanksData> _fetch() async {
    logger.d('[FirmwareUpdate] banks: _fetch() starting...');
    final usp = ref.read(uspClientProvider);
    if (usp == null) {
      logger.e('[FirmwareUpdate] banks: uspClientProvider is null!');
      throw StateError('UspClient is null - session may not be restored');
    }
    logger.d('[FirmwareUpdate] banks: calling FirmwareImages.fetch()...');
    final images = await FirmwareImages.fetch(usp).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        logger.e(
            '[FirmwareUpdate] banks: FirmwareImages.fetch() timeout after 30s');
        throw TimeoutException('FirmwareImages.fetch timeout');
      },
    );
    final banks = images.items.map(_toUIModel).toList();

    logger.d('[FirmwareUpdate] banks: fetched ${banks.length} banks, '
        'active=${banks.where((b) => b.isActive).firstOrNull?.version}');

    return FirmwareBanksData(banks: banks);
  }

  FirmwareImageUIModel _toUIModel(FirmwareImage img) => FirmwareImageUIModel(
        instance: _instanceFromPath(img.instancePath),
        instancePath: img.instancePath,
        name: img.name,
        version: img.version,
        status: img.status,
        available: img.available,
      );

  int _instanceFromPath(String path) {
    final trimmed =
        path.endsWith('.') ? path.substring(0, path.length - 1) : path;
    final lastDot = trimmed.lastIndexOf('.');
    if (lastDot < 0) return 0;
    return int.tryParse(trimmed.substring(lastDot + 1)) ?? 0;
  }
}
