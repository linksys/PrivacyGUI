import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/_ddns.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/_ports.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/providers/apps_and_gaming_state.dart';
import 'package:privacy_gui/providers/preservable.dart';
import 'package:privacy_gui/providers/preservable_contract.dart';
import 'package:privacy_gui/providers/preservable_notifier_mixin.dart';
import 'package:privacy_gui/providers/empty_status.dart';

final appsAndGamingProvider =
    NotifierProvider<AppsAndGamingViewNotifier, AppsAndGamingViewState>(
        () => AppsAndGamingViewNotifier());
final preservableAppsAndGamingSettingsProvider =
    Provider<PreservableContract<AppsAndGamingSettings, EmptyStatus>>(
        (ref) => ref.watch(appsAndGamingProvider.notifier));

class AppsAndGamingViewNotifier extends Notifier<AppsAndGamingViewState>
    with
        PreservableNotifierMixin<AppsAndGamingSettings, EmptyStatus,
            AppsAndGamingViewState> {
  @override
  AppsAndGamingViewState build() {
    // Listen to sub-providers to update the aggregate 'current' state.
    ref.listen(ddnsProvider, (previous, next) {
      if (previous?.settings.current != next.settings.current) {
        state = state.copyWith(
          settings: state.settings.copyWith(
            current: state.settings.current
                .copyWith(ddnsSettings: next.settings.current),
          ),
        );
      }
    });

    ref.listen(singlePortForwardingListProvider, (previous, next) {
      if (previous?.settings.current != next.settings.current) {
        state = state.copyWith(
          settings: state.settings.copyWith(
            current: state.settings.current
                .copyWith(singlePortForwardingList: next.settings.current),
          ),
        );
      }
    });

    ref.listen(portRangeForwardingListProvider, (previous, next) {
      if (previous?.settings.current != next.settings.current) {
        state = state.copyWith(
          settings: state.settings.copyWith(
            current: state.settings.current
                .copyWith(portRangeForwardingList: next.settings.current),
          ),
        );
      }
    });

    ref.listen(portRangeTriggeringListProvider, (previous, next) {
      if (previous?.settings.current != next.settings.current) {
        state = state.copyWith(
          settings: state.settings.copyWith(
            current: state.settings.current
                .copyWith(portRangeTriggeringList: next.settings.current),
          ),
        );
      }
    });

    // The initial state is built from the initial states of the sub-providers.
    // This is important for the 'original' value to be correct.
    final initialDdns = ref.read(ddnsProvider);
    final initialSinglePort = ref.read(singlePortForwardingListProvider);
    final initialPortRange = ref.read(portRangeForwardingListProvider);
    final initialPortTrigger = ref.read(portRangeTriggeringListProvider);

    return AppsAndGamingViewState(
      settings: Preservable(
        original: AppsAndGamingSettings(
          ddnsSettings: initialDdns.settings.original,
          singlePortForwardingList: initialSinglePort.settings.original,
          portRangeForwardingList: initialPortRange.settings.original,
          portRangeTriggeringList: initialPortTrigger.settings.original,
        ),
        current: AppsAndGamingSettings(
          ddnsSettings: initialDdns.settings.current,
          singlePortForwardingList: initialSinglePort.settings.current,
          portRangeForwardingList: initialPortRange.settings.current,
          portRangeTriggeringList: initialPortTrigger.settings.current,
        ),
      ),
      status: const EmptyStatus(),
    );
  }

  @override
  Future<(AppsAndGamingSettings?, EmptyStatus?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async {
    final ddnsSettings = await ref.read(ddnsProvider.notifier).fetch(
          forceRemote: forceRemote,
          updateStatusOnly: updateStatusOnly,
        );
    final singlePortForwardingList =
        await ref.read(singlePortForwardingListProvider.notifier).fetch(
              forceRemote: forceRemote,
              updateStatusOnly: updateStatusOnly,
            );
    final portRangeForwardingList =
        await ref.read(portRangeForwardingListProvider.notifier).fetch(
              forceRemote: forceRemote,
              updateStatusOnly: updateStatusOnly,
            );
    final portRangeTriggeringList =
        await ref.read(portRangeTriggeringListProvider.notifier).fetch(
              forceRemote: forceRemote,
              updateStatusOnly: updateStatusOnly,
            );

    return (
      AppsAndGamingSettings(
        ddnsSettings: ddnsSettings.current,
        singlePortForwardingList: singlePortForwardingList.current,
        portRangeForwardingList: portRangeForwardingList.current,
        portRangeTriggeringList: portRangeTriggeringList.current,
      ),
      const EmptyStatus(),
    );
  }

  @override
  Future<void> performSave() async {
    // Delegate save operations to sub-notifiers
    if (ref.read(ddnsProvider).isDirty) {
      await ref.read(ddnsProvider.notifier).save();
    }

    bool saveForwardingSuccess = false;
    try {
      if (ref.read(singlePortForwardingListProvider).isDirty) {
        await ref.read(singlePortForwardingListProvider.notifier).save();
      }
      if (ref.read(portRangeForwardingListProvider).isDirty) {
        await ref.read(portRangeForwardingListProvider.notifier).save();
      }
      saveForwardingSuccess = true;
    } catch (e) {
      logger.d('Save forwarding rules failed! try another combination');
    }

    if (!saveForwardingSuccess) {
      if (ref.read(portRangeForwardingListProvider).isDirty) {
        await ref.read(portRangeForwardingListProvider.notifier).save();
      }
      if (ref.read(singlePortForwardingListProvider).isDirty) {
        await ref.read(singlePortForwardingListProvider.notifier).save();
      }
    }

    if (ref.read(portRangeTriggeringListProvider).isDirty) {
      await ref.read(portRangeTriggeringListProvider.notifier).save();
    }
  }

  @override
  void revert() {
    super.revert(); // Call the mixin's revert to reset this notifier's settings
    ref.read(ddnsProvider.notifier).revert();
    ref.read(singlePortForwardingListProvider.notifier).revert();
    ref.read(portRangeForwardingListProvider.notifier).revert();
    ref.read(portRangeTriggeringListProvider.notifier).revert();
  }

  bool isDataValid() {
    return ref.read(ddnsProvider.notifier).isDataValid();
  }
}
