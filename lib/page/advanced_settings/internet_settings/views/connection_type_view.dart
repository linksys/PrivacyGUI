import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_state.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/views/internet_settings_view.dart';
import 'package:privacy_gui/page/advanced_settings/widgets/_widgets.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/providers/redirection/redirection_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/util/error_code_helper.dart';
import 'package:privacy_gui/util/url_helper/url_helper.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacy_gui/validator_rules/_validator_rules.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
import 'package:privacygui_widgets/widgets/dropdown/dropdown_menu.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/input_field/ip_form_field.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:privacygui_widgets/widgets/panel/general_section.dart';
import 'package:privacygui_widgets/widgets/radios/radio_list.dart';
import 'package:privacy_gui/core/jnap/providers/assign_ip/base_assign_ip.dart'
    if (dart.library.html) 'package:privacy_gui/core/jnap/providers/assign_ip/web_assign_ip.dart';

class ConnectionTypeView extends ArgumentsConsumerStatefulView {
  const ConnectionTypeView({super.key, super.args});

  @override
  ConsumerState<ConnectionTypeView> createState() => _ConnectionTypeViewState();
}

class _ConnectionTypeViewState extends ConsumerState<ConnectionTypeView> {
  final TextEditingController _pppoeUsernameController =
      TextEditingController();
  final TextEditingController _pppoePasswordController =
      TextEditingController();
  final TextEditingController _pppoeVLANIDController = TextEditingController();
  final TextEditingController _pppoeServiceNameController =
      TextEditingController();
  final TextEditingController _staticIpAddressController =
      TextEditingController();
  final TextEditingController _staticSubnetController = TextEditingController();
  final TextEditingController _staticGatewayController =
      TextEditingController();
  final TextEditingController _staticDns1Controller = TextEditingController();
  final TextEditingController _staticDns2Controller = TextEditingController();
  final TextEditingController _staticDns3Controller = TextEditingController();
  final TextEditingController _pptpUsernameController = TextEditingController();
  final TextEditingController _pptpPasswordController = TextEditingController();
  final TextEditingController _pptpServerIpController = TextEditingController();
  final TextEditingController _l2tpUsernameController = TextEditingController();
  final TextEditingController _l2tpPasswordController = TextEditingController();
  final TextEditingController _l2tpServerIpController = TextEditingController();
  final TextEditingController _idleTimeController = TextEditingController();
  final TextEditingController _redialPeriodController = TextEditingController();
  final TextEditingController _ipv6PrefixController = TextEditingController();
  final TextEditingController _ipv6PrefixLengthController =
      TextEditingController();
  final TextEditingController _ipv6BorderRelayController =
      TextEditingController();
  final TextEditingController _ipv6BorderRelayPrefixLengthController =
      TextEditingController();

  late final InternetSettingsViewType viewType;
  late InternetSettingsState state;
  bool isEditing = false;
  String loadingTitle = '';
  static const inputPadding = EdgeInsets.symmetric(
      horizontal: Spacing.small1, vertical: Spacing.medium);

  @override
  void initState() {
    super.initState();
    viewType = widget.args['viewType'] ?? InternetSettingsViewType.ipv4;

    state = ref.read(internetSettingsProvider).copyWith();
    initUI();
  }

  @override
  void dispose() {
    super.dispose();

    _pppoeUsernameController.dispose();
    _pppoePasswordController.dispose();
    _pppoeVLANIDController.dispose();
    _pppoeServiceNameController.dispose();
    _staticIpAddressController.dispose();
    _staticSubnetController.dispose();
    _staticGatewayController.dispose();
    _staticDns1Controller.dispose();
    _staticDns2Controller.dispose();
    _staticDns3Controller.dispose();
    _pptpUsernameController.dispose();
    _pptpPasswordController.dispose();
    _pptpServerIpController.dispose();
    _l2tpUsernameController.dispose();
    _l2tpPasswordController.dispose();
    _l2tpServerIpController.dispose();
    _idleTimeController.dispose();
    _redialPeriodController.dispose();
    _ipv6PrefixController.dispose();
    _ipv6PrefixLengthController.dispose();
    _ipv6BorderRelayController.dispose();
    _ipv6BorderRelayPrefixLengthController.dispose();
  }

  void initUI() {
    resetUI();
    // IPv4 setup
    switch (WanType.resolve(state.ipv4Setting.ipv4ConnectionType)) {
      case WanType.dhcp:
        break;
      case WanType.pppoe:
        _pppoeUsernameController.text = state.ipv4Setting.username ?? '';
        _pppoePasswordController.text = state.ipv4Setting.password ?? '';
        _pppoeServiceNameController.text = state.ipv4Setting.serviceName ?? '';
        _pppoeVLANIDController.text = state.ipv4Setting.vlanId != null
            ? '${state.ipv4Setting.vlanId}'
            : '5';
        break;
      case WanType.pptp:
        _pptpUsernameController.text = state.ipv4Setting.username ?? '';
        _pptpPasswordController.text = state.ipv4Setting.password ?? '';
        _pptpServerIpController.text = state.ipv4Setting.serverIp ?? '';
        final selectedPPTPIpAddressMode =
            (state.ipv4Setting.useStaticSettings ?? false)
                ? PPTPIpAddressMode.specify
                : PPTPIpAddressMode.dhcp;
        if (selectedPPTPIpAddressMode == PPTPIpAddressMode.specify) {
          _staticIpAddressController.text =
              state.ipv4Setting.staticIpAddress ?? '';
          final networkPrefixLength = state.ipv4Setting.networkPrefixLength;
          _staticSubnetController.text = networkPrefixLength != null
              ? NetworkUtils.prefixLengthToSubnetMask(networkPrefixLength)
              : NetworkUtils.prefixLengthToSubnetMask(24);
          _staticGatewayController.text = state.ipv4Setting.staticGateway ?? '';
          _staticDns1Controller.text = state.ipv4Setting.staticDns1 ?? '';
          _staticDns2Controller.text = state.ipv4Setting.staticDns2 ?? '';
          _staticDns3Controller.text = state.ipv4Setting.staticDns3 ?? '';
        }
        break;
      case WanType.l2tp:
        _l2tpUsernameController.text = state.ipv4Setting.username ?? '';
        _l2tpPasswordController.text = state.ipv4Setting.password ?? '';
        _l2tpServerIpController.text = state.ipv4Setting.serverIp ?? '';
        break;
      case WanType.static:
        _staticIpAddressController.text =
            state.ipv4Setting.staticIpAddress ?? '';
        final networkPrefixLength = state.ipv4Setting.networkPrefixLength;
        _staticSubnetController.text = networkPrefixLength != null
            ? NetworkUtils.prefixLengthToSubnetMask(networkPrefixLength)
            : NetworkUtils.prefixLengthToSubnetMask(24);
        _staticGatewayController.text = state.ipv4Setting.staticGateway ?? '';
        _staticDns1Controller.text = state.ipv4Setting.staticDns1 ?? '';
        _staticDns2Controller.text = state.ipv4Setting.staticDns2 ?? '';
        _staticDns3Controller.text = state.ipv4Setting.staticDns3 ?? '';
        break;
      case WanType.bridge:
        break;
      default:
        break;
    }
    // IPv6 setup
    switch (WanIPv6Type.resolve(state.ipv6Setting.ipv6ConnectionType)) {
      case WanIPv6Type.automatic:
        _ipv6PrefixController.text = state.ipv6Setting.ipv6Prefix ?? '';
        _ipv6PrefixLengthController.text =
            state.ipv6Setting.ipv6PrefixLength != null
                ? '${state.ipv6Setting.ipv6PrefixLength}'
                : '';
        _ipv6BorderRelayController.text =
            state.ipv6Setting.ipv6BorderRelay ?? '';
        _ipv6BorderRelayPrefixLengthController.text =
            state.ipv6Setting.ipv6BorderRelayPrefixLength != null
                ? '${state.ipv6Setting.ipv6BorderRelayPrefixLength}'
                : '';
        break;
      case WanIPv6Type.pppoe:
        break;
      case WanIPv6Type.passThrough:
        break;
      default:
        break;
    }

    _idleTimeController.text = state.ipv4Setting.maxIdleMinutes != null
        ? '${state.ipv4Setting.maxIdleMinutes}'
        : '15';
    _redialPeriodController.text =
        state.ipv4Setting.reconnectAfterSeconds != null
            ? '${state.ipv4Setting.reconnectAfterSeconds}'
            : '30';
  }

  void resetUI() {
    _pppoeUsernameController.text = '';
    _pppoePasswordController.text = '';
    _pppoeVLANIDController.text = '';
    _pppoeServiceNameController.text = '';
    _staticIpAddressController.text = '';
    _staticSubnetController.text = '';
    _staticGatewayController.text = '';
    _staticDns1Controller.text = '';
    _staticDns2Controller.text = '';
    _staticDns3Controller.text = '';
    _pptpUsernameController.text = '';
    _pptpPasswordController.text = '';
    _pptpServerIpController.text = '';
    _l2tpUsernameController.text = '';
    _l2tpPasswordController.text = '';
    _l2tpServerIpController.text = '';
    _idleTimeController.text = '';
    _redialPeriodController.text = '';
    _ipv6PrefixController.text = '';
    _ipv6PrefixLengthController.text = '';
    _ipv6BorderRelayController.text = '';
    _ipv6BorderRelayPrefixLengthController.text = '';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(redirectionProvider, (previous, next) {
      if (kIsWeb && previous != next && next != null) {
        logger.d('Redirect to $next');
        assignWebLocation(next);
      }
    });
    final title =
        '${viewType == InternetSettingsViewType.ipv4 ? loc(context).ipv4 : loc(context).ipv6} ${loc(context).connectionType}';
    final wanType = WanType.resolve(state.ipv4Setting.ipv4ConnectionType);
    return StyledAppPageView(
      scrollable: true,
      title: title,
      bottomBar: isEditing
          ? PageBottomBar(
              isPositiveEnabled: _isEdited(),
              onPositiveTap: _showRestartAlert,
            )
          : null,
      onBackTap: _isEdited()
          ? () async {
              final goBack = await showUnsavedAlert(context);
              if (goBack == true) {
                context.pop();
              }
            }
          : null,
      actions: [
        AppTextButton.noPadding(
          isEditing ? loc(context).cancel : loc(context).edit,
          icon: isEditing ? LinksysIcons.close : LinksysIcons.edit,
          onTap: isEditing
              ? () {
                  setState(() {
                    isEditing = false;
                    state = ref.read(internetSettingsProvider).copyWith();
                    initUI();
                  });
                }
              : () {
                  setState(() {
                    isEditing = true;
                  });
                },
        ),
      ],
      child: AppBasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _content(),
            const AppGap.small2(),
            if (viewType == InternetSettingsViewType.ipv4 &&
                wanType != WanType.bridge)
              AppSettingCard(
                key: const Key('mtu'),
                title: loc(context).mtu,
                description: state.ipv4Setting.mtu == 0
                    ? loc(context).auto
                    : loc(context).manual,
                trailing:
                    isEditing ? const Icon(LinksysIcons.chevronRight) : null,
                onTap: state.ipv4Setting.ipv4ConnectionType ==
                            WanType.bridge.type ||
                        !isEditing
                    ? null
                    : () async {
                        int? value = await context.pushNamed(
                          RouteNamed.mtuPicker,
                          extra: {
                            'selected': state.ipv4Setting.mtu,
                            'wanType': state.ipv4Setting.ipv4ConnectionType
                          },
                        );
                        if (value != null) {
                          setState(() {
                            state = state.copyWith(
                              ipv4Setting:
                                  state.ipv4Setting.copyWith(mtu: value),
                            );
                          });
                        }
                      },
              ),
            const AppGap.small2(),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    if (isEditing) {
      return _editingCard();
    } else {
      return _infoCard();
    }
  }

  Widget _editingCard() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InternetSettingCard(
          title: loc(context).connectionType,
          description: viewType == InternetSettingsViewType.ipv4
              ? state.ipv4Setting.ipv4ConnectionType
              : state.ipv6Setting.ipv6ConnectionType,
          onTap: viewType == InternetSettingsViewType.ipv4
              ? goIpv4ConnectionSelection
              : goIpv6ConnectionSelection,
        ),
        if (viewType == InternetSettingsViewType.ipv4)
          ..._buildIpv4EditingByConnectionType(),
        if (viewType == InternetSettingsViewType.ipv6)
          ..._buildIpv6EditingByConnectionType(),
      ],
    );
  }

  void goIpv4ConnectionSelection() async {
    String? select = await context.pushNamed(
      RouteNamed.connectionTypeSelection,
      extra: {
        'supportedList': state.ipv4Setting.supportedIPv4ConnectionType,
        'selected': state.ipv4Setting.ipv4ConnectionType,
      },
    );
    if (select != null) {
      setState(() {
        state = state.copyWith(
            ipv4Setting:
                state.ipv4Setting.copyWith(ipv4ConnectionType: select));
      });
    }
  }

  void goIpv6ConnectionSelection() async {
    final disabled = state.ipv6Setting.supportedIPv6ConnectionType
        .where((ipv6) => !state.ipv4Setting.supportedWANCombinations.any(
            (combine) =>
                combine.wanType == state.ipv4Setting.ipv4ConnectionType &&
                combine.wanIPv6Type == ipv6))
        .toList();
    String? select = await context.pushNamed(
      RouteNamed.connectionTypeSelection,
      extra: {
        'supportedList': state.ipv6Setting.supportedIPv6ConnectionType,
        'selected': state.ipv6Setting.ipv6ConnectionType,
        'disabled': disabled,
      },
    );
    if (select != null) {
      setState(() {
        state = state.copyWith(
          ipv6Setting: state.ipv6Setting.copyWith(ipv6ConnectionType: select),
        );
      });
    }
  }

  List<Widget> _buildIpv4EditingByConnectionType() {
    final type = WanType.resolve(state.ipv4Setting.ipv4ConnectionType);
    return switch (type) {
      WanType.dhcp => [],
      WanType.pppoe => _pppoeEditing(),
      WanType.static => _staticIpEditing(),
      WanType.pptp => _pptpEditing(),
      WanType.l2tp => _l2tpEditing(),
      WanType.bridge => [
          const AppGap.large3(),
          AppStyledText.bold(
              '${loc(context).toLogInLocallyWhileInBridgeMode}http://${ref.read(internetSettingsProvider.notifier).hostname}.local',
              defaultTextStyle: Theme.of(context).textTheme.bodyLarge!,
              tags: const ['b'])
        ],
      _ => [],
    };
  }

  List<Widget> _pppoeEditing() {
    return [
      const AppGap.large2(),
      Padding(
        padding: inputPadding,
        child: AppTextField(
          key: const Key('pppoeUsername'),
          headerText: loc(context).username,
          hintText: loc(context).username,
          controller: _pppoeUsernameController,
          border: const OutlineInputBorder(),
          onFocusChanged: (focused) {
            if (!focused) {
              setState(() {
                state = state.copyWith(
                  ipv4Setting: state.ipv4Setting
                      .copyWith(username: () => _pppoeUsernameController.text),
                );
              });
            }
          },
        ),
      ),
      Padding(
        padding: inputPadding,
        child: AppPasswordField(
          key: const Key('pppoePassword'),
          headerText: loc(context).password,
          hintText: loc(context).password,
          controller: _pppoePasswordController,
          border: const OutlineInputBorder(),
          onFocusChanged: (focused) {
            if (!focused) {
              setState(() {
                state = state.copyWith(
                  ipv4Setting: state.ipv4Setting
                      .copyWith(password: () => _pppoePasswordController.text),
                );
              });
            }
          },
        ),
      ),
      Padding(
        padding: inputPadding,
        child: AppTextField.minMaxNumber(
          min: 5,
          max: 4094,
          headerText: loc(context).vlanIdOptional,
          hintText: loc(context).vlanIdOptional,
          controller: _pppoeVLANIDController,
          border: const OutlineInputBorder(),
          onFocusChanged: (focused) {
            if (!focused) {
              setState(() {
                state = state.copyWith(
                  ipv4Setting: state.ipv4Setting.copyWith(
                      vlanId: () => int.parse(_pppoeVLANIDController.text)),
                );
              });
            }
          },
        ),
      ),
      Padding(
        padding: inputPadding,
        child: AppTextField(
          headerText: loc(context).serviceNameOptional,
          hintText: loc(context).serviceNameOptional,
          controller: _pppoeServiceNameController,
          border: const OutlineInputBorder(),
          onFocusChanged: (focused) {
            if (!focused) {
              setState(() {
                state = state.copyWith(
                  ipv4Setting: state.ipv4Setting.copyWith(
                      serviceName: () => _pppoeServiceNameController.text),
                );
              });
            }
          },
        ),
      ),
      const AppGap.small2(),
      _connectionMode(),
      const AppGap.small2(),
    ];
  }

  List<Widget> _staticIpEditing() {
    return [
      const AppGap.large2(),
      Padding(
        padding: inputPadding,
        child: AppIPFormField(
          semanticLabel: 'ip address',
          header: AppText.bodySmall(
            loc(context).internetIpv4Address,
          ),
          controller: _staticIpAddressController,
          border: const OutlineInputBorder(),
          onFocusChanged: (focused) {
            if (!focused) {
              setState(() {
                state = state.copyWith(
                  ipv4Setting: state.ipv4Setting.copyWith(
                      staticIpAddress: () => _staticIpAddressController.text),
                );
              });
            }
          },
        ),
      ),
      Padding(
        padding: inputPadding,
        child: AppIPFormField(
          key: const Key('staticSubnet'),
          semanticLabel: 'subnet mask',
          header: AppText.bodySmall(
            loc(context).subnetMask.capitalizeWords(),
          ),
          controller: _staticSubnetController,
          border: const OutlineInputBorder(),
          onFocusChanged: (focused) {
            if (!focused) {
              final subnetMaskValidator = SubnetMaskValidator();
              final isValidSubnetMask =
                  subnetMaskValidator.validate(_staticSubnetController.text);
              if (isValidSubnetMask) {
                setState(() {
                  state = state.copyWith(
                    ipv4Setting: state.ipv4Setting.copyWith(
                        networkPrefixLength: () =>
                            NetworkUtils.subnetMaskToPrefixLength(
                                _staticSubnetController.text)),
                  );
                });
              }
            }
          },
        ),
      ),
      Padding(
        padding: inputPadding,
        child: AppIPFormField(
          semanticLabel: 'default gateway',
          header: AppText.bodySmall(
            loc(context).defaultGateway,
          ),
          controller: _staticGatewayController,
          border: const OutlineInputBorder(),
          onFocusChanged: (focused) {
            if (!focused) {
              setState(() {
                state = state.copyWith(
                  ipv4Setting: state.ipv4Setting.copyWith(
                      staticGateway: () => _staticGatewayController.text),
                );
              });
            }
          },
        ),
      ),
      Padding(
        padding: inputPadding,
        child: AppIPFormField(
          semanticLabel: 'dns 1',
          header: AppText.bodySmall(
            loc(context).dns1,
          ),
          controller: _staticDns1Controller,
          border: const OutlineInputBorder(),
          onFocusChanged: (focused) {
            if (!focused) {
              setState(() {
                state = state.copyWith(
                  ipv4Setting: state.ipv4Setting
                      .copyWith(staticDns1: () => _staticDns1Controller.text),
                );
              });
            }
          },
        ),
      ),
      Padding(
        padding: inputPadding,
        child: AppIPFormField(
          semanticLabel: 'dns 2 optional',
          header: AppText.bodySmall(
            loc(context).dns2Optional,
          ),
          controller: _staticDns2Controller,
          border: const OutlineInputBorder(),
          onFocusChanged: (focused) {
            if (!focused) {
              setState(() {
                state = state.copyWith(
                  ipv4Setting: state.ipv4Setting.copyWith(
                      staticDns2: () => _staticDns2Controller.text.isEmpty
                          ? null
                          : _staticDns2Controller.text),
                );
              });
            }
          },
        ),
      ),
      Padding(
        padding: inputPadding,
        child: AppIPFormField(
          semanticLabel: 'dns 3 optional',
          header: AppText.bodySmall(
            loc(context).dns3Optional,
          ),
          controller: _staticDns3Controller,
          border: const OutlineInputBorder(),
          onFocusChanged: (focused) {
            if (!focused) {
              setState(() {
                state = state.copyWith(
                  ipv4Setting: state.ipv4Setting.copyWith(
                      staticDns3: () => _staticDns3Controller.text.isEmpty
                          ? null
                          : _staticDns3Controller.text),
                );
              });
            }
          },
        ),
      ),
      const AppGap.medium(),
    ];
  }

  List<Widget> _pptpEditing() {
    return [
      const AppGap.large2(),
      Padding(
        padding: inputPadding,
        child: AppTextField(
          headerText: loc(context).username,
          hintText: loc(context).username,
          controller: _pptpUsernameController,
          border: const OutlineInputBorder(),
          onFocusChanged: (focused) {
            if (!focused) {
              setState(() {
                state = state.copyWith(
                  ipv4Setting: state.ipv4Setting
                      .copyWith(username: () => _pptpUsernameController.text),
                );
              });
            }
          },
        ),
      ),
      Padding(
        padding: inputPadding,
        child: AppPasswordField(
          headerText: loc(context).password,
          hintText: loc(context).password,
          controller: _pptpPasswordController,
          border: const OutlineInputBorder(),
          onFocusChanged: (focused) {
            if (!focused) {
              setState(() {
                state = state.copyWith(
                  ipv4Setting: state.ipv4Setting
                      .copyWith(password: () => _pptpPasswordController.text),
                );
              });
            }
          },
        ),
      ),
      Padding(
        padding: inputPadding,
        child: AppIPFormField(
          header: AppText.bodySmall(
            loc(context).serverIpv4Address,
          ),
          controller: _pptpServerIpController,
          border: const OutlineInputBorder(),
          onFocusChanged: (focused) {
            if (!focused) {
              setState(() {
                state = state.copyWith(
                  ipv4Setting: state.ipv4Setting
                      .copyWith(serverIp: () => _pptpServerIpController.text),
                );
              });
            }
          },
        ),
      ),
      const AppGap.medium(),
      _pptpIpAddressMode(),
      if (state.ipv4Setting.useStaticSettings == true) ..._staticIpEditing(),
      const AppGap.medium(),
      _connectionMode(),
      const AppGap.medium(),
    ];
  }

  List<Widget> _l2tpEditing() {
    return [
      const AppGap.large2(),
      Padding(
        padding: inputPadding,
        child: AppTextField(
          headerText: loc(context).username,
          hintText: loc(context).username,
          controller: _l2tpUsernameController,
          border: const OutlineInputBorder(),
          onFocusChanged: (focused) {
            if (!focused) {
              setState(() {
                state = state.copyWith(
                  ipv4Setting: state.ipv4Setting
                      .copyWith(username: () => _l2tpUsernameController.text),
                );
              });
            }
          },
        ),
      ),
      Padding(
        padding: inputPadding,
        child: AppPasswordField(
          headerText: loc(context).password,
          hintText: loc(context).password,
          controller: _l2tpPasswordController,
          border: const OutlineInputBorder(),
          onFocusChanged: (focused) {
            if (!focused) {
              setState(() {
                state = state.copyWith(
                  ipv4Setting: state.ipv4Setting
                      .copyWith(password: () => _l2tpPasswordController.text),
                );
              });
            }
          },
        ),
      ),
      Padding(
        padding: inputPadding,
        child: AppIPFormField(
          semanticLabel: 'ip address',
          header: AppText.bodySmall(
            loc(context).serverIpv4Address,
          ),
          controller: _l2tpServerIpController,
          border: const OutlineInputBorder(),
          onFocusChanged: (focused) {
            if (!focused) {
              setState(() {
                state = state.copyWith(
                  ipv4Setting: state.ipv4Setting
                      .copyWith(serverIp: () => _l2tpServerIpController.text),
                );
              });
            }
          },
        ),
      ),
      const AppGap.medium(),
      _connectionMode(),
      const AppGap.medium(),
    ];
  }

  Widget _connectionMode() {
    final behavior =
        state.ipv4Setting.behavior ?? PPPConnectionBehavior.keepAlive;
    return AppSection(
      header: AppText.titleSmall(loc(context).connectionMode),
      child: AppRadioList(
        mainAxisSize: MainAxisSize.min,
        itemHeight: 56,
        initial: behavior,
        items: [
          AppRadioListItem(
            title: loc(context).connectOnDemand,
            value: PPPConnectionBehavior.connectOnDemand,
            expandedWidget: behavior == PPPConnectionBehavior.connectOnDemand
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.bodyMedium(loc(context).maxIdleTime),
                      const AppGap.medium(),
                      Row(
                        children: [
                          SizedBox(
                            width: 70,
                            height: 56,
                            child: AppTextField.minMaxNumber(
                              semanticLabel: 'max idle time',
                              max: 9999,
                              min: 1,
                              controller: _idleTimeController,
                              border: const OutlineInputBorder(),
                              onFocusChanged: (focused) {
                                if (!focused) {
                                  setState(() {
                                    state = state.copyWith(
                                      ipv4Setting: state.ipv4Setting.copyWith(
                                          behavior: () => PPPConnectionBehavior
                                              .connectOnDemand,
                                          maxIdleMinutes: () => int.parse(
                                              _idleTimeController.text)),
                                    );
                                  });
                                }
                              },
                            ),
                          ),
                          const AppGap.medium(),
                          AppText.bodyMedium(loc(context).minutes),
                        ],
                      ),
                    ],
                  )
                : null,
          ),
          AppRadioListItem(
            title: loc(context).keepAlive,
            value: PPPConnectionBehavior.keepAlive,
            expandedWidget: behavior == PPPConnectionBehavior.keepAlive
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.bodyMedium(loc(context).redialPeriod),
                      const AppGap.medium(),
                      Row(
                        children: [
                          SizedBox(
                            width: 70,
                            height: 56,
                            child: AppTextField.minMaxNumber(
                              semanticLabel: 'redial period',
                              max: 180,
                              min: 20,
                              controller: _redialPeriodController,
                              border: const OutlineInputBorder(),
                              onFocusChanged: (focused) {
                                if (!focused) {
                                  setState(() {
                                    state = state.copyWith(
                                      ipv4Setting: state.ipv4Setting.copyWith(
                                          behavior: () =>
                                              PPPConnectionBehavior.keepAlive,
                                          reconnectAfterSeconds: () =>
                                              int.parse(_redialPeriodController
                                                  .text)),
                                    );
                                  });
                                }
                              },
                            ),
                          ),
                          const AppGap.medium(),
                          AppText.bodyMedium(loc(context).seconds),
                        ],
                      ),
                    ],
                  )
                : null,
          ),
        ],
        onChanged: (index, type) {
          setState(() {
            if (type != null) {
              state = state.copyWith(
                ipv4Setting: state.ipv4Setting.copyWith(behavior: () => type),
              );
            }
          });
        },
      ),
    );
  }

  Widget _pptpIpAddressMode() {
    final useStaticSettings = state.ipv4Setting.useStaticSettings ?? false;
    return AppSection(
      header: AppText.titleSmall(loc(context).ipAddress.capitalizeWords()),
      child: SizedBox(
        // height: 100,
        child: AppRadioList(
          initial: useStaticSettings
              ? PPTPIpAddressMode.specify
              : PPTPIpAddressMode.dhcp,
          itemHeight: 56,
          items: [
            AppRadioListItem(
              title: loc(context).obtainIPv4AddressAutomatically,
              value: PPTPIpAddressMode.dhcp,
            ),
            AppRadioListItem(
              title: loc(context).specifyIPv4Address,
              value: PPTPIpAddressMode.specify,
            ),
          ],
          onChanged: (index, type) {
            setState(() {
              if (type != null) {
                state = state.copyWith(
                  ipv4Setting: state.ipv4Setting.copyWith(
                      useStaticSettings: () =>
                          type == PPTPIpAddressMode.specify),
                );
              }
            });
          },
        ),
      ),
    );
  }

  List<Widget> _buildIpv6EditingByConnectionType() {
    final type = WanIPv6Type.resolve(state.ipv6Setting.ipv6ConnectionType);
    return switch (type) {
      WanIPv6Type.automatic => _ipv6AutomaticEditing(),
      WanIPv6Type.static => [],
      WanIPv6Type.bridge => [],
      WanIPv6Type.sixRdTunnel => [],
      WanIPv6Type.slaac => [],
      WanIPv6Type.dhcpv6 => [],
      WanIPv6Type.pppoe => [],
      WanIPv6Type.passThrough => [],
      _ => [],
    };
  }

  List<Widget> _ipv6AutomaticEditing() {
    return [
      const AppGap.large2(),
      AppSettingCard.noBorder(
        title: loc(context).ipv6Automatic,
        color: Theme.of(context).colorScheme.background,
        trailing: AppSwitch(
          semanticLabel: 'ipv6 automatic',
          value: state.ipv6Setting.isIPv6AutomaticEnabled,
          onChanged: (value) {
            setState(() {
              state = state.copyWith(
                ipv6Setting:
                    state.ipv6Setting.copyWith(isIPv6AutomaticEnabled: value),
              );
            });
          },
        ),
      ),
      AppSettingCard.noBorder(
        title: loc(context).duid,
        description: state.ipv6Setting.duid,
        color: Theme.of(context).colorScheme.background,
      ),
      if (!state.ipv6Setting.isIPv6AutomaticEnabled) _sixrdTunnel(),
    ];
  }

  Widget _sixrdTunnel() {
    return Column(
      children: [
        AppSettingCard.noBorder(
          title: loc(context).sixrdTunnel,
          color: Theme.of(context).colorScheme.background,
          trailing: AppDropdownMenu<IPv6rdTunnelMode>(
            items: const [
              IPv6rdTunnelMode.disabled,
              IPv6rdTunnelMode.automatic,
              IPv6rdTunnelMode.manual,
            ],
            initial: state.ipv6Setting.ipv6rdTunnelMode,
            label: (item) => item.value,
            onChanged: (value) {
              setState(() {
                state = state.copyWith(
                  ipv6Setting:
                      state.ipv6Setting.copyWith(ipv6rdTunnelMode: () => value),
                );
              });
            },
          ),
        ),
        if (state.ipv6Setting.ipv6rdTunnelMode == IPv6rdTunnelMode.manual)
          _manualSixrdTunnel(),
      ],
    );
  }

  Widget _manualSixrdTunnel() {
    return Column(
      children: [
        Padding(
          padding: inputPadding,
          child: AppTextField(
            headerText: loc(context).prefix,
            hintText: '',
            controller: _ipv6PrefixController,
            border: const OutlineInputBorder(),
            onFocusChanged: (focused) {
              if (!focused) {
                setState(() {
                  state = state.copyWith(
                    ipv6Setting: state.ipv6Setting
                        .copyWith(ipv6Prefix: () => _ipv6PrefixController.text),
                  );
                });
              }
            },
          ),
        ),
        Padding(
          padding: inputPadding,
          child: AppTextField.minMaxNumber(
            headerText: loc(context).prefixLength,
            hintText: '',
            max: 64,
            controller: _ipv6PrefixLengthController,
            border: const OutlineInputBorder(),
            onFocusChanged: (focused) {
              if (!focused) {
                setState(() {
                  state = state.copyWith(
                    ipv6Setting: state.ipv6Setting.copyWith(
                        ipv6PrefixLength: () =>
                            int.parse(_ipv6PrefixLengthController.text)),
                  );
                });
              }
            },
          ),
        ),
        Padding(
          padding: inputPadding,
          child: AppIPFormField(
            semanticLabel: 'border relay',
            header: AppText.bodySmall(
              loc(context).borderRelay,
            ),
            controller: _ipv6BorderRelayController,
            border: const OutlineInputBorder(),
            onFocusChanged: (focused) {
              if (!focused) {
                setState(() {
                  state = state.copyWith(
                    ipv6Setting: state.ipv6Setting.copyWith(
                        ipv6BorderRelay: () => _ipv6BorderRelayController.text),
                  );
                });
              }
            },
          ),
        ),
        Padding(
          padding: inputPadding,
          child: AppTextField.minMaxNumber(
            key: const Key('borderRelayLength'),
            headerText: loc(context).borderRelayLength,
            hintText: '',
            max: 32,
            controller: _ipv6BorderRelayPrefixLengthController,
            border: const OutlineInputBorder(),
            onFocusChanged: (focused) {
              if (!focused) {
                setState(() {
                  state = state.copyWith(
                    ipv6Setting: state.ipv6Setting.copyWith(
                        ipv6BorderRelayPrefixLength: () => int.parse(
                            _ipv6BorderRelayPrefixLengthController.text)),
                  );
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _infoCard() {
    return AppCard(
      padding: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSettingCard.noBorder(
            title: loc(context).connectionType,
            description: viewType == InternetSettingsViewType.ipv4
                ? state.ipv4Setting.ipv4ConnectionType
                : state.ipv6Setting.ipv6ConnectionType,
            color: Theme.of(context).colorScheme.background,
            margin: EdgeInsets.zero,
          ),
          if (viewType == InternetSettingsViewType.ipv4)
            ..._buildIpv4InfoByConnectionType(),
          if (viewType == InternetSettingsViewType.ipv6)
            ..._buildIpv6InfoByConnectionType(),
        ],
      ),
    );
  }

  List<Widget> _buildIpv4InfoByConnectionType() {
    final type = WanType.resolve(state.ipv4Setting.ipv4ConnectionType);
    return switch (type) {
      WanType.dhcp => [],
      WanType.pppoe => _pppoeInfo(),
      WanType.static => _staticIpInfo(),
      WanType.pptp => _pptpInfo(),
      WanType.l2tp => _l2tpInfo(),
      WanType.bridge => _bridgeInfo(),
      _ => [],
    };
  }

  List<Widget> _pppoeInfo() {
    return [
      AppSettingCard.noBorder(
        title: loc(context).username,
        description: state.ipv4Setting.username ?? '',
        color: Theme.of(context).colorScheme.background,
      ),
      AppSettingCard.noBorder(
        title: loc(context).vlanIdOptional,
        description: (state.ipv4Setting.wanTaggingSettingsEnable ?? false)
            ? state.ipv4Setting.vlanId != null
                ? state.ipv4Setting.vlanId.toString()
                : ''
            : '',
        color: Theme.of(context).colorScheme.background,
      ),
      AppSettingCard.noBorder(
        title: loc(context).serviceNameOptional,
        description: state.ipv4Setting.serviceName ?? '',
        color: Theme.of(context).colorScheme.background,
      ),
    ];
  }

  List<Widget> _staticIpInfo() {
    return [
      AppSettingCard.noBorder(
        title: loc(context).internetIpv4Address,
        description: state.ipv4Setting.staticIpAddress ?? '',
        color: Theme.of(context).colorScheme.background,
      ),
      AppSettingCard.noBorder(
        title: loc(context).subnetMask.capitalizeWords(),
        description: NetworkUtils.prefixLengthToSubnetMask(
            state.ipv4Setting.networkPrefixLength ?? 24),
        color: Theme.of(context).colorScheme.background,
      ),
      AppSettingCard.noBorder(
        title: loc(context).defaultGateway,
        description: state.ipv4Setting.staticGateway ?? '',
        color: Theme.of(context).colorScheme.background,
      ),
      AppSettingCard.noBorder(
        title: loc(context).dns1,
        description: state.ipv4Setting.staticDns1 ?? '',
        color: Theme.of(context).colorScheme.background,
      ),
      AppSettingCard.noBorder(
        title: loc(context).dns2Optional,
        description: state.ipv4Setting.staticDns2 ?? '',
        color: Theme.of(context).colorScheme.background,
      ),
      AppSettingCard.noBorder(
        title: loc(context).dns3Optional,
        description: state.ipv4Setting.staticDns3 ?? '',
        color: Theme.of(context).colorScheme.background,
      ),
    ];
  }

  List<Widget> _pptpInfo() {
    final useStaticSettings = state.ipv4Setting.useStaticSettings ?? false;
    return [
      AppSettingCard.noBorder(
        title: loc(context).username,
        description: state.ipv4Setting.username ?? '',
        color: Theme.of(context).colorScheme.background,
      ),
      AppSettingCard.noBorder(
        title: loc(context).serverIpv4Address,
        description: state.ipv4Setting.serverIp ?? '',
        color: Theme.of(context).colorScheme.background,
      ),
      if (useStaticSettings) ..._staticIpInfo(),
    ];
  }

  List<Widget> _l2tpInfo() {
    return [
      AppSettingCard.noBorder(
        title: loc(context).username,
        description: state.ipv4Setting.username ?? '',
        color: Theme.of(context).colorScheme.background,
      ),
      AppSettingCard.noBorder(
        title: loc(context).serverIpv4Address,
        description: state.ipv4Setting.serverIp ?? '',
        color: Theme.of(context).colorScheme.background,
      ),
    ];
  }

  List<Widget> _bridgeInfo() {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppStyledText.bold(
              loc(context).toLogInLocallyWhileInBridgeMode,
              defaultTextStyle: Theme.of(context).textTheme.bodyLarge!,
              tags: const ['b'],
            ),
            const AppGap.small2(),
            AppTextButton.noPadding(
              state.ipv4Setting.redirection ?? '',
              icon: Icons.open_in_new,
              onTap: () {
                openUrl(state.ipv4Setting.redirection ?? '');
              },
            ),
            const AppGap.medium(),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildIpv6InfoByConnectionType() {
    final type = WanIPv6Type.resolve(state.ipv6Setting.ipv6ConnectionType);
    return switch (type) {
      WanIPv6Type.automatic => _ipv6AutomaticInfo(),
      WanIPv6Type.static => [],
      WanIPv6Type.bridge => [],
      WanIPv6Type.sixRdTunnel => [],
      WanIPv6Type.slaac => [],
      WanIPv6Type.dhcpv6 => [],
      WanIPv6Type.pppoe => [],
      WanIPv6Type.passThrough => [],
      _ => [],
    };
  }

  List<Widget> _ipv6AutomaticInfo() {
    final ipv6rdTunnelMode =
        state.ipv6Setting.ipv6rdTunnelMode ?? IPv6rdTunnelMode.disabled;
    return [
      AppSettingCard.noBorder(
        title: loc(context).ipv6Automatic,
        description: state.ipv6Setting.isIPv6AutomaticEnabled
            ? loc(context).enabled
            : loc(context).disabled,
        color: Theme.of(context).colorScheme.background,
      ),
      AppSettingCard.noBorder(
        title: loc(context).duid,
        description: state.ipv6Setting.duid,
        color: Theme.of(context).colorScheme.background,
      ),
      AppSettingCard.noBorder(
        title: loc(context).sixrdTunnel,
        description: getIpv6rdTunnelModeLoc(ipv6rdTunnelMode),
        color: Theme.of(context).colorScheme.background,
      ),
    ];
  }

  String getIpv6rdTunnelModeLoc(IPv6rdTunnelMode ipv6rdTunnelMode) {
    return switch (ipv6rdTunnelMode) {
      IPv6rdTunnelMode.automatic => loc(context).automatic,
      IPv6rdTunnelMode.disabled => loc(context).disabled,
      IPv6rdTunnelMode.manual => loc(context).manual,
    };
  }

  _showRestartAlert() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: AppText.titleLarge(loc(context).restartWifiAlertTitle),
            content: AppText.bodyMedium(loc(context).restartWifiAlertDesc),
            actions: [
              AppTextButton(
                loc(context).cancel,
                color: Theme.of(context).colorScheme.onSurface,
                onTap: () {
                  context.pop();
                },
              ),
              AppTextButton(
                loc(context).restart,
                onTap: () {
                  context.pop();
                  _onRestartButtonTap();
                },
              ),
            ],
          );
        });
  }

  _onRestartButtonTap() {
    setState(() {
      loadingTitle = loc(context).restarting;
    });

    doSomethingWithSpinner(
      context,
      _saveChange(viewType).then((value) {
        setState(() {
          isEditing = false;
          state = ref.read(internetSettingsProvider).copyWith();
          initUI();
        });
        showSuccessSnackBar(
          context,
          loc(context).changesSaved,
        );
      }).catchError(
        (error, stackTrace) {
          final errorMsg = errorCodeHelper(context, (error as JNAPError).result);
          showFailedSnackBar(
            context,
            errorMsg ?? loc(context).unknownErrorCode((error as JNAPError).result),
          );
        },
        test: (error) => error is JNAPError,
      ).whenComplete(
        () {
          setState(() {
            loadingTitle = '';
          });
        },
      ),
    );
  }

  Future _saveChange(InternetSettingsViewType viewType) {
    if (viewType == InternetSettingsViewType.ipv4) {
      return ref.read(internetSettingsProvider.notifier).saveIpv4(state);
    } else {
      return ref.read(internetSettingsProvider.notifier).saveIpv6(state);
    }
  }

  bool _isEdited() {
    final originState = ref.read(internetSettingsProvider);
    if (state != originState) return true;
    return false;
  }
}
