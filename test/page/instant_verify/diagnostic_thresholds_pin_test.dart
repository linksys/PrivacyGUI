import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

/// The vendored threshold table must be byte-identical to the canonical file
/// at the ai-msdm commit recorded in `thresholds.v0.source.json`
/// (linksys/linksys-ai-msdm#745). A hand edit to the copy fails here; a newer
/// canonical table is detected by `tools/instant_test/check_thresholds_sync.sh`.
void main() {
  const dir = 'test/page/instant_verify/contracts';

  test('the vendored table matches the sha256 recorded for its ai-msdm commit',
      () {
    final source = jsonDecode(File('$dir/thresholds.v0.source.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final canonical = source['canonical'] as Map<String, dynamic>;
    expect(canonical['repo'], 'linksys/linksys-ai-msdm');
    expect(canonical['path'], 'docs/contracts/thresholds.v0.json');
    expect(canonical['ref'], matches(RegExp(r'^[0-9a-f]{40}$')),
        reason: 'pin a full commit, never a branch');
    final bytes = File('$dir/thresholds.v0.json').readAsBytesSync();
    expect(sha256.convert(bytes).toString(), source['sha256'],
        reason: 'thresholds.v0.json was edited by hand or re-vendored without '
            'updating thresholds.v0.source.json; re-vendor with '
            'tools/instant_test/check_thresholds_sync.sh --update');
  });
}
