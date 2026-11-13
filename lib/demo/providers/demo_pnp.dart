import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_settings.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_notifier.dart';

/// Where the demo launcher asked the next PnP run to start: at the wizard's
/// steps on [wizard]'s router data, or at [phase].
class DemoPnpStart {
  const DemoPnpStart.wizard(PnpWizardData this.wizard) : phase = null;
  const DemoPnpStart.phase(PnpPhase this.phase) : wizard = null;

  final PnpWizardData? wizard;
  final PnpPhase? phase;
}

/// Where the demo launcher asked the next PnP run to start, or `null` for a
/// real run from the internet check.
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
final demoPnpStartProvider = StateProvider<DemoPnpStart?>((ref) => null);

/// The demo's PnP flow: a real [PnpNotifier] whose entry starts where the
/// launcher picked, if it picked anywhere.
///
/// Consumed once, so leaving PnP and coming back runs the real flow again.
/// A start at the steps goes through the same plan and drafts as a real run
/// (`setDemoWizard`), so the wizard it opens is the real one.
class DemoPnpNotifier extends PnpNotifier {
  @override
  Future<void> startPostLoginFlow() async {
    final start = ref.read(demoPnpStartProvider);
    if (start == null) return super.startPostLoginFlow();
    ref.read(demoPnpStartProvider.notifier).state = null;
    if (start.wizard case final router?) setDemoWizard(router);
    if (start.phase case final phase?) setDemoPhase(phase);
  }
}
