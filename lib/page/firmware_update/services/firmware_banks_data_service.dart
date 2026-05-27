import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/generated/firmware_images.g.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_image_ui_model.dart';

final firmwareBanksDataServiceProvider = Provider<FirmwareBanksDataService>(
  (ref) => FirmwareBanksDataService(ref.read(uspClientProvider)!),
);

/// Service layer for fetching firmware bank data.
///
/// Wraps codegen `FirmwareImages.fetch()` to comply with constitution
/// Article V §5.4.3 (no codegen in providers).
class FirmwareBanksDataService {
  final UspClient _usp;

  FirmwareBanksDataService(this._usp);

  /// Fetch all firmware banks from the router.
  Future<List<FirmwareImageUIModel>> fetch() async {
    try {
      final images = await FirmwareImages.fetch(_usp);
      return images.items.map(_toUIModel).toList();
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
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
