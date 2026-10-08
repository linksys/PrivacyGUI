// Every Wi-Fi write in `lib/` runs under `runWifiWriteWithRecovery` (#1499).
//
// Every Wi-Fi write reloads all the radios on FL-WRT 2.0, so each one has to run
// under one recovery entered before it is sent: otherwise the reload drops the
// event stream mid-write and the shell puts up a "Connection lost" of its own,
// the dashboard's polling times out against the reloading router, and the
// page's own report lands before the router can be read. Bench 2026-10-07 found
// the page save fixed and the dashboard's toggle and channel writes still
// bypassing it — each a right line of code that only one call site had.
//
// WHY A SOURCE SCAN. The risk is the call site that does not exist yet: a third
// dashboard control, or a card on another page, calling the notifier straight.
// Same corpus rules as `session_entry_call_sites_test.dart`.
//
// The page save (`UspWifiSettingsView._onSave`) goes through the dirty-guard
// `save()`, a name too common to census; its flow is pinned by
// `usp_wifi_settings_router_away_test.dart` instead.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _notifier =
    'lib/page/wifi_settings/providers/usp_wifi_settings_provider.dart';

void main() {
  late final Map<String, String> sources = {
    for (final f in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.startsWith('lib/l10n/')))
      f.path: f
          .readAsStringSync()
          .split('\n')
          .map((l) => l.replaceFirst(RegExp(r'(?<!:)//.*$'), ''))
          .join('\n'),
  };

  test('the stripped corpus is still recognisable code', () {
    expect(sources[_notifier], contains('class UspWifiSettingsNotifier'));
  });

  test('every caller of a dashboard Wi-Fi write runs it under one recovery',
      () {
    final callers = sources.entries
        .where((e) => e.key != _notifier)
        .where((e) => RegExp(r'\.(toggleSsidsByName|updateRadioChannel)\(')
            .hasMatch(e.value))
        .map((e) => e.key)
        .toList()
      ..sort();
    final bypassing = callers
        .where((f) => !sources[f]!.contains('runWifiWriteWithRecovery('))
        .toList();

    expect(callers, isNotEmpty,
        reason: 'no callers found — the census key no longer matches anything');
    expect(
      bypassing,
      isEmpty,
      reason: 'these call a Wi-Fi write without runWifiWriteWithRecovery: '
          '$bypassing. The write reloads every radio; without the one recovery '
          'the event stream drops mid-write, the shell stacks its own dialog, '
          'and the dashboard polls a reloading router.',
    );
  });
}
