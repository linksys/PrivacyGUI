import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_state.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/styled/styled_tab_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/providers/redirection/redirection_provider.dart';
import 'package:privacy_gui/util/error_code_helper.dart';
import 'package:privacy_gui/util/url_helper/url_helper.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacy_gui/validator_rules/_validator_rules.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/dropdown/dropdown_button.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/input_field/ip_form_field.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:privacygui_widgets/widgets/radios/radio_list.dart';
import 'package:privacy_gui/core/jnap/providers/assign_ip/base_assign_ip.dart'
    if (dart.library.html) 'package:privacy_gui/core/jnap/providers/assign_ip/web_assign_ip.dart';

enum InternetSettingsViewType {
  ipv4,
  ipv6,
}

enum PPTPIpAddressMode {
  dhcp,
  specify,
}

class InternetSettingsView extends ArgumentsConsumerStatefulView {
  const InternetSettingsView({super.key, super.args});

  @override
  ConsumerState<InternetSettingsView> createState() =>
      _InternetSettingsViewState();
}

class _InternetSettingsViewState extends ConsumerState<InternetSettingsView> {
  final TextEditingController _mtuSizeController = TextEditingController();
  final TextEditingController _macAddressCloneController =
      TextEditingController();
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
  final TextEditingController _staticDomainNameController =
      TextEditingController();
  final TextEditingController _tpUsernameController = TextEditingController();
  final TextEditingController _tpPasswordController = TextEditingController();
  final TextEditingController _tpServerIpController = TextEditingController();
  final TextEditingController _idleTimeController = TextEditingController();
  final TextEditingController _redialPeriodController = TextEditingController();
  final TextEditingController _ipv6PrefixController = TextEditingController();
  final TextEditingController _ipv6PrefixLengthController =
      TextEditingController();
  final TextEditingController _ipv6BorderRelayController =
      TextEditingController();
  final TextEditingController _ipv6BorderRelayPrefixLengthController =
      TextEditingController();

  late InternetSettingsState originState;
  late InternetSettingsNotifier _notifier;
  bool isIpv4Editing = false;
  bool isIpv6Editing = false;
  bool get isEditing => isIpv4Editing || isIpv6Editing;
  bool isMtuAuto = true;
  String? macAddressCloneErrorText;
  String? subnetMaskErrorText;
  String loadingTitle = '';
  static const inputPadding = EdgeInsets.symmetric(vertical: Spacing.small2);
  final InputValidator _macValidator = InputValidator([MACAddressRule()]);

  @override
  void initState() {
    super.initState();

    _notifier = ref.read(internetSettingsProvider.notifier);
    originState = ref.read(internetSettingsProvider).copyWith();
    initUI(originState);
    doSomethingWithSpinner(
      context,
      _notifier.fetch().then(
        (value) {
          setState(() {
            originState = ref.read(internetSettingsProvider).copyWith();
            initUI(originState);
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();

    _mtuSizeController.dispose();
    _macAddressCloneController.dispose();
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
    _staticDomainNameController.dispose();
    _tpUsernameController.dispose();
    _tpPasswordController.dispose();
    _tpServerIpController.dispose();
    _idleTimeController.dispose();
    _redialPeriodController.dispose();
    _ipv6PrefixController.dispose();
    _ipv6PrefixLengthController.dispose();
    _ipv6BorderRelayController.dispose();
    _ipv6BorderRelayPrefixLengthController.dispose();
  }

  void initUI(InternetSettingsState state) {
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
            : '';
        break;
      case WanType.pptp:
        _tpUsernameController.text = state.ipv4Setting.username ?? '';
        _tpPasswordController.text = state.ipv4Setting.password ?? '';
        _tpServerIpController.text = state.ipv4Setting.serverIp ?? '';
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
              : '';
          _staticGatewayController.text = state.ipv4Setting.staticGateway ?? '';
          _staticDns1Controller.text = state.ipv4Setting.staticDns1 ?? '';
          _staticDns2Controller.text = state.ipv4Setting.staticDns2 ?? '';
          _staticDns3Controller.text = state.ipv4Setting.staticDns3 ?? '';
          _staticDomainNameController.text = state.ipv4Setting.domainName ?? '';
        }
        break;
      case WanType.l2tp:
        _tpUsernameController.text = state.ipv4Setting.username ?? '';
        _tpPasswordController.text = state.ipv4Setting.password ?? '';
        _tpServerIpController.text = state.ipv4Setting.serverIp ?? '';
        break;
      case WanType.static:
        _staticIpAddressController.text =
            state.ipv4Setting.staticIpAddress ?? '';
        final networkPrefixLength = state.ipv4Setting.networkPrefixLength;
        _staticSubnetController.text = networkPrefixLength != null
            ? NetworkUtils.prefixLengthToSubnetMask(networkPrefixLength)
            : '';
        _staticGatewayController.text = state.ipv4Setting.staticGateway ?? '';
        _staticDns1Controller.text = state.ipv4Setting.staticDns1 ?? '';
        _staticDns2Controller.text = state.ipv4Setting.staticDns2 ?? '';
        _staticDns3Controller.text = state.ipv4Setting.staticDns3 ?? '';
        _staticDomainNameController.text = state.ipv4Setting.domainName ?? '';
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

    _mtuSizeController.text = '${state.ipv4Setting.mtu}';
    _macAddressCloneController.text =
        state.macCloneAddress != null ? '${state.macCloneAddress}' : '';
    _idleTimeController.text = state.ipv4Setting.maxIdleMinutes != null
        ? '${state.ipv4Setting.maxIdleMinutes}'
        : '15';
    _redialPeriodController.text =
        state.ipv4Setting.reconnectAfterSeconds != null
            ? '${state.ipv4Setting.reconnectAfterSeconds}'
            : '30';
    isMtuAuto = state.ipv4Setting.mtu == 0;
  }

  void resetUI() {
    _mtuSizeController.text = '0';
    _macAddressCloneController.text = '';
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
    _staticDomainNameController.text = '';
    _tpUsernameController.text = '';
    _tpPasswordController.text = '';
    _tpServerIpController.text = '';
    _idleTimeController.text = '';
    _redialPeriodController.text = '';
    _ipv6PrefixController.text = '';
    _ipv6PrefixLengthController.text = '';
    _ipv6BorderRelayController.text = '';
    _ipv6BorderRelayPrefixLengthController.text = '';
    isMtuAuto = true;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(redirectionProvider, (previous, next) {
      if (kIsWeb && previous != next && next != null) {
        logger.d('Redirect to $next');
        assignWebLocation(next);
      }
    });

    final state = ref.watch(internetSettingsProvider);
    final tabs = [
      loc(context).ipv4,
      loc(context).ipv6,
      loc(context).releaseAndRenew,
    ];
    final tabContents = [
      _connectionTypeView(InternetSettingsViewType.ipv4, state),
      _connectionTypeView(InternetSettingsViewType.ipv6, state),
      _releaseAndRenewView(),
    ];
    return StyledAppPageView(
      appBarStyle: AppBarStyle.none,
      bottomBar: isEditing
          ? PageBottomBar(
              isPositiveEnabled: _isEdited(state),
              onPositiveTap: _showRestartAlert,
            )
          : null,
      child: AppBasicLayout(
        content: StyledAppTabPageView(
          padding: EdgeInsets.zero,
          useMainPadding: false,
          title: loc(context).internetSettings.capitalizeWords(),
          onBackTap: _isEdited(state)
          ? () async {
              final goBack = await showUnsavedAlert(context);
              if (goBack == true) {
                _notifier.fetch();
                context.pop();
              }
            }
          : null,
          tabs: tabs
              .map((e) => Tab(
                    text: e,
                  ))
              .toList(),
          tabContentViews: tabContents,
          expandedHeight: 120,
        ),
      ),
    );
  }

  Widget _connectionTypeView(
    InternetSettingsViewType viewType,
    InternetSettingsState state,
  ) {
    return SingleChildScrollView(
      child: ResponsiveLayout(
        desktop: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: _infoCard(viewType, state),
            ),
            const AppGap.gutter(),
            Expanded(
              child: _optinalView(state),
            ),
          ],
        ),
        mobile: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _infoCard(viewType, state),
            AppGap.large4(),
            _optinalView(state),
          ],
        ),
      ),
    );
  }

  Widget _releaseAndRenewView() {
    final wanStatus =
        ref.watch(deviceManagerProvider.select((state) => state.wanStatus));
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.titleMedium(loc(context).internetIPAddress),
          const AppGap.medium(),
          SizedBox(
            width: 9.col,
            child: AppListCard(
              title: AppText.bodyMedium(loc(context).ipv4),
              description: AppText.labelLarge(
                  wanStatus?.wanConnection?.ipAddress ?? '-'),
              trailing: AppTextButton.noPadding(
                loc(context).releaseAndRenew,
                onTap: () {
                  _showRenewIPAlert(InternetSettingsViewType.ipv4);
                },
              ),
            ),
          ),
          const AppGap.small2(),
          SizedBox(
            width: 9.col,
            child: AppListCard(
              title: AppText.bodyMedium(loc(context).ipv6),
              description: AppText.labelLarge(
                  wanStatus?.wanIPv6Connection?.networkInfo?.ipAddress ?? '-'),
              trailing: AppTextButton.noPadding(
                loc(context).releaseAndRenew,
                onTap: () {
                  _showRenewIPAlert(InternetSettingsViewType.ipv6);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(
      InternetSettingsViewType viewType, InternetSettingsState state) {
    final infoCards = buildInfoCards(viewType, state);
    return AppCard(
      padding: const EdgeInsets.symmetric(
        vertical: Spacing.small3,
        horizontal: Spacing.large2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: Spacing.small3,
            ),
            child: Row(
              children: [
                AppText.titleMedium(
                    loc(context).internetConnectionType.capitalizeWords()),
                const Spacer(),
                _editButton(viewType, state),
              ],
            ),
          ),
          if (infoCards.isNotEmpty) ...infoCards,
        ],
      ),
    );
  }

  Widget _editButton(
      InternetSettingsViewType viewType, InternetSettingsState state) {
    return switch (viewType) {
      InternetSettingsViewType.ipv4 => AppIconButton.noPadding(
          icon: isIpv4Editing ? LinksysIcons.close : LinksysIcons.edit,
          color: isIpv4Editing ? null : Theme.of(context).colorScheme.primary,
          onTap: isIpv4Editing
              ? () {
                  setState(() {
                    isIpv4Editing = false;
                  });
                  if (!isEditing) {
                    _notifier.updateIpv4Settings(originState.ipv4Setting);
                    _notifier.updateMacAddressCloneEnable(originState.macClone);
                    _notifier
                        .updateMacAddressClone(originState.macCloneAddress);
                  } else {
                    _notifier.updateIpv4Settings(originState.ipv4Setting
                        .copyWith(mtu: state.ipv4Setting.mtu));
                  }
                  setState(() {
                    initUI(ref.read(internetSettingsProvider));
                  });
                }
              : () {
                  setState(() {
                    isIpv4Editing = true;
                  });
                },
        ),
      InternetSettingsViewType.ipv6 => AppIconButton.noPadding(
          icon: isIpv6Editing ? LinksysIcons.close : LinksysIcons.edit,
          color: isIpv6Editing ? null : Theme.of(context).colorScheme.primary,
          onTap: isIpv6Editing
              ? () {
                  setState(() {
                    isIpv6Editing = false;
                  });
                  _notifier.updateIpv6Settings(originState.ipv6Setting);
                  if (!isEditing) {
                    _notifier.updateIpv4Settings(state.ipv4Setting
                        .copyWith(mtu: originState.ipv4Setting.mtu));
                    _notifier.updateMacAddressCloneEnable(originState.macClone);
                    _notifier
                        .updateMacAddressClone(originState.macCloneAddress);
                  }
                  setState(() {
                    initUI(ref.read(internetSettingsProvider));
                  });
                }
              : () {
                  setState(() {
                    isIpv6Editing = true;
                  });
                },
        ),
      _ => Container(),
    };
  }

  Widget _internetSettingInfoCard({
    required String title,
    required String description,
  }) {
    return AppSettingCard.noBorder(
      title: title,
      description: description,
      padding: const EdgeInsets.symmetric(
        vertical: Spacing.small3,
      ),
    );
  }

  List<Widget> buildInfoCards(
      InternetSettingsViewType viewType, InternetSettingsState state) {
    return switch (viewType) {
      InternetSettingsViewType.ipv4 => isIpv4Editing
          ? _buildIpv4EditingCards(state.ipv4Setting)
          : _buildIpv4InfoCards(state.ipv4Setting),
      InternetSettingsViewType.ipv6 => isIpv6Editing
          ? _buildIpv6EditingCards(state)
          : _buildIpv6InfoCards(state.ipv6Setting),
      _ => [],
    };
  }

  List<Widget> _buildIpv4InfoCards(Ipv4Setting ipv4Setting) {
    final type = WanType.resolve(ipv4Setting.ipv4ConnectionType);
    final infoCards = switch (type) {
      WanType.dhcp => [],
      WanType.pppoe => _pppoeInfo(ipv4Setting),
      WanType.static => _staticIpInfo(ipv4Setting),
      WanType.pptp => _pptpInfo(ipv4Setting),
      WanType.l2tp => _l2tpInfo(ipv4Setting),
      WanType.bridge => _bridgeInfo(ipv4Setting),
      _ => [],
    };
    return [
      _internetSettingInfoCard(
        title: loc(context).connectionType,
        description: ipv4Setting.ipv4ConnectionType,
      ),
      ...infoCards,
    ];
  }

  List<Widget> _pppoeInfo(Ipv4Setting ipv4Setting) {
    return [
      _internetSettingInfoCard(
        title: loc(context).username,
        description: ipv4Setting.username ?? '-',
      ),
      _internetSettingInfoCard(
        title: loc(context).vlanIdOptional,
        description: (ipv4Setting.wanTaggingSettingsEnable ?? false)
            ? ipv4Setting.vlanId != null
                ? ipv4Setting.vlanId.toString()
                : '-'
            : '-',
      ),
      _internetSettingInfoCard(
        title: loc(context).serviceNameOptional,
        description: ipv4Setting.serviceName ?? '-',
      ),
    ];
  }

  List<Widget> _staticIpInfo(Ipv4Setting ipv4Setting) {
    return [
      _internetSettingInfoCard(
        title: loc(context).internetIpv4Address,
        description: ipv4Setting.staticIpAddress ?? '-',
      ),
      _internetSettingInfoCard(
        title: loc(context).subnetMask.capitalizeWords(),
        description: NetworkUtils.prefixLengthToSubnetMask(
            ipv4Setting.networkPrefixLength ?? 24),
      ),
      _internetSettingInfoCard(
        title: loc(context).defaultGateway,
        description: ipv4Setting.staticGateway ?? '-',
      ),
      _internetSettingInfoCard(
        title: loc(context).dns1,
        description: ipv4Setting.staticDns1 ?? '-',
      ),
      _internetSettingInfoCard(
        title: loc(context).dns2Optional,
        description: ipv4Setting.staticDns2 ?? '-',
      ),
      _internetSettingInfoCard(
        title: loc(context).dns3Optional,
        description: ipv4Setting.staticDns3 ?? '-',
      ),
    ];
  }

  List<Widget> _pptpInfo(Ipv4Setting ipv4Setting) {
    final useStaticSettings = ipv4Setting.useStaticSettings ?? false;
    return [
      _internetSettingInfoCard(
        title: loc(context).username,
        description: ipv4Setting.username ?? '-',
      ),
      _internetSettingInfoCard(
        title: loc(context).serverIpv4Address,
        description: ipv4Setting.serverIp ?? '-',
      ),
      if (useStaticSettings) ..._staticIpInfo(ipv4Setting),
    ];
  }

  List<Widget> _l2tpInfo(Ipv4Setting ipv4Setting) {
    return [
      _internetSettingInfoCard(
        title: loc(context).username,
        description: ipv4Setting.username ?? '-',
      ),
      _internetSettingInfoCard(
        title: loc(context).serverIpv4Address,
        description: ipv4Setting.serverIp ?? '-',
      ),
    ];
  }

  List<Widget> _bridgeInfo(Ipv4Setting ipv4Setting) {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppStyledText.bold(
              loc(context).toLogInLocallyWhileInBridgeMode,
              defaultTextStyle: Theme.of(context).textTheme.bodyLarge!,
              tags: const ['b'],
            ),
            const AppGap.small2(),
            AppTextButton.noPadding(
              ipv4Setting.redirection ?? '',
              icon: Icons.open_in_new,
              onTap: () {
                openUrl(ipv4Setting.redirection ?? '');
              },
            ),
            const AppGap.medium(),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildIpv6InfoCards(Ipv6Setting ipv6Setting) {
    final type = WanIPv6Type.resolve(ipv6Setting.ipv6ConnectionType);
    final infoCards = switch (type) {
      WanIPv6Type.automatic => _ipv6AutomaticInfo(ipv6Setting),
      WanIPv6Type.static => [],
      WanIPv6Type.bridge => [],
      WanIPv6Type.sixRdTunnel => [],
      WanIPv6Type.slaac => [],
      WanIPv6Type.dhcpv6 => [],
      WanIPv6Type.pppoe => [],
      WanIPv6Type.passThrough => [],
      _ => [],
    };
    return [
      _internetSettingInfoCard(
        title: loc(context).connectionType,
        description: ipv6Setting.ipv6ConnectionType,
      ),
      ...infoCards,
    ];
  }

  List<Widget> _ipv6AutomaticInfo(Ipv6Setting ipv6Setting) {
    final ipv6rdTunnelMode =
        ipv6Setting.ipv6rdTunnelMode ?? IPv6rdTunnelMode.disabled;
    return [
      _internetSettingInfoCard(
        title: loc(context).ipv6Automatic,
        description: ipv6Setting.isIPv6AutomaticEnabled
            ? loc(context).enabled
            : loc(context).disabled,
      ),
      _internetSettingInfoCard(
        title: loc(context).duid,
        description: ipv6Setting.duid,
      ),
      _divider(),
      _internetSettingInfoCard(
        title: loc(context).sixrdTunnel,
        description: getIpv6rdTunnelModeLoc(ipv6rdTunnelMode),
      ),
      _internetSettingInfoCard(
        title: loc(context).prefix,
        description: ipv6Setting.ipv6Prefix ?? '-',
      ),
      _internetSettingInfoCard(
        title: loc(context).prefixLength,
        description: ipv6Setting.ipv6PrefixLength != null
            ? '${ipv6Setting.ipv6PrefixLength}'
            : '-',
      ),
      _internetSettingInfoCard(
        title: loc(context).borderRelay,
        description: ipv6Setting.ipv6BorderRelay ?? '-',
      ),
      _internetSettingInfoCard(
        title: loc(context).borderRelayLength,
        description: ipv6Setting.ipv6BorderRelayPrefixLength != null
            ? '${ipv6Setting.ipv6BorderRelayPrefixLength}'
            : '-',
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

  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.symmetric(
        vertical: Spacing.small3,
      ),
      child: Divider(),
    );
  }

  Widget _optinalView(InternetSettingsState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText.titleMedium(loc(context).optional),
        const AppGap.medium(),
        _optinalCard(state.ipv4Setting),
        const AppGap.medium(),
        _macAddressCloneCard(state),
      ],
    );
  }

  Widget _optinalCard(Ipv4Setting ipv4Setting) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        vertical: Spacing.small1,
        horizontal: Spacing.large2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _domainName(ipv4Setting),
          _divider(),
          _mtu(ipv4Setting),
          _divider(),
          _mtuSize(ipv4Setting, isMtuAuto),
        ],
      ),
    );
  }

  Widget _domainName(Ipv4Setting ipv4Setting) {
    final type = WanType.resolve(ipv4Setting.ipv4ConnectionType);
    final isDomainNameEditable = switch (type) {
      WanType.static => true,
      WanType.pptp => true,
      // WanType.bridge => true,
      _ => false,
    };
    return isEditing && isDomainNameEditable
        ? Padding(
            padding: const EdgeInsets.symmetric(
              vertical: Spacing.small3,
            ),
            child: AppTextField(
              headerText: loc(context).domainName,
              hintText: '',
              semanticLabel: 'domain name',
              controller: _staticDomainNameController,
              border: const OutlineInputBorder(),
              onChanged: (value) {
                // if (!focused) {
                //   setState(() {
                //     state = state.copyWith(
                //       ipv4Setting: ipv4Setting.copyWith(
                //           domainName: () => _staticDomainNameController.text),
                //     );
                //   });
                // }
              },
            ),
          )
        : _internetSettingInfoCard(
            title: loc(context).domainName.capitalizeWords(),
            description: ipv4Setting.domainName ?? '-',
          );
  }

  Widget _mtu(Ipv4Setting ipv4Setting) {
    return isEditing
        ? Padding(
            padding: const EdgeInsets.symmetric(
              vertical: Spacing.small3,
            ),
            child: AppDropdownButton<String>(
              title: loc(context).mtu,
              selected: ipv4Setting.mtu == 0
                  ? loc(context).auto
                  : loc(context).manual,
              items: [loc(context).auto, loc(context).manual],
              label: (item) {
                if (item == loc(context).auto) {
                  return loc(context).auto;
                } else {
                  return loc(context).manual;
                }
              },
              onChanged: (value) {
                final maxMtu = _getMaxMtu(ipv4Setting.ipv4ConnectionType);
                setState(() {
                  isMtuAuto = value == loc(context).auto;
                  _mtuSizeController.text = isMtuAuto ? '0' : '$maxMtu';
                });
                _notifier.updateMtu(isMtuAuto ? 0 : maxMtu);
              },
            ),
          )
        : _internetSettingInfoCard(
            title: loc(context).mtu,
            description:
                ipv4Setting.mtu == 0 ? loc(context).auto : loc(context).manual,
          );
  }

  Widget _mtuSize(Ipv4Setting ipv4Setting, bool isMtuAuto) {
    return isEditing
        ? Padding(
            padding: const EdgeInsets.symmetric(
              vertical: Spacing.small3,
            ),
            child: AppTextField.minMaxNumber(
              controller: _mtuSizeController,
              enable: !isMtuAuto,
              border: const OutlineInputBorder(),
              headerText: loc(context).size,
              inputType: TextInputType.number,
              min: 576,
              max: _getMaxMtu(ipv4Setting.ipv4ConnectionType),
              onChanged: (value) {
                _notifier.updateMtu(value.isEmpty ? 0 : int.parse(value));
              },
              onFocusChanged: (hasFocus) {
                if (!hasFocus && !isMtuAuto) {
                  if (int.parse(_mtuSizeController.text) < 576) {
                    _mtuSizeController.text = '576';
                    _notifier.updateMtu(576);
                  }
                }
              },
            ),
          )
        : isMtuAuto
            ? AppListCard(
                showBorder: false,
                padding: const EdgeInsets.symmetric(
                  vertical: Spacing.small3,
                ),
                title: AppText.bodyMedium(
                  loc(context).size,
                  color: Theme.of(context).colorScheme.outline,
                ),
                description: AppText.labelLarge(
                  '0',
                  color: Theme.of(context).colorScheme.outline,
                ),
              )
            : _internetSettingInfoCard(
                title: loc(context).size,
                description: "${ipv4Setting.mtu}",
              );
  }

  Widget _macAddressCloneCard(InternetSettingsState state) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        vertical: Spacing.small1,
        horizontal: Spacing.large2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: Spacing.small3,
            ),
            child: Row(
              children: [
                AppText.titleMedium(
                    loc(context).macAddressClone.capitalizeWords()),
                const Spacer(),
                AppSwitch(
                  value: state.macClone,
                  onChanged: (value) {
                    _notifier.updateMacAddressCloneEnable(value);
                    _notifier.updateMacAddressClone(
                        value ? originState.macCloneAddress : null);
                    setState(() {
                      _macAddressCloneController.text =
                          value ? originState.macCloneAddress ?? '' : '';
                    });
                  },
                ),
              ],
            ),
          ),
          _divider(),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: Spacing.small3,
            ),
            child: AppTextField.macAddress(
              semanticLabel: 'mac address',
              controller: _macAddressCloneController,
              border: const OutlineInputBorder(),
              errorText:
                  isEditing && state.macClone ? macAddressCloneErrorText : null,
              enable: isEditing && state.macClone,
              onChanged: (value) {
                _notifier.updateMacAddressClone(value);
                setState(() {
                  final isValid = _macValidator.validate(value);
                  if (isValid) {
                    macAddressCloneErrorText = null;
                  } else {
                    macAddressCloneErrorText = loc(context).invalidMACAddress;
                  }
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: Spacing.small3,
            ),
            child: AppTextButton.noPadding(
              loc(context).cloneCurrentClientMac,
              icon: LinksysIcons.duplicateControl,
              onTap: isEditing && state.macClone
                  ? () {
                      _notifier.getMyMACAddress().then((value) {
                        _notifier.updateMacAddressClone(value);
                        setState(() {
                          _macAddressCloneController.text = value ?? '';
                          final isValid = _macValidator
                              .validate(_macAddressCloneController.text);
                          if (isValid) {
                            macAddressCloneErrorText = null;
                          } else {
                            macAddressCloneErrorText =
                                loc(context).invalidMACAddress;
                          }
                        });
                      });
                    }
                  : null,
            ),
          ),
          const AppGap.small2(),
        ],
      ),
    );
  }

  List<Widget> _buildIpv4EditingCards(Ipv4Setting ipv4Setting) {
    final type = WanType.resolve(ipv4Setting.ipv4ConnectionType);
    final infoCards = switch (type) {
      WanType.dhcp => [],
      WanType.pppoe => _pppoeEditing(ipv4Setting),
      WanType.static => _staticIpEditing(ipv4Setting),
      WanType.pptp => _tpEditing(ipv4Setting, type),
      WanType.l2tp => _tpEditing(ipv4Setting, type),
      WanType.bridge => _bridgeEditing(),
      _ => [],
    };
    return [
      Padding(
        padding: const EdgeInsets.symmetric(
          vertical: Spacing.small3,
        ),
        child: AppDropdownButton<String>(
          selected: ipv4Setting.ipv4ConnectionType,
          items: ipv4Setting.supportedIPv4ConnectionType,
          label: (item) {
            return _getWanConnectedTypeText(item);
          },
          onChanged: (value) {
            _notifier.updateIpv4Settings(
                value == originState.ipv4Setting.ipv4ConnectionType
                    ? originState.ipv4Setting.copyWith(mtu: ipv4Setting.mtu)
                    : Ipv4Setting(
                        ipv4ConnectionType: value,
                        supportedIPv4ConnectionType:
                            ipv4Setting.supportedIPv4ConnectionType,
                        supportedWANCombinations:
                            ipv4Setting.supportedWANCombinations,
                        mtu: ipv4Setting.mtu,
                      ));
            setState(() {
              initUI(ref.read(internetSettingsProvider));
            });
          },
        ),
      ),
      ...infoCards,
    ];
  }

  List<Widget> _pppoeEditing(Ipv4Setting ipv4Setting) {
    return [
      _divider(),
      const AppGap.small1(),
      Padding(
        padding: inputPadding,
        child: AppTextField(
          key: const Key('pppoeUsername'),
          headerText: loc(context).username,
          controller: _pppoeUsernameController,
          border: const OutlineInputBorder(),
          onChanged: (value) {
            _notifier.updateIpv4Settings(ipv4Setting.copyWith(
              username: () => value,
            ));
          },
        ),
      ),
      Padding(
        padding: inputPadding,
        child: AppPasswordField(
          key: const Key('pppoePassword'),
          headerText: loc(context).password,
          controller: _pppoePasswordController,
          border: const OutlineInputBorder(),
          onChanged: (value) {
            _notifier.updateIpv4Settings(ipv4Setting.copyWith(
              password: () => value,
            ));
          },
        ),
      ),
      Padding(
        padding: inputPadding,
        child: AppTextField.minMaxNumber(
          min: 5,
          max: 4094,
          acceptEmpty: true,
          headerText: loc(context).vlanIdOptional,
          controller: _pppoeVLANIDController,
          border: const OutlineInputBorder(),
          onChanged: (value) {
            _notifier.updateIpv4Settings(ipv4Setting.copyWith(
              vlanId: () => value.isEmpty ? 0 : int.parse(value),
            ));
          },
          onFocusChanged: (hasFocus) {
            if (!hasFocus) {
              final value = _pppoeVLANIDController.text;
              if (value.isNotEmpty && int.parse(value) < 5) {
                _pppoeVLANIDController.text = '5';
                _notifier.updateIpv4Settings(ipv4Setting.copyWith(
                  vlanId: () => 5,
                ));
              }
            }
          },
        ),
      ),
      Padding(
        padding: inputPadding,
        child: AppTextField(
          headerText: loc(context).serviceNameOptional,
          controller: _pppoeServiceNameController,
          border: const OutlineInputBorder(),
          onChanged: (value) {
            _notifier.updateIpv4Settings(ipv4Setting.copyWith(
              serviceName: () => value,
            ));
          },
        ),
      ),
      const AppGap.small1(),
      _divider(),
      _connectionMode(ipv4Setting),
    ];
  }

  List<Widget> _staticIpEditing(Ipv4Setting ipv4Setting) {
    return [
      _divider(),
      const AppGap.small1(),
      Padding(
        padding: inputPadding,
        child: AppIPFormField(
          semanticLabel: 'ip address',
          header: AppText.bodySmall(
            loc(context).internetIpv4Address,
          ),
          controller: _staticIpAddressController,
          border: const OutlineInputBorder(),
          onChanged: (value) {
            _notifier.updateIpv4Settings(ipv4Setting.copyWith(
              staticIpAddress: () => value,
            ));
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
          errorText: subnetMaskErrorText,
          border: const OutlineInputBorder(),
          onChanged: (value) {
            final subnetMaskValidator = SubnetMaskValidator();
            final isValidSubnetMask = subnetMaskValidator.validate(value);
            if (isValidSubnetMask) {
              _notifier.updateIpv4Settings(ipv4Setting.copyWith(
                networkPrefixLength: () =>
                    NetworkUtils.subnetMaskToPrefixLength(value),
              ));
              setState(() {
                subnetMaskErrorText = null;
              });
            } else {
              setState(() {
                subnetMaskErrorText = loc(context).invalidSubnetMask;
              });
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
          onChanged: (value) {
            _notifier.updateIpv4Settings(ipv4Setting.copyWith(
              staticGateway: () => value,
            ));
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
          onChanged: (value) {
            _notifier.updateIpv4Settings(ipv4Setting.copyWith(
              staticDns1: () => value,
            ));
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
          onChanged: (value) {
            _notifier.updateIpv4Settings(ipv4Setting.copyWith(
              staticDns2: () => value.isEmpty ? null : value,
            ));
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
          onChanged: (value) {
            _notifier.updateIpv4Settings(ipv4Setting.copyWith(
              staticDns3: () => value.isEmpty ? null : value,
            ));
          },
        ),
      ),
      const AppGap.small1(),
    ];
  }

  List<Widget> _tpEditing(Ipv4Setting ipv4Setting, WanType? type) {
    return [
      _divider(),
      const AppGap.small3(),
      if (type == WanType.pptp) ...[
        _pptpIpAddressMode(ipv4Setting.useStaticSettings ?? false, ipv4Setting),
        if (ipv4Setting.useStaticSettings == true)
          ..._staticIpEditing(ipv4Setting),
        _divider(),
      ],
      Padding(
        padding: const EdgeInsets.symmetric(
          vertical: Spacing.small3,
        ),
        child: AppIPFormField(
          header: AppText.bodySmall(
            loc(context).serverIpv4Address,
          ),
          controller: _tpServerIpController,
          border: const OutlineInputBorder(),
          onChanged: (value) {
            _notifier.updateIpv4Settings(ipv4Setting.copyWith(
              serverIp: () => value,
            ));
          },
        ),
      ),
      const AppGap.small1(),
      Padding(
        padding: inputPadding,
        child: AppTextField(
          headerText: loc(context).username,
          controller: _tpUsernameController,
          border: const OutlineInputBorder(),
          onChanged: (value) {
            _notifier.updateIpv4Settings(ipv4Setting.copyWith(
              username: () => value,
            ));
          },
        ),
      ),
      Padding(
        padding: inputPadding,
        child: AppPasswordField(
          headerText: loc(context).password,
          controller: _tpPasswordController,
          border: const OutlineInputBorder(),
          onChanged: (value) {
            _notifier.updateIpv4Settings(ipv4Setting.copyWith(
              password: () => value,
            ));
          },
        ),
      ),
      const AppGap.small1(),
      _divider(),
      _connectionMode(ipv4Setting),
    ];
  }

  List<Widget> _bridgeEditing() {
    return [
      _divider(),
      const AppGap.small3(),
      AppStyledText.bold(
        '${loc(context).toLogInLocallyWhileInBridgeMode}http://${_notifier.hostname}.local',
        defaultTextStyle: Theme.of(context).textTheme.bodyMedium!,
        tags: const ['b'],
      ),
      const AppGap.small3(),
    ];
  }

  Widget _connectionMode(Ipv4Setting ipv4Setting) {
    final behavior = ipv4Setting.behavior ?? PPPConnectionBehavior.keepAlive;
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: Spacing.small3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.titleSmall(loc(context).connectionMode),
          const AppGap.medium(),
          AppRadioList(
            mainAxisSize: MainAxisSize.min,
            selected: behavior,
            items: [
              AppRadioListItem(
                titleWidget: AppText.bodyLarge(loc(context).connectOnDemand),
                value: PPPConnectionBehavior.connectOnDemand,
                expandedWidget: Row(
                  children: [
                    const SizedBox(width: 40),
                    Expanded(
                      child: AppTextField.minMaxNumber(
                        headerText:
                            '${loc(context).maxIdleTime} (${loc(context).minutes})',
                        semanticLabel: 'max idle time',
                        max: 9999,
                        min: 1,
                        controller: _idleTimeController,
                        border: const OutlineInputBorder(),
                        onChanged: (value) {
                          _notifier.updateIpv4Settings(ipv4Setting.copyWith(
                            behavior: () =>
                                PPPConnectionBehavior.connectOnDemand,
                            maxIdleMinutes: () =>
                                int.parse(_idleTimeController.text),
                          ));
                        },
                      ),
                    ),
                  ],
                ),
              ),
              AppRadioListItem(
                titleWidget: AppText.bodyLarge(loc(context).keepAlive),
                value: PPPConnectionBehavior.keepAlive,
                expandedWidget: Row(
                  children: [
                    const SizedBox(width: 40),
                    Expanded(
                      child: AppTextField.minMaxNumber(
                        headerText:
                            '${loc(context).redialPeriod} (${loc(context).seconds})',
                        semanticLabel: 'redial period',
                        max: 180,
                        min: 20,
                        controller: _redialPeriodController,
                        border: const OutlineInputBorder(),
                        onChanged: (value) {
                          _notifier.updateIpv4Settings(ipv4Setting.copyWith(
                            behavior: () => PPPConnectionBehavior.keepAlive,
                            reconnectAfterSeconds: () =>
                                int.parse(_redialPeriodController.text),
                          ));
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
            onChanged: (index, type) {
              if (type == PPPConnectionBehavior.connectOnDemand) {
                _notifier.updateIpv4Settings(ipv4Setting.copyWith(
                  behavior: () => PPPConnectionBehavior.connectOnDemand,
                  maxIdleMinutes: () => int.parse(_idleTimeController.text),
                ));
              } else {
                _notifier.updateIpv4Settings(ipv4Setting.copyWith(
                  behavior: () => PPPConnectionBehavior.keepAlive,
                  reconnectAfterSeconds: () =>
                      int.parse(_redialPeriodController.text),
                ));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _pptpIpAddressMode(bool useStaticSettings, Ipv4Setting ipv4Setting) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: Spacing.small3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.titleSmall(loc(context).ipAddress.capitalizeWords()),
          const AppGap.medium(),
          AppRadioList(
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
              _notifier.updateIpv4Settings(ipv4Setting.copyWith(
                useStaticSettings: () => type == PPTPIpAddressMode.specify,
              ));
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildIpv6EditingCards(InternetSettingsState state) {
    final type = WanIPv6Type.resolve(state.ipv6Setting.ipv6ConnectionType);
    final infoCards = switch (type) {
      WanIPv6Type.automatic => _ipv6AutomaticEditing(state.ipv6Setting),
      WanIPv6Type.static => [],
      WanIPv6Type.bridge => [],
      WanIPv6Type.sixRdTunnel => [],
      WanIPv6Type.slaac => [],
      WanIPv6Type.dhcpv6 => [],
      WanIPv6Type.pppoe => [],
      WanIPv6Type.passThrough => [],
      _ => [],
    };
    // final allowedTypeList = state.ipv6Setting.supportedIPv6ConnectionType
    //     .where((ipv6) => state.ipv4Setting.supportedWANCombinations.any(
    //         (combine) =>
    //             combine.wanType == state.ipv4Setting.ipv4ConnectionType &&
    //             combine.wanIPv6Type == ipv6))
    //     .toList();
    final allowedTypeList = state.ipv6Setting.supportedIPv6ConnectionType;
    return [
      Padding(
        padding: const EdgeInsets.symmetric(
          vertical: Spacing.small3,
        ),
        child: AppDropdownButton<String>(
          selected: state.ipv6Setting.ipv6ConnectionType,
          items: allowedTypeList,
          label: (item) {
            return _getWanConnectedTypeText(item);
          },
          onChanged: (value) {
            _notifier.updateIpv6Settings(
                value == originState.ipv6Setting.ipv6ConnectionType
                    ? originState.ipv6Setting
                    : Ipv6Setting(
                        ipv6ConnectionType: value,
                        supportedIPv6ConnectionType:
                            state.ipv6Setting.supportedIPv6ConnectionType,
                        duid: state.ipv6Setting.duid,
                        isIPv6AutomaticEnabled:
                            state.ipv6Setting.isIPv6AutomaticEnabled,
                      ));
            setState(() {
              initUI(ref.read(internetSettingsProvider));
            });
          },
        ),
      ),
      ...infoCards,
    ];
  }

  List<Widget> _ipv6AutomaticEditing(Ipv6Setting ipv6Setting) {
    return [
      const AppGap.small3(),
      AppCard(
        padding: const EdgeInsets.symmetric(vertical: Spacing.medium),
        showBorder: false,
        child: Row(
          children: [
            AppCheckbox(
              semanticLabel: 'ipv6 automatic',
              value: ipv6Setting.isIPv6AutomaticEnabled,
              onChanged: (value) {
                if (value == true) {
                  _notifier.updateIpv6Settings(Ipv6Setting(
                    ipv6ConnectionType: ipv6Setting.ipv6ConnectionType,
                    supportedIPv6ConnectionType:
                        ipv6Setting.supportedIPv6ConnectionType,
                    duid: ipv6Setting.duid,
                    isIPv6AutomaticEnabled: true,
                  ));
                } else {
                  _notifier.updateIpv6Settings(
                      ipv6Setting.copyWith(isIPv6AutomaticEnabled: value));
                }
                setState(() {
                  initUI(ref.read(internetSettingsProvider));
                });
              },
            ),
            const AppGap.medium(),
            AppText.bodyLarge(loc(context).ipv6Automatic),
          ],
        ),
      ),
      AppSettingCard.noBorder(
        title: loc(context).duid,
        description: ipv6Setting.duid,
        padding: const EdgeInsets.symmetric(vertical: Spacing.small2),
      ),
      const AppGap.small1(),
      _divider(),
      _sixrdTunnel(ipv6Setting),
    ];
  }

  Widget _sixrdTunnel(Ipv6Setting ipv6Setting) {
    return Padding(
      padding:
          const EdgeInsets.only(top: Spacing.small1, bottom: Spacing.small3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: inputPadding,
            child: AppDropdownButton<IPv6rdTunnelMode>(
              title: loc(context).sixrdTunnel,
              selected: ipv6Setting.ipv6rdTunnelMode ?? IPv6rdTunnelMode.disabled,
              items: const [
                IPv6rdTunnelMode.disabled,
                IPv6rdTunnelMode.automatic,
                IPv6rdTunnelMode.manual,
              ],
              label: (item) {
                return item.value;
              },
              onChanged: ipv6Setting.isIPv6AutomaticEnabled
                  ? null
                  : (value) {
                      _notifier.updateIpv6Settings(
                          ipv6Setting.copyWith(ipv6rdTunnelMode: () => value));
                    },
            ),
          ),
          _manualSixrdTunnel(ipv6Setting),
        ],
      ),
    );
  }

  Widget _manualSixrdTunnel(Ipv6Setting ipv6Setting) {
    final isEnable = !ipv6Setting.isIPv6AutomaticEnabled &&
        ipv6Setting.ipv6rdTunnelMode == IPv6rdTunnelMode.manual;
    return Column(
      children: [
        Padding(
          padding: inputPadding,
          child: AppTextField(
            headerText: loc(context).prefix,
            hintText: '',
            controller: _ipv6PrefixController,
            enable: isEnable,
            border: const OutlineInputBorder(),
            onChanged: (value) {
              _notifier.updateIpv6Settings(
                  ipv6Setting.copyWith(ipv6Prefix: () => value));
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
            enable: isEnable,
            border: const OutlineInputBorder(),
            onChanged: (value) {
              _notifier.updateIpv6Settings(ipv6Setting.copyWith(
                  ipv6PrefixLength: () => int.parse(value)));
            },
          ),
        ),
        Padding(
          padding: inputPadding,
          child: AppIPFormField(
            semanticLabel: 'border relay',
            header: AppText.bodySmall(
              loc(context).borderRelay,
              color: isEnable ? null : Theme.of(context).colorScheme.outline,
            ),
            controller: _ipv6BorderRelayController,
            enable: isEnable,
            border: const OutlineInputBorder(),
            onChanged: (value) {
              _notifier.updateIpv6Settings(
                  ipv6Setting.copyWith(ipv6BorderRelay: () => value));
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
            enable: isEnable,
            border: const OutlineInputBorder(),
            onChanged: (value) {
              _notifier.updateIpv6Settings(ipv6Setting.copyWith(
                  ipv6BorderRelayPrefixLength: () => int.parse(value)));
            },
          ),
        ),
      ],
    );
  }

  int _getMaxMtu(String wanType) {
    return switch (WanType.resolve(wanType)) {
      WanType.dhcp => 1500,
      WanType.pppoe => 1492,
      WanType.static => 1500,
      WanType.pptp => 1460,
      WanType.l2tp => 1460,
      _ => 0,
    };
  }

  String _getWanConnectedTypeText(String type) {
    return switch (type) {
      'DHCP' => loc(context).connectionTypeDhcp,
      'Static' => loc(context).connectionTypeStatic,
      'PPPoE' => loc(context).connectionTypePppoe,
      'PPTP' => loc(context).connectionTypePptp,
      'L2TP' => loc(context).connectionTypeL2tp,
      'Bridge' => loc(context).connectionTypeBridge,
      'Automatic' => loc(context).connectionTypeAutomatic,
      'Pass-through' => loc(context).connectionTypePassThrough,
      _ => ''
    };
  }

  bool _isEdited(InternetSettingsState state) {
    if (state != originState) return true;
    return false;
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
      },
    );
  }

  _onRestartButtonTap() {
    // Show error if WAN combinations are invalid
    final state = ref.read(internetSettingsProvider);
    final isValidCombination = state.ipv4Setting.supportedWANCombinations.any(
        (combine) =>
            combine.wanType == state.ipv4Setting.ipv4ConnectionType &&
            combine.wanIPv6Type == state.ipv6Setting.ipv6ConnectionType);
    if (!isValidCombination) {
      return showSimpleAppOkDialog(
        context,
        title: loc(context).error,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText.bodyMedium('${loc(context).selectedCombinationNotValid}:'),
            const AppGap.medium(),
            Table(
              border: const TableBorder(),
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(1),
              },
              children: [
                const TableRow(children: [
                  AppText.labelLarge('IPv4'),
                  AppText.labelLarge('IPv6'),
                ]),
                ...state.ipv4Setting.supportedWANCombinations.map((combine) {
                  return TableRow(children: [
                    AppText.bodyMedium(combine.wanType),
                    AppText.bodyMedium(combine.wanIPv6Type),
                  ]);
                }).toList(),
              ],
            ),
          ],
        ),
      );
    }
    // Save changes
    _saveChange();
  }

  void _saveChange() {
    setState(() {
      loadingTitle = loc(context).restarting;
    });
    final state = ref.read(internetSettingsProvider);
    doSomethingWithSpinner(
      context,
      _notifier.saveInternetSettings(state).then((value) {
        setState(() {
          isIpv4Editing = false;
          isIpv6Editing = false;
          originState = ref.read(internetSettingsProvider).copyWith();
          initUI(originState);
        });
        showSuccessSnackBar(
          context,
          loc(context).changesSaved,
        );
      }).catchError((error) {
        showRouterNotFoundAlert(context, ref, onComplete: () async {
          await _notifier.fetch(fetchRemote: true);
          showSuccessSnackBar(
            context,
            loc(context).changesSaved,
          );
        });
      }, test: (error) => error is JNAPSideEffectError).onError(
          (error, stackTrace) {
        final errorMsg = switch (error.runtimeType) {
          JNAPError => errorCodeHelper(context, (error as JNAPError).result),
          TimeoutException => loc(context).generalError,
          _ => loc(context).unknownError,
        };
        showFailedSnackBar(
          context,
          errorMsg ??
              loc(context).unknownErrorCode((error as JNAPError).result),
        );
      }).whenComplete(
        () {
          setState(() {
            loadingTitle = '';
          });
        },
      ),
    );
  }

  _showRenewIPAlert(InternetSettingsViewType type) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: AppText.titleLarge(loc(context).releaseAndRenewIpAddress),
          content: AppText.bodyMedium(
              loc(context).releaseAndRenewIpAddressDescription),
          actions: [
            AppTextButton(
              loc(context).cancel,
              color: Theme.of(context).colorScheme.onSurface,
              onTap: () {
                context.pop();
              },
            ),
            AppTextButton(
              loc(context).releaseAndRenew,
              onTap: () {
                context.pop();
                if (type == InternetSettingsViewType.ipv4) {
                  _releaseAndRenewIpv4();
                } else {
                  _releaseAndRenewIpv6();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _releaseAndRenewIpv4() {
    doSomethingWithSpinner(
      context,
      _notifier.renewDHCPWANLease().then(
        (value) {
          showSuccessSnackBar(
            context,
            loc(context).successExclamation,
          );
        },
      ).catchError((error) {
        showRouterNotFoundAlert(context, ref, onComplete: () async {
          await ref.read(pollingProvider.notifier).forcePolling();
          showSuccessSnackBar(
            context,
            loc(context).successExclamation,
          );
        });
      }, test: (error) => error is JNAPSideEffectError).onError(
          (error, stackTrace) {
        final errorMsg = switch (error.runtimeType) {
          JNAPError => (error as JNAPError).result == 'ErrorInvalidWANType'
              ? loc(context).currentWanTypeIsNotDhcp
              : errorCodeHelper(context, (error as JNAPError).result),
          TimeoutException => loc(context).generalError,
          _ => loc(context).unknownError,
        };
        showFailedSnackBar(
          context,
          errorMsg ??
              loc(context).unknownErrorCode((error as JNAPError).result),
        );
      }),
    );
  }

  void _releaseAndRenewIpv6() {
    doSomethingWithSpinner(
      context,
      _notifier.renewDHCPIPv6WANLease().then(
        (value) {
          showSuccessSnackBar(
            context,
            loc(context).successExclamation,
          );
        },
      ).catchError((error) {
        showRouterNotFoundAlert(context, ref, onComplete: () async {
          await ref.read(pollingProvider.notifier).forcePolling();
          showSuccessSnackBar(
            context,
            loc(context).successExclamation,
          );
        });
      }, test: (error) => error is JNAPSideEffectError).onError(
          (error, stackTrace) {
        final errorMsg = switch (error.runtimeType) {
          JNAPError => (error as JNAPError).result == 'ErrorInvalidIPv6WANType'
              ? loc(context).currentIPv6ConnectionTypeIsNotAutomatic
              : errorCodeHelper(context, (error as JNAPError).result),
          TimeoutException => loc(context).generalError,
          _ => loc(context).unknownError,
        };
        showFailedSnackBar(
          context,
          errorMsg ??
              loc(context).unknownErrorCode((error as JNAPError).result),
        );
      }),
    );
  }
}
