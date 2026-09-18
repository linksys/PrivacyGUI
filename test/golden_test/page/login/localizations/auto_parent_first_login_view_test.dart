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
// ## What this suite's first capture found, and fixed
//
// The spinner was sitting on the title's first line. The geometry said flush rather than
// overlapping — **`title.top - loader.bottom == 0.0`**, measured at 320, 480 and 1280 —
// and the picture is why anyone looked: no gate cell could report it, because nothing
// overflowed and nothing clipped.
//
// **What turned it from a design question into a consistency fix was counting the other
// sites.** Every `AppLoader`-then-text pairing in `lib/page` has an `AppGap` between them:
// the wizard's `_buildSavingOverlay` and `_buildTestingReconnect` both use `AppGap.lg()`,
// and five more agree. This page was the only one with nothing, so the convention had
// already been decided and this screen was the outlier. `AppGap.lg()` added (Austin,
// 2026-09-17).
//
// Worth keeping because of the order it happened in: the first read of the picture called
// it an overlap, the geometry said flush, and the *census* is what made it actionable. A
// picture is what surfaces this class of defect; it is not by itself the argument for
// changing `lib/`.
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
