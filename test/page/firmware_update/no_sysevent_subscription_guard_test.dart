// The source-scan half of "state is polled, never subscribed" (#1551, W5).
//
// The decision guarded: **no SSE subscription is ever registered under
// `Device.X_LINKSYS_Sysevent.`** A `ValueChange` subscription on that subtree was
// measured delivering *zero* notifications while `fwup_state` went 0→1→0 — these
// are sysevents behind a dm-reflector, and notification there is itself sampled —
// so `FirmwareRouterOtaInstallService` samples on a clock it owns.
//
// Why a guard, when `firmware_router_ota_install_service_test.dart` already pins
// that `observe()` subscribes to nothing: that test asserts about the awaiter this
// service is handed, and a sysevent subscription would not arrive through it. Core
// subscriptions are registered by `SseManager` from `coreSubscriptions`, once per
// session, unconditionally — nothing in `lib/page/firmware_update/` is involved, so
// every test in that directory stays green while the router is asked for
// notifications it does not send.
//
// And it arrives by regeneration rather than by editing. `subscriptions.g.dart` is
// built from the `subscribe:` blocks in `linksys/usp_framework`; adding one to
// `firmware_auto_update.yaml` (or adding a `subscribe:` with no `paths:`, which
// subscribes the whole table) rewrites this file from upstream with no diff of ours
// to review. This test is the review.
//
// What a failure here costs, if it is ever tempting to delete: a subscription that
// delivers nothing does not fail loudly. It leaves a `Device.LocalAgent.Subscription`
// instance on the router for the life of the session, and a progress UI that was
// wired to it would sit on its first reading for the whole of a twenty-minute flash
// — indistinguishable from an install that hung.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/utils/usp_subscriptions.dart';

/// The subtree the router does not notify on.
///
/// Not just `fwup_state`: the whole prefix. A subscription is registered against an
/// object path, so the shape a mistake takes here is the subtree rather than the
/// leaf, and every leaf under it is sampled the same way.
const _syseventPrefix = 'Device.X_LINKSYS_Sysevent';

void main() {
  /// Everything in `lib/` except codegen, which necessarily spells these paths.
  List<File> appDartFiles() => Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.startsWith('lib/generated/'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  /// [source] with `//` and `///` lines removed.
  ///
  /// Line comments only, and stripped deliberately: the install service's own doc
  /// comment names the subtree to explain why it is polled, and that paragraph is
  /// the reason a future reader does not subscribe to it. Exempting the file to
  /// accommodate the prose would blind the scan to the file most likely to grow the
  /// call.
  String withoutLineComments(String source) => source
      .split('\n')
      .where((line) => !line.trimLeft().startsWith('//'))
      .join('\n');

  group('firmware state is polled, never subscribed', () {
    test('no core subscription covers the sysevent subtree', () {
      final offenders = coreSubscriptions
          .where((s) => s.$3.startsWith(_syseventPrefix))
          .map((s) => '${s.$1} (${s.$2}) on ${s.$3}')
          .toList();

      expect(offenders, isEmpty,
          reason: 'A ValueChange subscription under $_syseventPrefix. was '
              'measured delivering zero notifications while the value changed. '
              'If upstream added a `subscribe:` block to a sysevent YAML, the '
              'fix is upstream — not a poller deleted here.\n'
              '${offenders.join('\n')}');
    });

    test('the subscription list still has entries to check', () {
      // Without this, a codegen change that empties or restructures
      // `coreSubscriptions` turns the test above into an assertion about an empty
      // list — green forever, and green for the wrong reason.
      expect(coreSubscriptions, isNotEmpty,
          reason: 'coreSubscriptions is empty: either SSE bootstrap moved, or '
              'the generated list did. Re-point this scan before trusting it.');
      expect(coreSubscriptions.map((s) => s.$2), contains('ValueChange'),
          reason: 'no ValueChange subscription is registered at all, which is '
              'the notification type this guard is about — the list shape has '
              'changed under the test');
    });

    test('no hand-written file reaches for a sysevent path', () {
      // The other route in, and the reason this is not only about
      // `subscriptions.g.dart`: a hand-rolled `Get`, a second poller, or a
      // subscription registered directly through `UspClient` all have to spell the
      // path. The app has exactly one reader — `FirmwareAutoUpdate.fetch()` in
      // codegen — and a second one is a second clock against a router that is
      // writing NAND.
      final offenders = <String>[];
      for (final file in appDartFiles()) {
        if (withoutLineComments(file.readAsStringSync())
            .contains(_syseventPrefix)) {
          offenders.add(file.path);
        }
      }

      expect(offenders, isEmpty,
          reason: 'Read sysevents through `FirmwareAutoUpdate.fetch()`, which '
              'returns all four leaves in one round trip. A path spelled by '
              'hand is a reader codegen cannot keep in step.\n'
              '${offenders.join('\n')}');
    });

    test('the generated model is still the reader', () {
      final generated =
          File('lib/generated/firmware_auto_update.g.dart').readAsStringSync();
      expect(generated.contains('$_syseventPrefix.fwup_state'), isTrue,
          reason:
              'FirmwareAutoUpdate no longer reads `fwup_state`, so the scan '
              'above is asserting the absence of a string nothing uses. '
              'Re-derive the path from firmware_auto_update.g.dart.');
    });
  });
}
