import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// The router could not be asked, and **that is not an update that failed**.
///
/// The one requirement in #1551 that is about two states not sharing a widget.
/// `loadBanks()` used to record its read failure in
/// `FirmwareUpdateState.errorMessage`, which is what `FirmwareInstallPhaseCard`'s
/// failure arm renders — so a router that was merely slow, busy, or behind a
/// dropped bridge got "Update failed / Try again" painted over it on a page where
/// nothing had been attempted. That is worse than unhelpful: a user told an update
/// has failed will power-cycle a router that may be mid-flash. And the retry made
/// it worse again, because `firmware-retry` calls `cancel()` — it clears state
/// instead of re-reading, so the only control on screen could not fix the only
/// thing wrong.
///
/// So: its own copy, none of the failure vocabulary, an explicit "nothing has been
/// changed", and a retry that goes back to the router. `outline` colours rather
/// than `error`, because nothing here is a fault the user caused.
///
/// `FirmwareUpdateState.stateReadError` is the signal that this card is due, not
/// the sentence on it: it carries a `ServiceError.toString()`, which is
/// untranslated and about the transport rather than the firmware. It goes to the
/// log.
///
/// **Shared by both firmware pages, and the two ask different questions to decide
/// it is due.** The OTA page needs a conjunction — `loadBanks` and
/// `observeRunningOtaInstall` run there at once and record into one
/// `stateReadError`, so that field alone would replace a working Check button
/// whenever only the observe read failed. The manual page makes one read, so it
/// keys on that read's own `AsyncError` directly. Deciding it is the caller's job
/// precisely because it is not the same decision; what is shared is the answer.
/// **Stateful for one reason: the retry has to look like it did something.** The
/// read it starts goes to a router that has just failed to answer, so the honest
/// case is the slow one — and with no busy state the card redrew identically after
/// up to thirty seconds of nothing, which reads as a dead button and gets tapped
/// again. The flag lives here rather than in either page because it is this
/// button's own state and both callers would otherwise keep an identical copy.
class FirmwareStateUnreadableCard extends StatefulWidget {
  const FirmwareStateUnreadableCard({super.key, required this.onRetry});

  /// Re-reads. Not `cancel()` — see the class comment.
  ///
  /// The callers pass `refresh: true`: once the L1 banks provider is in
  /// `AsyncError`, `ref.read(provider.future)` rethrows the *cached* error without
  /// going near the router, so a retry that did not ask for a refetch would redraw
  /// this card forever.
  ///
  /// Returns a future so the button can wait on it. It must be the *read's* future
  /// and not a watch's: the OTA page's other read polls for up to twenty minutes,
  /// and a spinner tied to that is a hung button. Neither caller lets a failure out
  /// — the failure is what put this card on screen — so nothing is caught here.
  final Future<void> Function() onRetry;

  @override
  State<FirmwareStateUnreadableCard> createState() =>
      _FirmwareStateUnreadableCardState();
}

class _FirmwareStateUnreadableCardState
    extends State<FirmwareStateUnreadableCard> {
  bool _retrying = false;

  Future<void> _retry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    try {
      await widget.onRetry();
    } finally {
      // A successful read replaces this card, so the widget is usually gone by
      // here — and `setState` after that is an error rather than a no-op.
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.cloud_off_outlined,
                  color: scheme.onSurfaceVariant, size: 24),
              AppGap.sm(),
              // `Expanded`, so the title wraps rather than overflowing: this
              // sentence is three words in `en` and considerably more in `de`
              // and `ru`, and the card's content line is ~230px at 320px.
              Expanded(
                  child: AppText.titleMedium(
                      loc(context).firmwareStatusUnavailable)),
            ],
          ),
          AppGap.md(),
          AppText.bodyMedium(
            loc(context).firmwareStatusUnavailableDesc,
            color: scheme.onSurfaceVariant,
          ),
          AppGap.xl(),
          AppButton.primaryOutline(
            label: loc(context).retry,
            // Its own hook, distinct from `firmware-retry`. The two do opposite
            // things — that one abandons an update, this one re-reads — and an
            // E2E spec that could not tell them apart would be driving whichever
            // card happened to be on screen.
            identifier: 'firmware-state-retry',
            onTap: _retry,
            // `AppButton._isEnabled` is `onTap != null && !isLoading`, so this both
            // shows the read is in flight and swallows the second tap. The
            // `_retrying` early return in [_retry] is the belt for a caller that
            // reaches it another way.
            isLoading: _retrying,
          ),
        ],
      ),
    );
  }
}
