import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'golden_runner.dart';
import 'golden_test_config.dart';

/// Guards the provider container the golden runner shares across alchemist's
/// navigator (#905): it must still be disposed when the widget tree unmounts.
///
/// `ProviderScope` used to own each cell's container and disposed it when its
/// state was disposed, which `testWidgets` does by unmounting the tree *before*
/// it asserts that no timer is pending. A provider that starts a timer and
/// cancels it in `ref.onDispose` therefore left nothing behind. Disposing the
/// shared container in a tear-down instead would run after that assertion, and
/// the same provider would fail the golden with "A Timer is still pending even
/// after the widget tree was disposed". The real providers that do this
/// (debounced SSE refreshes, the system health poll) are overridden or idle in
/// today's goldens, so this cell is the one place the property is exercised.
void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'golden_runner_container',
      view: () => const _TimerReader(),
      shell: ShellType.custom,
      devices: const [GoldenDevice('tiny', Size(64, 64))],
      states: {
        'timer_cancelled_on_dispose': (overrides) {},
      },
    ),
  );
}

/// A provider shaped like the app's debounced and polling ones: a periodic
/// timer, cancelled only when the provider is disposed.
final _timerProvider = Provider<int>((ref) {
  final timer = Timer.periodic(const Duration(minutes: 5), (_) {});
  ref.onDispose(timer.cancel);
  return 0;
});

class _TimerReader extends ConsumerWidget {
  const _TimerReader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(_timerProvider);
    return const SizedBox.expand();
  }
}
