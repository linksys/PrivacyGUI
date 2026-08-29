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
      expect(
        Directory('web/assets/chromium').existsSync(),
        isFalse,
        reason: 'web/assets/chromium/ was removed in #1281 to save 1.71 MB of '
            'rootfs. If a Flutter upgrade re-copied build/web/canvaskit/, '
            'delete the chromium/ subdirectory again.',
      );

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

      final sdkCanvasKit =
          Directory('$flutterRoot/bin/cache/flutter_web_sdk/canvaskit');
      expect(
        sdkCanvasKit.existsSync(),
        isTrue,
        reason: 'No flutter_web_sdk in $flutterRoot. It is an on-demand '
            'artifact — `flutter test` does not fetch it, only a web build or '
            '`--platform chrome` does. Run `flutter precache --web`. CI does '
            'this in .github/workflows/ci.yml before the unit test step.',
      );

      for (final entry in _vendoredCanvasKit.entries) {
        final vendored = File('web/assets/${entry.key}');
        final fromSdk = File('${sdkCanvasKit.path}/${entry.key}');

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
          vendored.lengthSync(),
          entry.value.bytes,
          reason: 'web/assets/${entry.key} is the wrong size for Flutter '
              '$_pinnedFlutterVersion.',
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
      expect(
        setup,
        contains("flutter-version: '$_pinnedFlutterVersion'"),
        reason: 'The composite action every CI job calls must pin the same '
            'version as .fvmrc. A `channel:` there instead of a version means '
            'CI moves SDK on its own schedule, which is what shipped a 3.44.0 '
            'CanvasKit under a 3.47.0 engine for a week.',
      );
      expect(
        _withoutLineComments(setup, '#'),
        isNot(contains('channel:')),
        reason: 'subosito/flutter-action takes `flutter-version` OR `channel`. '
            'Leaving a live `channel:` key in place lets the pin be overridden '
            'and puts this back to floating.',
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
    test('there are no placeholders other than those three', () {
      final found = RegExp(r'\{\{([A-Za-z_][A-Za-z0-9_]*)\}\}')
          .allMatches(bootstrap)
          .map((m) => m.group(1)!)
          .toSet();

      expect(
        found.difference(placeholders.toSet()),
        isEmpty,
        reason: 'Unrecognised double-braced token in web/flutter_bootstrap.js. '
            'The build substitutes only the three names above and leaves any '
            'other verbatim, so a typo here reaches the browser instead of '
            'failing the build.',
      );
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
            'value to fill. Note the value is currently inert here: the loader '
            'only uses it as active.scriptURL.endsWith(version), and our '
            'serviceWorkerUrl carries no ?v= query, so update() is called '
            'unconditionally whatever the value is. It becomes load-bearing the '
            'moment that override goes, since the default URL is '
            'flutter_service_worker.js?v=<version>.',
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
/// Whole-line only: a trailing comment cannot hide a live key, since the key
/// would still be on the line before it.
String _withoutLineComments(String source, String marker) =>
    const LineSplitter()
        .convert(source)
        .where((line) => !line.trimLeft().startsWith(marker))
        .join('\n');
