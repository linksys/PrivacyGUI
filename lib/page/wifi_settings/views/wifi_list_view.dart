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
  // Simple mode
  final _simpleWifiNameController = TextEditingController();
  final _simpleWifiPasswordController = TextEditingController();
  WifiSecurityType _simpleSecurityType = WifiSecurityType.wpa2Personal;

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
    _simpleWifiNameController.dispose();
    _simpleWifiPasswordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wifiListProvider);

    ref.listen(wifiListProvider, (previous, next) {
      if (_preservedMainWiFiState != null) {
        ref
            .read(wifiViewProvider.notifier)
            .setWifiListViewStateChanged(next != _preservedMainWiFiState);
      }
    });
    final isPositiveEnabled = (!const ListEquality()
                .equals(_preservedMainWiFiState?.mainWiFi, state.mainWiFi) ||
            _preservedMainWiFiState?.guestWiFi != state.guestWiFi ||
            _preservedMainWiFiState?.isSimpleMode != state.isSimpleMode) &&
        _dataVerify(state);

    final wifiBands =
        state.mainWiFi.map((e) => e.radioID.bandName).toList().join(', ');

    return StyledAppPageView(
      appBarStyle: AppBarStyle.none,
      hideTopbar: true,
      scrollable: true,
      padding: EdgeInsets.zero,
      bottomBar: PageBottomBar(
        isPositiveEnabled: isPositiveEnabled,
        onPositiveTap: () {
          if (state.isSimpleMode) {
            setQuickSetup(
              ssid: _simpleWifiNameController.text,
              password: _simpleWifiPasswordController.text,
              securityType: _simpleSecurityType,
              mainWiFi: state.mainWiFi,
            );
          }
          _showSaveConfirmModal();
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
                      simpleWifiNameController: _simpleWifiNameController,
                      simpleWifiPasswordController:
                          _simpleWifiPasswordController,
                      simpleSecurityType: _simpleSecurityType,
                      onWifiNameEdited: (value) {
                        setState(() {
                          _simpleWifiNameController.text = value;
                        });
                      },
                      onWifiPasswordEdited: (value) {
                        setState(() {
                          _simpleWifiPasswordController.text = value;
                        });
                      },
                      onSecurityTypeChanged: (value) {
                        setState(() {
                          _simpleSecurityType = value;
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
                if (value) {
                  _initSimpleModeSettings(ref.read(wifiListProvider));
                }
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
    for (var radio in mainWiFi) {
      final notifier = ref.read(wifiListProvider.notifier);
      // SSID
      notifier.setWiFiSSID(ssid, radio.radioID);
      // Password
      notifier.setWiFiPassword(password, radio.radioID);
      // Security type
      notifier.setWiFiSecurityType(securityType, radio.radioID);
      // Enable wifi
      notifier.setWiFiEnabled(true, radio.radioID);
    }
  }

  _showSaveConfirmModal() async {
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
              context.pop();
            },
          ),
          AppTextButton(loc(context).ok, onTap: () {
            context.pop(true);
          })
        ]);
    if (result) {
      if (!mounted) return;
      doSomethingWithSpinner(
              context, ref.read(wifiListProvider.notifier).save())
          .then((state) {
        if (!mounted) return;
        update(state);
        showChangesSavedSnackBar();
      }).catchError((error, stackTrace) {
        if (!mounted) return;
        showRouterNotFoundAlert(context, ref,
            onComplete: () =>
                ref.read(wifiListProvider.notifier).fetch(true)).then((state) {
          if (!mounted) return;
          update(state);
          showChangesSavedSnackBar();
        });
      }, test: (error) => error is JNAPSideEffectError).onError(
              (error, stackTrace) {
        if (!mounted) return;
        showErrorMessageSnackBar(error);
      });
    }
  }

  bool _dataVerify(WiFiState state) {
    // Password verify
    final hasEmptyPassword = state.mainWiFi
        .any((e) => !e.securityType.isOpenVariant && e.password.isEmpty);
    return !hasEmptyPassword;
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
      _initSimpleModeSettings(state);
    });
  }

  void _initSimpleModeSettings(WiFiState state) {
    setState(() {
      final firstEnabledWifi = _getFirstEnabledWifi(state.mainWiFi);
      _simpleWifiNameController.text = firstEnabledWifi.ssid;
      _simpleWifiPasswordController.text = firstEnabledWifi.password;
      _simpleSecurityType = firstEnabledWifi.securityType;
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

  WiFiItem _getFirstEnabledWifi(List<WiFiItem> mainWiFi) {
    return mainWiFi.firstWhereOrNull((e) => e.isEnabled) ?? mainWiFi.first;
  }
}
