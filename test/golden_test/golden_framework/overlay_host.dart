import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// An empty screen that overlay goldens open their overlay over (#905).
///
/// A `ConsumerStatefulWidget` and not a `Scaffold`, because its state carries a
/// [WidgetRef]: that is what lets an interaction step call the helpers that take
/// one, like `showRecoveryDialog(context, ref, ...)`, through their real
/// signature, from inside the golden runner's `ProviderScope` and so under the
/// state's own overrides. The alternative, a host that calls the helper from its
/// own `initState`, would need a host per helper and a flag per variant.
///
/// The [Scaffold] inside is for the overlays that need one: a snackbar's
/// `ScaffoldMessenger` lives above it in `MaterialApp`, but it shows the
/// snackbar in the nearest registered `Scaffold`.
class OverlayHost extends ConsumerStatefulWidget {
  const OverlayHost({super.key});

  @override
  ConsumerState<OverlayHost> createState() => _OverlayHostState();
}

class _OverlayHostState extends ConsumerState<OverlayHost> {
  @override
  Widget build(BuildContext context) => const Scaffold(body: SizedBox.expand());
}

/// The host's `BuildContext` and `WidgetRef`, read through `ConsumerState`'s
/// public `context` and `ref` rather than by casting the element.
({BuildContext context, WidgetRef ref}) overlayHostOf(WidgetTester tester) {
  final state =
      tester.state<ConsumerState<OverlayHost>>(find.byType(OverlayHost));
  return (context: state.context, ref: state.ref);
}
