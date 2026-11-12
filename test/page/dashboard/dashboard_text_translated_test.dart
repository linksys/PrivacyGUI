import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';

import '../../util/arb_keys_read.dart';

/// #1312: every ARB key the mascot and the card and preset names read is
/// translated in every locale.
///
/// gen-l10n back-fills a key a locale lacks with the English template, so a
/// key added to `app_en.arb` alone still compiles and still reads English —
/// which is the defect #1312 removes. Nothing else would fail.
///
/// The keys are read off the source rather than listed here, so a key a later
/// change starts reading is checked without anyone remembering to add it. That
/// covers reused keys too: `security`, `ipv4Firewall` and `ipv6Firewall` were
/// missing from several locales before #1312 needed them.
const _sources = [
  'lib/page/dashboard/mascot',
  'lib/page/dashboard/views/components/card_and_preset_names.dart',
];

void main() {
  test('every key the dashboard names and the mascot read is in every locale',
      () {
    final keys = arbKeysReadBy(_sources);

    final template =
        jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map;
    expect(keys.where((k) => !template.containsKey(k)), isEmpty,
        reason: 'the pattern picked up something that is not a key');
    expect(keys.length, greaterThan(100),
        reason: 'the scan finds too few keys; it is not reading the sources '
            'it claims to');

    final arbs = Directory('lib/l10n')
        .listSync()
        .whereType<File>()
        .where((f) => RegExp(r'app_\w+\.arb$').hasMatch(f.path))
        .toList();
    expect(arbs, hasLength(AppLocalizations.supportedLocales.length));

    final missing = <String>[];
    for (final arb in arbs) {
      final entries = jsonDecode(arb.readAsStringSync()) as Map;
      final absent = keys.where((k) => entries[k] is! String).toList()..sort();
      if (absent.isNotEmpty) {
        missing.add('${arb.path}: ${absent.join(', ')}');
      }
    }
    expect(missing, isEmpty);
  });
}
