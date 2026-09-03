import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Flutter SDK `web/assets/canvaskit.*` were vendored from, and the only
/// version this repo declares anywhere else: `.fvmrc` and the CI setup action
/// are both asserted against it below.
///
/// All three digits, and the patch is not decoration. Every 3.47 hotfix ships
/// its own engine, and `canvaskit.wasm` really does change between them — 3.47.0
/// is `2898c079…` at 7,284,349 B against 3.47.2's `fbed517a…` at 7,284,602 B —
/// so a pin of "3.47" would re-open the exact mismatch #1316 closed.
const _pinnedFlutterVersion = '3.47.2';

/// `engineRevision` of [_pinnedFlutterVersion], from that SDK's
/// `bin/cache/flutter.version.json`. Recorded for the error messages and for
/// `doc/web/vendored-canvaskit.md`; the hashes are what actually gate.
const _pinnedEngineRevision = 'a804b261645ef8c13eb3d5c44a5c2fb0340c5539';

/// sha256 and byte size of each vendored file as shipped by
/// [_pinnedFlutterVersion]. A committed expectation rather than a live
/// byte-compare, so the check still means something on a machine with no web
/// SDK unpacked — the same reason `web/usp-artifacts.json` exists.
///
/// `canvaskit.js` is byte-identical in 3.47.0 and 3.47.2. That is why both files
/// are still listed and both are still copied on a bump: which of the two moves
/// is not knowable in advance, and "only one file showed up in git status" is
/// the expected outcome of a hotfix bump rather than a sign of a half-copy.
const _vendoredCanvasKit = <String, ({String sha256, int bytes})>{
  'canvaskit.js': (
    sha256: 'bb559f6080c7d312ac2a912b4abec9f68ff3d3022d4a603c7796b9b31460642b',
    bytes: 86987,
  ),
  'canvaskit.wasm': (
    sha256: 'fbed517a43e82452404446683f00f2e876d835aed84410695759e67b6bb01cd3',
    bytes: 7284602,
  ),
};

/// Guards the CanvasKit shipping decision made in #1281.
///
/// `web/assets/canvaskit.*` are hand-vendored copies of the engine's
/// `build/web/canvaskit/` output — byte-identical, but committed rather than
/// generated. That makes both halves of #1281 reversible by an unrelated
/// Flutter upgrade: whoever re-copies the engine directory brings
/// `chromium/` straight back, and nothing in the build fails.
///
/// The two assertions below are one change, not two. `flutter_bootstrap.js`
/// commits to a variant from browser capability detection and then `import()`s
/// its loader with no 404 fallback path, so shipping either half alone
/// white-screens: the directory without the config pins Chromium browsers at a
/// deleted file, and the config without the directory leaves 1.71 MB of
/// unreachable payload in the rootfs.
///
/// A widget test cannot cover this. `canvasKitVariant` is read by the JS
/// bootstrap in a real browser, and the golden suite runs under the Flutter
/// test VM with no CanvasKit involved, so a variant swap is invisible to it.
void main() {
  group('CanvasKit variant shipping decision (#1281)', () {
    test('only the full variant is present under web/assets', () {
      // Both, not just chromium/. The scenario this test exists for is "someone
      // re-copied build/web/canvaskit/", and under 3.47 that directory holds two
      // variant subdirectories, not one: chromium/ (5.26 MB of js+wasm) and the
      // newer webparagraph/ (3.63 MB), measured in the 3.47.2 web SDK. They are
      // reachable only through the same negated `variant !== "full"` check that
      // web/flutter_bootstrap.js pins, so `canvasKitVariant: "full"` covers both
      // — but a re-copy brings back both, and asserting only one would let 3.63 MB
      // of unreachable payload into the rootfs while this test stayed green.
      for (final variant in const ['chromium', 'webparagraph']) {
        expect(
          Directory('web/assets/$variant').existsSync(),
          isFalse,
          reason: 'web/assets/$variant/ is a CanvasKit variant this repo does '
              'not ship (#1281 removed chromium/; webparagraph/ arrived in '
              '3.47). If a Flutter upgrade re-copied build/web/canvaskit/, '
              'delete the variant subdirectories again — only canvaskit.js and '
              'canvaskit.wasm belong here.',
        );
      }

      expect(File('web/assets/canvaskit.js').existsSync(), isTrue);
      expect(File('web/assets/canvaskit.wasm').existsSync(), isTrue);
    });

    test('flutter_bootstrap.js pins the full variant and serves it locally',
        () {
      final bootstrap = File('web/flutter_bootstrap.js').readAsStringSync();

      expect(
        bootstrap,
        contains('canvasKitVariant: "full"'),
        reason: 'Required by the removal of web/assets/chromium/. Without it, '
            'capability detection routes Chromium-based browsers to the '
            'deleted assets/chromium/canvaskit.js and the app never boots.',
      );

      expect(
        bootstrap,
        contains('canvasKitBaseUrl: "./assets/"'),
        reason: 'Offline-critical. buildConfig sets no useLocalCanvasKit, so '
            'dropping this line makes the loader fetch CanvasKit from '
            'gstatic.com — which passes every online test and white-screens '
            'only on a router with no WAN.',
      );
    });
  });

  // ------------------------------------------------------------------------
  // #1316. The group above pins the *variant*; nothing pinned the *version*,
  // and that is the hole a 3.44.0 CanvasKit fell through while CI had already
  // moved to 3.47.0. Three gates were blind to it: the loader version check
  // does not exist, the smoke build never opens a browser, and the golden
  // suite runs in the test VM with no CanvasKit at all.
  //
  // canvaskit.js (glue) and canvaskit.wasm are version-locked to each other —
  // 3.44 glue against 3.47 wasm throws `pb.setFillType is not a function`, and
  // the reverse throws `this._setFillType is not a function`. So the two files
  // are one artifact, and the test treats them as one.
  // ------------------------------------------------------------------------
  group('Vendored CanvasKit tracks the pinned SDK (#1316)', () {
    test('web/assets/canvaskit.* match the SDK they were vendored from', () {
      // FLUTTER_ROOT, not Platform.resolvedExecutable: under `flutter test` the
      // latter is bin/cache/artifacts/engine/<arch>/flutter_tester, from which
      // flutter_web_sdk is not reachable by any stable relative path.
      final flutterRoot = Platform.environment['FLUTTER_ROOT'];
      expect(
        flutterRoot,
        isNotNull,
        reason: 'FLUTTER_ROOT is unset. It is populated by `flutter test`, so '
            'this runner is not one — and a skip here would recreate exactly '
            'the blindness #1316 closed.',
      );

      // Which SDK is this? Asked before anything is compared against it, because
      // FLUTTER_ROOT names the SDK actually running the test — the flutter tool
      // sets it for the child process and an ambient value does not survive — so
      // under a non-pinned SDK every hash below is compared against the wrong
      // reference and the failure reads "the vendored copy is stale". It is not:
      // 3.47.0 ships canvaskit.wasm 2898c079… against 3.47.2's fbed517a…, so a
      // bare `flutter test` on the wrong SDK sends the reader off to re-vendor,
      // which is the one action that would break a correct tree. CLAUDE.md
      // documents that hazard for exactly this repo: `flutter` is an alias to
      // fvm, and the alias does not survive into a non-interactive shell.
      final versionFile = File('$flutterRoot/bin/cache/flutter.version.json');
      if (versionFile.existsSync()) {
        final sdk =
            jsonDecode(versionFile.readAsStringSync()) as Map<String, dynamic>;
        expect(
          sdk['flutterVersion'],
          _pinnedFlutterVersion,
          reason:
              'This test ran under Flutter ${sdk['flutterVersion']}, not the '
              'pinned $_pinnedFlutterVersion. Use `fvm flutter test` (or '
              './run_tests.sh, which resolves fvm itself). Nothing below is '
              'meaningful until the runner is the pinned SDK — do NOT re-vendor '
              'in response to a failure from here.',
        );
        // Same file is where _pinnedEngineRevision was copied from, so assert it
        // rather than leaving a hand-copied constant to rot in a doc comment.
        expect(
          sdk['engineRevision'],
          _pinnedEngineRevision,
          reason:
              'Flutter $_pinnedFlutterVersion in $flutterRoot reports engine '
              '${sdk['engineRevision']}, not the recorded '
              '$_pinnedEngineRevision. Update this constant and '
              'doc/web/vendored-canvaskit.md together.',
        );
      }

      final sdkCanvasKit =
          Directory('$flutterRoot/bin/cache/flutter_web_sdk/canvaskit');
      expect(
        sdkCanvasKit.existsSync(),
        isTrue,
        reason: 'No flutter_web_sdk in $flutterRoot. It is an on-demand '
            'artifact — `flutter test` does not fetch it, only a web build or '
            '`--platform chrome` does. Run `flutter precache --web`. '
            './run_tests.sh does this for you; a bare `flutter test` on this '
            'directory does not.',
      );

      for (final entry in _vendoredCanvasKit.entries) {
        final vendored = File('web/assets/${entry.key}');
        final fromSdk = File('${sdkCanvasKit.path}/${entry.key}');

        // Size before hash, because the hash subsumes it and would therefore
        // report a truncated or LFS-pointer checkout — a few hundred bytes — as
        // "this is not the copy shipped by 3.47.2". Those need different fixes:
        // one is `git lfs pull`, the other is re-vendoring.
        expect(
          vendored.lengthSync(),
          entry.value.bytes,
          reason: 'web/assets/${entry.key} is ${vendored.lengthSync()} B, not '
              'the ${entry.value.bytes} B Flutter $_pinnedFlutterVersion ships. '
              'A wildly smaller file is a truncated or pointer-only checkout, '
              'not a version mismatch.',
        );
        expect(
          _sha256(vendored),
          entry.value.sha256,
          reason: 'web/assets/${entry.key} is not the copy shipped by Flutter '
              '$_pinnedFlutterVersion (engine $_pinnedEngineRevision). '
              'Re-vendor BOTH canvaskit.js and canvaskit.wasm together — a '
              'half-copy white-screens on load. See '
              'doc/web/vendored-canvaskit.md.',
        );
        expect(
          _sha256(fromSdk),
          entry.value.sha256,
          reason: 'The SDK at $flutterRoot ships a ${entry.key} this repo does '
              'not expect. The pin moved without the vendored copy moving: '
              'update .fvmrc, the CI setup action, this test\'s constants and '
              'web/assets/${entry.key} in one change.',
        );
      }
    });

    // The hashes above catch a vendored copy that stopped matching the SDK the
    // test ran under. They cannot catch local and CI running DIFFERENT SDKs,
    // which is how this drift started: ci.yml pinned `channel: stable` and
    // silently moved to 3.47.0 on 2026-08-12, never invokes fvm, and so could
    // not agree with .fvmrc's 3.44.0 by construction.
    test('.fvmrc and the CI setup action pin the same Flutter version', () {
      // A hotfix is not cosmetic here. `channel: stable` carried CI from 3.47.0
      // to 3.47.2 in seventeen days, each hotfix bringing its own engine and a
      // different canvaskit.wasm, so a two-digit pin drifts across CanvasKit
      // versions while looking pinned.
      expect(
        _pinnedFlutterVersion,
        matches(RegExp(r'^\d+\.\d+\.\d+$')),
        reason:
            'The pin must name a patch version. "3.47" would let the runner '
            'pick any 3.47.x, and those do not all ship the same CanvasKit.',
      );

      final fvmrc =
          jsonDecode(File('.fvmrc').readAsStringSync()) as Map<String, dynamic>;
      expect(
        fvmrc['flutter'],
        _pinnedFlutterVersion,
        reason: '.fvmrc pins local development. Bumping it means re-vendoring '
            'web/assets/canvaskit.* and moving this test\'s constants.',
      );

      final setup = File('.github/actions/setup/action.yml').readAsStringSync();
      // Match the value, not one serialisation of it. `'3.47.2'`, `"3.47.2"` and
      // bare `3.47.2` are the same YAML, and a substring check on one of them
      // turns a reformat into a red build whose stated reason ("CI moves SDK on
      // its own schedule") is false.
      expect(
        setup,
        matches(RegExp(
          '^\\s*flutter-version\\s*:\\s*[\'"]?'
          '${RegExp.escape(_pinnedFlutterVersion)}'
          '[\'"]?\\s*\$',
          multiLine: true,
        )),
        reason: 'The composite action every CI job calls must pin the same '
            'version as .fvmrc ($_pinnedFlutterVersion). A `channel:` there '
            'instead of a version means CI moves SDK on its own schedule, which '
            'is what shipped a 3.44.0 CanvasKit under a 3.47.0 engine for a '
            'week.',
      );
      // Scoped to the one step that has a `channel` input, not searched over the
      // whole file. `channel:` is an ordinary input name — a Slack notify step is
      // the realistic collision — and a file-wide search would fail that PR while
      // claiming the Flutter pin went back to floating, which sends the reader to
      // the wrong line. Comment-stripped as well, because the reason a `channel:`
      // must not come back is worth recording in the file it must not come back to,
      // and that record must not read as the thing itself.
      expect(
        _withoutLineComments(_stepBlock(setup, 'subosito/flutter-action'), '#'),
        isNot(matches(RegExp(r'^\s*channel\s*:', multiLine: true))),
        reason: 'subosito/flutter-action takes `flutter-version` OR `channel`. '
            'Leaving a live `channel:` key in that step lets the pin be '
            'overridden and puts this back to floating.',
      );
    });

    // The scoping above is only worth having if the slice really stops at the
    // step. It is an indentation walk, not a parser, so its boundary is asserted
    // against YAML written to break it rather than against the file it happens to
    // read today — where the Flutter step sits in the middle of the list and both
    // terminators would look equally correct.
    test('the step slice stops at the step, including the last one', () {
      // The case that used to over-extend: target step is LAST in `steps:`, and a
      // later top-level key carries a `channel:`. Without the dedent break the
      // slice ran to EOF and the assertion above accused the Flutter pin of
      // floating because of an unrelated output name.
      const lastInList = '''
runs:
  using: composite
  steps:
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.47.2'

outputs:
  notify:
    channel: stable
''';
      expect(
        _stepBlock(lastInList, 'subosito/flutter-action'),
        isNot(matches(RegExp(r'^\s*channel\s*:', multiLine: true))),
        reason:
            'A `channel:` outside the step was read as being inside it. The '
            'slice ran past the end of `steps:`, so this assertion would have '
            'failed a PR that never touched the Flutter pin.',
      );

      // The other direction: a sibling step after it must still end the slice,
      // and its own inputs must stay outside.
      const midList = '''
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.47.2'
    - name: Notify
      uses: slackapi/slack-github-action@v1
      with:
        channel: releases
''';
      final mid = _stepBlock(midList, 'subosito/flutter-action');
      expect(
        mid,
        isNot(matches(RegExp(r'^\s*channel\s*:', multiLine: true))),
        reason: 'The next sibling step must end the slice.',
      );
      expect(
        mid,
        contains("flutter-version: '3.47.2'"),
        reason: 'A slice that stops too early asserts nothing. It must still '
            'carry the step body it exists to read.',
      );

      // Indented comments must not terminate it — this repo writes the rationale
      // for a step above the step, at the step's own indentation, and one of those
      // comments is the record of why `channel:` must not come back.
      expect(
        _stepBlock(File('.github/actions/setup/action.yml').readAsStringSync(),
                'subosito/flutter-action')
            .contains("flutter-version: '$_pinnedFlutterVersion'"),
        isTrue,
        reason:
            'The slice of the real file lost the value it is scoped to read.',
      );
    });

    // CLAUDE.md tells readers to consult the vendored-artifact manifest before
    // bumping one. CanvasKit was missing from every manifest in the repo, which
    // is how a 3.44.0 copy survived a 3.47.0 CI move unnoticed. A manifest that
    // is allowed to go stale is worse than none, so the constants above and the
    // document a human reads are asserted to agree.
    test('doc/web/vendored-canvaskit.md records what this test enforces', () {
      final doc = File('doc/web/vendored-canvaskit.md');
      expect(
        doc.existsSync(),
        isTrue,
        reason: 'The manifest CLAUDE.md points bumpers at must exist.',
      );

      final text = doc.readAsStringSync();
      final expected = <String>[
        _pinnedFlutterVersion,
        _pinnedEngineRevision,
        for (final e in _vendoredCanvasKit.entries) ...[
          e.value.sha256,
          e.value.bytes.toString(),
        ],
      ];
      for (final value in expected) {
        expect(
          text,
          contains(value),
          reason: 'doc/web/vendored-canvaskit.md does not mention "$value". '
              'The document and this test are one manifest — move both, or a '
              'reader is told the wrong version of what ships.',
        );
      }
    });

    // Prose copies of the pin were the one unguarded category left: `.fvmrc`, the
    // setup action, these constants and the manifest are all asserted above, but
    // two files spell the version out in English where nothing checks it, and a
    // stale version in the document that tells you how to bump is worse than no
    // document. Cheaper to assert than to keep promising not to forget.
    test('prose that names the pin names the pinned version', () {
      const carriers = <String, String>{
        'CLAUDE.md': 'the Flutter SDK Pin section',
        'build_web.sh': 'the environment-contract header comment',
      };
      for (final entry in carriers.entries) {
        expect(
          File(entry.key).readAsStringSync(),
          contains(_pinnedFlutterVersion),
          reason:
              '${entry.key} names a Flutter version in ${entry.value} and it '
              'is no longer $_pinnedFlutterVersion. Moving the pin means moving '
              'every copy of it; if you added a new prose copy elsewhere, add the '
              'file here too.',
        );
      }
    });
  });

  // ------------------------------------------------------------------------
  // #1316 part B. `web/flutter_bootstrap.js` is hand-maintained, and the tool
  // substitutes `{{...}}` placeholders into whatever this repo commits. Someone
  // replaced all three with literals, so the shipped loader stopped being
  // refreshed: `cmp web/flutter_bootstrap.js build/web/flutter_bootstrap.js`
  // reported the two files IDENTICAL, which is the tell.
  //
  // Three things were frozen by that, and none of them announce themselves:
  // an embedded 3.27-era flutter.js, an engineRevision belonging to no SDK this
  // repo has ever pinned, and a constant serviceWorkerVersion — so returning
  // clients could hold a stale bundle across releases.
  //
  // Hand-setting the literals to 3.47.0 values would only recreate this at the
  // next bump, so the fix is placeholders and this test is what keeps them.
  // ------------------------------------------------------------------------
  group('flutter_bootstrap.js is a template, not a snapshot (#1316)', () {
    late final String bootstrap =
        File('web/flutter_bootstrap.js').readAsStringSync();

    // Written split so this file does not contain the literal placeholders it
    // asserts on: the tool substitutes EVERY {{name}} it finds, including ones
    // inside comments, and this test is not a web template — but the day someone
    // copies one of these strings into web/index.html, being habitually careful
    // here costs nothing.
    const placeholders = <String>[
      'flutter_js',
      'flutter_build_config',
      'flutter_service_worker_version',
    ];

    test('the three tool-filled placeholders are present', () {
      for (final name in placeholders) {
        expect(
          bootstrap,
          contains('{{$name}}'),
          reason: 'web/flutter_bootstrap.js must keep {{$name}} for the build '
              'to fill in. Replacing it with a literal freezes that value at '
              'whatever the SDK was on the day someone pasted it, which is how '
              'a 3.27-era loader survived to 3.47.0.',
        );
      }
    });

    // A misspelled placeholder does not fail the build. The substitution is a
    // regex over known names, so an unknown one is left verbatim and ships into
    // build/web/flutter_bootstrap.js — a syntax error if it landed in code, and
    // confusing noise if it landed in a comment. Caught in review exactly once
    // already, in the header comment of the file under test.
    test('there are no placeholders other than those three, once each', () {
      final found = RegExp(r'\{\{([A-Za-z_][A-Za-z0-9_]*)\}\}')
          .allMatches(bootstrap)
          .map((m) => m.group(1)!)
          .toList();

      expect(
        found.toSet().difference(placeholders.toSet()),
        isEmpty,
        reason: 'Unrecognised double-braced token in web/flutter_bootstrap.js. '
            'The build substitutes only the three names above and leaves any '
            'other verbatim, so a typo here reaches the browser instead of '
            'failing the build.',
      );

      // Counted, not just set-compared. A *recognised* name written twice passes
      // any set-based check and is then substituted twice — and since the
      // substitution is a plain regex that does not know about comments (the
      // reason this file keeps its own placeholder names split apart), a second
      // {{flutter_js}} inside a comment injects the whole minified loader into a
      // comment block in the built output.
      for (final name in placeholders) {
        expect(
          found.where((f) => f == name).length,
          1,
          reason: '{{$name}} appears ${found.where((f) => f == name).length} '
              'times in web/flutter_bootstrap.js; it must appear exactly once. '
              'Every occurrence is substituted, comments included.',
        );
      }
    });

    test('nothing the tool owns is hardcoded', () {
      // Comments dropped: this file explains at length which literals were
      // frozen and why, and naming them there is the point.
      final code = _withoutLineComments(bootstrap, '//');

      // The frozen value was cf56914b326edb0ccb123ffdc60f00060bd513fa, which is
      // neither 3.44.0's engine nor 3.47.0's. Assert on the KEY rather than that
      // string: the next freeze will use a different, equally wrong, revision.
      expect(
        code,
        isNot(contains('engineRevision')),
        reason: 'engineRevision belongs to _flutter.buildConfig, which the '
            'build generates. Writing it here pins the CanvasKit CDN path to a '
            'literal and desynchronises it from the engine actually running.',
      );
      expect(
        code,
        isNot(contains('_flutter.buildConfig =')),
        reason: 'The whole buildConfig assignment is generated, guard clause '
            'included. Hand-writing it also drops wasmHashes, which 3.47 emits '
            'and instantiate_wasm.js reads for Cross-Origin Storage.',
      );
      expect(
        code,
        isNot(matches(RegExp(r'serviceWorkerVersion:\s*"'))),
        reason:
            'serviceWorkerVersion must stay a placeholder — it is the build\'s '
            'value to fill. The value is inert as this project is configured, '
            'which is NOT a reason to hardcode it: see the note on that key in '
            'web/flutter_bootstrap.js for the measurement and the two conditions '
            'that end it.',
      );
    });

    // The config: block is ours, not the tool's, and #1281 depends on two of its
    // three lines. Restoring the placeholders around it must not disturb it —
    // the group above asserts the same two lines for the same reason, and this
    // is deliberately not deduplicated with it: that group is about the variant
    // decision and would still be right if this template were reverted.
    test('our own config: block survived the template restore', () {
      expect(bootstrap, contains('canvasKitBaseUrl: "./assets/"'));
      expect(bootstrap, contains('canvasKitVariant: "full"'));
      expect(bootstrap, contains('fontFallbackBaseUrl:'));
      expect(
        bootstrap,
        contains('serviceWorkerUrl: "service_worker.js"'),
        reason:
            'We ship our own web/service_worker.js, which importScripts the '
            'generated flutter_service_worker.js and adds skipWaiting + '
            'clients.claim on top. Dropping this line sends the loader straight '
            'at the generated file, losing both — and also switches it from '
            'registering unconditionally to registering only when a '
            'registration already exists.',
      );
    });
  });
}

String _sha256(File file) => sha256.convert(file.readAsBytesSync()).toString();

/// [source] with whole-line comments dropped, for assertions that must read code
/// rather than the prose explaining it.
///
/// Every "must not contain X" check here needs this, because the reason X was
/// removed belongs in the file it was removed from — and asserting over the
/// comments too would forbid recording the reason, which is the part that stops
/// the next person putting X back.
///
/// Whole-line only, and that is a scoping decision rather than a proof. A `/* */`
/// block and a same-line trailing comment both slip through, so this strips less
/// than "the comments" — it is enough because every caller asserts the ABSENCE of
/// a key, and stripping less can only make such an assertion stricter, never
/// blinder. Do not reuse it for a check that asserts something is present.
String _withoutLineComments(String source, String marker) =>
    const LineSplitter()
        .convert(source)
        .where((line) => !line.trimLeft().startsWith(marker))
        .join('\n');

/// The single workflow step in [yaml] whose `uses:` mentions [action], as text.
///
/// Indentation-sliced rather than YAML-parsed, and that is a deliberate ceiling:
/// this repo has no YAML dependency in its dev_dependencies, and adding one to
/// scope a single negative assertion is a worse trade than a slice that fails
/// loudly. Throws if the step is not found, because a silently empty slice is a
/// check that passes while reading nothing.
///
/// An earlier version of this comment claimed the only failure mode was a slice
/// too small — a missed assertion rather than a false accusation. That was wrong,
/// and the test below proves it: without the dedent break, a step that is LAST in
/// its `steps:` list runs to end-of-file, so a `channel:` key under a later
/// top-level mapping is read as the Flutter pin going back to floating. Both
/// terminators are therefore needed — the next sibling `- ` ends a step in the
/// middle of a list, and a dedent ends the last one.
String _stepBlock(String yaml, String action) {
  final lines = const LineSplitter().convert(yaml);
  final usesAt = lines.indexWhere(
    (l) => RegExp('uses\\s*:\\s*\\S*${RegExp.escape(action)}').hasMatch(l),
  );
  if (usesAt < 0) {
    throw StateError(
      'No step in this YAML uses $action. Either the step was renamed — in '
      'which case move this assertion with it — or the Flutter setup no longer '
      'goes through that action, which is a bigger change than this test.',
    );
  }
  // Walk back to the `- ` that opens the step, so a `with:` written above `uses:`
  // is inside the slice too.
  var start = usesAt;
  while (start > 0 && !lines[start].trimLeft().startsWith('-')) {
    start--;
  }
  final indent = lines[start].indexOf('-');
  var end = start + 1;
  while (end < lines.length) {
    final line = lines[end];
    if (line.trim().isEmpty) {
      end++;
      continue;
    }
    // The next sibling list item ends this step.
    if (line.indexOf('-') == indent && line.trimLeft().startsWith('-')) break;
    // So does dedenting out of the list, which is what ends the LAST step —
    // otherwise the slice runs to end-of-file and swallows unrelated keys.
    // Comments are exempt: a comment column-aligned above the list would
    // otherwise cut the slice short, and this file indents its comments to the
    // step level anyway.
    final lineIndent = line.length - line.trimLeft().length;
    if (lineIndent < indent && !line.trimLeft().startsWith('#')) break;
    end++;
  }
  return lines.sublist(start, end).join('\n');
}
