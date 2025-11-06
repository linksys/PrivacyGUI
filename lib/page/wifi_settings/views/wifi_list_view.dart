import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/mixin/page_snackbar_mixin.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_view_provider.dart';
import 'package:privacy_gui/page/wifi_settings/views/wifi_list_advanced_mode_view.dart';
import 'package:privacy_gui/page/wifi_settings/views/wifi_list_simple_mode_view.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';

class WiFiListView extends ArgumentsConsumerStatefulView {
  const WiFiListView({Key? key, super.args}) : super(key: key);

  @override
  ConsumerState<WiFiListView> createState() => _WiFiListViewState();
}

class _WiFiListViewState extends ConsumerState<WiFiListView>
    with PageSnackbarMixin {
  WiFiState? _preservedMainWiFiState;

  @override
  void initState() {
    super.initState();

    doSomethingWithSpinner(
      context,
      ref.read(wifiListProvider.notifier).fetch().then(
        (state) {
          if (!mounted) {
            return;
          }
          setState(
            () {
              update(state);
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wifiListProvider);

    ref.listen(wifiListProvider, (previous, next) {
      if (_preservedMainWiFiState != null) {
        ref.read(wifiViewProvider.notifier).setWifiListViewStateChanged(
            _stateHasChanged(state: next, preserved: _preservedMainWiFiState));
      }
    });

    // The "Save" button is enabled if settings have changed and the data is valid.
    // A change is detected if:
    // - The main WiFi list has been modified. (Only if not in simple mode)
    // - The guest WiFi settings have changed.
    // - The user has switched to simple mode.
    // - The simple mode WiFi settings have been modified. (Only if in simple mode)
    // The data is considered valid if no secured WiFi network has an empty password.
    final hasChanged =
        _stateHasChanged(state: state, preserved: _preservedMainWiFiState);
    final isPositiveEnabled = hasChanged && _dataVerify(state);

    final wifiBands =
        state.mainWiFi.map((e) => e.radioID.bandName).toList().join(', ');

    return StyledAppPageView(
      appBarStyle: AppBarStyle.none,
      hideTopbar: true,
      scrollable: true,
      padding: EdgeInsets.zero,
      bottomBar: PageBottomBar(
        isPositiveEnabled: isPositiveEnabled,
        onPositiveTap: () async {
          if (state.isSimpleMode) {
            setQuickSetup(
              ssid: state.simpleModeWifi.ssid,
              password: state.simpleModeWifi.password,
              securityType: state.simpleModeWifi.securityType,
              mainWiFi: state.mainWiFi,
            );
          }
          final result = await _showSaveConfirmModal();
          if (!result) {
            _restoreMainWifi();
          }
        },
      ),
      useMainPadding: true,
      child: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _wifiDescription(wifiBands),
            const AppGap.medium(),
            _quickSetupSwitch(state.isSimpleMode),
            const AppGap.medium(),
            Expanded(
              child: state.isSimpleMode
                  ? SimpleModeView(
                      onWifiNameEdited: (value) {
                        setState(() {
                          final wifiItem =
                              state.simpleModeWifi.copyWith(ssid: value);
                          ref
                              .read(wifiListProvider.notifier)
                              .setSimpleModeWifi(wifiItem);
                        });
                      },
                      onWifiPasswordEdited: (value) {
                        setState(() {
                          final wifiItem =
                              state.simpleModeWifi.copyWith(password: value);
                          ref
                              .read(wifiListProvider.notifier)
                              .setSimpleModeWifi(wifiItem);
                        });
                      },
                      onSecurityTypeChanged: (value) {
                        setState(() {
                          final wifiItem = state.simpleModeWifi
                              .copyWith(securityType: value);
                          ref
                              .read(wifiListProvider.notifier)
                              .setSimpleModeWifi(wifiItem);
                        });
                      },
                    )
                  : const AdvancedModeView(),
            ),
          ],
        );
      },
    );
  }

  Widget _wifiDescription(String wifiBands) {
    return AppCard(
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            semanticLabel: 'info icon',
            color: Theme.of(context).colorScheme.primary,
          ),
          const AppGap.medium(),
          Expanded(
            child: AppText.bodySmall(
              loc(context).wifiListDescription(wifiBands),
              maxLines: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickSetupSwitch(bool isSimpleMode) {
    return AppCard(
      child: Row(
        children: [
          Icon(
            Icons.bolt_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          const AppGap.medium(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText.labelMedium(
                  loc(context).quickSetup,
                ),
                const AppGap.small1(),
                AppText.bodySmall(
                  loc(context).quickSetupDescription,
                ),
              ],
            ),
          ),
          AppSwitch(
            semanticLabel: 'quick setup switch',
            value: isSimpleMode,
            onChanged: (value) {
              setState(() {
                ref.read(wifiListProvider.notifier).setSimpleMode(value);
              });
            },
          ),
        ],
      ),
    );
  }

  void setQuickSetup({
    required String ssid,
    required String password,
    required WifiSecurityType securityType,
    required List<WiFiItem> mainWiFi,
  }) {
    logger.i('[WiFiListView] setQuickSetup');
    final notifier = ref.read(wifiListProvider.notifier);
    for (var radio in mainWiFi) {
      // SSID
      notifier.setWiFiSSID(ssid, radio.radioID);
      // Password
      notifier.setWiFiPassword(password, radio.radioID);
      // Security type
      if (radio.radioID == WifiRadioBand.radio_6 && securityType == WifiSecurityType.wpa2Or3MixedPersonal) {
        // Set to WPA3 Personal if WPA2 or WPA3 mixed personal is selected for 6G band
        notifier.setWiFiSecurityType(WifiSecurityType.wpa3Personal, radio.radioID);
      } else {
        notifier.setWiFiSecurityType(securityType, radio.radioID);
      }
      // Enable wifi
      notifier.setWiFiEnabled(true, radio.radioID);
    }
  }

  void _restoreMainWifi() {
    logger.i('[WiFiListView] restoreMainWifi');
    final notifier = ref.read(wifiListProvider.notifier);
    for (var radio in _preservedMainWiFiState!.mainWiFi) {
      // SSID
      notifier.setWiFiSSID(radio.ssid, radio.radioID);
      // Password
      notifier.setWiFiPassword(radio.password, radio.radioID);
      // Security type
      notifier.setWiFiSecurityType(radio.securityType, radio.radioID);
      // Enable wifi
      notifier.setWiFiEnabled(radio.isEnabled, radio.radioID);
    }
  }

  Future<bool> _showSaveConfirmModal() async {
    final newState = ref.read(wifiListProvider);
    final result = await showSimpleAppDialog(context,
        title: loc(context).wifiListSaveModalTitle,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.bodyMedium(loc(context).wifiListSaveModalDesc),
              ..._mloWarning(newState),
              ..._disableBandWarning(newState),
              const AppGap.medium(),
              ..._buildNewSettings(newState),
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
      if (!mounted) return false;
      doSomethingWithSpinner(
              context, ref.read(wifiListProvider.notifier).save())
          .then((state) {
        if (!mounted) return false;
        update(state);
        showChangesSavedSnackBar();
      }).catchError((error, stackTrace) {
        if (!mounted) return false;
        showRouterNotFoundAlert(context, ref,
            onComplete: () =>
                ref.read(wifiListProvider.notifier).fetch(true)).then((state) {
          if (!mounted) return false;
          update(state);
          showChangesSavedSnackBar();
        });
      }, test: (error) => error is JNAPSideEffectError).onError(
              (error, stackTrace) {
        if (!mounted) return false;
        showErrorMessageSnackBar(error);
      });
    }
    return result;
  }

  bool _stateHasChanged({required WiFiState state, WiFiState? preserved}) {
    if (preserved == null) return false;

    // A change is detected if:
    // - The main WiFi list has been modified. (Only if not in simple mode)
    // - The guest WiFi settings have changed.
    // - The user has switched to simple mode.
    // - The simple mode WiFi settings have been modified. (Only if in simple mode)
    final mainWiFiChanged = state.isSimpleMode
        ? false
        : !const ListEquality().equals(preserved.mainWiFi, state.mainWiFi);
    final guestWiFiChanged = preserved.guestWiFi != state.guestWiFi;
    final switchedToSimpleMode = preserved.isSimpleMode != state.isSimpleMode &&
        state.isSimpleMode == true;
    final simpleModeWifiChanged = state.isSimpleMode
        ? preserved.simpleModeWifi != state.simpleModeWifi
        : false;

    return mainWiFiChanged ||
        guestWiFiChanged ||
        switchedToSimpleMode ||
        simpleModeWifiChanged;
  }

  bool _dataVerify(WiFiState state) {
    // Password verify
    if (state.isSimpleMode) {
      final emptyPassword = !state.simpleModeWifi.securityType.isOpenVariant &&
          state.simpleModeWifi.password.isEmpty;
      return !emptyPassword;
    } else {
      final hasEmptyPassword = state.mainWiFi
          .any((e) => !e.securityType.isOpenVariant && e.password.isEmpty);
      return !hasEmptyPassword;
    }
  }

  void update(WiFiState? state) {
    if (!mounted) {
      return;
    }
    if (state == null) {
      return;
    }
    setState(() {
      _preservedMainWiFiState = state;
      ref
          .read(wifiViewProvider.notifier)
          .setWifiListViewStateChanged(state != _preservedMainWiFiState);
    });
  }

  List<Widget> _disableBandWarning(WiFiState state) {
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

  List<Widget> _mloWarning(WiFiState state) {
    final radios =
        Map.fromIterables(state.mainWiFi.map((e) => e.radioID), state.mainWiFi);
    final isMLOEnabled = ref.read(wifiAdvancedProvider).isMLOEnabled ?? false;
    return ref
            .read(wifiListProvider.notifier)
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

  List<Widget> _buildNewSettings(WiFiState state) {
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
