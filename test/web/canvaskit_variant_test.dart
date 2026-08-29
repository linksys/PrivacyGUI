import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Flutter SDK `web/assets/canvaskit.*` were vendored from, and the only
/// version this repo declares anywhere else: `.fvmrc` and the CI setup action
/// are both asserted against it below.
const _pinnedFlutterVersion = '3.47.0';

/// `engineRevision` of [_pinnedFlutterVersion], from that SDK's
/// `bin/cache/flutter.version.json`. Recorded for the error messages and for
/// `doc/web/vendored-canvaskit.md`; the hashes are what actually gate.
const _pinnedEngineRevision = '5f77625673248ee5846fbcaf5d3e1a3878386fd7';

/// sha256 and byte size of each vendored file as shipped by
/// [_pinnedFlutterVersion]. A committed expectation rather than a live
/// byte-compare, so the check still means something on a machine with no web
/// SDK unpacked — the same reason `web/usp-artifacts.json` exists.
const _vendoredCanvasKit = <String, ({String sha256, int bytes})>{
  'canvaskit.js': (
    sha256: 'bb559f6080c7d312ac2a912b4abec9f68ff3d3022d4a603c7796b9b31460642b',
    bytes: 86987,
  ),
  'canvaskit.wasm': (
    sha256: '2898c0795cf4a694e86ee3445c7414c2503fbcb46967154762f50ebde988da04',
    bytes: 7284349,
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
      // Comment lines stripped first: the reason `channel:` is gone belongs in
      // that file as prose, and asserting over the prose too would forbid
      // explaining the decision.
      final setupYaml = const LineSplitter()
          .convert(setup)
          .where((line) => !line.trimLeft().startsWith('#'))
          .join('\n');
      expect(
        setupYaml,
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
}

String _sha256(File file) => sha256.convert(file.readAsBytesSync()).toString();
