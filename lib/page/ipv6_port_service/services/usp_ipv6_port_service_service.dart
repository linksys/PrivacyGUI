import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/generated/ipv6port_service.g.dart';
import 'package:privacy_gui/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/usp/services/usp_service.dart';
import 'package:privacy_gui/page/ipv6_port_service/models/ipv6_port_service_ui_model.dart';
import 'package:privacy_gui/validator_rules/rules.dart';

final uspIpv6PortServiceServiceProvider = Provider<UspIpv6PortServiceService>(
  (ref) => UspIpv6PortServiceService(ref.read(uspServiceProvider)!),
);

/// Service layer for IPv6 Port Service — encapsulates codegen CRUD + transform + validation.
class UspIpv6PortServiceService {
  final UspService _usp;

  UspIpv6PortServiceService(this._usp);
  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  /// Fetch IPv6 port service rules and transform to UI models.
  Future<List<Ipv6PortServiceRuleUIModel>> fetch() async {
    final data = await Ipv6PortService.fetch(_usp);
    return buildRuleUIModels(data);
  }

  /// Batch save: diff original vs current, execute delete/add/update.
  Future<({int added, int updated, int deleted})> saveBatch({
    required List<Ipv6PortServiceRuleUIModel> original,
    required List<Ipv6PortServiceRuleUIModel> current,
  }) async {
    // 1. Delete (in original, not in current)
    final currentPaths = <String>{
      for (final r in current)
        if (r.instancePath != null) r.instancePath!,
    };
    final toDelete = original
        .where((r) =>
            r.instancePath != null && !currentPaths.contains(r.instancePath))
        .toList();

    for (var i = 0; i < toDelete.length; i++) {
      if (i > 0) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
      await Ipv6PortService.delete(_usp, toDelete[i].instancePath!);
    }

    // 2. Add (instancePath == null → new)
    final toAdd = current.where((r) => r.instancePath == null).toList();

    for (var i = 0; i < toAdd.length; i++) {
      if (i > 0) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
      final r = toAdd[i];
      await Ipv6PortService.add(
        _usp,
        enable: r.enabled,
        description: r.description,
        ipVersion: 6,
        destIp: r.ipv6Address,
        destPort: r.startPort,
        destPortRangeMax: r.endPort,
        protocol: mapDisplayToIana(r.protocol),
        target: 'Accept',
      );
    }

    // 3. Update (same path, different content)
    final originalByPath = <String, Ipv6PortServiceRuleUIModel>{
      for (final r in original)
        if (r.instancePath != null) r.instancePath!: r,
    };

    final toUpdate = <Ipv6PortServiceRuleUpdate>[];
    for (final cur in current) {
      if (cur.instancePath == null) continue;
      final orig = originalByPath[cur.instancePath!];
      if (orig == null) continue;
      if (cur != orig) {
        toUpdate.add(Ipv6PortServiceRuleUpdate(
          instancePath: cur.instancePath!,
          enable: cur.enabled,
          description: cur.description,
          destIp: cur.ipv6Address,
          destPort: cur.startPort,
          destPortRangeMax: cur.endPort,
          protocol: mapDisplayToIana(cur.protocol),
          target: 'Accept',
        ));
      }
    }

    if (toUpdate.isNotEmpty) {
      await Ipv6PortService.updateMany(_usp, toUpdate);
    }

    return (
      added: toAdd.length,
      updated: toUpdate.length,
      deleted: toDelete.length,
    );
  }

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
  static Map<String, String> validateRule({
    required String description,
    required String ipv6Address,
    required String startPort,
    required String endPort,
  }) {
    final errors = <String, String>{};

    if (description.isEmpty) {
      errors['description'] = 'Name is required';
    } else if (!NoSurroundWhitespaceRule().validate(description)) {
      errors['description'] = 'Name must not have leading or trailing spaces';
    } else if (description.length > 32) {
      errors['description'] = 'Name must be 32 characters or less';
    }

    if (ipv6Address.isEmpty) {
      errors['ipv6Address'] = 'IPv6 address is required';
    } else if (!IPv6Rule().validate(ipv6Address)) {
      errors['ipv6Address'] = 'Invalid IPv6 address format';
    } else if (!IPv6WithReservedRule().validate(ipv6Address)) {
      errors['ipv6Address'] = 'Reserved IPv6 address is not allowed';
    }

    final start = int.tryParse(startPort);
    final end = int.tryParse(endPort);

    if (startPort.isEmpty || start == null) {
      errors['startPort'] = 'Start port is required';
    } else if (start < 1 || start > 65535) {
      errors['startPort'] = 'Port must be 1-65535';
    }

    if (endPort.isEmpty || end == null) {
      errors['endPort'] = 'End port is required';
    } else if (end < 1 || end > 65535) {
      errors['endPort'] = 'Port must be 1-65535';
    }

    if (start != null && end != null && end < start) {
      errors['endPort'] = 'End port must be >= start port';
    }

    return errors;
  }
}
