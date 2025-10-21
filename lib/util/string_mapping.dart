import 'package:flutter/cupertino.dart';
import 'package:privacy_gui/localization/localization_hook.dart';

/// Maps a connection type string to a [ConnectionTypeData] object with a localized title.
///
/// This function takes a raw connection type string (e.g., 'DHCP', 'PPPoE') and
/// returns a [ConnectionTypeData] object containing the original type and its
/// corresponding human-readable, localized title. If the type is not recognized,
/// it returns a [ConnectionTypeData] object with an empty title.
///
/// [context] The `BuildContext` required to access localized strings.
/// [type] The connection type string to be mapped.
///
/// Returns a [ConnectionTypeData] object.
ConnectionTypeData toConnectionTypeData(BuildContext context, String type) {
  switch (type) {
    case 'DHCP':
      return ConnectionTypeData(
        type: type,
        title: loc(context).connectionTypeDhcp,
      );
    case 'Static':
      return ConnectionTypeData(
        type: type,
        title: loc(context).connectionTypeStatic,
      );
    case 'PPPoE':
      return ConnectionTypeData(
        type: type,
        title: loc(context).connectionTypePppoe,
      );
    case 'PPTP':
      return ConnectionTypeData(
        type: type,
        title: loc(context).connectionTypePptp,
      );
    case 'L2TP':
      return ConnectionTypeData(
        type: type,
        title: loc(context).connectionTypeL2tp,
      );
    case 'Bridge':
      return ConnectionTypeData(
        type: type,
        title: loc(context).connectionTypeBridge,
      );
    case 'Automatic':
      return ConnectionTypeData(
        type: type,
        title: loc(context).connectionTypeAutomatic,
      );
    case 'Pass-through':
      return ConnectionTypeData(
        type: type,
        title: loc(context).connectionTypePassThrough,
      );
    default:
      return ConnectionTypeData(type: type, title: ' ');
  }
}

/// A data class that holds information about a network connection type.
class ConnectionTypeData {
  /// The raw string identifier for the connection type (e.g., 'DHCP').
  final String type;

  /// The localized, human-readable title for the connection type (e.g., 'Automatic IP').
  final String title;

  /// Creates a [ConnectionTypeData] object.
  const ConnectionTypeData({
    required this.type,
    required this.title,
  });
}
