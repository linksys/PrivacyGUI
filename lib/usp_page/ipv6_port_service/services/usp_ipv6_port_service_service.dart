import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/generated/ipv6port_service.g.dart';
import 'package:privacy_gui/usp_page/ipv6_port_service/models/ipv6_port_service_ui_model.dart';

final uspIpv6PortServiceServiceProvider = Provider<UspIpv6PortServiceService>(
  (ref) => UspIpv6PortServiceService(),
);

/// Transforms codegen [Ipv6PortService] data into [Ipv6PortServiceRuleUIModel]
/// list.
///
/// Responsibilities:
/// - Filter by IPVersion == 6 (exclude IPv4 and system rules)
/// - Map IANA protocol numbers to display names
/// - Validate rule fields
class UspIpv6PortServiceService {
  // ---------------------------------------------------------------------------
  // Protocol IANA <-> display mapping
  // ---------------------------------------------------------------------------

  static const protocolOptions = ['TCP', 'UDP', 'Both'];

  static const _ianaToDisplay = {
    6: 'TCP',
    17: 'UDP',
    255: 'Both',
  };

  static const _displayToIana = {
    'TCP': 6,
    'UDP': 17,
    'Both': 255,
  };

  /// Convert display name to IANA protocol number.
  int mapDisplayToIana(String display) => _displayToIana[display] ?? 255;

  /// Convert IANA protocol number to display name.
  String mapIanaToDisplay(int iana) => _ianaToDisplay[iana] ?? 'Both';

  // ---------------------------------------------------------------------------
  // Build UI models
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // System rule filtering
  // ---------------------------------------------------------------------------

  /// System/firmware rules have CreationDate set to the zero epoch value.
  /// User-created rules always have a real timestamp.
  static const _systemRuleCreationDate = '0001-01-01T00:00:00Z';

  /// Filter to IPv6 user rules (IPVersion == 6, Target == Accept,
  /// not a system rule by CreationDate) and transform to UI models.
  List<Ipv6PortServiceRuleUIModel> buildRuleUIModels(Ipv6PortService data) {
    return data.items
        .where((r) =>
            r.ipVersion == 6 &&
            r.target == 'Accept' &&
            r.creationDate != _systemRuleCreationDate)
        .map((r) => Ipv6PortServiceRuleUIModel(
              instancePath: r.instancePath,
              enabled: r.enable,
              description: r.description,
              ipv6Address: r.destIp,
              protocol: mapIanaToDisplay(r.protocol),
              startPort: r.destPort,
              endPort: r.destPortRangeMax,
            ))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  /// Validate rule fields. Returns a map of field key -> error message.
  Map<String, String> validateRule({
    required String description,
    required String ipv6Address,
    required String startPort,
    required String endPort,
  }) {
    final errors = <String, String>{};

    if (description.isEmpty) {
      errors['description'] = 'Name is required';
    } else if (description.length > 32) {
      errors['description'] = 'Name must be 32 characters or less';
    }

    if (ipv6Address.isEmpty) {
      errors['ipv6Address'] = 'IPv6 address is required';
    }

    final start = int.tryParse(startPort);
    final end = int.tryParse(endPort);

    if (startPort.isEmpty || start == null) {
      errors['startPort'] = 'Start port is required';
    } else if (start < 0 || start > 65535) {
      errors['startPort'] = 'Port must be 0-65535';
    }

    if (endPort.isEmpty || end == null) {
      errors['endPort'] = 'End port is required';
    } else if (end < 0 || end > 65535) {
      errors['endPort'] = 'Port must be 0-65535';
    }

    if (start != null && end != null && end < start) {
      errors['endPort'] = 'End port must be >= start port';
    }

    return errors;
  }
}
