import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/picker/simple_item_picker.dart';
import 'package:linksys_app/page/components/shortcuts/snack_bar.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/page/dashboard/view/administration/common_widget.dart';
import 'package:linksys_app/provider/local_network_settings/local_network_settings_provider.dart';
import 'package:linksys_app/provider/local_network_settings/local_network_settings_state.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_app/utils.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/input_field/ip_form_field.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';

class LocalNetworkSettingsView extends ArgumentsConsumerStatefulView {
  const LocalNetworkSettingsView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<LocalNetworkSettingsView> createState() =>
      _LocalNetworkSettingsViewState();
}

class _LocalNetworkSettingsViewState
    extends ConsumerState<LocalNetworkSettingsView> {
  bool _isLoading = true;
  late LocalNetworkSettingsState currentSettings;
  final _hostNameController = TextEditingController();
  final _hostIpAddressController = TextEditingController();
  final _hostSubnetMaskController = TextEditingController();
  final _startIpAddressController = TextEditingController();
  final _maxUserAllowedController = TextEditingController();
  final _clientLeaseTimeController = TextEditingController();
  final _dns1Controller = TextEditingController();
  final _dns2Controller = TextEditingController();
  final _dns3Controller = TextEditingController();
  final _winsController = TextEditingController();
  final Map<String, String> errors = {};

  @override
  void initState() {
    super.initState();
    ref.read(localNetworkSettingProvider.notifier).fetch().then((value) {
      setState(() {
        currentSettings =
            ref.read(localNetworkSettingProvider.notifier).currentSettings();
        _hostNameController.text = currentSettings.hostName;
        _hostIpAddressController.text = currentSettings.ipAddress;
        _hostSubnetMaskController.text = currentSettings.subnetMask;
        _startIpAddressController.text = currentSettings.firstIPAddress;
        _maxUserAllowedController.text = '${currentSettings.maxUserAllowed}';
        _clientLeaseTimeController.text = '${currentSettings.clientLeaseTime}';
        if (currentSettings.dns1 != null) {
          _dns1Controller.text = currentSettings.dns1!;
        }
        if (currentSettings.dns2 != null) {
          _dns2Controller.text = currentSettings.dns2!;
        }
        if (currentSettings.dns3 != null) {
          _dns3Controller.text = currentSettings.dns3!;
        }
        if (currentSettings.wins != null) {
          _winsController.text = currentSettings.wins!;
        }
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? AppFullScreenSpinner(
            text: getAppLocalizations(context).processing,
          )
        : settingVIew(context);
  }

  Widget settingVIew(BuildContext context) {
    return StyledAppPageView(
      scrollable: true,
      title: getAppLocalizations(context).lan,
      actions: [
        AppTextButton(
          getAppLocalizations(context).save,
          onTap: errors.isEmpty
              ? () {
                  _saveSettings();
                }
              : null,
        )
      ],
      child: AppBasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Temp error messages
            if (errors.isNotEmpty)
              AppText.labelLarge(
                errors.toString(),
                color: Colors.red,
              ),
            // Host name
            const AppText.bodyLarge(
              'Host name',
            ),
            const AppGap.small(),
            AppTextField.outline(
              controller: _hostNameController,
            ),
            const AppGap.regular(),
            // IP address
            AppIPFormField(
              header: AppText.bodyLarge(
                getAppLocalizations(context).ip_address,
              ),
              controller: _hostIpAddressController,
              onFocusChanged: (focused) {
                if (focused) return;
                // Host IP input finishes
                final result = ref
                    .read(localNetworkSettingProvider.notifier)
                    .routerIpAddressFinished(
                      _hostIpAddressController.text,
                      currentSettings,
                    );
                setState(() {
                  updateErrorPrompts(
                    'RouterIpAddress',
                    result.$1 ? null : 'Invalid IP address',
                  );
                  currentSettings = result.$2;
                  // Update the value of first Ip text controller
                  _startIpAddressController.text =
                      currentSettings.firstIPAddress;
                });
              },
            ),
            const AppGap.regular(),
            // Subnet mask
            AppIPFormField(
              header: AppText.bodyLarge(
                getAppLocalizations(context).subnet_mask,
              ),
              octet1ReadOnly: true,
              octet2ReadOnly: true,
              controller: _hostSubnetMaskController,
              onFocusChanged: (focused) {
                if (focused) return;
                // Subnet mask input finishes
                final result = ref
                    .read(localNetworkSettingProvider.notifier)
                    .subnetMaskFinished(
                      _hostSubnetMaskController.text,
                      currentSettings,
                    );
                setState(() {
                  updateErrorPrompts(
                    'SubnetMask',
                    result.$1 ? null : 'Invalid subnet mask',
                  );
                  currentSettings = result.$2;
                  // Update the value of maxUserAllowed text controller
                  _maxUserAllowedController.text =
                      '${currentSettings.maxUserAllowed}';
                });
              },
            ),
            const AppGap.regular(),
            dhcpServerSettingView(context),
          ],
        ),
      ),
    );
  }

  Widget dhcpServerSettingView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText.headlineSmall(
          'DHCP Server',
        ),
        const AppGap.small(),
        Row(
          children: [
            AppText.bodyLarge(
              getAppLocalizations(context).enabled,
            ),
            const Spacer(),
            AppSwitch(
              value: currentSettings.isDHCPEnabled,
              onChanged: (enabled) {
                setState(() {
                  currentSettings = currentSettings.copyWith(
                    isDHCPEnabled: enabled,
                  );
                });
              },
            ),
          ],
        ),
        const AppGap.regular(),
        Visibility(
          visible: currentSettings.isDHCPEnabled,
          replacement: const Center(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIPFormField(
                header: AppText.bodyLarge(
                  getAppLocalizations(context).start_ip_address,
                ),
                controller: _startIpAddressController,
                octet1ReadOnly: true,
                octet2ReadOnly: true,
                onFocusChanged: (focused) {
                  if (focused) return;
                  // Start Ip input finishes
                  final result = ref
                      .read(localNetworkSettingProvider.notifier)
                      .startIpFinished(
                        _startIpAddressController.text,
                        currentSettings,
                      );
                  setState(() {
                    updateErrorPrompts(
                      'StartIpAddress',
                      result.$1
                          ? null
                          : 'Invalid Ip or the same as the Host Ip',
                    );
                    currentSettings = result.$2;
                  });
                },
              ),
              const AppGap.regular(),
              AppText.bodyLarge(
                'Maximum number of users: [1 - ${currentSettings.maxUserLimit}]',
              ),
              const AppGap.small(),
              AppTextField.minMaxNumber(
                max: currentSettings.maxUserLimit,
                controller: _maxUserAllowedController,
                hintText: '1 - ${currentSettings.maxUserLimit}',
                onFocusChanged: (focused) {
                  if (focused) return;
                  // Max user input finishes
                  final result = ref
                      .read(localNetworkSettingProvider.notifier)
                      .maxUserAllowedFinished(
                        _maxUserAllowedController.text,
                        currentSettings,
                      );
                  setState(() {
                    updateErrorPrompts(
                      'MaxUserAllowed',
                      result.$1 ? null : 'Invalid number',
                    );
                    currentSettings = result.$2;
                  });
                },
              ),
              const AppGap.regular(),
              AppText.bodyLarge(
                'IP address range:\n${currentSettings.firstIPAddress}\nto\n${currentSettings.lastIPAddress}',
              ),
              const AppGap.regular(),
              AppText.bodyLarge(
                getAppLocalizations(context).client_lease_time,
              ),
              AppTextField.minMaxNumber(
                min: currentSettings.minAllowDHCPLeaseMinutes,
                max: currentSettings.maxAllowDHCPLeaseMinutes,
                controller: _clientLeaseTimeController,
                hintText: getAppLocalizations(context).client_lease_time,
                descriptionText: getAppLocalizations(context).minutes,
                onFocusChanged: (focused) {
                  if (focused) return;
                  // Client lease time input finishes
                  final result = ref
                      .read(localNetworkSettingProvider.notifier)
                      .clientLeaseFinished(
                        _clientLeaseTimeController.text,
                        currentSettings,
                      );
                  setState(() {
                    updateErrorPrompts(
                      'LeaseTime',
                      result.$1 ? null : 'Invalid number',
                    );
                    currentSettings = result.$2;
                  });
                },
              ),
              ..._buildDNSInputFields(),
              AppPanelWithInfo(
                title: getAppLocalizations(context).dhcp_reservations,
                infoText: ' ',
                onTap: () {
                  //TODO: Show DHCP reservation table
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildDNSInputFields() {
    return [
      AppIPFormField(
        header: AppText.bodyLarge(
          getAppLocalizations(context).static_dns1,
        ),
        controller: _dns1Controller,
        onFocusChanged: (focused) {
          if (!focused && _dns1Controller.text.isNotEmpty) {
            // DNS1 input finishes
            final result = ref
                .read(localNetworkSettingProvider.notifier)
                .staticDns1Finished(
                  _dns1Controller.text,
                  currentSettings,
                );
            setState(() {
              updateErrorPrompts(
                'DNS1',
                result.$1 ? null : 'Invalid IP address',
              );
              currentSettings = result.$2;
            });
          }
        },
      ),
      const AppGap.regular(),
      AppIPFormField(
        header: AppText.bodyLarge(
          getAppLocalizations(context).static_dns2_optional,
        ),
        controller: _dns2Controller,
        onFocusChanged: (focused) {
          if (!focused && _dns2Controller.text.isNotEmpty) {
            // DNS2 input finishes
            final result = ref
                .read(localNetworkSettingProvider.notifier)
                .staticDns2Finished(
                  _dns2Controller.text,
                  currentSettings,
                );
            setState(() {
              updateErrorPrompts(
                'DNS2',
                result.$1 ? null : 'Invalid IP address',
              );
              currentSettings = result.$2;
            });
          }
        },
      ),
      const AppGap.regular(),
      AppIPFormField(
        header: AppText.bodyLarge(
          getAppLocalizations(context).static_dns3_optional,
        ),
        controller: _dns3Controller,
        onFocusChanged: (focused) {
          if (!focused && _dns3Controller.text.isNotEmpty) {
            // DNS3 input finishes
            final result = ref
                .read(localNetworkSettingProvider.notifier)
                .staticDns3Finished(
                  _dns3Controller.text,
                  currentSettings,
                );
            setState(() {
              updateErrorPrompts(
                'DNS3',
                result.$1 ? null : 'Invalid IP address',
              );
              currentSettings = result.$2;
            });
          }
        },
      ),
      const AppGap.regular(),
      AppIPFormField(
        header: AppText.bodyLarge(
          getAppLocalizations(context).wins,
        ),
        controller: _winsController,
        onFocusChanged: (focused) {
          if (!focused && _winsController.text.isNotEmpty) {
            // WINS server input finishes
            final result = ref
                .read(localNetworkSettingProvider.notifier)
                .winsServerFinished(
                  _winsController.text,
                  currentSettings,
                );
            setState(() {
              updateErrorPrompts(
                'WINS',
                result.$1 ? null : 'Invalid IP address',
              );
              currentSettings = result.$2;
            });
          }
        },
      ),
    ];
  }

  void _saveSettings() {
    setState(() {
      _isLoading = true;
    });
    ref
        .read(localNetworkSettingProvider.notifier)
        .saveSettings(currentSettings)
        .then((value) {
      setState(() {
        _isLoading = false;
      });
      showSuccessSnackBar(context, 'Success!');
    }).onError((error, stackTrace) {
      _isLoading = false;
      showFailedSnackBar(context, 'Failed!');
    });
  }

  updateErrorPrompts(String key, String? value) {
    if (value != null) {
      errors[key] = value;
    } else {
      errors.remove(key);
    }
  }
}

// class LocalNetworkSettingsView extends ArgumentsConsumerStatelessView {
//   const LocalNetworkSettingsView({super.key, super.args});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return LANContentView(
//       args: super.args,
//     );
//   }
// }

/*
class LANContentView extends ArgumentsConsumerStatefulView {
  const LANContentView({super.key, super.args});

  @override
  ConsumerState<LANContentView> createState() => _LANContentViewState();
}


class _LANContentViewState extends ConsumerState<LANContentView> {
  late final LANNotifier _notifier;

  final TextEditingController _ipAddressController = TextEditingController();
  final TextEditingController _subnetMaskController = TextEditingController();
  final TextEditingController _firstIPController = TextEditingController();
  final TextEditingController _maxNumUserController = TextEditingController();
  final TextEditingController _clientLeaseController = TextEditingController();
  final TextEditingController _dns1Controller = TextEditingController();
  final TextEditingController _dns2Controller = TextEditingController();

  @override
  void initState() {
    _notifier = ref.read(lanProvider.notifier);
    _notifier.fetch().then((state) {
      // init text field
      _ipAddressController.text = state.ipAddress;
      _subnetMaskController.text = state.subnetMask;
      _firstIPController.text = state.firstIPAddress;
      _maxNumUserController.text = '${state.maxNumUsers}';
      _clientLeaseController.text = '${state.clientLeaseTime}';
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(lanProvider);
    return StyledAppPageView(
      scrollable: true,
      title: getAppLocalizations(context).lan,
      actions: [
        AppTextButton(
          getAppLocalizations(context).save,
          onTap: () {},
        )
      ],
      child: AppBasicLayout(
        content: Column(
          children: [
            administrationSection(
              title: getAppLocalizations(context).router_details,
              content: Column(
                children: [
                  AppIPFormField(
                    header: AppText.bodyLarge(
                      getAppLocalizations(context).ip_address,
                    ),
                    controller: _ipAddressController,
                    onFocusChanged: (focused) {
                      if (!focused) {
                        _notifier.setIPAddress(_ipAddressController.text);
                      }
                    },
                    isError: state.errors['ipAddress'] != null,
                  ),
                  const AppGap.semiBig(),
                  AppIPFormField(
                    header: AppText.bodyLarge(
                      getAppLocalizations(context).subnet_mask,
                    ),
                    controller: _subnetMaskController,
                    onFocusChanged: (focused) {
                      if (!focused) {
                        _notifier.setSubnetMask(_subnetMaskController.text);
                      }
                    },
                    isError: state.errors['subnetMask'] != null,
                  ),
                ],
              ),
            ),
            administrationSection(
              title: getAppLocalizations(context).dhcp_server,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppGap.semiBig(),
                  AppPanelWithSwitch(
                    value: state.isDHCPEnabled,
                    title: getAppLocalizations(context).dhcp_server,
                    onChangedEvent: (value) {},
                  ),
                  AppIPFormField(
                    header: AppText.bodyLarge(
                      getAppLocalizations(context).start_ip_address,
                    ),
                    controller: _firstIPController,
                    onFocusChanged: (focused) {
                      if (!focused) {
                        _notifier.setFirstIPAddress(_firstIPController.text);
                      }
                    },
                    isError: state.errors['firstIPAddress'] != null,
                  ),
                  const AppGap.semiBig(),
                  AppTextField(
                    controller: _maxNumUserController,
                    headerText:
                        getAppLocalizations(context).max_number_of_users,
                    hintText: getAppLocalizations(context).max_number_of_users,
                    descriptionText: getAppLocalizations(context)
                        .dhcp_users_limit(state.maxNumUsers),
                    onFocusChanged: (focused) {
                      if (!focused) {
                        _notifier.setMaxUsers(_maxNumUserController.text);
                      }
                    },
                  ),
                  const AppGap.semiSmall(),
                  AppText.bodyMedium(
                    getAppLocalizations(context).dhcp_ip_range(
                        state.firstIPAddress, state.lastIPAddress),
                  ),
                  const AppGap.semiBig(),
                  AppTextField(
                    controller: _clientLeaseController,
                    headerText: getAppLocalizations(context).client_lease_time,
                    hintText: getAppLocalizations(context).client_lease_time,
                    descriptionText: getAppLocalizations(context).minutes,
                    onFocusChanged: (focused) {
                      if (!focused) {
                        _notifier.setLeaseTime(_clientLeaseController.text);
                      }
                    },
                  ),
                  const AppGap.semiBig(),
                ],
              ),
            ),
            administrationSection(
              enabled: state.isDHCPEnabled,
              title: getAppLocalizations(context).dns_settings,
              content: Column(
                children: [
                  AppPanelWithInfo(
                    title: getAppLocalizations(context).dns,
                    infoText: state.isAutoDNS
                        ? getAppLocalizations(context).auto
                        : getAppLocalizations(context).manual,
                    onTap: () async {
                      String? result = await context.pushNamed(
                        RouteNamed.itemPicker,
                        queryParameters: {
                          'items': [
                            const Item(title: 'Auto', id: 'Auto'),
                            const Item(title: 'Manual', id: 'Manual'),
                          ],
                          'selected': state.isAutoDNS ? 'Auto' : 'Manual',
                        },
                      );
                      if (result != null) {
                        _notifier.setAutoDNS(result == 'Auto');
                      }
                    },
                  ),
                  ..._buildDNSInputFields(state),
                  AppPanelWithInfo(
                    title: getAppLocalizations(context).dhcp_reservations,
                    infoText: ' ',
                    onTap: () {
                      context.pushNamed(RouteNamed.dhcpReservation);
                    },
                  ),
                ],
              ),
            ),
            const AppGap.extraBig(),
          ],
        ),
      ),
    );
  }

  
}
*/
