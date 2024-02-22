import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';
import 'package:linksys_app/page/administration/internet_settings/_internet_settings.dart';
import 'package:linksys_app/providers/connectivity/_connectivity.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_app/util/string_mapping.dart';
import 'package:linksys_widgets/theme/const/spacing.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/dropdown/dropdown_menu.dart';
import 'package:linksys_widgets/widgets/input_field/ip_form_field.dart';

import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/panel/general_section.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';
import 'package:linksys_widgets/widgets/radios/radio_list.dart';

enum InternetSettingsViewType {
  ipv4,
  ipv6,
}

enum PPTPIpAddressMode {
  dhcp,
  specify,
}

class InternetSettingsView extends ArgumentsConsumerStatelessView {
  const InternetSettingsView({super.key, super.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InternetSettingsContentView(
      args: super.args,
    );
  }
}

class InternetSettingsContentView extends ArgumentsConsumerStatefulView {
  const InternetSettingsContentView({super.key, super.args});

  @override
  ConsumerState<InternetSettingsContentView> createState() =>
      _InternetSettingsContentViewState();
}

class _InternetSettingsContentViewState
    extends ConsumerState<InternetSettingsContentView> {
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

  bool isLoading = true;
  InternetSettingsViewType _selected = InternetSettingsViewType.ipv4;
  PPPConnectionBehavior _selectedConnectionMode =
      PPPConnectionBehavior.keepAlive;
  PPTPIpAddressMode _selectedPPTPIpAddressMode = PPTPIpAddressMode.dhcp;
  bool _isBehindRouter = false;
  late InternetSettingsState state;

  @override
  void initState() {
    ref.read(internetSettingsProvider.notifier).fetch().then((value) {
      setState(() {
        state = value.copyWith();
        initUI();
        isLoading = false;
      });
    });

    super.initState();
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
    // IPv4 setup
    switch (WanType.resolve(state.ipv4ConnectionType)) {
      case WanType.dhcp:
        break;
      case WanType.pppoe:
        _pppoeUsernameController.text = state.username ?? '';
        _pppoePasswordController.text = state.password ?? '';
        _pppoeServiceNameController.text = state.serviceName ?? '';
        _pppoeVLANIDController.text =
            state.vlanId != null ? '${state.vlanId}' : '5';
        break;
      case WanType.pptp:
        _pptpUsernameController.text = state.username ?? '';
        _pptpPasswordController.text = state.password ?? '';
        _pptpServerIpController.text = state.serverIp ?? '';
        _selectedPPTPIpAddressMode = (state.useStaticSettings ?? false)
            ? PPTPIpAddressMode.specify
            : PPTPIpAddressMode.dhcp;
        if (_selectedPPTPIpAddressMode == PPTPIpAddressMode.specify) {
          _staticIpAddressController.text = state.staticIpAddress ?? '';
          _staticGatewayController.text = state.staticGateway ?? '';
          _staticDns1Controller.text = state.staticDns1 ?? '';
          _staticDns2Controller.text = state.staticDns2 ?? '';
          _staticDns3Controller.text = state.staticDns3 ?? '';
        }
        break;
      case WanType.l2tp:
        _l2tpUsernameController.text = state.username ?? '';
        _l2tpPasswordController.text = state.password ?? '';
        _l2tpServerIpController.text = state.serverIp ?? '';
        break;
      case WanType.static:
        _staticIpAddressController.text = state.staticIpAddress ?? '';
        _staticGatewayController.text = state.staticGateway ?? '';
        _staticDns1Controller.text = state.staticDns1 ?? '';
        _staticDns2Controller.text = state.staticDns2 ?? '';
        _staticDns3Controller.text = state.staticDns3 ?? '';
        break;
      case WanType.bridge:
        break;
      default:
        break;
    }
    // IPv6 setup
    switch (WanIPv6Type.resolve(state.ipv6ConnectionType)) {
      case WanIPv6Type.automatic:
        _ipv6PrefixController.text = state.ipv6Prefix ?? '';
        _ipv6PrefixLengthController.text =
            state.ipv6PrefixLength != null ? '${state.ipv6PrefixLength}' : '';
        _ipv6BorderRelayController.text = state.ipv6BorderRelay ?? '';
        _ipv6BorderRelayPrefixLengthController.text =
            state.ipv6BorderRelayPrefixLength != null
                ? '${state.ipv6BorderRelayPrefixLength}'
                : '';
        break;
      case WanIPv6Type.pppoe:
        break;
      case WanIPv6Type.passThrough:
        break;
      default:
        break;
    }

    _selectedConnectionMode = state.behavior ?? _selectedConnectionMode;
    _idleTimeController.text =
        state.maxIdleMinutes != null ? '${state.maxIdleMinutes}' : '15';
    _redialPeriodController.text = state.reconnectAfterSeconds != null
        ? '${state.reconnectAfterSeconds}'
        : '30';
  }

  Future save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      isLoading = true;
    });
    if (_selected == InternetSettingsViewType.ipv4) {
      await ref.read(internetSettingsProvider.notifier).saveIpv4(state);
    } else {
      await ref.read(internetSettingsProvider.notifier).saveIpv6(state);
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectivityState = ref.watch(connectivityProvider);
    _isBehindRouter = connectivityState.connectivityInfo.routerType ==
        RouterType.behindManaged;
    return isLoading
        ? const AppFullScreenSpinner()
        : StyledAppPageView(
            padding: const EdgeInsets.only(),
            scrollable: true,
            title: getAppLocalizations(context).internet_settings,
            actions: [
              AppTextButton(
                getAppLocalizations(context).save,
                onTap: _isBehindRouter
                    ? () async {
                        setState(() {
                          isLoading = true;
                        });
                        await save().onError((error, stackTrace) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(AppToastHelp.negativeToast(
                            context,
                            text: (error as JNAPError).result,
                          ));
                        }).whenComplete(() {
                          setState(() {
                            isLoading = false;
                          });
                          ScaffoldMessenger.of(context)
                              .showSnackBar(AppToastHelp.positiveToast(
                            context,
                            text: 'Saved',
                          ));
                        });
                      }
                    : null,
              ),
            ],
            child: AppBasicLayout(
              content: Column(
                children: [
                  if (!_isBehindRouter)
                    Container(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      width: double.infinity,
                      height: 100,
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: AppText.bodyLarge(
                          'To change these settings. connect to ${ref.read(dashboardHomeProvider).mainWifiSsid}',
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(Spacing.semiSmall),
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            _buildSegmentController(),
                            const AppGap.semiBig(),
                            _buildSegment(),
                            const AppGap.semiBig(),
                            if (_selected == InternetSettingsViewType.ipv4)
                              _buildAdditionalSettings(),
                          ],
                        ),
                        if (!_isBehindRouter)
                          Container(
                            decoration:
                                const BoxDecoration(color: Color(0x88aaaaaa)),
                          )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
  }

  Widget _buildSegmentController() {
    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<InternetSettingsViewType>(
        // backgroundColor: const Color.fromRGBO(211, 211, 211, 1.0),
        // thumbColor: const Color.fromRGBO(248, 248, 248, 1.0),
        groupValue: _selected,
        onValueChanged: (InternetSettingsViewType? value) {
          if (value != null) {
            setState(() {
              _selected = value;
              switch (value) {
                case InternetSettingsViewType.ipv4:
                  break;
                case InternetSettingsViewType.ipv6:
                  break;
              }
            });
          }
        },
        children: {
          InternetSettingsViewType.ipv4: Padding(
            padding: const EdgeInsets.all(Spacing.semiSmall),
            child: AppText.bodyLarge(getAppLocalizations(context).label_ipv4),
          ),
          InternetSettingsViewType.ipv6: Padding(
            padding: const EdgeInsets.all(Spacing.semiSmall),
            child: AppText.bodyLarge(getAppLocalizations(context).label_ipv6),
          ),
        },
      ),
    );
  }

  Widget _buildSegment() {
    return _selected == InternetSettingsViewType.ipv4
        ? _buildIPv4Segment()
        : _buildIPv6Segment();
  }

  Widget _buildAdditionalSettings() {
    return AppSection(
      header:
          AppText.labelLarge(getAppLocalizations(context).additional_setting),
      child: Column(
        children: [
          AppPanelWithInfo(
            title: getAppLocalizations(context).mtu,
            description: state.mtu == 0
                ? getAppLocalizations(context).auto
                : getAppLocalizations(context).manual,
            infoText: ' ',
            onTap: state.ipv4ConnectionType == WanType.bridge.type
                ? null
                : () async {
                    int? value = await context.pushNamed(
                      RouteNamed.mtuPicker,
                      extra: {
                        'selected': state.mtu,
                        'wanType': state.ipv4ConnectionType
                      },
                    );
                    if (value != null) {
                      setState(() {
                        state = state.copyWith(mtu: value);
                      });
                    }
                  },
          ),
          AppPanelWithInfo(
            title: getAppLocalizations(context).mac_address_clone,
            description: state.macClone
                ? getAppLocalizations(context).on
                : getAppLocalizations(context).off,
            infoText: ' ',
            onTap: state.ipv4ConnectionType == WanType.bridge.type
                ? null
                : () async {
                    String? macAddress = await context
                        .pushNamed(RouteNamed.macClone, extra: {
                      'enabled': state.macClone,
                      'macAddress': state.macCloneAddress
                    });
                    if (macAddress != null) {
                      setState(() {
                        state = state.copyWith(
                            macClone: macAddress.isNotEmpty,
                            macCloneAddress: macAddress);
                      });
                    }
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildIPv4Segment() {
    return Column(
      children: [
        AppPanelWithInfo(
          title: getAppLocalizations(context).connection_type,
          description:
              toConnectionTypeData(context, state.ipv4ConnectionType).title,
          infoText: ' ',
          onTap: () async {
            String? select =
                await context.pushNamed(RouteNamed.connectionType, extra: {
              'supportedList': state.supportedIPv4ConnectionType,
              'selected': state.ipv4ConnectionType,
            });
            if (select != null) {
              setState(() {
                state = state.copyWith(ipv4ConnectionType: select);
              });
            }
          },
        ),
        _buildIPv4SettingsByConnectionType(),
      ],
    );
  }

  Widget _buildIPv4SettingsByConnectionType() {
    final type = WanType.resolve(state.ipv4ConnectionType);
    switch (type) {
      case WanType.dhcp:
        return _buildDHCPSettings();
      case WanType.pppoe:
        return _buildPPPoESettings();
      case WanType.static:
        return _buildStaticSettings();
      case WanType.pptp:
        return _buildPPTPSettings();
      case WanType.l2tp:
        return _buildL2TPSettings();
      case WanType.bridge:
        return _buildBridgeModeSettings();
      default:
        return const Center();
    }
  }

  Widget _buildDHCPSettings() {
    return const Center();
  }

  Widget _buildPPPoESettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          headerText: getAppLocalizations(context).username,
          hintText: getAppLocalizations(context).username,
          controller: _pppoeUsernameController,
          onFocusChanged: (focused) {
            if (!focused) {
              setState(() {
                state = state.copyWith(username: _pppoeUsernameController.text);
              });
            }
          },
        ),
        const AppGap.semiSmall(),
        AppPasswordField(
          headerText: getAppLocalizations(context).password,
          hintText: getAppLocalizations(context).password,
          controller: _pppoePasswordController,
          onFocusChanged: (focused) {
            if (!focused) {
              setState(() {
                state = state.copyWith(password: _pppoePasswordController.text);
              });
            }
          },
        ),
        const AppGap.semiSmall(),
        AppTextField(
          headerText: 'Service Name (Optional)',
          hintText: 'Service Name (Optional)',
          controller: _pppoeServiceNameController,
          onFocusChanged: (focused) {
            if (!focused) {
              setState(() {
                state = state.copyWith(
                    serviceName: _pppoeServiceNameController.text);
              });
            }
          },
        ),
        const AppGap.semiSmall(),
        AppTextField.minMaxNumber(
          min: 5,
          max: 4094,
          headerText: getAppLocalizations(context).vlan_id,
          hintText: getAppLocalizations(context).vlan_id,
          controller: _pppoeVLANIDController,
          onFocusChanged: (focused) {
            if (!focused) {
              setState(() {
                state = state.copyWith(
                    vlanId: int.parse(_pppoeVLANIDController.text));
              });
            }
          },
        ),
        const AppGap.semiSmall(),
        AppText.bodyMedium(getAppLocalizations(context).vlan_id_desc),
        const AppGap.regular(),
        _buildConnectionModeSection(),
      ],
    );
  }

  Widget _buildStaticSettings() {
    return Column(
      children: [
        AppIPFormField(
          header: AppText.bodyLarge(
            getAppLocalizations(context).internet_ipv4_address,
          ),
          controller: _staticIpAddressController,
          onFocusChanged: (focused) {
            if (!focused) {
              setState(() {
                state = state.copyWith(
                    staticIpAddress: _staticIpAddressController.text);
              });
            }
          },
        ),
        const AppGap.semiSmall(),
        AppIPFormField(
          header: AppText.bodyLarge(
            getAppLocalizations(context).subnet_mask,
          ),
          controller: _staticSubnetController,
          onFocusChanged: (focused) {},
        ),
        const AppGap.semiSmall(),
        AppIPFormField(
          header: AppText.bodyLarge(
            getAppLocalizations(context).default_gateway,
          ),
          controller: _staticGatewayController,
          onFocusChanged: (focused) {
            if (!focused) {
              setState(() {
                state = state.copyWith(
                    staticGateway: _staticGatewayController.text);
              });
            }
          },
        ),
        const AppGap.semiSmall(),
        AppIPFormField(
          header: AppText.bodyLarge(
            getAppLocalizations(context).dns1,
          ),
          controller: _staticDns1Controller,
          onFocusChanged: (focused) {
            if (!focused) {
              setState(() {
                state = state.copyWith(staticDns1: _staticDns1Controller.text);
              });
            }
          },
        ),
        const AppGap.semiSmall(),
        AppIPFormField(
          header: const AppText.bodyLarge(
            'DNS 2 (Optional)',
          ),
          controller: _staticDns2Controller,
          onFocusChanged: (focused) {
            if (!focused) {
              setState(() {
                state = state.copyWith(staticDns2: _staticDns2Controller.text);
              });
            }
          },
        ),
        const AppGap.semiSmall(),
        AppIPFormField(
          header: const AppText.bodyLarge(
            'DNS 3 (Optional)',
          ),
          controller: _staticDns3Controller,
          onFocusChanged: (focused) {
            if (!focused) {
              setState(() {
                state = state.copyWith(staticDns3: _staticDns3Controller.text);
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildPPTPSettings() {
    return Column(
      children: [
        AppTextField(
          headerText: getAppLocalizations(context).username,
          hintText: getAppLocalizations(context).username,
          controller: _pptpUsernameController,
          onFocusChanged: (focused) {
            if (!focused) {
              setState(() {
                state = state.copyWith(username: _pptpUsernameController.text);
              });
            }
          },
        ),
        const AppGap.semiSmall(),
        AppPasswordField(
          headerText: getAppLocalizations(context).password,
          hintText: getAppLocalizations(context).password,
          controller: _pptpPasswordController,
          onFocusChanged: (focused) {
            if (!focused) {
              setState(() {
                state = state.copyWith(password: _pptpPasswordController.text);
              });
            }
          },
        ),
        const AppGap.semiSmall(),
        AppIPFormField(
          header: AppText.bodyLarge(
            getAppLocalizations(context).server_ipv4_address,
          ),
          controller: _pptpServerIpController,
          onFocusChanged: (focused) {
            if (!focused) {
              setState(() {
                state = state.copyWith(serverIp: _pptpServerIpController.text);
              });
            }
          },
        ),
        const AppGap.regular(),
        _pptpIpAddressModeSection(),
        if (_selectedPPTPIpAddressMode == PPTPIpAddressMode.specify)
          _buildStaticSettings(),
        const AppGap.regular(),
        _buildConnectionModeSection(),
      ],
    );
  }

  Widget _buildL2TPSettings() {
    return Column(
      children: [
        AppTextField(
          headerText: getAppLocalizations(context).username,
          hintText: getAppLocalizations(context).username,
          controller: _l2tpUsernameController,
          onFocusChanged: (focused) {
            if (!focused) {
              setState(() {
                state = state.copyWith(username: _l2tpUsernameController.text);
              });
            }
          },
        ),
        const AppGap.semiSmall(),
        AppPasswordField(
          headerText: getAppLocalizations(context).password,
          hintText: getAppLocalizations(context).password,
          controller: _l2tpPasswordController,
          onFocusChanged: (focused) {
            if (!focused) {
              setState(() {
                state = state.copyWith(password: _l2tpPasswordController.text);
              });
            }
          },
        ),
        const AppGap.semiSmall(),
        AppIPFormField(
          header: AppText.bodyLarge(
            getAppLocalizations(context).server_ipv4_address,
          ),
          controller: _l2tpServerIpController,
          onFocusChanged: (focused) {
            if (!focused) {
              setState(() {
                state = state.copyWith(serverIp: _l2tpServerIpController.text);
              });
            }
          },
        ),
        const AppGap.regular(),
        _buildConnectionModeSection(),
      ],
    );
  }

  Widget _buildBridgeModeSettings() {
    return const Center();
  }

  Widget _buildIPv6Segment() {
    return Column(
      children: [
        AppPanelWithInfo(
          title: getAppLocalizations(context).connection_type,
          description:
              toConnectionTypeData(context, state.ipv6ConnectionType).title,
          infoText: ' ',
          onTap: () async {
            final disabled = state.supportedIPv6ConnectionType
                .where((ipv6) => !state.supportedWANCombinations.any(
                    (combine) =>
                        combine.wanType == state.ipv4ConnectionType &&
                        combine.wanIPv6Type == ipv6))
                .toList();
            String? select = await context.pushNamed(
              RouteNamed.connectionType,
              extra: {
                'supportedList': state.supportedIPv6ConnectionType,
                'selected': state.ipv6ConnectionType,
                'disabled': disabled
              },
            );
            if (select != null) {
              setState(() {
                state = state.copyWith(ipv6ConnectionType: select);
              });
            }
          },
        ),
        _buildIPv6SettingsByConnectionType(),
      ],
    );
  }

  Widget _buildIPv6SettingsByConnectionType() {
    final type = WanIPv6Type.resolve(state.ipv6ConnectionType);
    switch (type) {
      case WanIPv6Type.automatic:
        return _buildIpv6AutomaticSettings();
      case WanIPv6Type.passThrough:
        return const Center();
      case WanIPv6Type.pppoe:
        return const Center();
      default:
        return const Center();
    }
  }

  Widget _buildIpv6AutomaticSettings() {
    return Column(
      children: [
        Row(
          children: [
            AppText.bodyLarge(getAppLocalizations(context).ipv6_automatic),
            const Spacer(),
            AppSwitch(
              value: state.isIPv6AutomaticEnabled,
              onChanged: (value) {
                setState(() {
                  state = state.copyWith(isIPv6AutomaticEnabled: value);
                });
              },
            ),
          ],
        ),
        AppPanelWithInfo(
          title: getAppLocalizations(context).duid,
          description: state.duid,
          infoText: ' ',
          forcedHidingAccessory: true,
        ),
        if (!state.isIPv6AutomaticEnabled) _sixrdTunnel(),
      ],
    );
  }

  Widget _sixrdTunnel() {
    return Column(
      children: [
        Row(
          children: [
            AppText.bodyLarge(getAppLocalizations(context).sixth_tunnel),
            const Spacer(),
            AppDropdownMenu<IPv6rdTunnelMode>(
              items: const [
                IPv6rdTunnelMode.disabled,
                IPv6rdTunnelMode.automatic,
                IPv6rdTunnelMode.manual,
              ],
              initial: state.ipv6rdTunnelMode,
              label: (item) => item.value,
              onChanged: (value) {
                setState(() {
                  state = state.copyWith(ipv6rdTunnelMode: value);
                });
              },
            ),
          ],
        ),
        if (state.ipv6rdTunnelMode == IPv6rdTunnelMode.manual)
          _manualSixrdTunnel(),
      ],
    );
  }

  Widget _manualSixrdTunnel() {
    return Column(
      children: [
        AppTextField(
          headerText: 'Prefix',
          hintText: '',
          controller: _ipv6PrefixController,
          onFocusChanged: (focused) {
            if (!focused) {
              setState(() {
                state = state.copyWith(ipv6Prefix: _ipv6PrefixController.text);
              });
            }
          },
        ),
        AppTextField.minMaxNumber(
          headerText: 'Prefix length',
          hintText: '',
          max: 64,
          controller: _ipv6PrefixLengthController,
          onFocusChanged: (focused) {
            if (!focused) {
              setState(() {
                state = state.copyWith(
                    ipv6PrefixLength:
                        int.parse(_ipv6PrefixLengthController.text));
              });
            }
          },
        ),
        AppIPFormField(
          header: const AppText.bodyLarge(
            'Border relay',
          ),
          controller: _ipv6BorderRelayController,
          onFocusChanged: (focused) {
            if (!focused) {
              setState(() {
                state = state.copyWith(
                    ipv6BorderRelay: _ipv6BorderRelayController.text);
              });
            }
          },
        ),
        AppTextField.minMaxNumber(
          headerText: 'Border relay length',
          hintText: '',
          max: 32,
          controller: _ipv6BorderRelayPrefixLengthController,
          onFocusChanged: (focused) {
            if (!focused) {
              setState(() {
                state = state.copyWith(
                    ipv6BorderRelayPrefixLength:
                        int.parse(_ipv6BorderRelayPrefixLengthController.text));
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildConnectionModeSection() {
    return AppSection(
      header: const AppText.titleMedium('Connection Mode'),
      child: SizedBox(
        height: 180,
        child: AppRadioList(
          initial: _selectedConnectionMode,
          items: [
            AppRadioListItem(
              title: 'Connect on demand',
              value: PPPConnectionBehavior.connectOnDemand,
              subtitleWidget: Row(
                children: [
                  const AppText.bodyMedium('Max Idle Time: '),
                  const AppGap.semiSmall(),
                  SizedBox(
                    width: 70,
                    child: AppTextField.minMaxNumber(
                      max: 9999,
                      min: 1,
                      controller: _idleTimeController,
                      onFocusChanged: (focused) {
                        if (!focused) {
                          setState(() {
                            state = state.copyWith(
                                maxIdleMinutes:
                                    int.parse(_idleTimeController.text));
                          });
                        }
                      },
                    ),
                  ),
                  const AppGap.semiSmall(),
                  const AppText.bodyMedium('Minutes'),
                ],
              ),
            ),
            AppRadioListItem(
              title: 'Keep alive',
              value: PPPConnectionBehavior.keepAlive,
              subtitleWidget: Row(
                children: [
                  const AppText.bodyMedium('Redial Period: '),
                  const AppGap.semiSmall(),
                  SizedBox(
                    width: 70,
                    child: AppTextField.minMaxNumber(
                      max: 180,
                      min: 20,
                      controller: _redialPeriodController,
                      onFocusChanged: (focused) {
                        if (!focused) {
                          setState(() {
                            state = state.copyWith(
                                reconnectAfterSeconds:
                                    int.parse(_redialPeriodController.text));
                          });
                        }
                      },
                    ),
                  ),
                  const AppGap.semiSmall(),
                  const AppText.bodyMedium('Seconds'),
                ],
              ),
            ),
          ],
          onChanged: (index, type) {
            setState(() {
              if (type != null) {
                _selectedConnectionMode = type;
              }
            });
          },
        ),
      ),
    );
  }

  Widget _pptpIpAddressModeSection() {
    return AppSection(
      header: const AppText.titleMedium('IP Address'),
      child: SizedBox(
        // height: 100,
        child: AppRadioList(
          initial: _selectedPPTPIpAddressMode,
          items: [
            AppRadioListItem(
              title: 'Obtain an IPv4 address automatically (DHCP)',
              value: PPTPIpAddressMode.dhcp,
            ),
            AppRadioListItem(
              title: 'Specify an IPv4 address',
              value: PPTPIpAddressMode.specify,
            ),
          ],
          onChanged: (index, type) {
            setState(() {
              if (type != null) {
                _selectedPPTPIpAddressMode = type;
                state = state.copyWith(
                    useStaticSettings: type == PPTPIpAddressMode.specify);
              }
            });
          },
        ),
      ),
    );
  }
}
