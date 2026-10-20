import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/generated/ipv6port_service.g.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/_shared/services/batch_tally.dart';
import 'package:privacy_gui/page/ipv6_port_service/models/ipv6_port_service_page_data.dart';
import 'package:privacy_gui/page/ipv6_port_service/models/ipv6_port_service_ui_model.dart';

final uspIpv6PortServiceServiceProvider = Provider<UspIpv6PortServiceService>(
  (ref) => UspIpv6PortServiceService(ref.read(uspClientProvider)!),
);

/// Service layer for IPv6 Port Service — encapsulates codegen CRUD + transform + validation.
class UspIpv6PortServiceService {
  final UspClient _usp;

  UspIpv6PortServiceService(this._usp);
  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  /// Fetch IPv6 port service rules and transform to UI models.
  Future<List<Ipv6PortServiceRuleUIModel>> fetch() async =>
      (await fetchPage()).rules;

  /// Fetch the rules the page lists, with the descriptions of every firewall
  /// rule it does not list, which the rule dialog checks a description
  /// against.
  Future<Ipv6PortServicePageData> fetchPage() async {
    try {
      final data = await Ipv6PortService.fetch(_usp);
      return Ipv6PortServicePageData(
        rules: buildRuleUIModels(data),
        hiddenRuleDescriptions: {
          for (final r in data.items)
            if (!_isListed(r) && r.description.isNotEmpty) r.description,
        },
      );
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Batch save: diff original vs current, then Delete, Set and Add.
  ///
  /// Every step runs; any failed step fails the batch once they are done
  /// ([UspCompleteFailureError] when every step failed, otherwise
  /// [UspPartialFailureError]), with the router's message. FW refuses a rule
  /// that breaks FWDEV#204's checks (feed_usp#50), and the batch used to log
  /// that and report success. Counts are returned only when every step
  /// succeeded.
  Future<({int added, int updated, int deleted})> saveBatch({
    required List<Ipv6PortServiceRuleUIModel> original,
    required List<Ipv6PortServiceRuleUIModel> current,
  }) async {
    try {
      final tally = BatchTally('[IPv6PortService]');

      // 1. Delete (in original, not in current)
      final currentPaths = <String>{
        for (final r in current)
          if (r.instancePath != null) r.instancePath!,
      };
      final toDelete = original
          .where((r) =>
              r.instancePath != null && !currentPaths.contains(r.instancePath))
          .toList();

      // Delete in reverse instance order to avoid firmware renumbering issues
      for (final r in toDelete.reversed) {
        final result = await Ipv6PortService.delete(_usp, [r.instancePath!]);
        tally.record('Delete', UspResultParser.parseDeleteResult(result));
      }

      // 2. Update (same path, different content), before Add: a rule renamed
      // or moved off a port in this save frees it for a rule added in it,
      // and FW checks an Add against the rules as they are when it arrives.
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
            // FW runs its checks when Target is written, so it goes last.
            target: 'Accept',
          ));
        }
      }

      if (toUpdate.isNotEmpty) {
        final result = await Ipv6PortService.update(_usp, toUpdate);
        tally.record('Update', UspResultParser.parseSetResult(result));
      }

      // 3. Add (instancePath == null → new)
      final toAdd = current.where((r) => r.instancePath == null).toList();
      if (toAdd.isNotEmpty) {
        final result = await Ipv6PortService.add(
          _usp,
          toAdd
              .map((r) => {
                    'Enable': r.enabled,
                    'Description': r.description,
                    'IPVersion': 6,
                    'DestIP': r.ipv6Address,
                    'DestPort': r.startPort,
                    'DestPortRangeMax': r.endPort,
                    'Protocol': mapDisplayToIana(r.protocol),
                    // FW runs its checks when Target is written, so it goes
                    // last.
                    'Target': 'Accept',
                  })
              .toList(),
        );
        tally.record('Add', UspResultParser.parseAddResult(result));
      }

      tally.throwIfAnyFailed();

      return (
        added: toAdd.length,
        updated: toUpdate.length,
        deleted: toDelete.length,
      );
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Protocol IANA <-> display mapping
  // ---------------------------------------------------------------------------

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

  /// System/firmware rules have CreationDate set to the zero epoch value
  /// (`0001-01-01T00:00:00Z`). User-created rules always have a real timestamp.
  static final _systemRuleCreationDate = DateTime.parse('0001-01-01T00:00:00Z');

  /// Filter to IPv6 user rules (IPVersion == 6, Target == Accept,
  /// not a system rule by CreationDate) and transform to UI models.
  List<Ipv6PortServiceRuleUIModel> buildRuleUIModels(Ipv6PortService data) {
    return data.items
        .where(_isListed)
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

  static bool _isListed(Ipv6PortServiceRule r) =>
      r.ipVersion == 6 &&
      r.target == 'Accept' &&
      r.creationDate != _systemRuleCreationDate;
}
