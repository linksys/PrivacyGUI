import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/components/mixin/page_snackbar_mixin.dart';
import 'package:privacy_gui/page/vpn/providers/vpn_notifier.dart';
import 'package:privacy_gui/page/vpn/providers/vpn_state.dart';
import 'package:privacy_gui/page/vpn/views/shared_widgets.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacy_gui/validator_rules/_validator_rules.dart';
import 'package:privacy_gui/page/vpn/models/vpn_models.dart';
import 'package:privacy_gui/page/components/mixin/preserved_state_mixin.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:ui_kit_library/ui_kit.dart' hide AppBarStyle, AppStyledText;

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
          AppButton.text(
              label: loc(context).cancel,
              onTap: () {
                context.pop(false);
              }),
          AppButton.text(
              label: loc(context).save,
              onTap: () {
                context.pop(true);
              }),
        ]);
  }

  Future<void> _saveChanges() async {
    if (_hasErrors()) return;
    final shouldSave = await _confirmSaveDialog();
    if (!shouldSave) return;
    final notifier = ref.read(vpnProvider.notifier);
    // If the widget is disposed before the save request, do nothing
    if (!mounted) return;
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
        if (shouldDiscard == true && mounted) {
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

    return UiKitPageView(
      title: loc(context).vpnSettingsTitle,
      onBackTap: _onBackTap,
      scrollable: true,
      bottomBar: UiKitBottomBarConfig(
        positiveLabel: loc(context).save,
        onPositiveTap: _saveChanges,
        isPositiveEnabled: !_hasErrors() && isStateChanged(state.settings),
      ),
      child: (context, constraints) {
        return Form(
          key: _formKey,
          child: Column(
            children: [
              _buildStatusCard(state, notifier),
              AppGap.lg(),
              context.isMobileLayout
                  ? _buildMobileLayout(state, notifier)
                  : _buildDesktopLayout(state, notifier),
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
          AppButton.text(
            key: const ValueKey('testAgain'),
            label: loc(context).testAgain,
            onTap: () async {
              final isChanged = isStateChanged(state.settings);
              final hasErrors = _hasErrors();

              bool shouldGo;
              if (!isChanged) {
                shouldGo = true;
              } else if (!hasErrors) {
                shouldGo = await showMessageAppDialog(
                  context,
                  title: loc(context).unsavedChangesTitle,
                  message:
                      'Your changes is unsaved, do you want to save and test it?',
                  actions: [
                    AppButton.text(
                        label: loc(context).cancel,
                        onTap: () {
                          context.pop(false);
                        }),
                    AppButton.text(
                        label: loc(context).save,
                        onTap: () {
                          context.pop(true);
                        }),
                  ],
                );
              } else {
                await showMessageAppOkDialog(
                  context,
                  title: loc(context).alertExclamation,
                  message:
                      'Your changes has errors, please fix them before testing.',
                  icon: AppFontIcons.error,
                );
                shouldGo = false;
              }

              if (!shouldGo) {
                return;
              }
              if (isChanged) {
                await _saveChanges();
              }

              if (!mounted) return;
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
          width: context.colWidth(6),
          child: Column(
            children: [
              _buildCredentialsSection(state, notifier),
              AppGap.lg(),
              _buildGatewaySection(state, notifier),
            ],
          ),
        ),
        AppGap.xxl(),
        SizedBox(
          width: context.colWidth(6),
          child: Column(
            children: [
              _buildEnabledCard(state, notifier),
              AppGap.lg(),
              _buildAutoConnectCard(state, notifier),
              AppGap.lg(),
              _buildTunneledUserSection(state, notifier),
              if (state.status.tunnelStatus == IPsecStatus.connected &&
                  state.status.statistics != null) ...[
                AppGap.lg(),
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
        AppGap.lg(),
        _buildAutoConnectCard(state, notifier),
        AppGap.lg(),
        _buildCredentialsSection(state, notifier),
        AppGap.lg(),
        _buildGatewaySection(state, notifier),
        AppGap.lg(),
        _buildTunneledUserSection(state, notifier),
        if (state.status.tunnelStatus == IPsecStatus.connected &&
            state.status.statistics != null) ...[
          AppGap.lg(),
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
        icon: AppIcon.font(
            state.settings.isEditingCredentials
                ? AppFontIcons.close
                : AppFontIcons.edit,
            color: Theme.of(context).colorScheme.primary),
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
        AppTextFormField(
          key: const ValueKey('username'),
          label: loc(context).username,
          controller: _usernameController,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (value) => _usernameValidator.isValid ?? true
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
          // onFocusChanged handled manually via listener if critical or ignored for now assuming validation updates on change
        ),
        AppGap.lg(),
        AppDropdown<String>(
          label: loc(context).vpnAuthMode,
          items: AuthMode.values.map((e) => e.toDisplayName(context)).toList(),
          value:
              state.settings.userCredentials?.authMode.toDisplayName(context),
          onChanged: (value) {
            if (value != null && state.settings.userCredentials != null) {
              final selectedMode = AuthMode.values.firstWhere(
                (e) => e.toDisplayName(context) == value,
              );
              notifier.setVPNUser(
                VPNUserCredentials(
                  username: state.settings.userCredentials!.username,
                  authMode: selectedMode,
                  secret: null,
                ),
              );
              setState(() {});
            }
          },
        ),
        if (state.settings.isEditingCredentials) ...[
          AppGap.lg(),
          AppTextFormField(
            key: const ValueKey('password'),
            label: loc(context).password,
            controller: _passwordController,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) => _passwordValidator.isValid ?? true
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
          ),
        ]
      ],
    );
  }

  Widget _buildGatewaySection(VPNState state, VPNNotifier notifier) {
    return _buildSection(
      title: loc(context).gateway,
      children: [
        AppTextFormField(
          key: const ValueKey('gateway'),
          label: loc(context).gateway,
          controller: _gatewayController,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (value) => _gatewayValidator.isValid ?? true
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
        AppGap.lg(),
        AppTextFormField(
          key: const ValueKey('dns'),
          label: loc(context).dns,
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
        AppGap.lg(),
        AppDropdown<String>(
          label: loc(context).vpnIkeMode,
          items: IKEMode.values.map((e) => e.toDisplayName(context)).toList(),
          value: state.settings.gatewaySettings?.ikeMode.toDisplayName(context),
          onChanged: (value) {
            if (value != null && state.settings.gatewaySettings != null) {
              final selectedMode = IKEMode.values.firstWhere(
                (e) => e.toDisplayName(context) == value,
              );
              notifier.setVPNGateway(
                state.settings.gatewaySettings!.copyWith(ikeMode: selectedMode),
              );
              setState(() {});
            }
          },
        ),
        AppGap.lg(),
        AppTextFormField(
          key: const ValueKey('ikeProposal'),
          label: loc(context).vpnIkeProposal,
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
        AppGap.lg(),
        AppTextFormField(
          key: const ValueKey('espProposal'),
          label: loc(context).vpnEspProposal,
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
      isEnabled: state.settings.serviceSettings.enabled,
      children: [
        AppTextFormField(
          key: const ValueKey('tunneledUser'),
          label: loc(context).ipAddress,
          controller: _tunneledUserController,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (value) => _tunneledUserValidator.isValid ?? true
              ? null
              : loc(context).invalidIpAddress,
          onChanged: (value) {
            notifier.setTunneledUser(value);
            setState(() {});
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
          AppGap.sm(),
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
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Expanded(child: AppText.titleMedium(loc(context).vpnEnabled)),
            AppSwitch(
              value: state.settings.serviceSettings.enabled,
              onChanged: (value) {
                notifier.setVPNService(
                  state.settings.serviceSettings.copyWith(enabled: value),
                );
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoConnectCard(VPNState state, VPNNotifier notifier) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Expanded(child: AppText.titleMedium(loc(context).vpnAutoConnect)),
            AppSwitch(
              value: state.settings.serviceSettings.autoConnect,
              onChanged: (value) {
                notifier.setVPNService(
                  state.settings.serviceSettings.copyWith(autoConnect: value),
                );
                setState(() {});
              },
            ),
          ],
        ),
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
          AppGap.sm(),
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
