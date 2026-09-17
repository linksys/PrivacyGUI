import 'package:privacy_gui/page/login/auto_parent/views/auto_parent_first_login_view.dart';

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../../mocks/provider_overrides/mock_login.dart';

// The first-connection firmware screen (#1554), and the last firmware surface in the app
// without a picture.
//
// It is the *other* screen that says "we are installing firmware, do not unplug the
// router" — the one the layout gate exempts as loader-is-content
// (`kPagesWhoseLoaderIsContent`), and whose argument the setup wizard's firmware stage
// joined when it became that set's second entry. The wizard's version is photographed by
// `pnp_setup/updating_firmware`; this one was not, which left the pair asymmetric for no
// reason anyone had stated.
//
// ## One state, and that is the whole view rather than a choice
//
// `build` has no branches. It returns a centred `AppCard` holding a loader, a title and a
// body, and nothing in it reads a phase: the `isNewFwAvailable` decision lives in
// `_doFirmwareUpdateCheck`, which **navigates** rather than re-rendering this card. So the
// fixture's `firmwareAvailable: true` does not select a rendering here — it is what keeps
// `initState` from reaching a real provider, and it is the same value the gate case pins
// for the same reason.
//
// What the picture buys over the sweep, which already covers this page at nine widths:
// the two sentences are `pnpFwUpdateTitle` and `pnpFwUpdateDesc` in 26 languages, inside
// `context.colWidth(4)` — a four-column box, so a narrow one — and the gate can only say
// the box holds them, not that they read as an instruction not to unplug a router.
//
// ## Recorded, not fixed: the loader sits flush against the title
//
// The first capture showed the spinner touching the title, and the geometry says it is
// exactly that rather than an overlap — **`title.top - loader.bottom == 0.0`**, measured at
// 320, 480 and 1280. Every other pair in that `Column` has an `AppGap.lg()` between them;
// the loader and the title have nothing. It is not an overflow and not a clip, so no gate
// cell would ever report it, which is the kind of thing this picture exists to surface.
//
// Left alone deliberately. Whether a spinner should be spaced off the heading it belongs
// to is a design call on a page outside this work's scope, and a `lib/` edit made on the
// strength of one reviewer's eye is the wrong way to settle it. The measurement is here so
// the decision can be made rather than re-discovered.
void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'auto_parent_first_login',
      view: () => const AutoParentFirstLoginView(),
      // The view builds its own `UiKitPageView`, with `backState: none` — there is
      // deliberately no way back out of a flash in progress, which is the same lock
      // REQ-B2 puts on the wizard's stage.
      shell: ShellType.custom,
      // The card is centred and short; the default device heights would work, but a
      // fixed height keeps the two devices' framing comparable, which is the only thing
      // a reviewer does with this page.
      height: 900,
      states: {
        'checking': (overrides) => overrides.addAll(
              autoParentFirstLoginOverrides(firmwareAvailable: true),
            ),
      },
    ),
  );
}
