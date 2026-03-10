import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/generated/dmz.g.dart';
import 'package:privacy_gui/usp_page/dmz/models/dmz_ui_model.dart';

final uspDmzServiceProvider = Provider<UspDmzService>(
  (ref) => UspDmzService(),
);

/// Transforms codegen [Dmz] data into [DmzUIModel] for the view layer.
///
/// DMZ is multi-instance on the router but practically only 0-1 entries.
/// This service treats the first entry as "the" DMZ configuration.
class UspDmzService {
  /// Build a [DmzUIModel] from codegen [Dmz] collection.
  ///
  /// If no entries exist, returns a disabled model.
  DmzUIModel buildUIModel(Dmz data) {
    if (data.items.isEmpty) return const DmzUIModel.disabled();
    final entry = data.items.first;
    return DmzUIModel(
      isEnabled: entry.enable,
      destIp: entry.destIp,
      sourceType: _parseSourceType(entry.sourcePrefix),
      sourcePrefix: entry.sourcePrefix,
    );
  }

  /// Determine source type from the CIDR string.
  DmzSourceType _parseSourceType(String prefix) {
    if (prefix.isEmpty || prefix == '0.0.0.0/0') {
      return DmzSourceType.any;
    }
    return DmzSourceType.cidr;
  }
}
