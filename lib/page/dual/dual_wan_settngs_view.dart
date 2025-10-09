import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/mixin/preserved_state_mixin.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/dual/models/balance_ratio.dart';
import 'package:privacy_gui/page/dual/models/connection.dart';
import 'package:privacy_gui/page/dual/models/connection_status.dart';
import 'package:privacy_gui/page/dual/models/mode.dart';
import 'package:privacy_gui/page/dual/models/port_type.dart';
import 'package:privacy_gui/page/dual/models/wan_configuration.dart';
import 'package:privacy_gui/page/dual/providers/dual_wan_settings_state.dart';
import 'package:privacy_gui/route/constants.dart';

import 'package:privacy_gui/utils.dart';
import 'package:privacy_gui/validator_rules/input_validators.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/information_card.dart';
import 'package:privacygui_widgets/widgets/card/selection_card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/dropdown/dropdown_button.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/input_field/ip_form_field.dart';

import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/mixin/page_snackbar_mixin.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/dual/providers/dual_wan_settings_provider.dart';
import 'package:privacygui_widgets/widgets/label/text_label.dart';

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

  // Primary
  late final TextEditingController _primaryMTUSizeController;
  late final TextEditingController _primaryStaticIpAddressController;
  late final TextEditingController _primaryStaticSubnetController;
  late final TextEditingController _primaryStaticGatewayController;
  late final TextEditingController _primaryStaticDNSController;
  late final TextEditingController _primaryPPPoEUsernameController;
  late final TextEditingController _primaryPPPoEPasswordController;
  late final TextEditingController _primaryPPPoEServiceNameController;
  late final TextEditingController _primaryPPTPUsernameController;
  late final TextEditingController _primaryPPTPPasswordController;
  late final TextEditingController _primaryPPTPServerController;

  // Secondary
  late final TextEditingController _secondaryMTUSizeController;
  late final TextEditingController _secondaryStaticIpAddressController;
  late final TextEditingController _secondaryStaticSubnetController;
  late final TextEditingController _secondaryStaticGatewayController;
  late final TextEditingController _secondaryStaticDNSController;
  late final TextEditingController _secondaryPPPoEUsernameController;
  late final TextEditingController _secondaryPPPoEPasswordController;
  late final TextEditingController _secondaryPPPoEServiceNameController;
  late final TextEditingController _secondaryPPTPUsernameController;
  late final TextEditingController _secondaryPPTPPasswordController;
  late final TextEditingController _secondaryPPTPServerController;

  // errors
  final Map<TextEditingController, String?> _errors = {};

  // show logging and advanced settings
  bool showLoggingAndAdvancedSettings = false;

  @override
  void initState() {
    _notifier = ref.read(dualWANSettingsProvider.notifier);

    _primaryMTUSizeController = TextEditingController();
    _primaryStaticIpAddressController = TextEditingController();
    _primaryStaticSubnetController = TextEditingController();
    _primaryStaticGatewayController = TextEditingController();
    _primaryStaticDNSController = TextEditingController();
    _primaryPPPoEUsernameController = TextEditingController();
    _primaryPPPoEPasswordController = TextEditingController();
    _primaryPPPoEServiceNameController = TextEditingController();
    _primaryPPTPUsernameController = TextEditingController();
    _primaryPPTPPasswordController = TextEditingController();
    _primaryPPTPServerController = TextEditingController();

    _secondaryMTUSizeController = TextEditingController();
    _secondaryStaticIpAddressController = TextEditingController();
    _secondaryStaticSubnetController = TextEditingController();
    _secondaryStaticGatewayController = TextEditingController();
    _secondaryStaticDNSController = TextEditingController();
    _secondaryPPPoEUsernameController = TextEditingController();
    _secondaryPPPoEPasswordController = TextEditingController();
    _secondaryPPPoEServiceNameController = TextEditingController();
    _secondaryPPTPUsernameController = TextEditingController();
    _secondaryPPTPPasswordController = TextEditingController();
    _secondaryPPTPServerController = TextEditingController();

    doSomethingWithSpinner(
      context,
      _notifier.fetch(),
    ).then((value) {
      preservedState = value?.settings;
      _initWANConfiguration(preservedState);
    });
    super.initState();
  }

  @override
  void dispose() {
    _errors.clear();
    _primaryMTUSizeController.dispose();
    _primaryStaticIpAddressController.dispose();
    _primaryStaticSubnetController.dispose();
    _primaryStaticGatewayController.dispose();
    _primaryStaticDNSController.dispose();
    _primaryPPPoEUsernameController.dispose();
    _primaryPPPoEPasswordController.dispose();
    _primaryPPPoEServiceNameController.dispose();
    _primaryPPTPUsernameController.dispose();
    _primaryPPTPPasswordController.dispose();
    _primaryPPTPServerController.dispose();

    _secondaryMTUSizeController.dispose();
    _secondaryStaticIpAddressController.dispose();
    _secondaryStaticSubnetController.dispose();
    _secondaryStaticGatewayController.dispose();
    _secondaryStaticDNSController.dispose();
    _secondaryPPPoEUsernameController.dispose();
    _secondaryPPPoEPasswordController.dispose();
    _secondaryPPPoEServiceNameController.dispose();
    _secondaryPPTPUsernameController.dispose();
    _secondaryPPTPPasswordController.dispose();
    _secondaryPPTPServerController.dispose();
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
                  _operationModeCard(twoColWidth, gutter),
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
                        constraints: BoxConstraints(
                          minHeight: 486,
                        ),
                        width: twoColWidth,
                        child: _connectionStatusCard(),
                      ),
                      if (state.status.speedStatus != null)
                        Container(
                          constraints: BoxConstraints(
                            minHeight: 486,
                          ),
                          width: twoColWidth,
                          child: _speedAndDiagnosticsCard(),
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

  void _initWANConfiguration(DualWANSettings? settings) {
    if (settings == null) return;
    switch (settings.primaryWAN.wanType) {
      case 'Static':
        _primaryStaticIpAddressController.text =
            settings.primaryWAN.staticIpAddress ?? '';
        _primaryStaticSubnetController.text =
            settings.primaryWAN.networkPrefixLength != null
                ? NetworkUtils.prefixLengthToSubnetMask(
                    settings.primaryWAN.networkPrefixLength!)
                : '';
        _primaryStaticGatewayController.text =
            settings.primaryWAN.staticGateway ?? '';
        _primaryStaticDNSController.text =
            settings.primaryWAN.staticDns1 ?? '';
        break;
      case 'PPPoE':
        _primaryPPPoEUsernameController.text =
            settings.primaryWAN.username ?? '';
        _primaryPPPoEPasswordController.text =
            settings.primaryWAN.password ?? '';
        _primaryPPPoEServiceNameController.text =
            settings.primaryWAN.serviceName ?? '';
        break;
      case 'PPTP':
        _primaryPPTPUsernameController.text =
            settings.primaryWAN.username ?? '';
        _primaryPPTPPasswordController.text =
            settings.primaryWAN.password ?? '';
        _primaryPPTPServerController.text =
            settings.primaryWAN.serviceName ?? '';
        break;
    }
    _primaryMTUSizeController.text = settings.primaryWAN.mtu.toString();

    switch (settings.secondaryWAN.wanType) {
      case 'Static':
        _secondaryStaticIpAddressController.text =
            settings.secondaryWAN.staticIpAddress ?? '';
        _secondaryStaticSubnetController.text =
            settings.secondaryWAN.networkPrefixLength != null
                ? NetworkUtils.prefixLengthToSubnetMask(
                    settings.secondaryWAN.networkPrefixLength!)
                : '';
        _secondaryStaticGatewayController.text =
            settings.secondaryWAN.staticGateway ?? '';
        _secondaryStaticDNSController.text =
            settings.secondaryWAN.staticDns1 ?? '';
        break;
      case 'PPPoE':
        _secondaryPPPoEUsernameController.text =
            settings.secondaryWAN.username ?? '';
        _secondaryPPPoEPasswordController.text =
            settings.secondaryWAN.password ?? '';
        _secondaryPPPoEServiceNameController.text =
            settings.secondaryWAN.serviceName ?? '';
        break;
      case 'PPTP':
        _secondaryPPTPUsernameController.text =
            settings.secondaryWAN.username ?? '';
        _secondaryPPTPPasswordController.text =
            settings.secondaryWAN.password ?? '';
        _secondaryPPTPServerController.text =
            settings.secondaryWAN.serviceName ?? '';
        break;
    }
    _secondaryMTUSizeController.text = settings.secondaryWAN.mtu.toString();
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

  Widget _operationModeCard(double twoColWidth, double gutter) {
    final mode = ref.watch(dualWANSettingsProvider).settings.mode;
    final balanceRatio =
        ref.watch(dualWANSettingsProvider).settings.balanceRatio;
    return AppInformationCard(
      title: loc(context).dualWanOperationMode,
      description: loc(context).dualWanOperationModeDescription,
      content: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: Spacing.medium,
        children: [
          Wrap(spacing: gutter, runSpacing: gutter, children: [
            SizedBox(
              width: twoColWidth - gutter / 2 - 6,
              child: AppSelectionCard(
                value: DualWANMode.failover,
                groupValue: mode,
                title: DualWANMode.failover.toDisplayString(context),
                label: 'Recommended',
                description: loc(context).dualWanFailoverDescription,
                onTap: () {
                  _notifier.updateOperationMode(DualWANMode.failover);
                },
              ),
            ),
            SizedBox(
              width: twoColWidth - gutter / 2 - 6,
              child: AppSelectionCard(
                value: DualWANMode.loadBalanced,
                groupValue: mode,
                title: DualWANMode.loadBalanced.toDisplayString(context),
                label: 'Advanced',
                description: loc(context).dualWanLoadBalancingDescription,
                onTap: () {
                  _notifier.updateOperationMode(DualWANMode.loadBalanced);
                },
              ),
            ),
          ]),
          if (mode == DualWANMode.loadBalanced) ...[
            AppCard(
              color: Theme.of(context).colorScheme.primary.withAlpha(0x10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                spacing: Spacing.small2,
                children: [
                  AppText.labelLarge(loc(context).dualWanLoadBalanceRatio),
                  AppDropdownButton<DualWANBalanceRatio>(
                    selected: balanceRatio,
                    items: DualWANBalanceRatio.values,
                    label: (value) => value.toDisplayString(context),
                    onChanged: (value) {
                      _notifier.updateBalanceRatio(value);
                    },
                  ),
                  AppText.bodySmall(
                      loc(context).dualWanLoadBalanceRatioDescription),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _primaryWANCard() {
    final primaryWAN = ref.watch(dualWANSettingsProvider).settings.primaryWAN;
    final connectionStatus =
        ref.watch(dualWANSettingsProvider).status.connectionStatus;
    return _wanCard(primaryWAN, connectionStatus, true, (wan) {
      _notifier.updatePrimaryWAN(wan);
    });
  }

  Widget _secondaryWANCard() {
    final secondaryWAN =
        ref.watch(dualWANSettingsProvider).settings.secondaryWAN;
    final connectionStatus =
        ref.watch(dualWANSettingsProvider).status.connectionStatus;
    return _wanCard(secondaryWAN, connectionStatus, false, (wan) {
      _notifier.updateSecondaryWAN(wan);
    });
  }

  Widget _wanCard(
      DualWANConfiguration wan,
      DualWANConnectionStatus connectionStatus,
      bool isPrimary,
      void Function(DualWANConfiguration wan) onChanged) {
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
            items: wan.supportedWANType,
            label: (value) => value,
            onChanged: (value) {
              onChanged(wan.copyWith(wanType: value));
            },
          ),
          const AppGap.medium(),
          if (wan.wanType != 'DHCP')
            _buildWANSettingsForm(isPrimary, wan, onChanged),
          AppText.labelLarge(loc(context).mtu),
          AppTextField.minMaxNumber(
            key: ValueKey('${isPrimary ? 'primary' : 'secondary'}MtuSizeText'),
            controller: isPrimary
                ? _primaryMTUSizeController
                : _secondaryMTUSizeController,
            errorText: _errors[isPrimary
                ? _primaryMTUSizeController
                : _secondaryMTUSizeController],
            border: const OutlineInputBorder(),
            inputType: TextInputType.number,
            min: 576,
            max: NetworkUtils.getMaxMtu(wan.wanType),
            onChanged: (value) {
              final intVal = int.tryParse(value) ?? 0;
              // 0 means Auto
              if (intVal == 0 ||
                  (576 <= intVal &&
                      intVal <=
                          NetworkUtils.getMaxMtu(wan.wanType))) {
                _errors.remove(isPrimary
                    ? _primaryMTUSizeController
                    : _secondaryMTUSizeController);
              } else {
                // invalid valude
                _errors[isPrimary
                    ? _primaryMTUSizeController
                    : _secondaryMTUSizeController] = loc(context).invalidNumber;
              }
            },
            onFocusChanged: (focus) {
              if (!focus) {
                final intVal = int.tryParse(isPrimary
                        ? _primaryMTUSizeController.text
                        : _secondaryMTUSizeController.text) ??
                    0;
                // 0 means Auto
                if (intVal == 0 ||
                    (576 <= intVal &&
                        intVal <=
                            NetworkUtils.getMaxMtu(wan.wanType))) {
                  onChanged(wan.copyWith(mtu: intVal));
                }
                setState(() {});
              }
            },
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.bodyMedium(loc(context).status),
              _wanConnectionLabel(isPrimary
                  ? connectionStatus.primaryStatus
                  : connectionStatus.secondaryStatus),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.bodyMedium(loc(context).ipAddress),
              AppText.bodyMedium((isPrimary
                      ? connectionStatus.primaryWANIPAddress
                      : connectionStatus.secondaryWANIPAddress) ??
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
    final List<Widget> children = switch (wan.wanType) {
      'Static' => [
          AppText.labelLarge(loc(context).ipAddress),
          AppIPFormField(
            key: ValueKey(isPrimary
                ? 'primaryStaticIpAddress'
                : 'secondaryStaticIpAddress'),
            semanticLabel: isPrimary
                ? 'primaryStaticIpAddress'
                : 'secondaryStaticIpAddress',
            identifier: isPrimary
                ? 'primaryStaticIpAddress'
                : 'secondaryStaticIpAddress',
            border: const OutlineInputBorder(),
            controller: isPrimary
                ? _primaryStaticIpAddressController
                : _secondaryStaticIpAddressController,
            onChanged: (value) {
              final isValid = IpAddressRequiredValidator().validate(value);
              if (isValid) {
                _errors.remove(isPrimary
                    ? _primaryStaticIpAddressController
                    : _secondaryStaticIpAddressController);
              } else {
                _errors[isPrimary
                        ? _primaryStaticIpAddressController
                        : _secondaryStaticIpAddressController] =
                    loc(context).invalidIpAddress;
              }
            },
            onFocusChanged: (focus) {
              if (!focus) {
                final value = isPrimary
                    ? _primaryStaticIpAddressController.text
                    : _secondaryStaticIpAddressController.text;
                onChanged(wan.copyWith(staticIpAddress: () => value));
                setState(() {});
              }
            },
            errorText: _errors[isPrimary
                ? _primaryStaticIpAddressController
                : _secondaryStaticIpAddressController],
          ),
          const AppGap.small3(),
          AppText.labelLarge(loc(context).subnetMask),
          AppIPFormField(
            key: ValueKey(
                isPrimary ? 'primaryStaticSubnet' : 'secondaryStaticSubnet'),
            semanticLabel:
                isPrimary ? 'primaryStaticSubnet' : 'secondaryStaticSubnet',
            identifier:
                isPrimary ? 'primaryStaticSubnet' : 'secondaryStaticSubnet',
            border: const OutlineInputBorder(),
            controller: isPrimary
                ? _primaryStaticSubnetController
                : _secondaryStaticSubnetController,
            onChanged: (value) {
              final isValid = SubnetMaskValidator().validate(value);
              if (isValid) {
                _errors.remove(isPrimary
                    ? _primaryStaticSubnetController
                    : _secondaryStaticSubnetController);
              } else {
                _errors[isPrimary
                        ? _primaryStaticSubnetController
                        : _secondaryStaticSubnetController] =
                    loc(context).invalidSubnetMask;
              }
            },
            onFocusChanged: (focus) {
              if (!focus) {
                final value = isPrimary
                    ? _primaryStaticSubnetController.text
                    : _secondaryStaticSubnetController.text;
                // Prevent to update networkPrefixLength if subnet mask is invalid
                if (SubnetMaskValidator().validate(value)) {
                  onChanged(wan.copyWith(
                      networkPrefixLength: () =>
                          NetworkUtils.subnetMaskToPrefixLength(value)));
                }
                setState(() {});
              }
            },
            errorText: _errors[isPrimary
                ? _primaryStaticSubnetController
                : _secondaryStaticSubnetController],
          ),
          const AppGap.small3(),
          AppText.labelLarge(loc(context).gateway),
          AppIPFormField(
            key: ValueKey(
                isPrimary ? 'primaryStaticGateway' : 'secondaryStaticGateway'),
            semanticLabel:
                isPrimary ? 'primaryStaticGateway' : 'secondaryStaticGateway',
            identifier:
                isPrimary ? 'primaryStaticGateway' : 'secondaryStaticGateway',
            border: const OutlineInputBorder(),
            controller: isPrimary
                ? _primaryStaticGatewayController
                : _secondaryStaticGatewayController,
            onChanged: (value) {
              final isValid = IpAddressValidator().validate(value);
              if (isValid) {
                _errors.remove(isPrimary
                    ? _primaryStaticGatewayController
                    : _secondaryStaticGatewayController);
              } else {
                _errors[isPrimary
                        ? _primaryStaticGatewayController
                        : _secondaryStaticGatewayController] =
                    loc(context).invalidIpAddress;
              }
            },
            onFocusChanged: (focus) {
              if (!focus) {
                final value = isPrimary
                    ? _primaryStaticGatewayController.text
                    : _secondaryStaticGatewayController.text;
                onChanged(wan.copyWith(staticGateway: () => value));
                setState(() {});
              }
            },
            errorText: _errors[isPrimary
                ? _primaryStaticGatewayController
                : _secondaryStaticGatewayController],
          ),
        ],
      'PPPoE' => [
          AppText.labelLarge(loc(context).username),
          AppTextField.outline(
            key: ValueKey(
                isPrimary ? 'primaryPPPoEUsername' : 'secondaryPPPoEUsername'),
            semanticLabel:
                isPrimary ? 'primaryPPPoEUsername' : 'secondaryPPPoEUsername',
            identifier:
                isPrimary ? 'primaryPPPoEUsername' : 'secondaryPPPoEUsername',
            controller: isPrimary
                ? _primaryPPPoEUsernameController
                : _secondaryPPPoEUsernameController,
            onChanged: (value) {
              final isValid = value.isNotEmpty;
              if (isValid) {
                _errors.remove(isPrimary
                    ? _primaryPPPoEUsernameController
                    : _secondaryPPPoEUsernameController);
              } else {
                _errors[isPrimary
                        ? _primaryPPPoEUsernameController
                        : _secondaryPPPoEUsernameController] =
                    loc(context).invalidUsername;
              }
            },
            onFocusChanged: (focus) {
              if (!focus) {
                final value = isPrimary
                    ? _primaryPPPoEUsernameController.text
                    : _secondaryPPPoEUsernameController.text;
                onChanged(wan.copyWith(username: () => value));
                setState(() {});
              }
            },
            errorText: _errors[isPrimary
                ? _primaryPPPoEUsernameController
                : _secondaryPPPoEUsernameController],
          ),
          const AppGap.small3(),
          AppText.labelLarge(loc(context).password),
          AppTextField.outline(
            key: ValueKey(
                isPrimary ? 'primaryPPPoEPassword' : 'secondaryPPPoEPassword'),
            semanticLabel:
                isPrimary ? 'primaryPPPoEPassword' : 'secondaryPPPoEPassword',
            identifier:
                isPrimary ? 'primaryPPPoEPassword' : 'secondaryPPPoEPassword',
            controller: isPrimary
                ? _primaryPPPoEPasswordController
                : _secondaryPPPoEPasswordController,
            onChanged: (value) {
              final isValid = value.isNotEmpty;
              if (isValid) {
                _errors.remove(isPrimary
                    ? _primaryPPPoEPasswordController
                    : _secondaryPPPoEPasswordController);
              } else {
                _errors[isPrimary
                        ? _primaryPPPoEPasswordController
                        : _secondaryPPPoEPasswordController] =
                    loc(context).invalidPassword;
              }
            },
            onFocusChanged: (focus) {
              if (!focus) {
                final value = isPrimary
                    ? _primaryPPPoEPasswordController.text
                    : _secondaryPPPoEPasswordController.text;
                onChanged(wan.copyWith(password: () => value));
                setState(() {});
              }
            },
            errorText: _errors[isPrimary
                ? _primaryPPPoEPasswordController
                : _secondaryPPPoEPasswordController],
          ),
          const AppGap.small3(),
          AppText.labelLarge(loc(context).serviceNameOptional),
          AppTextField.outline(
            key: ValueKey(isPrimary
                ? 'primaryPPPoEServiceName'
                : 'secondaryPPPoEServiceName'),
            semanticLabel: isPrimary
                ? 'primaryPPPoEServiceName'
                : 'secondaryPPPoEServiceName',
            identifier: isPrimary
                ? 'primaryPPPoEServiceName'
                : 'secondaryPPPoEServiceName',
            controller: isPrimary
                ? _primaryPPPoEServiceNameController
                : _secondaryPPPoEServiceNameController,
            onChanged: (value) {},
            onFocusChanged: (focus) {
              if (!focus) {
                final value = isPrimary
                    ? _primaryPPPoEServiceNameController.text
                    : _secondaryPPPoEServiceNameController.text;
                onChanged(wan.copyWith(serviceName: () => value));
                setState(() {});
              }
            },
            errorText: _errors[isPrimary
                ? _primaryPPPoEServiceNameController
                : _secondaryPPPoEServiceNameController],
          ),
        ],
      'PPTP' => [
          AppText.labelLarge(loc(context).serviceIpName),
          AppTextField.outline(
            key: ValueKey(
                isPrimary ? 'primaryPPTPServer' : 'secondaryPPTPServer'),
            semanticLabel:
                isPrimary ? 'primaryPPTPServer' : 'secondaryPPTPServer',
            identifier: isPrimary ? 'primaryPPTPServer' : 'secondaryPPTPServer',
            controller: isPrimary
                ? _primaryPPTPServerController
                : _secondaryPPTPServerController,
            onChanged: (value) {},
            onFocusChanged: (focus) {
              if (!focus) {
                final value = isPrimary
                    ? _primaryPPTPServerController.text
                    : _secondaryPPTPServerController.text;
                onChanged(wan.copyWith(serverIp: () => value));
                setState(() {});
              }
            },
            errorText: _errors[isPrimary
                ? _primaryPPTPServerController
                : _secondaryPPTPServerController],
          ),
          const AppGap.small3(),
          AppText.labelLarge(loc(context).username),
          AppTextField.outline(
            key: ValueKey(
                isPrimary ? 'primaryPPTPUsername' : 'secondaryPPTPUsername'),
            semanticLabel:
                isPrimary ? 'primaryPPTPUsername' : 'secondaryPPTPUsername',
            identifier:
                isPrimary ? 'primaryPPTPUsername' : 'secondaryPPTPUsername',
            controller: isPrimary
                ? _primaryPPTPUsernameController
                : _secondaryPPTPUsernameController,
            onChanged: (value) {
              final isValid = value.isNotEmpty;
              if (isValid) {
                _errors.remove(isPrimary
                    ? _primaryPPTPUsernameController
                    : _secondaryPPTPUsernameController);
              } else {
                _errors[isPrimary
                        ? _primaryPPTPUsernameController
                        : _secondaryPPTPUsernameController] =
                    loc(context).invalidUsername;
              }
            },
            onFocusChanged: (focus) {
              if (!focus) {
                final value = isPrimary
                    ? _primaryPPTPUsernameController.text
                    : _secondaryPPTPUsernameController.text;
                onChanged(wan.copyWith(username: () => value));
                setState(() {});
              }
            },
            errorText: _errors[isPrimary
                ? _primaryPPTPUsernameController
                : _secondaryPPTPUsernameController],
          ),
          const AppGap.small3(),
          AppText.labelLarge(loc(context).password),
          AppTextField.outline(
            key: ValueKey(
                isPrimary ? 'primaryPPTPPassword' : 'secondaryPPTPPassword'),
            semanticLabel:
                isPrimary ? 'primaryPPTPPassword' : 'secondaryPPTPPassword',
            identifier:
                isPrimary ? 'primaryPPTPPassword' : 'secondaryPPTPPassword',
            controller: isPrimary
                ? _primaryPPTPPasswordController
                : _secondaryPPTPPasswordController,
            onChanged: (value) {
              final isValid = value.isNotEmpty;
              if (isValid) {
                _errors.remove(isPrimary
                    ? _primaryPPTPPasswordController
                    : _secondaryPPTPPasswordController);
              } else {
                _errors[isPrimary
                        ? _primaryPPTPPasswordController
                        : _secondaryPPTPPasswordController] =
                    loc(context).invalidPassword;
              }
            },
            onFocusChanged: (focus) {
              if (!focus) {
                final value = isPrimary
                    ? _primaryPPTPPasswordController.text
                    : _secondaryPPTPPasswordController.text;
                onChanged(wan.copyWith(password: () => value));
                setState(() {});
              }
            },
            errorText: _errors[isPrimary
                ? _primaryPPTPPasswordController
                : _secondaryPPTPPasswordController],
          ),
        ],
      _ => [],
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [...children, const AppGap.small3()],
    );
  }

  Widget _connectionStatusCard() {
    final connectionStatus =
        ref.watch(dualWANSettingsProvider).status.connectionStatus;
    final ports = ref.watch(dualWANSettingsProvider).status.ports;
    return AppInformationCard(
      headerIcon: Icon(Icons.show_chart),
      title: loc(context).connectionStatus,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        spacing: Spacing.small2,
        children: [
          AppCard(
            showBorder: false,
            color: Theme.of(context).colorScheme.primary.withAlpha(0x10),
            child: Row(
              children: [
                Icon(LinksysIcons.check),
                const AppGap.small2(),
                AppText.bodyMedium(loc(context).primaryWan),
                const Spacer(),
                _wanConnectionLabel(connectionStatus.primaryStatus),
              ],
            ),
          ),
          AppCard(
            showBorder: false,
            color: Theme.of(context).colorSchemeExt.green?.withAlpha(0x10),
            child: Row(
              children: [
                Icon(LinksysIcons.check),
                const AppGap.small2(),
                AppText.bodyMedium(loc(context).secondaryWan),
                const Spacer(),
                _wanConnectionLabel(connectionStatus.secondaryStatus),
              ],
            ),
          ),
          const Divider(height: 24),
          if (ports.isNotEmpty) ...[
            AppText.bodyMedium(loc(context).routerPortLayout),
            AppCard(
                showBorder: false,
                color: Theme.of(context).colorSchemeExt.surfaceContainerLow,
                child: Column(
                  children: [
                    AppText.bodyMedium(loc(context).backOfRouter),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: Spacing.small2,
                        children: ports
                            .map((port) => _portWidget(
                                port.speed, port.type, port.portNumber))
                            .toList()),
                  ],
                )),
            const AppGap.medium(),
          ],
          if (connectionStatus.primaryUptime != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppText.bodyMedium(loc(context).primaryWanUptime),
                AppText.bodyMedium(DateFormatUtils.formatDuration(
                    Duration(seconds: connectionStatus.primaryUptime!), null)),
              ],
            ),
          if (connectionStatus.secondaryUptime != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppText.bodyMedium(loc(context).secondaryWanUptime),
                AppText.bodyMedium(DateFormatUtils.formatDuration(
                    Duration(seconds: connectionStatus.secondaryUptime!),
                    null)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _portWidget(String? connection, PortType portType, [int? lanIndex]) {
    final hasConnection = connection != null && connection != 'None';
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(Spacing.small2),
          child: SvgPicture(
            hasConnection
                ? CustomTheme.of(context).images.imgPortOff
                : CustomTheme.of(context).images.imgPortOn,
            semanticsLabel: 'port status image',
            width: 40,
            height: 40,
            colorFilter: ColorFilter.mode(
              portType.getDisplayColor(context),
              BlendMode.srcIn,
            ),
          ),
        ),
        AppText.labelMedium('${portType.toDisplayString()}${lanIndex ?? ''}',
            color: portType.getDisplayColor(context)),
        if (hasConnection)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LinksysIcons.bidirectional,
                color: portType.getDisplayColor(context),
                size: 16,
              ),
              AppText.bodySmall(connection,
                  color: portType.getDisplayColor(context)),
            ],
          ),
      ],
    );
  }

  Widget _speedAndDiagnosticsCard() {
    final speedStatus = ref.watch(dualWANSettingsProvider).status.speedStatus;
    return AppInformationCard(
      headerIcon: Icon(Icons.monitor_heart),
      title: loc(context).speedTestsDiagnostics,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        spacing: Spacing.small2,
        children: [
          AppOutlinedButton.fillWidth(
            loc(context).testPrimaryWanSpeed,
            onTap: () {},
          ),
          const AppGap.medium(),
          AppOutlinedButton.fillWidth(
            loc(context).testSecondaryWanSpeed,
            onTap: () {},
          ),
          const AppGap.medium(),
          AppFilledButton.fillWidth(
            loc(context).testBothConnections,
            onTap: () {},
          ),
          const AppGap.large2(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppText.bodyMedium(loc(context).primaryWanSpeed),
              AppText.bodyMedium(NetworkUtils.formatBits(
                  speedStatus?.primaryDownloadSpeed ?? 0,
                  decimals: 2)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppText.bodyMedium(loc(context).secondaryWanSpeed),
              AppText.bodyMedium(NetworkUtils.formatBits(
                  speedStatus?.secondaryDownloadSpeed ?? 0,
                  decimals: 2)),
            ],
          ),
        ],
      ),
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
}
