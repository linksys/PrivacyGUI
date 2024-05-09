import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';
import 'package:linksys_app/core/utils/extension.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/advanced_settings/internet_settings/views/internet_settings_view.dart';
import 'package:linksys_app/page/components/shortcuts/snack_bar.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/page/advanced_settings/local_network_settings/providers/local_network_settings_provider.dart';
import 'package:linksys_app/page/advanced_settings/local_network_settings/providers/local_network_settings_state.dart';
import 'package:linksys_app/route/constants.dart';
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
  late LocalNetworkSettingsState originalSettings;
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
        originalSettings =
            ref.read(localNetworkSettingProvider.notifier).currentSettings();
        _hostNameController.text = originalSettings.hostName;
        _hostIpAddressController.text = originalSettings.ipAddress;
        _hostSubnetMaskController.text = originalSettings.subnetMask;
        _startIpAddressController.text = originalSettings.firstIPAddress;
        _maxUserAllowedController.text = '${originalSettings.maxUserAllowed}';
        _clientLeaseTimeController.text = '${originalSettings.clientLeaseTime}';
        if (originalSettings.dns1 != null) {
          _dns1Controller.text = originalSettings.dns1!;
        }
        if (originalSettings.dns2 != null) {
          _dns2Controller.text = originalSettings.dns2!;
        }
        if (originalSettings.dns3 != null) {
          _dns3Controller.text = originalSettings.dns3!;
        }
        if (originalSettings.wins != null) {
          _winsController.text = originalSettings.wins!;
        }
        _isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _hostNameController.dispose();
    _hostIpAddressController.dispose();
    _hostSubnetMaskController.dispose();
    _startIpAddressController.dispose();
    _maxUserAllowedController.dispose();
    _clientLeaseTimeController.dispose();
    _dns1Controller.dispose();
    _dns2Controller.dispose();
    _dns3Controller.dispose();
    _winsController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(localNetworkSettingProvider);
    return _isLoading
        ? AppFullScreenSpinner(
            text: loc(context).processing,
          )
        : infoView(state);
  }

  Widget infoView(LocalNetworkSettingsState state) {
    return StyledAppPageView(
      scrollable: true,
      title: loc(context).localNetwork,
      saveAction: SaveAction(
        enabled: _isEdited(),
        onSave: _saveSettings,
      ),
      onBackTap: _isEdited()
          ? () {
              _showUnsavedAlert();
            }
          : null,
      child: AppBasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InternetSettingCard(
              title: loc(context).hostName,
              description: state.hostName,
              onTap: () {
                context.pushNamed(RouteNamed.localNetworkEdit, extra: {
                  'viewType': 'hostName',
                });
              },
            ),
            InternetSettingCard(
              title: loc(context).ipAddress.capitalizeWords(),
              description: state.ipAddress,
              onTap: () {
                context.pushNamed(RouteNamed.localNetworkEdit, extra: {
                  'viewType': 'ipAddress',
                });
              },
            ),
            InternetSettingCard(
              title: loc(context).subnetMask,
              description: state.subnetMask,
              onTap: () {
                context.pushNamed(RouteNamed.localNetworkEdit, extra: {
                  'viewType': 'subnetMask',
                });
              },
            ),
            InternetSettingCard(
              title: loc(context).dhcpServer,
              description:
                  state.isDHCPEnabled ? loc(context).on : loc(context).off,
              onTap: () {
                context.pushNamed(RouteNamed.dhcpServer);
              },
            ),
            InternetSettingCard(
              title: loc(context).dhcpReservations,
              onTap: () {
                context.pushNamed(RouteNamed.dhcpReservation);
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _isEdited() {
    final state = ref.read(localNetworkSettingProvider);
    return originalSettings != state;
  }

  void _showUnsavedAlert() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: AppText.titleLarge(loc(context).unsavedChangesTitle),
            content: AppText.bodyMedium(loc(context).unsavedChangesDesc),
            actions: [
              AppTextButton(
                loc(context).goBack,
                color: Theme.of(context).colorScheme.onSurface,
                onTap: () {
                  context.pop();
                },
              ),
              AppTextButton(
                loc(context).discardChanges,
                color: Theme.of(context).colorScheme.error,
                onTap: () {
                  ref
                      .read(localNetworkSettingProvider.notifier)
                      .updateState(originalSettings);
                  context.pop();
                  context.pop();
                },
              ),
            ],
          );
        });
  }

  Widget settingView(BuildContext context) {
    return StyledAppPageView(
      scrollable: true,
      title: loc(context).lan,
      actions: [
        AppTextButton(
          loc(context).save,
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
                loc(context).ipAddress.capitalizeWords(),
              ),
              controller: _hostIpAddressController,
              onFocusChanged: (focused) {
                if (focused) return;
                // Host IP input finishes
                final result = ref
                    .read(localNetworkSettingProvider.notifier)
                    .routerIpAddressFinished(
                      _hostIpAddressController.text,
                      originalSettings,
                    );
                setState(() {
                  updateErrorPrompts(
                    'RouterIpAddress',
                    result.$1 ? null : 'Invalid IP address',
                  );
                  originalSettings = result.$2;
                  // Update the value of first Ip text controller
                  _startIpAddressController.text =
                      originalSettings.firstIPAddress;
                });
              },
            ),
            const AppGap.regular(),
            // Subnet mask
            AppIPFormField(
              header: AppText.bodyLarge(
                loc(context).subnetMask,
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
                      originalSettings,
                    );
                setState(() {
                  updateErrorPrompts(
                    'SubnetMask',
                    result.$1 ? null : 'Invalid subnet mask',
                  );
                  originalSettings = result.$2;
                  // Update the value of maxUserAllowed text controller
                  _maxUserAllowedController.text =
                      '${originalSettings.maxUserAllowed}';
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
              loc(context).enabled,
            ),
            const Spacer(),
            AppSwitch(
              value: originalSettings.isDHCPEnabled,
              onChanged: (enabled) {
                setState(() {
                  originalSettings = originalSettings.copyWith(
                    isDHCPEnabled: enabled,
                  );
                });
              },
            ),
          ],
        ),
        const AppGap.regular(),
        Visibility(
          visible: originalSettings.isDHCPEnabled,
          replacement: const Center(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIPFormField(
                header: AppText.bodyLarge(
                  loc(context).startIpAddress,
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
                        originalSettings,
                      );
                  setState(() {
                    updateErrorPrompts(
                      'StartIpAddress',
                      result.$1
                          ? null
                          : 'Invalid Ip or the same as the Host Ip',
                    );
                    originalSettings = result.$2;
                  });
                },
              ),
              const AppGap.regular(),
              AppText.bodyLarge(
                'Maximum number of users: [1 - ${originalSettings.maxUserLimit}]',
              ),
              const AppGap.small(),
              AppTextField.minMaxNumber(
                max: originalSettings.maxUserLimit,
                controller: _maxUserAllowedController,
                hintText: '1 - ${originalSettings.maxUserLimit}',
                onFocusChanged: (focused) {
                  if (focused) return;
                  // Max user input finishes
                  final result = ref
                      .read(localNetworkSettingProvider.notifier)
                      .maxUserAllowedFinished(
                        _maxUserAllowedController.text,
                        originalSettings,
                      );
                  setState(() {
                    updateErrorPrompts(
                      'MaxUserAllowed',
                      result.$1 ? null : 'Invalid number',
                    );
                    originalSettings = result.$2;
                  });
                },
              ),
              const AppGap.regular(),
              AppText.bodyLarge(
                'IP address range:\n${originalSettings.firstIPAddress}\nto\n${originalSettings.lastIPAddress}',
              ),
              const AppGap.regular(),
              AppText.bodyLarge(
                loc(context).clientLeaseTime,
              ),
              AppTextField.minMaxNumber(
                min: originalSettings.minAllowDHCPLeaseMinutes,
                max: originalSettings.maxAllowDHCPLeaseMinutes,
                controller: _clientLeaseTimeController,
                hintText: loc(context).clientLeaseTime,
                descriptionText: loc(context).minutes,
                onFocusChanged: (focused) {
                  if (focused) return;
                  // Client lease time input finishes
                  final result = ref
                      .read(localNetworkSettingProvider.notifier)
                      .clientLeaseFinished(
                        _clientLeaseTimeController.text,
                        originalSettings,
                      );
                  setState(() {
                    updateErrorPrompts(
                      'LeaseTime',
                      result.$1 ? null : 'Invalid number',
                    );
                    originalSettings = result.$2;
                  });
                },
              ),
              ..._buildDNSInputFields(),
              AppPanelWithInfo(
                title: loc(context).dhcpReservations.capitalizeWords(),
                infoText: ' ',
                onTap: () {
                  context.pushNamed(RouteNamed.dhcpReservation);
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
          loc(context).staticDns1,
        ),
        controller: _dns1Controller,
        onFocusChanged: (focused) {
          if (!focused && _dns1Controller.text.isNotEmpty) {
            // DNS1 input finishes
            final result = ref
                .read(localNetworkSettingProvider.notifier)
                .staticDns1Finished(
                  _dns1Controller.text,
                  originalSettings,
                );
            setState(() {
              updateErrorPrompts(
                'DNS1',
                result.$1 ? null : 'Invalid IP address',
              );
              originalSettings = result.$2;
            });
          }
        },
      ),
      const AppGap.regular(),
      AppIPFormField(
        header: AppText.bodyLarge(
          loc(context).static_dns2_optional,
        ),
        controller: _dns2Controller,
        onFocusChanged: (focused) {
          if (!focused && _dns2Controller.text.isNotEmpty) {
            // DNS2 input finishes
            final result = ref
                .read(localNetworkSettingProvider.notifier)
                .staticDns2Finished(
                  _dns2Controller.text,
                  originalSettings,
                );
            setState(() {
              updateErrorPrompts(
                'DNS2',
                result.$1 ? null : 'Invalid IP address',
              );
              originalSettings = result.$2;
            });
          }
        },
      ),
      const AppGap.regular(),
      AppIPFormField(
        header: AppText.bodyLarge(
          loc(context).static_dns3_optional,
        ),
        controller: _dns3Controller,
        onFocusChanged: (focused) {
          if (!focused && _dns3Controller.text.isNotEmpty) {
            // DNS3 input finishes
            final result = ref
                .read(localNetworkSettingProvider.notifier)
                .staticDns3Finished(
                  _dns3Controller.text,
                  originalSettings,
                );
            setState(() {
              updateErrorPrompts(
                'DNS3',
                result.$1 ? null : 'Invalid IP address',
              );
              originalSettings = result.$2;
            });
          }
        },
      ),
      const AppGap.regular(),
      AppIPFormField(
        header: AppText.bodyLarge(
          loc(context).wins,
        ),
        controller: _winsController,
        onFocusChanged: (focused) {
          if (!focused && _winsController.text.isNotEmpty) {
            // WINS server input finishes
            final result = ref
                .read(localNetworkSettingProvider.notifier)
                .winsServerFinished(
                  _winsController.text,
                  originalSettings,
                );
            setState(() {
              updateErrorPrompts(
                'WINS',
                result.$1 ? null : 'Invalid IP address',
              );
              originalSettings = result.$2;
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
    final state = ref.read(localNetworkSettingProvider);
    ref
        .read(localNetworkSettingProvider.notifier)
        .saveSettings(state)
        .then((value) {
      originalSettings = state;
      showSuccessSnackBar(context, loc(context).changesSaved);
    }).onError((error, stackTrace) {
      final err = error as JNAPError;
      showFailedSnackBar(context, err.result);
    }).whenComplete(() {
      setState(() {
        _isLoading = false;
      });
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
