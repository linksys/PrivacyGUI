import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_notifier.dart';

/// The phase the demo launcher asked the next PnP run to start at, or `null`
/// for a real run from the internet check.
///
/// The launcher writes it and then navigates into `/pnp`; the flow reads it
/// from its own entry (#1511 P3). Before, the launcher set the phase on
/// `pnpProvider` itself and then navigated — which stopped working once the
/// flow became `autoDispose`: a flow touched from outside the PnP shell has
/// nothing holding it, so the phase was set on an instance that was gone by the
/// time the shell built its own.
///
/// Not `autoDispose`: it has to outlive the launcher page, which is gone by the
/// time the entry reads it.
final demoPnpStartPhaseProvider = StateProvider<PnpPhase?>((ref) => null);

/// The demo's PnP flow: a real [PnpNotifier] whose entry starts at the phase
/// the launcher picked, if it picked one.
///
/// Consumed once, so leaving PnP and coming back runs the real flow again.
class DemoPnpNotifier extends PnpNotifier {
  @override
  Future<void> startPostLoginFlow() async {
    final start = ref.read(demoPnpStartPhaseProvider);
    if (start == null) return super.startPostLoginFlow();
    ref.read(demoPnpStartPhaseProvider.notifier).state = null;
    setDemoPhase(start);
  }
}
