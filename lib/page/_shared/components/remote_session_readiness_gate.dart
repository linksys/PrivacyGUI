import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/services/sse_manager.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Holds a Remote Assistance agent behind a dialog until the session keeps its
/// dashboard current by itself (Austin, 2026-10-01).
///
/// Under RA the dashboard renders and fetches first, and subscribes to the
/// router through Guardian only afterwards — on purpose, so subscription POSTs
/// do not compete with the first reads — and Guardian takes a few seconds per
/// subscription: about a minute on the QA router. Acting in that window means
/// acting on a page that will not update itself. So this sits over the shell,
/// a dialog over a dimmed but visible dashboard, which the agent watches fill
/// in.
///
/// **It can never trap the agent.** It lets go when the core subscriptions are
/// in, or after [_maxWait], whichever comes first; a registration with failures
/// ends the wait like a clean one, and either imperfect ending says the live
/// updates may be incomplete.
///
/// **It is for the start of a session only.** Once it has let go it stays gone:
/// a routine ~10-minute Guardian stream close puts the subscriptions back to
/// pending, and raising a dialog over a session in progress would be wrong.
/// Mounted by `RemoteSurface.sessionReadinessGate`, so a local build — which
/// subscribes on the LAN, where none of this is slow — never has one.
class RemoteSessionReadinessGate extends ConsumerStatefulWidget {
  const RemoteSessionReadinessGate({super.key});

  @override
  ConsumerState<RemoteSessionReadinessGate> createState() =>
      _RemoteSessionReadinessGateState();
}

class _RemoteSessionReadinessGateState
    extends ConsumerState<RemoteSessionReadinessGate> {
  /// Longer than the ~60 s the QA router took, with room for a slow Guardian,
  /// and short enough that an agent stuck behind it has not given up.
  static const _maxWait = Duration(seconds: 90);

  bool _released = false;
  Timer? _giveUp;

  @override
  void initState() {
    super.initState();
    _giveUp = Timer(_maxWait, () => _release(complete: false));
    ref.listenManual(sseCoreSubscriptionsProvider, (prev, next) {
      final state = next.valueOrNull;
      if (state is CoreSubscriptionsReady) {
        _release(complete: state.failed == 0);
      }
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _giveUp?.cancel();
    super.dispose();
  }

  void _release({required bool complete}) {
    if (_released || !mounted) return;
    _giveUp?.cancel();
    setState(() => _released = true);
    if (!complete) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(loc(context).raPreparingPartial)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_released) return const SizedBox.shrink();

    final scrim = Theme.of(context).colorScheme.scrim.withValues(alpha: 0.32);
    return Positioned.fill(
      child: Stack(
        children: [
          // Takes every tap meant for the dashboard; the dialog is above it.
          ModalBarrier(color: scrim, dismissible: false),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: AppDialog(
                  titleText: loc(context).raPreparingTitle,
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Center(child: AppLoader()),
                      AppGap.lg(),
                      AppText.bodyMedium(
                        loc(context).raPreparingBody,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
