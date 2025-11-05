import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/mixin/page_snackbar_mixin.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';
import 'package:privacy_gui/page/wifi_settings/views/mac_filtering_view.dart';
import 'package:privacy_gui/page/wifi_settings/views/wifi_advanced_settings_view.dart';
import 'package:privacy_gui/page/wifi_settings/views/wifi_list_view.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';

class WiFiMainView extends ArgumentsConsumerStatefulView {
  const WiFiMainView({Key? key, super.args}) : super(key: key);

  @override
  ConsumerState<WiFiMainView> createState() => _WiFiMainViewState();
}

class _WiFiMainViewState extends ConsumerState<WiFiMainView>
    with SingleTickerProviderStateMixin, PageSnackbarMixin<WiFiMainView> {
  late TabController _tabController;
  late int _previousIndex;
  late WifiBundleNotifier _notifier;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _previousIndex = _tabController.index;
    _tabController.addListener(_handleTabChange);
    _notifier = ref.read(wifiBundleProvider.notifier);
    doSomethingWithSpinner(context, _notifier.fetch());
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleTabChange() async {
    if (!_tabController.indexIsChanging) {
      return;
    }

    final notifier = ref.read(wifiBundleProvider.notifier);
    if (notifier.isDirty()) {
      final shouldDiscard = await showUnsavedAlert(context);
      if (shouldDiscard == true) {
        notifier.revert();
      } else {
        // User cancelled, prevent tab change
        _tabController.index = _previousIndex;
        return;
      }
    }
    _previousIndex = _tabController.index;
  }

  @override
  Widget build(BuildContext context) {
    final bundleState = ref.watch(wifiBundleProvider);

    final tabs = [
      loc(context).wifi,
      loc(context).advanced,
      loc(context).macFiltering
    ];

    final tabContents = [
      WiFiListView(args: widget.args),
      const WifiAdvancedSettingsView(),
      const MacFilteringView(),
    ];

    return StyledAppPageView.withSliver(
      title: loc(context).incredibleWiFi,
      useMainPadding: false,
      bottomBar: PageBottomBar(
        isPositiveEnabled: bundleState.isDirty &&
            bundleState.current.wifiList.isSettingsValid(),
        onPositiveTap: () async {
          // if current tab is wifi list settings, show save confirm modal
          if (_tabController.index == 0) {
            final shouldSave = await _showSaveConfirmModal();
            if (shouldSave) {
              await ref.read(wifiBundleProvider.notifier).save();
            }
          } else {
            // if current tab is advanced settings, save advanced settings
            await _doSave();
          }
        },
      ),
      tabs: tabs
          .mapIndexed((index, e) => Tab(
                child: AppText.titleSmall(
                  e,
                ),
              ))
          .toList(),
      tabContentViews: tabContents,
      tabController: _tabController,
    );
  }

  Future<void> _doSave() async {
    if (!mounted) return;
    doSomethingWithSpinner(
            context, ref.read(wifiBundleProvider.notifier).save())
        .then((state) {
      if (!mounted) return;
      // update(state);
      showChangesSavedSnackBar();
    }).catchError((error, stackTrace) {
      if (!mounted) return;
      showRouterNotFoundAlert(context, ref,
          onComplete: () => ref
              .read(wifiBundleProvider.notifier)
              .fetch(forceRemote: true)).then((state) {
        if (!mounted) return;
        // update(state);
        showChangesSavedSnackBar();
      });
    }, test: (error) => error is JNAPSideEffectError).onError(
            (error, stackTrace) {
      if (!mounted) return;
      showErrorMessageSnackBar(error);
    });
  }

  Future<bool> _showSaveConfirmModal() async {
    final newState = ref.read(wifiBundleProvider);
    final wifiListSettings = newState.current.wifiList.isSimpleMode
        ? newState.current.wifiList.getMainWifiItemsWithSimpleSettings()
        : newState.current.wifiList.mainWiFi;
    final previewState =
        newState.current.wifiList.copyWith(mainWiFi: wifiListSettings);
    final result = await showSimpleAppDialog(context,
        title: loc(context).wifiListSaveModalTitle,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.bodyMedium(loc(context).wifiListSaveModalDesc),
              ..._mloWarning(previewState),
              ..._disableBandWarning(previewState),
              const AppGap.medium(),
              ..._buildNewSettings(previewState),
              const AppGap.medium(),
              AppText.bodyMedium(loc(context).doYouWantToContinue),
            ],
          ),
        ),
        actions: [
          AppTextButton(
            loc(context).cancel,
            onTap: () {
              context.pop(false);
            },
          ),
          AppTextButton(loc(context).ok, onTap: () {
            context.pop(true);
          })
        ]);
    if (result) {
      await _doSave();
    }
    return result;
  }

  // void update(WiFiListSettings? state) {
  //   if (!mounted) {
  //     return;
  //   }
  //   if (state == null) {
  //     return;
  //   }
  //   setState(() {
  //     _preservedMainWiFiState = state;
  //     ref
  //         .read(wifiViewProvider.notifier)
  //         .setWifiListViewStateChanged(state != _preservedMainWiFiState);
  //     _initSimpleModeSettings(state);
  //   });
  // }

  List<Widget> _disableBandWarning(WiFiListSettings state) {
    final disabledWiFiBands =
        state.mainWiFi.where((e) => !e.isEnabled).toList();
    final isGuestEnabled = state.guestWiFi.isEnabled;
    return isGuestEnabled
        ? [
            AppGap.small2(),
            ...disabledWiFiBands
                .map((e) => AppText.labelMedium(
                      loc(context).disableBandWarning(e.radioID.bandName),
                      color: Theme.of(context).colorScheme.error,
                    ))
                .toList()
          ]
        : [];
  }

  List<Widget> _mloWarning(WiFiListSettings state) {
    final radios =
        Map.fromIterables(state.mainWiFi.map((e) => e.radioID), state.mainWiFi);
    final isMLOEnabled =
        ref.read(wifiBundleProvider).current.advanced.isMLOEnabled ?? false;
    return ref
            .read(wifiBundleProvider.notifier)
            .checkingMLOSettingsConflicts(radios, isMloEnabled: isMLOEnabled)
        ? [
            const AppGap.small3(),
            AppText.labelLarge(
              loc(context).mloWarning,
              color: Theme.of(context).colorScheme.error,
            ),
          ]
        : [];
  }

  List<Widget> _buildNewSettings(WiFiListSettings state) {
    List<Widget> advanced = state.mainWiFi
        .map(
          (e) => Column(
            key: ValueKey(e.radioID.value),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.bodyMedium(e.radioID.value),
              SizedBox(
                width: double.infinity,
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.bodyMedium('${loc(context).wifiName}: ${e.ssid}'),
                      if (!e.securityType.isOpenVariant)
                        AppText.bodyMedium(
                            '${loc(context).wifiPassword}: ${e.password}'),
                      AppText.bodyMedium(
                          '${loc(context).securityMode}: ${e.securityType.value}'),
                    ],
                  ),
                ),
              ),
              const AppGap.small3(),
            ],
          ),
        )
        .toList();
    advanced.add(
      Column(
        key: ValueKey('guest'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.bodyMedium(loc(context).guest),
          SizedBox(
            width: double.infinity,
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.bodyMedium(
                      '${loc(context).wifiName}: ${state.guestWiFi.ssid}'),
                  AppText.bodyMedium(
                      '${loc(context).wifiPassword}: ${state.guestWiFi.password}'),
                ],
              ),
            ),
          ),
          const AppGap.small3(),
        ],
      ),
    );
    return advanced;
  }
}
