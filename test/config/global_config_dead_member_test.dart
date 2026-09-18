// Phase 8 of epic #1474: every flag on `RemoteConfig` has a reader.
//
// THE DECISION GUARDED. `GlobalConfig.remote` is not a policy table. Phase 8
// deleted three getters from it — `allowDashboardEdit`, `allowConfigChanges`,
// `showAdvancedSettings` — that had **zero** consumers each while reading as
// though the restrictions they named were enforced. Measured, one duplicated a
// live gate and the other two named a policy the epic has decided *against*: a
// blanket write block, which #1496 replaced with a per-operation one, and a
// surface hidden by a flag, which #1474 rules out outright. The per-flag
// measurement lives in `RemoteConfig`'s own doc comment and is deliberately not
// repeated here.
//
// That is the whole argument #1474 makes against a declarative `UiCapabilities`
// table: an unread bool cannot be seen to be wrong, and a *well named* unread
// bool actively misleads. For two of these three it described a posture nobody
// had decided to adopt, and it read as settled.
//
// The rule phase 8 wrote down is "a new member here needs a consumer in the same
// change". This file is that rule, executable.
//
// HOW IT COULD SILENTLY REVERT. By doing the obvious, tidy thing. The next phase
// that needs a mode decision has a class literally named `RemoteConfig` sitting in
// `lib/config/`, with a `RemoteConfig._()` private constructor and four
// well-documented siblings; adding `bool get allowFactoryReset => !isActive;`
// there takes ten seconds, reviews as good practice, and is indistinguishable from
// the three flags just deleted until someone greps for consumers years later.
// Nothing else objects: the analyzer does not warn on an unread public getter, and
// no test pumps this class.
//
// WHY THIS TEST TYPE. The property is "somebody reads this", which is a property
// of the repository rather than of any execution. A behavioural test proves the
// opposite thing — that a *particular* reader behaves correctly — and stays green
// when a sibling flag has no reader at all. There is no runtime moment at which an
// unread getter misbehaves; that is precisely what makes it dangerous.
//
// Scoped to `RemoteConfig` on purpose. It is the only one of the four config
// objects that encodes *policy*; `FeatureConfig`, `ThemeConfig` and `UIConfig`
// carry values whose spelling is data, and an unused breakpoint constant is
// clutter rather than a false claim about what the app enforces.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final configFile = File('lib/config/global_config.dart');

  group('RemoteConfig declares no unread flag', () {
    test('the config file is where this scan expects it', () {
      expect(configFile.existsSync(), isTrue,
          reason: 'lib/config/global_config.dart moved — re-point this scan');
    });

    test('every public getter on RemoteConfig is read outside the config file',
        () {
      final source = configFile.readAsStringSync();

      // Slice `class RemoteConfig` out of the file so the scan does not pick up
      // getters belonging to the three sibling classes.
      final start = source.indexOf('class RemoteConfig {');
      expect(start, isNot(-1),
          reason: 'class RemoteConfig was renamed — re-anchor this scan');
      final afterStart = source.substring(start);
      final nextClass = afterStart.indexOf('\nclass ');
      final body =
          nextClass < 0 ? afterStart : afterStart.substring(0, nextClass);

      final getters = RegExp(
              r'^\s{2}(?:\w+\??|\w+<[^>]+>\??)\s+get\s+(\w+)\s*=>',
              multiLine: true)
          .allMatches(body)
          .map((m) => m.group(1)!)
          .toList()
        ..sort();

      expect(getters, isNotEmpty,
          reason: 'the getter regex matched nothing, so this test is asserting '
              'a property of the empty set — RemoteConfig was reformatted or '
              'rewritten in a shape the scan cannot read');

      final libAndTest = [
        ...Directory('lib').listSync(recursive: true),
        ...Directory('test').listSync(recursive: true),
      ]
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => f.path != configFile.path)
          .map((f) => f.readAsStringSync())
          .join('\n');

      final unread = getters
          .where((g) => !RegExp('\\.$g\\b').hasMatch(libAndTest))
          .toList();

      expect(
        unread,
        isEmpty,
        reason: 'These RemoteConfig flags have no reader anywhere in lib/ or '
            'test/. #1474 phase 8 deleted three of exactly this shape, two of '
            'which described restrictions the app never enforced — a named, '
            'documented, centralised bool that nothing consults is worse than no '
            'bool, because it reads as the gate. Either add the consumer in this '
            'same change, or delete the flag. If the policy belongs to a mode '
            'rather than to a build flag, it belongs in phase 6\'s '
            '`OperationGuard` or phase 7\'s `SurfaceStrategy`, where being '
            'unreached is visible.',
      );
    });
  });
}
