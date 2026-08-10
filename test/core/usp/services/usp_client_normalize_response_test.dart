import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';

/// Regression tests for issue #1184.
///
/// `UspClient._rawGet` used to back-fill every absent non-wildcard requested
/// path with `null` before returning. That silently defeated the codegen
/// required-leaf check (`code: 9998` → `ServiceErrorView`) for models that GET
/// with concrete paths: a back-filled key made `response.containsKey(path)`
/// return true, so the `missing` list stayed empty and 9998 never fired.
///
/// The fix removes the back-fill. These tests pin that behaviour on the pure,
/// testable [UspClient.normalizeGetResponse] seam (the real `_rawGet` cannot be
/// unit-tested directly — its constructor throws off-Web and the WASM client is
/// not injectable, which is exactly why the back-fill was never covered).
void main() {
  group('UspClient.normalizeGetResponse — no back-fill (#1184)', () {
    test('absent concrete path is NOT added to the result', () {
      // The router omitted a requested concrete leaf entirely.
      final result = UspClient.normalizeGetResponse(
        ['Device.DHCPv4.Server.Pool.1.MinAddress'],
        <String, String?>{},
      );

      // The load-bearing assertion: adding `putIfAbsent(path, () => null)` back
      // makes containsKey true and fails this test.
      expect(
        result.containsKey('Device.DHCPv4.Server.Pool.1.MinAddress'),
        isFalse,
      );
      expect(result, isEmpty);
    });

    test('present paths are kept and value-coerced', () {
      final result = UspClient.normalizeGetResponse(
        [
          'Device.DHCPv4.Server.Pool.1.Enable', // bool suffix
          'Device.DHCPv4.Server.Pool.1.MinAddress', // plain string
        ],
        <String, String?>{
          'Device.DHCPv4.Server.Pool.1.Enable': '1',
          'Device.DHCPv4.Server.Pool.1.MinAddress': '192.168.1.100',
        },
      );

      expect(result['Device.DHCPv4.Server.Pool.1.Enable'], isTrue);
      expect(
        result['Device.DHCPv4.Server.Pool.1.MinAddress'],
        '192.168.1.100',
      );
    });

    test(
        'a path present with an empty string stays present (not treated as '
        'missing)', () {
      final result = UspClient.normalizeGetResponse(
        ['Device.DHCPv4.Server.Pool.1.DNSServers'],
        <String, String?>{'Device.DHCPv4.Server.Pool.1.DNSServers': ''},
      );

      // Empty string is a real value → key present, coerced to ''.
      expect(
          result.containsKey('Device.DHCPv4.Server.Pool.1.DNSServers'), isTrue);
      expect(result['Device.DHCPv4.Server.Pool.1.DNSServers'], '');
    });

    test('wildcard request paths never trigger a missing-path warning', () {
      final missing = <String>[];
      // Router expands the wildcard into a concrete instance; the original
      // wildcard path is absent from the response but must be ignored.
      UspClient.normalizeGetResponse(
        ['Device.DNS.Client.Server.*.DNSServer'],
        <String, String?>{'Device.DNS.Client.Server.1.DNSServer': '8.8.8.8'},
        onMissingPath: missing.add,
      );

      expect(missing, isEmpty);
    });

    test(
        'trailing-dot object/table request paths never trigger a missing-path '
        'warning', () {
      final missing = <String>[];
      // A path ending in '.' is an object/table GET (e.g. IPv6Address.); the
      // router expands it into instance paths, so the requested key itself is
      // absent from the response and must NOT be reported as missing.
      UspClient.normalizeGetResponse(
        ['Device.IP.Interface.1.IPv6Address.'],
        <String, String?>{
          'Device.IP.Interface.1.IPv6Address.1.IPAddress': '::1',
        },
        onMissingPath: missing.add,
      );

      expect(missing, isEmpty);
    });

    test('absent concrete path invokes onMissingPath; present one does not',
        () {
      final missing = <String>[];
      UspClient.normalizeGetResponse(
        [
          'Device.DHCPv4.Server.Pool.1.MinAddress', // absent
          'Device.DHCPv4.Server.Pool.1.MaxAddress', // present
        ],
        <String, String?>{
          'Device.DHCPv4.Server.Pool.1.MaxAddress': '192.168.1.200',
        },
        onMissingPath: missing.add,
      );

      expect(missing, ['Device.DHCPv4.Server.Pool.1.MinAddress']);
    });

    test(
        'onMissingPath collects every absent concrete leaf so the caller can '
        'emit a single aggregated warning', () {
      // Underpins _rawGet's aggregation: a partial response with several
      // absent leaves must surface all of them through the callback, so the
      // caller logs one "missing N paths" line instead of one line per path.
      final missing = <String>[];
      UspClient.normalizeGetResponse(
        [
          'Device.DHCPv4.Server.Pool.1.MinAddress', // absent
          'Device.DHCPv4.Server.Pool.1.MaxAddress', // absent
          'Device.DHCPv4.Server.Pool.1.LeaseTime', // absent
          'Device.DHCPv4.Server.Pool.1.Enable', // present
        ],
        <String, String?>{
          'Device.DHCPv4.Server.Pool.1.Enable': '1',
        },
        onMissingPath: missing.add,
      );

      expect(missing, [
        'Device.DHCPv4.Server.Pool.1.MinAddress',
        'Device.DHCPv4.Server.Pool.1.MaxAddress',
        'Device.DHCPv4.Server.Pool.1.LeaseTime',
      ]);
    });
  });

  group('UspClient.isWildcardOnlyRequest — empty-GET log classification', () {
    // An empty GET response to a wildcard-only request means a multi-instance
    // table has zero rows (a normal outcome), so _rawGet logs it at debug
    // instead of warn. This seam is what that decision is pinned on, because
    // _rawGet itself is not unit-testable (see the file header).
    test('all-wildcard request is classified as wildcard-only', () {
      expect(
        UspClient.isWildcardOnlyRequest([
          'Device.Firewall.DMZ.*.Enable',
          'Device.NAT.PortMapping.*.Protocol',
        ]),
        isTrue,
      );
    });

    test('a single concrete path makes the request NOT wildcard-only', () {
      expect(
        UspClient.isWildcardOnlyRequest([
          'Device.Firewall.DMZ.*.Enable', // wildcard
          'Device.GRE.Tunnel.1.RemoteEndpoints', // concrete → must still warn
        ]),
        isFalse,
      );
    });

    test('all-concrete request is NOT wildcard-only', () {
      expect(
        UspClient.isWildcardOnlyRequest(
          ['Device.GRE.Tunnel.1.RemoteEndpoints'],
        ),
        isFalse,
      );
    });

    test('an empty path list is NOT treated as a wildcard-only request', () {
      // Nothing was requested — an empty response is not a "no rows" table
      // outcome, so it should not be silently downgraded.
      expect(UspClient.isWildcardOnlyRequest(const []), isFalse);
    });
  });

  group('Codegen required-leaf contract is reachable again (#1184)', () {
    // Ties the normalize seam to a real concrete-path model. When a required
    // leaf is omitted, normalizeGetResponse leaves it absent, so the model's
    // `containsKey` required-check adds it to `missing` and throws 9998.
    // (Before the fix the back-fill made this branch unreachable.)
    const instancePath = 'Device.IP.Interface.1.';

    List<String> lanPaths() => [
          '${instancePath}IPv4Address.1.IPAddress',
          '${instancePath}IPv4Address.1.SubnetMask',
          'Device.DHCPv4.Server.Pool.1.Enable',
          'Device.DHCPv4.Server.Pool.1.MinAddress',
          'Device.DHCPv4.Server.Pool.1.MaxAddress',
          'Device.DHCPv4.Server.Pool.1.LeaseTime',
          'Device.DHCPv4.Server.Pool.1.DNSServers',
          'Device.DeviceInfo.HostName',
          '${instancePath}IPv6Enable',
        ];

    Map<String, String?> fullLanResponse() => <String, String?>{
          '${instancePath}IPv4Address.1.IPAddress': '192.168.1.1',
          '${instancePath}IPv4Address.1.SubnetMask': '255.255.255.0',
          'Device.DHCPv4.Server.Pool.1.Enable': '1',
          'Device.DHCPv4.Server.Pool.1.MinAddress': '192.168.1.100',
          'Device.DHCPv4.Server.Pool.1.MaxAddress': '192.168.1.200',
          'Device.DHCPv4.Server.Pool.1.LeaseTime': '86400',
          'Device.DHCPv4.Server.Pool.1.DNSServers': '8.8.8.8',
          'Device.DeviceInfo.HostName': 'router',
          '${instancePath}IPv6Enable': 'true',
        };

    test(
        'normalized response omitting a required leaf makes the codegen check '
        'see it as missing (→ 9998)', () {
      final withMissing = fullLanResponse()
        ..remove('Device.DHCPv4.Server.Pool.1.MinAddress');

      final normalized =
          UspClient.normalizeGetResponse(lanPaths(), withMissing);

      // This is precisely the predicate the generated `_fromResponse` evaluates;
      // false here means `missing.add(...)` runs and 9998 is thrown.
      expect(
        normalized.containsKey('Device.DHCPv4.Server.Pool.1.MinAddress'),
        isFalse,
      );
    });

    test(
        'complete normalized response keeps every required leaf present '
        '(no false 9998)', () {
      final normalized =
          UspClient.normalizeGetResponse(lanPaths(), fullLanResponse());

      // Every required leaf the generated check inspects must be present, so
      // `missing` stays empty and the model builds normally.
      for (final path in lanPaths()) {
        expect(normalized.containsKey(path), isTrue,
            reason: 'required leaf $path must survive normalization');
      }
      // Spot-check coercion feeding the generated assignments.
      expect(normalized['Device.DHCPv4.Server.Pool.1.Enable'], isTrue);
      expect(normalized['Device.DHCPv4.Server.Pool.1.MinAddress'],
          '192.168.1.100');
    });
  });
}
