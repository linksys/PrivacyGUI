import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/mixin/page_snackbar_mixin.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';
import 'package:privacy_gui/page/wifi_settings/services/wifi_settings_mapper.dart';
import 'package:privacy_gui/page/wifi_settings/services/wifi_settings_service.dart';
import 'package:privacy_gui/page/wifi_settings/views/mac_filtering_view.dart';
import 'package:privacy_gui/page/wifi_settings/views/wifi_advanced_settings_view.dart';
import 'package:privacy_gui/page/wifi_settings/views/wifi_list_view.dart';
import 'package:ui_kit_library/ui_kit.dart';

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

    // Tab keys for testing
    const tabKeys = ['wifiTab', 'advancedTab', 'macFilteringTab'];

    final tabContents = [
      WiFiListView(args: widget.args),
      const WifiAdvancedSettingsView(),
      const MacFilteringView(),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      return UiKitPageView.withSliver(
        title: loc(context).incredibleWiFi,
        useMainPadding: true,
        bottomBar: UiKitBottomBarConfig(
          isPositiveEnabled: bundleState.isDirty &&
              ref
                  .read(wifiSettingsServiceProvider)
                  .validateWifiListSettings(bundleState.current.wifiList),
          onPositiveTap: () async {
            if (_tabController.index == 0) {
              // if current tab is wifi list settings, show save confirm modal
              _showSaveConfirmModal();
            } else if (_tabController.index == 1) {
              // if current tab is advanced settings, show dfs confirm modal if dfs is enabled
              if (bundleState.current.advanced.isDFSEnabled == true) {
                final shouldSave = await _showConfirmDFSModal();
                if (shouldSave == true) {
                  await _doSave();
                }
              } else {
                await _doSave();
              }
            } else {
              // if current tab is mac filtering, save mac filtering settings
              final enableMacFiltering =
                  bundleState.current.privacy.mode.isEnabled;
              final shouldSave = await showMacFilteringConfirmDialog(
                  context, enableMacFiltering);
              if (shouldSave == true) {
                await _doSave();
              }
            }
          },
        ),
        tabs: tabs
            .mapIndexed((index, e) => Tab(
                  key: Key(tabKeys[index]),
                  child: AppText.titleSmall(
                    e,
                  ),
                ))
            .toList(),
        tabContentViews: tabContents,
        tabController: _tabController,
        unboundedFallbackHeight: constraints.maxHeight,
      );
    });
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
        ? WifiSettingsMapper.toSimpleModeWifiItems(newState.current.wifiList)
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
              AppGap.lg(),
              ..._buildNewSettings(previewState),
              AppGap.lg(),
              AppText.bodyMedium(loc(context).doYouWantToContinue),
            ],
          ),
        ),
        actions: [
          AppButton.text(
            label: loc(context).cancel,
            onTap: () {
              context.pop(false);
            },
          ),
          AppButton.text(
            label: loc(context).ok,
            onTap: () {
              context.pop(true);
            },
          )
        ]);
    if (result) {
      await _doSave();
    }
    return result;
  }

  Future<bool?> _showConfirmDFSModal() {
    return showMessageAppDialog(
      context,
      title: loc(context).dfs,
      message: loc(context).modalDFSDesc,
      actions: [
        AppButton.text(
          label: loc(context).cancel,
          onTap: () => context.pop(),
        ),
        AppButton.text(
          label: loc(context).ok,
          onTap: () => context.pop(true),
        ),
      ],
    );
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
            AppGap.sm(),
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
            .read(wifiSettingsServiceProvider)
            .checkingMLOSettingsConflicts(radios, isMloEnabled: isMLOEnabled)
        ? [
            AppGap.md(),
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
              AppGap.md(),
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
          AppGap.md(),
        ],
      ),
    );
    return advanced;
  }
}
