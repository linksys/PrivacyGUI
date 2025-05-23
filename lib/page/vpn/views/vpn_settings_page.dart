import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/components/mixin/page_snackbar_mixin.dart';
import 'package:privacy_gui/page/vpn/providers/vpn_notifier.dart';
import 'package:privacy_gui/page/vpn/providers/vpn_state.dart';
import 'package:privacy_gui/page/vpn/views/shared_widgets.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacy_gui/validator_rules/_validator_rules.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/dropdown/dropdown_button.dart';
import 'package:privacy_gui/page/vpn/models/vpn_models.dart';
import 'package:privacy_gui/page/components/mixin/preserved_state_mixin.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacygui_widgets/widgets/input_field/ip_form_field.dart';

class VPNSettingsPage extends ArgumentsConsumerStatefulView {
  const VPNSettingsPage({super.key, super.args});

  @override
  ConsumerState<VPNSettingsPage> createState() => _VPNSettingsPageState();
}

class _VPNSettingsPageState extends ConsumerState<VPNSettingsPage>
    with PageSnackbarMixin, PreservedStateMixin<VPNSettings, VPNSettingsPage> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _gatewayController = TextEditingController();
  final _dnsController = TextEditingController();
  final _ikeProposalController = TextEditingController();
  final _espProposalController = TextEditingController();
  final _tunneledUserController = TextEditingController();

  final _usernameValidator = InputValidator([
    RequiredRule(),
    NoSurroundWhitespaceRule(),
    LengthRule(min: 1),
    AsciiRule(),
  ]);
  final _passwordValidator = InputValidator([
    RequiredRule(),
    NoSurroundWhitespaceRule(),
    LengthRule(min: 1),
    AsciiRule(),
  ]);
  final _tunneledUserValidator = IpAddressValidator();
  final _gatewayValidator = IpAddressValidator();

  @override
  void initState() {
    super.initState();

    doSomethingWithSpinner(
        context,
        ref.read(vpnProvider.notifier).fetch().then((state) {
          preservedState = state.settings;
          _initializeControllers(state.settings);
        }));
  }

  void _initializeControllers(VPNSettings state) {
    _usernameController.text = state.userCredentials?.username ?? '';
    if (_usernameController.text.isNotEmpty) {
      _usernameValidator.validate(_usernameController.text);
    }
    _passwordController.text = state.userCredentials?.secret ?? '';
    if (_passwordController.text.isNotEmpty) {
      _passwordValidator.validate(_passwordController.text);
    }
    _gatewayController.text = state.gatewaySettings?.gatewayAddress ?? '';
    if (_gatewayController.text.isNotEmpty) {
      _gatewayValidator.validate(_gatewayController.text);
    }
    _dnsController.text = state.gatewaySettings?.dnsName ?? '';
    _ikeProposalController.text = state.gatewaySettings?.ikeProposal ?? '';
    _espProposalController.text = state.gatewaySettings?.espProposal ?? '';
    _tunneledUserController.text = state.tunneledUserIP ?? '';
    if (_tunneledUserController.text.isNotEmpty) {
      _tunneledUserValidator.validate(_tunneledUserController.text);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _gatewayController.dispose();
    _dnsController.dispose();
    _ikeProposalController.dispose();
    _espProposalController.dispose();
    _tunneledUserController.dispose();
    super.dispose();
  }

  bool _hasErrors() {
    final isEditingCredentials =
        ref.watch(vpnProvider).settings.isEditingCredentials;
    final isUsernameValid = _usernameValidator.isValid;
    final isPasswordValid = _passwordValidator.isValid;
    final isTunneledUserValid = _tunneledUserValidator.isValid;
    final isGatewayValid = _gatewayValidator.isValid;
    return (isEditingCredentials
            ? (isUsernameValid != true || isPasswordValid != true)
            : false) ||
        (_tunneledUserController.text.isNotEmpty
            ? isTunneledUserValid != true
            : false) ||
        (_gatewayController.text.isNotEmpty ? isGatewayValid != true : false);
  }

  Future<bool> _confirmSaveDialog() async {
    return await showMessageAppDialog(context,
        title: loc(context).alertExclamation,
        message:
            'We are applying your changes, please wait for a moment. It will restart the VPN service. Do you want to proceed?',
        actions: [
          AppTextButton(loc(context).cancel, onTap: () {
            context.pop(false);
          }),
          AppTextButton(loc(context).save, onTap: () {
            context.pop(true);
          }),
        ]);
  }

  Future<void> _saveChanges() async {
    if (_hasErrors()) return;
    final shouldSave = await _confirmSaveDialog();
    if (!shouldSave) return;
    final notifier = ref.read(vpnProvider.notifier);
    doSomethingWithSpinner(context, notifier.save()).then((state) {
      if (state == null) {
        return;
      }
      preservedState = state.settings;
      // _hasChanges = false;
      _initializeControllers(state.settings);
      if (mounted) {
        showChangesSavedSnackBar();
      }
    }).onError((error, stack) {
      if (mounted) {
        showErrorMessageSnackBar(error);
      }
    });
  }

  void _onBackTap() {
    if (isStateChanged(ref.read(vpnProvider).settings)) {
      showUnsavedAlert(context).then((shouldDiscard) {
        if (shouldDiscard == true) {
          context.pop();
        }
      });
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vpnProvider);
    final notifier = ref.read(vpnProvider.notifier);

    // final changed = isStateChanged(state.settings);
    // if (_hasChanges != changed) {
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     if (mounted) setState(() => _hasChanges = changed);
    //   });
    // }

    return StyledAppPageView(
      title: loc(context).vpnSettingsTitle,
      onBackTap: _onBackTap,
      scrollable: true,
      bottomBar: PageBottomBar(
        isPositiveEnabled: !_hasErrors() && isStateChanged(state.settings),
        positiveLabel: loc(context).save,
        onPositiveTap: _saveChanges,
      ),
      child: (context, constraints) {
        return Form(
          key: _formKey,
          child: Column(
            children: [
              _buildStatusCard(state, notifier),
              const AppGap.medium(),
              ResponsiveLayout(
                desktop: _buildDesktopLayout(state, notifier),
                mobile: _buildMobileLayout(state, notifier),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusCard(VPNState state, VPNNotifier notifier) {
    final status = state.status.tunnelStatus;

    return AppCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          vpnStatus(context, status),
          AppTextButton(
            key: ValueKey('testAgain'),
            loc(context).testAgain,
            onTap: () async {
              bool isChanged = isStateChanged(state.settings);
              bool hasErrors = _hasErrors();

              final shouldGo = !isChanged
                  ? true
                  : !hasErrors
                      ? await showMessageAppDialog(context,
                          title: loc(context).unsavedChangesTitle,
                          message:
                              'Your changes is undaved, do you want to save and test it?',
                          actions: [
                              AppTextButton(loc(context).cancel, onTap: () {
                                context.pop(false);
                              }),
                              AppTextButton(loc(context).save, onTap: () {
                                context.pop(true);
                              }),
                            ])
                      : await showMessageAppOkDialog(context,
                              title: loc(context).alertExclamation,
                              message:
                                  'Your changes has errors, please fix them before testing.',
                              icon: Icon(LinksysIcons.error))
                          .then((_) => false);

              if (!shouldGo) {
                return;
              }
              if (isChanged) {
                await _saveChanges();
              }

              doSomethingWithSpinner(context, notifier.testVPNConnection())
                  .then((state) {
                if (state == null) {
                  return;
                }
                preservedState = state.settings;
                if (state.status.testResult?.success == true) {
                  showSuccessSnackBar(
                    state.status.testResult!.statusMessage,
                  );
                } else {
                  showFailedSnackBar(
                    state.status.testResult!.statusMessage,
                  );
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(VPNState state, VPNNotifier notifier) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 6.col,
          child: Column(
            children: [
              _buildCredentialsSection(state, notifier),
              const AppGap.medium(),
              _buildGatewaySection(state, notifier),
            ],
          ),
        ),
        const AppGap.gutter(),
        SizedBox(
          width: 6.col,
          child: Column(
            children: [
              _buildEnabledCard(state, notifier),
              const AppGap.medium(),
              _buildAutoConnectCard(state, notifier),
              const AppGap.medium(),
              _buildTunneledUserSection(state, notifier),
              if (state.status.tunnelStatus == IPsecStatus.connected &&
                  state.status.statistics != null) ...[
                const AppGap.medium(),
                _buildStatisticsSection(state.status.statistics!),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(VPNState state, VPNNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEnabledCard(state, notifier),
        const AppGap.medium(),
        _buildAutoConnectCard(state, notifier),
        const AppGap.medium(),
        _buildCredentialsSection(state, notifier),
        const AppGap.medium(),
        _buildGatewaySection(state, notifier),
        const AppGap.medium(),
        _buildTunneledUserSection(state, notifier),
        if (state.status.tunnelStatus == IPsecStatus.connected &&
            state.status.statistics != null) ...[
          const AppGap.medium(),
          _buildStatisticsSection(state.status.statistics!),
        ],
      ],
    );
  }

  Widget _buildCredentialsSection(VPNState state, VPNNotifier notifier) {
    return _buildSection(
      title: loc(context).vpnUserCredentialsSection,
      isEnabled: state.settings.isEditingCredentials,
      trailing: AppIconButton(
        icon: state.settings.isEditingCredentials
            ? LinksysIcons.close
            : LinksysIcons.edit,
        color: Theme.of(context).colorScheme.primary,
        onTap: () {
          setState(() {
            if (state.settings.isEditingCredentials) {
              // restore user credentials state
              final preservedUserCredentials =
                  getPreservedState('userCredentials');
              if (preservedUserCredentials != null &&
                  preservedUserCredentials.userCredentials != null) {
                notifier.setVPNUser(preservedUserCredentials.userCredentials!);
                _initializeControllers(preservedUserCredentials);
              }
            } else {
              // preserve user credentials state
              setPreservedState('userCredentials', state.settings);
            }
            notifier
                .setEditingCredentials(!state.settings.isEditingCredentials);
          });
        },
      ),
      children: [
        AppTextField.outline(
          key: ValueKey('username'),
          hintText: loc(context).username,
          headerText: loc(context).username,
          controller: _usernameController,
          errorText: _usernameValidator.isValid ?? true
              ? null
              : loc(context).invalidUsername,
          onChanged: (value) {
            if (state.settings.userCredentials != null) {
              notifier.setVPNUser(
                VPNUserCredentials(
                  username: value,
                  authMode: state.settings.userCredentials!.authMode,
                  secret: null,
                ),
              );
              setState(() {});
            }
          },
          onFocusChanged: (focus) {
            if (!focus) {
              _usernameValidator.validate(_usernameController.text);
              setState(() {});
            }
          },
        ),
        const AppGap.medium(),
        AppDropdownButton<AuthMode>(
          title: loc(context).vpnAuthMode,
          items: AuthMode.values,
          selected: state.settings.userCredentials?.authMode,
          label: (mode) => mode.toDisplayName(context),
          onChanged: (value) {
            if (state.settings.userCredentials != null) {
              notifier.setVPNUser(
                VPNUserCredentials(
                  username: state.settings.userCredentials!.username,
                  authMode: value,
                  secret: null,
                ),
              );
              setState(() {});
            }
          },
        ),
        if (state.settings.isEditingCredentials) ...[
          const AppGap.medium(),
          AppTextField.outline(
            key: ValueKey('password'),
            hintText: loc(context).password,
            headerText: loc(context).password,
            controller: _passwordController,
            errorText: _passwordValidator.isValid ?? true
                ? null
                : loc(context).invalidPassword,
            onChanged: (value) {
              if (state.settings.userCredentials != null) {
                notifier.setVPNUser(
                  state.settings.userCredentials!.copyWith(secret: value),
                );
                setState(() {});
              }
            },
            onFocusChanged: (focus) {
              if (!focus) {
                _passwordValidator.validate(_passwordController.text);
                setState(() {});
              }
            },
          ),
        ]
      ],
    );
  }

  Widget _buildGatewaySection(VPNState state, VPNNotifier notifier) {
    return _buildSection(
      title: loc(context).gateway,
      children: [
        AppTextField.outline(
          key: ValueKey('gateway'),
          hintText: loc(context).gateway,
          headerText: loc(context).gateway,
          controller: _gatewayController,
          errorText: _gatewayValidator.isValid ?? true
              ? null
              : loc(context).invalidGatewayIpAddress,
          onChanged: (value) {
            if (state.settings.gatewaySettings != null) {
              notifier.setVPNGateway(
                state.settings.gatewaySettings!.copyWith(gatewayAddress: value),
              );
              setState(() {});
            }
          },
        ),
        const AppGap.medium(),
        AppTextField.outline(
          key: ValueKey('dns'),
          hintText: loc(context).dns,
          headerText: loc(context).dns,
          controller: _dnsController,
          onChanged: (value) {
            if (state.settings.gatewaySettings != null) {
              notifier.setVPNGateway(
                state.settings.gatewaySettings!.copyWith(dnsName: value),
              );
              setState(() {});
            }
          },
        ),
        const AppGap.medium(),
        AppDropdownButton<IKEMode>(
          title: loc(context).vpnIkeMode,
          items: IKEMode.values,
          selected: state.settings.gatewaySettings?.ikeMode,
          label: (mode) => mode.toDisplayName(context),
          onChanged: (value) {
            if (state.settings.gatewaySettings != null) {
              notifier.setVPNGateway(
                state.settings.gatewaySettings!.copyWith(ikeMode: value),
              );
              setState(() {});
            }
          },
        ),
        const AppGap.medium(),
        AppTextField.outline(
          key: ValueKey('ikeProposal'),
          hintText: loc(context).vpnIkeProposal,
          headerText: loc(context).vpnIkeProposal,
          controller: _ikeProposalController,
          onChanged: (value) {
            if (state.settings.gatewaySettings != null) {
              notifier.setVPNGateway(
                state.settings.gatewaySettings!.copyWith(ikeProposal: value),
              );
              setState(() {});
            }
          },
        ),
        const AppGap.medium(),
        AppTextField.outline(
          key: ValueKey('espProposal'),
          hintText: loc(context).vpnEspProposal,
          headerText: loc(context).vpnEspProposal,
          controller: _espProposalController,
          onChanged: (value) {
            if (state.settings.gatewaySettings != null) {
              notifier.setVPNGateway(
                state.settings.gatewaySettings!.copyWith(espProposal: value),
              );
              setState(() {});
            }
          },
        ),
      ],
    );
  }

  Widget _buildTunneledUserSection(VPNState state, VPNNotifier notifier) {
    return _buildSection(
      title: loc(context).vpnTunneledUserSection,
      isEnabled: state.settings.serviceSettings?.enabled ?? false,
      children: [
        AppIPFormField(
          key: ValueKey('tunneledUser'),
          header: AppText.labelLarge(loc(context).ipAddress),
          controller: _tunneledUserController,
          border: OutlineInputBorder(),
          errorText: _tunneledUserValidator.isValid ?? true
              ? null
              : loc(context).invalidIpAddress,
          onChanged: (value) {
            notifier.setTunneledUser(value);
            setState(() {});
          },
          onFocusChanged: (focus) {
            if (!focus && _tunneledUserController.text.isNotEmpty) {
              _tunneledUserValidator.validate(
                _tunneledUserController.text,
              );
              setState(() {});
            }
          },
        ),
      ],
    );
  }

  Widget _buildStatisticsSection(VPNStatistics statistics) {
    final uptimeInt = ref.watch(
        vpnProvider.select((value) => value.status.statistics?.uptime ?? 0));
    final uptime = uptimeInt > 0
        ? DateFormatUtils.formatDuration(Duration(seconds: uptimeInt), null)
        : '--';
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium(loc(context).vpnTunnelStatistics),
          const AppGap.small2(),
          buildStatRow(loc(context).vpnUptime, uptime),
          buildStatRow(
              loc(context).vpnPacketsSent, statistics.packetsSent.toString()),
          buildStatRow(loc(context).vpnPacketsReceived,
              statistics.packetsReceived.toString()),
          buildStatRow(
              loc(context).vpnBytesSent, '${statistics.bytesSent} bytes'),
          buildStatRow(loc(context).vpnBytesReceived,
              '${statistics.bytesReceived} bytes'),
          buildStatRow(loc(context).vpnCurrentBandwidth,
              '${statistics.currentBandwidth} bps'),
          buildStatRow(
              loc(context).vpnActiveSAs, statistics.activeSAs.toString()),
          buildStatRow(
              loc(context).vpnRekeyCount, statistics.rekeyCount.toString()),
        ],
      ),
    );
  }

  Widget _buildEnabledCard(VPNState state, VPNNotifier notifier) {
    return AppSettingCard(
      title: loc(context).vpnEnabled,
      trailing: AppSwitch(
        value: state.settings.serviceSettings?.enabled ?? false,
        onChanged: (value) {
          if (state.settings.serviceSettings != null) {
            notifier.setVPNService(
              state.settings.serviceSettings!.copyWith(enabled: value),
            );
            setState(() {});
          }
        },
      ),
    );
  }

  Widget _buildAutoConnectCard(VPNState state, VPNNotifier notifier) {
    return AppSettingCard(
      title: loc(context).vpnAutoConnect,
      trailing: AppSwitch(
        value: state.settings.serviceSettings?.autoConnect ?? false,
        onChanged: (value) {
          if (state.settings.serviceSettings != null) {
            notifier.setVPNService(
              state.settings.serviceSettings!.copyWith(autoConnect: value),
            );
            setState(() {});
          }
        },
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
    Widget? trailing,
    bool isEnabled = true,
  }) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: AppText.titleMedium(title)),
              if (trailing != null) trailing,
            ],
          ),
          const AppGap.small2(),
          Opacity(
            opacity: isEnabled ? 1 : 0.5,
            child: AbsorbPointer(
              absorbing: !isEnabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
