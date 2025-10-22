import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/mixin/preserved_state_mixin.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/dual/models/connection.dart';
import 'package:privacy_gui/page/dual/models/port_type.dart';
import 'package:privacy_gui/page/dual/models/wan_configuration.dart';
import 'package:privacy_gui/page/dual/providers/dual_wan_settings_state.dart';
import 'package:privacy_gui/route/constants.dart';

import 'package:privacy_gui/utils.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/information_card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/dropdown/dropdown_button.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';

import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/mixin/page_snackbar_mixin.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/dual/providers/dual_wan_settings_provider.dart';
import 'package:privacygui_widgets/widgets/label/text_label.dart';
import 'package:privacy_gui/page/dual/widgets/wan_configuration_forms.dart';
import 'package:privacy_gui/page/dual/widgets/operation_mode_card.dart';
import 'package:privacy_gui/page/dual/widgets/connection_status_card.dart';
import 'package:privacy_gui/page/dual/widgets/speed_diagnostics_card.dart';

class DualWANSettingsView extends ArgumentsConsumerStatefulView {
  const DualWANSettingsView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<DualWANSettingsView> createState() =>
      _DualWANSettingsViewState();
}

class _DualWANSettingsViewState extends ConsumerState<DualWANSettingsView>
    with
        PageSnackbarMixin,
        PreservedStateMixin<DualWANSettings, DualWANSettingsView> {
  late final DualWANSettingsNotifier _notifier;
  final Map<TextEditingController, String?> _errors = {};

  // show logging and advanced settings
  bool showLoggingAndAdvancedSettings = false;

  @override
  void initState() {
    _notifier = ref.read(dualWANSettingsProvider.notifier);

    doSomethingWithSpinner(
      context,
      _notifier.fetch(),
    ).then((value) {
      preservedState = value?.settings;
    });
    super.initState();
  }

  @override
  void dispose() {
    _errors.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dualWANSettingsProvider);
    final twoColWidth = ResponsiveLayout.isOverMedimumLayout(context)
        ? 6.col
        : ResponsiveLayout.isOverSmallLayout(context)
            ? 8.col
            : 4.col;
    final gutter = ResponsiveLayout.columnPadding(context);
    return StyledAppPageView(
        // scrollable: true,
        pageContentType: PageContentType.fit,
        title: loc(context).dualWanTitle,
        onBackTap: isStateChanged(state.settings)
            ? () async {
                if (!mounted) return;

                final goBack = await showUnsavedAlert(context);
                if (goBack == true) {
                  context.pop();
                }
              }
            : null,
        bottomBar: PageBottomBar(
          isPositiveEnabled: _errors.isEmpty && isStateChanged(state.settings),
          onPositiveTap: () {
            if (!mounted) return;

            final primaryWAN =
                ref.read(dualWANSettingsProvider).settings.primaryWAN;
            final secondaryWAN =
                ref.read(dualWANSettingsProvider).settings.secondaryWAN;

            final isPrimaryValid = _validateWANSettingsForm(true, primaryWAN);
            final isSecondaryValid =
                _validateWANSettingsForm(false, secondaryWAN);

            if (!isPrimaryValid || !isSecondaryValid) {
              return; // Stop if validation fails
            }

            doSomethingWithSpinner(
              context,
              _notifier.save(),
            ).then((value) {
              if (!mounted) return;
              if (value != null) {
                showChangesSavedSnackBar();
              }
              preservedState = value?.settings;
            }).onError((e, _) {
              if (!mounted) return;
              showErrorMessageSnackBar(e);
            });
          },
        ),
        child: (context, constraints) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: Spacing.large1,
              children: [
                _enableCard(),
                if (state.settings.enable) ...[
                  OperationModeCard(
                    twoColWidth: twoColWidth,
                  ),
                  Wrap(
                    spacing: gutter,
                    runSpacing: gutter,
                    children: [
                      SizedBox(
                        width: twoColWidth,
                        child: _primaryWANCard(),
                      ),
                      SizedBox(
                        width: twoColWidth,
                        child: _secondaryWANCard(),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: gutter,
                    runSpacing: gutter,
                    children: [
                      Container(
                        constraints: const BoxConstraints(
                          minHeight: 486,
                        ),
                        width: twoColWidth,
                        child: const ConnectionStatusCard(),
                      ),
                      if (state.status.speedStatus != null)
                        Container(
                          constraints: const BoxConstraints(
                            minHeight: 486,
                          ),
                          width: twoColWidth,
                          child: const SpeedDiagnosticsCard(),
                        ),
                    ],
                  ),
                  if (state.settings.loggingOptions != null)
                    AppFilledButton(
                      key: ValueKey('toggleLoggingAndAdvancedSettings'),
                      showLoggingAndAdvancedSettings
                          ? loc(context).hideLoggingAndAdvancedSettings
                          : loc(context).showLoggingAndAdvancedSettings,
                      icon: LinksysIcons.settings,
                      onTap: () {
                        setState(() {
                          showLoggingAndAdvancedSettings =
                              !showLoggingAndAdvancedSettings;
                        });
                      },
                    ),
                  if (showLoggingAndAdvancedSettings)
                    _loggingAndAdvancedSettingsCard(twoColWidth, gutter),
                  const AppGap.large1(),
                ],
              ],
            ),
          );
        });
  }

  Widget _enableCard() {
    final enable = ref.watch(dualWANSettingsProvider).settings.enable;
    return AppInformationCard(
      headerIcon: Icon(LinksysIcons.networkNode),
      title: loc(context).dualWan,
      description: loc(context).dualWanDescription,
      content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.labelLarge(loc(context).dualWanEnable),
                  AppText.bodyLarge(loc(context).dualWanEnableDescription),
                ]),
            AppSwitch(
                value: enable,
                onChanged: (value) {
                  _notifier.updateDualWANEnable(value);
                }),
          ]),
    );
  }


  Widget _primaryWANCard() {
    final primaryWAN = ref.watch(dualWANSettingsProvider).settings.primaryWAN;
    final status = ref.watch(dualWANSettingsProvider).status;
    return _wanCard(primaryWAN, status, true, (wan) {
      _notifier.updatePrimaryWAN(wan);
    });
  }

  Widget _secondaryWANCard() {
    final secondaryWAN =
        ref.watch(dualWANSettingsProvider).settings.secondaryWAN;
    final status = ref.watch(dualWANSettingsProvider).status;
    return _wanCard(secondaryWAN, status, false, (wan) {
      _notifier.updateSecondaryWAN(wan);
    });
  }

  Widget _wanCard(DualWANConfiguration wan, DualWANStatus status,
      bool isPrimary, void Function(DualWANConfiguration wan) onChanged) {
    return AppInformationCard(
      headerIcon: Icon(Icons.settings_ethernet,
          color: isPrimary
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorSchemeExt.orange),
      title: isPrimary
          ? loc(context).primaryWanConfiguration
          : loc(context).secondaryWanConfiguration,
      description: isPrimary
          ? loc(context).primaryWanDescription
          : loc(context).secondaryWanDescription,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          AppText.labelLarge(loc(context).connectionType),
          AppDropdownButton<String>(
            key: ValueKey(isPrimary ? 'primaryWANType' : 'secondaryWANType'),
            selected: wan.wanType,
            items: status.supportedWANTypes,
            label: (value) => value,
            onChanged: (value) {
              onChanged(wan.copyWith(wanType: value));
            },
          ),
          const AppGap.medium(),
          if (wan.wanType != 'DHCP')
            _buildWANSettingsForm(isPrimary, wan, onChanged),
          // AppText.labelLarge(loc(context).mtu),
          // AppTextField.minMaxNumber(
          //   key: ValueKey('${isPrimary ? 'primary' : 'secondary'}MtuSizeText'),
          //   controller: isPrimary
          //       ? _primaryMTUSizeController
          //       : _secondaryMTUSizeController,
          //   errorText: _errors[isPrimary
          //       ? _primaryMTUSizeController
          //       : _secondaryMTUSizeController],
          //   border: const OutlineInputBorder(),
          //   inputType: TextInputType.number,
          //   min: 576,
          //   max: NetworkUtils.getMaxMtu(wan.wanType),
          //   onChanged: (value) {
          //     final intVal = int.tryParse(value) ?? 0;
          //     // 0 means Auto
          //     if (intVal == 0 ||
          //         (576 <= intVal &&
          //             intVal <=
          //                 NetworkUtils.getMaxMtu(wan.wanType))) {
          //       _errors.remove(isPrimary
          //           ? _primaryMTUSizeController
          //           : _secondaryMTUSizeController);
          //     } else {
          //       // invalid valude
          //       _errors[isPrimary
          //           ? _primaryMTUSizeController
          //           : _secondaryMTUSizeController] = loc(context).invalidNumber;
          //     }
          //   },
          //   onFocusChanged: (focus) {
          //     if (!focus) {
          //       final intVal = int.tryParse(isPrimary
          //               ? _primaryMTUSizeController.text
          //               : _secondaryMTUSizeController.text) ??
          //           0;
          //       // 0 means Auto
          //       if (intVal == 0 ||
          //           (576 <= intVal &&
          //               intVal <=
          //                   NetworkUtils.getMaxMtu(wan.wanType))) {
          //         onChanged(wan.copyWith(mtu: intVal));
          //       }
          //       setState(() {});
          //     }
          //   },
          // ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.bodyMedium(loc(context).status),
              _wanConnectionLabel(isPrimary
                  ? status.connectionStatus.primaryStatus
                  : status.connectionStatus.secondaryStatus),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.bodyMedium(loc(context).ipAddress),
              AppText.bodyMedium((isPrimary
                      ? status.connectionStatus.primaryWANIPAddress
                      : status.connectionStatus.secondaryWANIPAddress) ??
                  '--'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _wanConnectionLabel(DualWANConnection status) {
    return AppLabelText(
        label: status.toDisplayString(context),
        labelColor: status.resolveLabelColor(context),
        color: status.resolveLabelColor(context).withAlpha(0x10));
  }

  Widget _buildWANSettingsForm(bool isPrimary, DualWANConfiguration wan,
      Function(DualWANConfiguration) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        switch (wan.wanType) {
          'Static' => StaticWANSettingsForm(
              isPrimary: isPrimary,
              wan: wan,
              onChanged: onChanged,
              errors: _errors,
            ),
          'PPPoE' => PPPoEWANSettingsForm(
              isPrimary: isPrimary,
              wan: wan,
              onChanged: onChanged,
              errors: _errors,
            ),
          'PPTP' => PPTPWANSettingsForm(
              isPrimary: isPrimary,
              wan: wan,
              onChanged: onChanged,
              errors: _errors,
            ),
          'L2TP' => L2TPWANSettingsForm(
              isPrimary: isPrimary,
              wan: wan,
              onChanged: onChanged,
              errors: _errors,
            ),
          _ => const SizedBox.shrink(),
        },
        const AppGap.small3(),
      ],
    );
  }




  Widget _loggingAndAdvancedSettingsCard(double twoColWidth, double gutter) {
    final loggingOptions =
        ref.watch(dualWANSettingsProvider).settings.loggingOptions;
    return AppInformationCard(
      title: loc(context).loggingAdvancedSettings,
      description: loc(context).loggingAdvancedSettingsDescription,
      content: Column(
        spacing: Spacing.large1,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                AppText.labelLarge(loc(context).loggingOptions),
                const AppGap.medium(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AppText.labelMedium(loc(context).logFailoverEvents),
                    AppSwitch(
                      value: loggingOptions?.failoverEvents ?? false,
                      onChanged: (value) {
                        if (loggingOptions == null) return;

                        _notifier.updateLoggingOptions(
                            loggingOptions.copyWith(failoverEvents: value));
                      },
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AppText.labelMedium(loc(context).logWanUptime),
                    AppSwitch(
                      value: loggingOptions?.wanUptime ?? false,
                      onChanged: (value) {
                        if (loggingOptions == null) return;

                        _notifier.updateLoggingOptions(
                            loggingOptions.copyWith(wanUptime: value));
                      },
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AppText.labelMedium(loc(context).logSpeedChecks),
                    AppSwitch(
                      value: loggingOptions?.speedChecks ?? false,
                      onChanged: (value) {
                        if (loggingOptions == null) return;
                        _notifier.updateLoggingOptions(
                            loggingOptions.copyWith(speedChecks: value));
                      },
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AppText.labelMedium(loc(context).logThroughputData),
                    AppSwitch(
                      value: loggingOptions?.throughputData ?? false,
                      onChanged: (value) {
                        if (loggingOptions == null) return;
                        _notifier.updateLoggingOptions(
                            loggingOptions.copyWith(throughputData: value));
                      },
                    ),
                  ],
                ),
                const Divider(
                  height: 24,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: AppOutlinedButton.fillWidth(loc(context).viewLogs,
                      onTap: () {
                    // Log View
                    context.pushNamed(RouteNamed.dualWANLog);
                  }),
                ),
              ],
            ),
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              spacing: Spacing.small2,
              children: [
                AppText.labelLarge(loc(context).selfTestTools),
                const AppGap.medium(),
                AppOutlinedButton.fillWidth(loc(context).connectionHealthCheck,
                    onTap: () {}),
                AppOutlinedButton.fillWidth(loc(context).failoverTest,
                    onTap: () {}),
              ],
            ),
          ),
          _failoverWarningCard(),
        ],
      ),
    );
  }

  Widget _failoverWarningCard() {
    return AppCard(
      showBorder: false,
      color: Theme.of(context).colorSchemeExt.orange?.withAlpha(0x10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LinksysIcons.infoCircle,
            semanticLabel: 'info icon',
            color: Theme.of(context).colorSchemeExt.orange,
          ),
          const AppGap.medium(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.labelMedium(
                  loc(context).failoverBehavior,
                  color: Theme.of(context).colorSchemeExt.orange,
                ),
                AppText.bodyMedium(
                  loc(context).failoverBehaviorDescription,
                  color: Theme.of(context).colorSchemeExt.orange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _validateWANSettingsForm(bool isPrimary, DualWANConfiguration wan) {
    bool isValid = true;

    switch (wan.wanType) {
      case 'Static':
        // Validation handled by StaticWANSettingsForm
        break;
      case 'PPPoE':
        // Validation handled by PPPoEWANSettingsForm
        break;
      case 'PPTP':
        // Validation handled by PPTPWANSettingsForm
        break;
      case 'L2TP':
        // Validation handled by L2TPWANSettingsForm
        break;
    }
    return isValid;
  }
}
