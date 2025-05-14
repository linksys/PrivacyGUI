import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/components/mixin/page_snackbar_mixin.dart';
import 'package:privacy_gui/vpn/providers/vpn_notifier.dart';
import 'package:privacy_gui/vpn/providers/vpn_state.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/dropdown/dropdown_button.dart';
import 'package:privacy_gui/vpn/models/vpn_models.dart';
import 'package:privacy_gui/page/components/mixin/preserved_state_mixin.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';

class VPNSettingsPage extends ArgumentsConsumerStatefulView {
  const VPNSettingsPage({super.key});

  @override
  ConsumerState<VPNSettingsPage> createState() => _VPNSettingsPageState();
}

class _VPNSettingsPageState extends ConsumerState<VPNSettingsPage>
    with PageSnackbarMixin, PreservedStateMixin<VPNSettings, VPNSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  bool _hasChanges = false;

  // Text controllers
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _gatewayController = TextEditingController();
  final _dnsController = TextEditingController();
  final _ikeProposalController = TextEditingController();
  final _espProposalController = TextEditingController();
  final _tunneledUserController = TextEditingController();

  @override
  void initState() {
    super.initState();
    doSomethingWithSpinner(
        context,
        ref.read(vpnProvider.notifier).fetch().then((state) {
          preservedState = state.settings;
          _initializeControllers(state);
        }));
  }

  void _initializeControllers(VPNState state) {
    _usernameController.text = state.settings.userCredentials?.username ?? '';
    _passwordController.text = state.settings.userCredentials?.secret ?? '';
    _gatewayController.text =
        state.settings.gatewaySettings?.gatewayAddress ?? '';
    _dnsController.text = state.settings.gatewaySettings?.dnsName ?? '';
    _ikeProposalController.text =
        state.settings.gatewaySettings?.ikeProposal ?? '';
    _espProposalController.text =
        state.settings.gatewaySettings?.espProposal ?? '';
    _tunneledUserController.text = state.settings.tunneledUserIP ?? '';
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

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(vpnProvider.notifier);
    final state = ref.read(vpnProvider);
    try {
      if (state.settings.userCredentials != null) {
        await notifier.setVPNUser(
          VPNUserCredentials(
            username: state.settings.userCredentials!.username,
            authMode: state.settings.userCredentials!.authMode,
            secret: null,
          ),
        );
      }
      if (state.settings.gatewaySettings != null) {
        await notifier.setVPNGateway(state.settings.gatewaySettings!);
      }
      if (state.settings.serviceSettings != null) {
        await notifier.setVPNService(state.settings.serviceSettings!);
      }
      if (state.settings.tunneledUserIP != null) {
        await notifier.setTunneledUser(state.settings.tunneledUserIP!);
      }
      if (mounted) {
        showChangesSavedSnackBar();
        setState(() {
          preservedState = state.settings;
          _hasChanges = false;
        });
      }
    } catch (e) {
      if (mounted) {
        showErrorMessageSnackBar(e.toString());
      }
    }
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

    final changed = isStateChanged(state.settings);
    if (_hasChanges != changed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _hasChanges = changed);
      });
    }

    return StyledAppPageView(
      title: loc(context).vpnSettingsTitle,
      onBackTap: _onBackTap,
      scrollable: true,
      bottomBar: PageBottomBar(
        isPositiveEnabled: isStateChanged(state.settings),
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
    Color statusColor = Colors.grey; // Default color
    switch (status) {
      case IPsecStatus.connected:
        statusColor = Colors.green;
        break;
      case IPsecStatus.connecting:
        statusColor = Colors.orange;
        break;
      case IPsecStatus.disconnected:
        statusColor = Colors.grey;
        break;
      case IPsecStatus.failed:
        statusColor = Colors.red;
        break;
      case IPsecStatus.unknown:
        statusColor = Colors.grey;
        break;
    }

    return AppCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const AppGap.small2(),
              AppText.titleMedium(status.toDisplayName(context)),
            ],
          ),
          AppTextButton(
            loc(context).testAgain,
            onTap: () {
              doSomethingWithSpinner(
                context,
                notifier.testVPNConnection().then((state) {
                  preservedState = state.settings;
                }),
              );
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
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveLayout.pageHorizontalPadding(context),
              vertical: Spacing.medium,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCredentialsSection(state, notifier),
                const AppGap.medium(),
                _buildGatewaySection(state, notifier),
                const AppGap.medium(),
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
        ),
      ],
    );
  }

  Widget _buildCredentialsSection(VPNState state, VPNNotifier notifier) {
    return _buildSection(
      title: loc(context).vpnUserCredentialsSection,
      children: [
        AppTextField.outline(
          hintText: loc(context).username,
          headerText: loc(context).username,
          controller: _usernameController,
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
        const AppGap.medium(),
        AppTextField.outline(
          hintText: loc(context).password,
          headerText: loc(context).password,
          controller: _passwordController,
          onChanged: (value) {
            if (state.settings.userCredentials != null) {
              notifier.setVPNUser(
                state.settings.userCredentials!.copyWith(secret: value),
              );
              setState(() {});
            }
          },
        ),
      ],
    );
  }

  Widget _buildGatewaySection(VPNState state, VPNNotifier notifier) {
    return _buildSection(
      title: loc(context).gateway,
      children: [
        AppTextField.outline(
          hintText: loc(context).gateway,
          headerText: loc(context).gateway,
          controller: _gatewayController,
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
    return IgnorePointer(
      ignoring: !(state.settings.serviceSettings?.enabled ?? false),
      child: Opacity(
        opacity: state.settings.serviceSettings?.enabled ?? false ? 1 : 0.5,
        child: _buildSection(
          title: loc(context).vpnTunneledUserSection,
          children: [
            AppTextField.outline(
              hintText: loc(context).ipAddress,
              headerText: loc(context).ipAddress,
              controller: _tunneledUserController,
              onChanged: (value) {
                notifier.setTunneledUser(value);
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsSection(VPNStatistics statistics) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium(loc(context).vpnTunnelStatistics),
          const AppGap.small2(),
          _buildStatRow(loc(context).vpnUptime, '${statistics.uptime} seconds'),
          _buildStatRow(
              loc(context).vpnPacketsSent, statistics.packetsSent.toString()),
          _buildStatRow(loc(context).vpnPacketsReceived,
              statistics.packetsReceived.toString()),
          _buildStatRow(
              loc(context).vpnBytesSent, '${statistics.bytesSent} bytes'),
          _buildStatRow(loc(context).vpnBytesReceived,
              '${statistics.bytesReceived} bytes'),
          _buildStatRow(loc(context).vpnCurrentBandwidth,
              '${statistics.currentBandwidth} bps'),
          _buildStatRow(
              loc(context).vpnActiveSAs, statistics.activeSAs.toString()),
          _buildStatRow(
              loc(context).vpnRekeyCount, statistics.rekeyCount.toString()),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText.bodyMedium(label),
          AppText.bodyMedium(value),
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
  }) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium(title),
          const AppGap.small2(),
          ...children,
        ],
      ),
    );
  }
}
