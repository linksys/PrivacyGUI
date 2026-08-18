import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dashboard/providers/selected_card_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_controller.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// #1299 — the bridge that carries the grid's selection into Riverpod.
///
/// The form picker acts on "the selected card", and the selection lives on
/// `DashboardController.selectedItemIds`, a `state_beacon` beacon owned by the
/// `sliver_dashboard` package. Reading a beacon from a widget needs
/// `state_beacon`'s own `watch(context)` extension, and `state_beacon` is a
/// transitive dependency here that the package does not re-export — nothing in
/// `lib/` observes a beacon that way. So the beacon is mirrored into
/// [selectedCardIdProvider], the way the picked forms are published into
/// `cardFormsProvider`, and the widgets stay on one reactive mechanism.
///
/// This file pins the mirror against the real controller. The picker's own
/// behaviour is in `test/page/dashboard/views/components/card_form_bar_test.dart`.
///
/// ## Mutation table
///
/// Each row is one edit to `usp_layout_controller.dart`, applied to the real file
/// and run against this file.
///
/// | # | mutation | killed by |
/// |---|---|---|
/// | 1 | constructor does not call `_armSelectionMirror` | 3 — nothing is ever published |
/// | 2 | `_swapController` does not re-arm the mirror | a swap leaves the mirror on the dead controller |
/// | 3 | `_armSelectionMirror` does not cancel `_selectionGuard` first | a swap leaves the mirror on the dead controller |
/// | 4 | `_publishSelection` takes the first of the set instead of requiring one | two selected cards read as one |
///
/// ### Two guards this table used to have, and why the code no longer does
///
/// The first version subscribed with `startNow: false` and published the current
/// value by hand, and compared before assigning — both to avoid writing to a
/// provider while this one was still being built. Mutated away, neither could be
/// killed, and the reason is the same for both: beacons flush their subscriptions on
/// a microtask (`BeaconScheduler`'s default), so the first callback lands after the
/// build has returned. The hazard being guarded against is not reachable, so the
/// guards went rather than sitting here as untestable branches.
///
/// What that does leave is a dependency on the scheduler: switching the beacon
/// scheduler to a synchronous one would make the constructor publish inside the
/// build. Nothing in this app sets a scheduler, and the two tests below that read
/// the provider without awaiting anything would fail loudly if that changed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Lets the beacon's subscription queue drain.
  ///
  /// `state_beacon` flushes subscriptions on a microtask rather than inside the
  /// assignment (`BeaconScheduler`'s default async scheduler), so the mirror lands
  /// one turn of the event loop after the selection changes. In the app that is
  /// invisible — it is well inside the frame that draws the selection border — but
  /// a test that read the provider straight after `toggleSelection` would read the
  /// value from before the tap.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  Future<ProviderContainer> createContainer() async {
    SharedPreferences.setMockInitialValues(const {});
    final container = ProviderContainer();
    container.read(uspSliverDashboardControllerProvider);
    await container.read(uspLayoutPreferencesProvider.notifier).initialized;
    await Future.delayed(const Duration(milliseconds: 100));
    return container;
  }

  test('a card starts unselected', () async {
    final container = await createContainer();
    addTearDown(container.dispose);

    expect(container.read(selectedCardIdProvider), isNull);
  });

  test('selecting one card publishes its id', () async {
    final container = await createContainer();
    addTearDown(container.dispose);

    container
        .read(uspSliverDashboardControllerProvider)
        .toggleSelection('device_info');
    await settle();

    expect(container.read(selectedCardIdProvider), 'device_info');
  });

  test('selecting a second card publishes nothing', () async {
    final container = await createContainer();
    addTearDown(container.dispose);

    final controller = container.read(uspSliverDashboardControllerProvider);
    controller.toggleSelection('device_info');
    controller.toggleSelection('lan_info', multi: true);
    await settle();

    expect(container.read(selectedCardIdProvider), isNull,
        reason: 'A form is picked per card, so a two-card selection has no '
            'unambiguous target. Publishing the first of the set would let the '
            'picker reshape a card the user did not aim at.');
  });

  test('clearing the selection publishes nothing', () async {
    final container = await createContainer();
    addTearDown(container.dispose);

    final controller = container.read(uspSliverDashboardControllerProvider);
    controller.toggleSelection('device_info');
    await settle();
    expect(container.read(selectedCardIdProvider), 'device_info');

    controller.clearSelection();
    await settle();

    expect(container.read(selectedCardIdProvider), isNull);
  });

  test('a controller swap moves the mirror to the new instance', () async {
    final container = await createContainer();
    addTearDown(container.dispose);

    final stale = container.read(uspSliverDashboardControllerProvider);
    stale.toggleSelection('device_info');
    await settle();
    expect(container.read(selectedCardIdProvider), 'device_info');

    // Removing a card swaps the controller instance — membership changes have to,
    // because StateNotifier only notifies on a new instance.
    await container
        .read(uspSliverDashboardControllerProvider.notifier)
        .removeWidget('lan_info');
    final fresh = container.read(uspSliverDashboardControllerProvider);
    expect(fresh, isNot(same(stale)));

    expect(container.read(selectedCardIdProvider), isNull,
        reason: 'The fresh controller has nothing selected, and re-arming '
            'publishes that — otherwise the picker would keep naming a card '
            'whose selection border is gone.');

    fresh.toggleSelection('topology');
    await settle();
    expect(container.read(selectedCardIdProvider), 'topology');

    stale.toggleSelection('wan_info');
    await settle();
    expect(container.read(selectedCardIdProvider), 'topology',
        reason: 'The old subscription has to be cancelled, or the discarded '
            'controller keeps writing over the live one.');
  });
}
