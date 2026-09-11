import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_state.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/views/auto_ipoe_section.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_issue.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_models.dart';
import 'package:privacy_gui/page/auto_ipoe/providers/auto_ipoe_notifier.dart';
import 'package:privacy_gui/page/auto_ipoe/providers/auto_ipoe_state.dart';
import 'package:privacy_gui/page/auto_ipoe/service/auto_ipoe_internet_settings_bridge.dart';
import 'package:privacy_gui/page/auto_ipoe/service/auto_ipoe_service.dart';
import 'package:privacy_gui/page/auto_ipoe/views/auto_ipoe_optional_pane.dart';
import 'package:privacy_gui/page/auto_ipoe/views/auto_ipoe_recovery_ui.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/providers/redirection/redirection_provider.dart';
import 'package:privacy_gui/util/error_code_helper.dart';
import 'package:privacy_gui/util/url_helper/url_helper.dart'
    if (dart.library.io) 'package:privacy_gui/util/url_helper/url_helper_mobile.dart'
    if (dart.library.html) 'package:privacy_gui/util/url_helper/url_helper_web.dart';
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

enum InternetSettingsViewType { ipv4, ipv6 }

enum PPTPIpAddressMode { dhcp, specify }

class InternetSettingsView extends ArgumentsConsumerStatefulView {
  const InternetSettingsView({super.key, super.args});

  @override
  ConsumerState<InternetSettingsView> createState() =>
      _InternetSettingsViewState();
}

class _InternetSettingsViewState extends ConsumerState<InternetSettingsView>
    with SingleTickerProviderStateMixin {
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

  late InternetSettingsState originalState;
  late AutoIPoEState originalAutoIPoEState;
  late InternetSettingsNotifier _notifier;
  late AutoIPoENotifier _autoIPoENotifier;
  bool isIpv4Editing = false;
  bool isIpv6Editing = false;
  bool get isEditing => isIpv4Editing || isIpv6Editing;
  bool isMtuAuto = true;
  bool isBridgeMode = false;
  String? macAddressCloneErrorText;
  String? ipv6PrefixErrorText;
  String? subnetMaskErrorText;
  String? borderRelayErrorText;
  String loadingTitle = '';
  static const inputPadding = EdgeInsets.symmetric(vertical: Spacing.small2);
  final InputValidator _macValidator = InputValidator([MACAddressRule()]);
  final InputValidator _ipv6PrefixValidator = InputValidator([
    IPv6WithReservedRule(),
  ]);
  final InputValidator _borderRelayValidator = InputValidator([
    IpAddressNoReservedRule(),
  ]);
  late final TabController _tabController;
  bool _awaitingAutoIPoECompletion = false;
  bool _isCheckingAutoIPoE = false;
  bool _isFinalizingAutoIPoE = false;
  bool _autoIPoETerminalDialogVisible = false;
  int _advancedRecoveryGeneration = 0;
  AutoIPoEIssue? _autoIPoEIssue;
  final ValueNotifier<AutoIPoEReconciliationProgress>
      _advancedAutoIPoEProgress = ValueNotifier(
    const AutoIPoEReconciliationProgress.initial(),
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _notifier = ref.read(internetSettingsProvider.notifier);
    _autoIPoENotifier = ref.read(autoIPoEProvider.notifier);
    originalState = ref.read(internetSettingsProvider).copyWith();
    originalAutoIPoEState = ref.read(autoIPoEProvider).copyWith();
    initUI(originalState);
    doSomethingWithSpinner(
      context,
      Future.wait([
        _notifier.fetch(fetchRemote: true),
        _autoIPoENotifier.fetchAll(),
      ]).then((value) {
        final internetState = value[0] as InternetSettingsState;
        final autoState = value[1] as AutoIPoEState;
          setState(() {
          originalState = internetState;
          originalAutoIPoEState = autoState;
            initUI(originalState);
          });
      }),
    );
  }

  @override
  void dispose() {
    _advancedAutoIPoEProgress.dispose();
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
    _tabController.dispose();
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

  WanType? _effectiveIpv4WanType(InternetSettingsState state) =>
      WanType.resolve(state.ipv4Setting.ipv4ConnectionType);

  List<String> _effectiveSupportedIpv4ConnectionTypes(
    InternetSettingsState state,
  ) {
    final normalizedTypes = <String>[];
    final seen = <String>{};

    for (final type in state.ipv4Setting.supportedIPv4ConnectionType) {
      final canonicalType = WanType.canonical(type) ?? type.trim();
      if (canonicalType.isEmpty) {
        continue;
      }
      if (seen.add(canonicalType.toLowerCase())) {
        normalizedTypes.add(canonicalType);
      }
    }

    return normalizedTypes;
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
    final autoIPoEState = ref.watch(autoIPoEProvider);
    isBridgeMode = _effectiveIpv4WanType(state) == WanType.bridge;
    final List<String> tabs = [
      loc(context).ipv4,
      loc(context).ipv6,
      loc(context).releaseAndRenew,
    ];
    final tabContents = [
      _connectionTypeView(InternetSettingsViewType.ipv4, state, autoIPoEState),
      _connectionTypeView(InternetSettingsViewType.ipv6, state, autoIPoEState),
      _releaseAndRenewView(state, autoIPoEState),
    ];
    return AppBasicLayout(
      content: StyledAppPageView(
        padding: EdgeInsets.zero,
        useMainPadding: false,
        title: loc(context).internetSettings.capitalizeWords(),
        bottomBar: isEditing
            ? PageBottomBar(
                isPositiveEnabled: !_awaitingAutoIPoECompletion &&
                    !_isCheckingAutoIPoE &&
                    _isEdited(state, autoIPoEState) &&
                    (state.ipv6Setting.ipv6rdTunnelMode !=
                            IPv6rdTunnelMode.manual ||
                        ipv6PrefixErrorText == null &&
                            borderRelayErrorText == null),
                onPositiveTap: _onSaveButtonTap,
              )
            : null,
        onBackTap: _isEdited(state, autoIPoEState)
            ? () async {
                final goBack = await showUnsavedAlert(context);
                if (goBack == true) {
                  _notifier.fetch();
                  _autoIPoENotifier.fetchAll();
                  context.pop();
                }
              }
            : null,
        tabs: tabs.map((e) => Tab(text: e)).toList(),
        tabContentViews: tabContents,
        tabController: _tabController,
      ),
    );
  }

  Widget _connectionTypeView(
    InternetSettingsViewType viewType,
    InternetSettingsState state,
    AutoIPoEState autoIPoEState,
  ) {
    return StyledAppPageView.innerPage(
      child: (context, constraints) => ResponsiveLayout(
        desktop: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(child: _infoCard(viewType, state, autoIPoEState)),
            const AppGap.gutter(),
            Expanded(child: _optinalView(state, autoIPoEState)),
          ],
        ),
        mobile: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _infoCard(viewType, state, autoIPoEState),
            AppGap.large4(),
            _optinalView(state, autoIPoEState),
          ],
        ),
      ),
    );
  }

  Widget _releaseAndRenewView(
    InternetSettingsState state,
    AutoIPoEState autoIPoEState,
  ) {
    final wanStatus = ref.watch(
      deviceManagerProvider.select((state) => state.wanStatus),
    );
    final wanIpv6Type = WanIPv6Type.resolve(
      state.ipv6Setting.ipv6ConnectionType,
    );
    return StyledAppPageView.innerPage(
      child: (context, constraints) => Column(
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
                wanStatus?.wanConnection?.ipAddress ?? '-',
              ),
              trailing: AppTextButton.noPadding(
                loc(context).releaseAndRenew,
                onTap:
                    isBridgeMode || _effectiveIpv4WanType(state) == WanType.ipoe
                    ? null
                    : () {
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
                wanStatus?.wanIPv6Connection?.networkInfo?.ipAddress ?? '-',
              ),
              trailing: AppTextButton.noPadding(
                loc(context).releaseAndRenew,
                onTap: isBridgeMode ||
                        _isIPv6LockedByAutoIPoE(state, autoIPoEState) ||
                        wanIpv6Type == WanIPv6Type.passThrough
                    ? null
                    : () {
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
    InternetSettingsViewType viewType,
    InternetSettingsState state,
    AutoIPoEState autoIPoEState,
  ) {
    final infoCards = buildInfoCards(viewType, state, autoIPoEState);
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
            padding: const EdgeInsets.symmetric(vertical: Spacing.small3),
            child: Row(
              children: [
                AppText.titleMedium(
                  loc(context).internetConnectionType.capitalizeWords(),
                ),
                const Spacer(),
                _editButton(viewType, state, autoIPoEState),
              ],
            ),
          ),
          if (infoCards.isNotEmpty) ...infoCards,
        ],
      ),
    );
  }

  Widget _editButton(
    InternetSettingsViewType viewType,
    InternetSettingsState state,
    AutoIPoEState autoIPoEState,
  ) {
    final isRemote = BuildConfig.isRemote();
    final isIpv6Locked = _isIPv6LockedByAutoIPoE(state, autoIPoEState);
    return Tooltip(
        message: isRemote ? loc(context).featureUnavailableInRemoteMode : '',
        child: switch (viewType) {
          InternetSettingsViewType.ipv4 => AppIconButton.noPadding(
              icon: isIpv4Editing ? LinksysIcons.close : LinksysIcons.edit,
            color: isIpv4Editing ? null : Theme.of(context).colorScheme.primary,
              onTap: isRemote
                  ? null
                  : isIpv4Editing
                      ? () {
                          setState(() {
                            isIpv4Editing = false;
                          });
                          if (!isEditing) {
                            _notifier
                                .updateIpv4Settings(originalState.ipv4Setting);
                          _autoIPoENotifier
                              .updateSettings(originalAutoIPoEState.settings);
                            _notifier.updateMacAddressCloneEnable(
                            originalState.macClone,
                          );
                            _notifier.updateMacAddressClone(
                            originalState.macCloneAddress,
                          );
                          } else {
                          _notifier.updateIpv4Settings(
                            originalState.ipv4Setting.copyWith(
                              mtu: state.ipv4Setting.mtu,
                            ),
                          );
                          _autoIPoENotifier
                              .updateSettings(originalAutoIPoEState.settings);
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
            color: isBridgeMode || isIpv6Locked
                  ? null
                  : isIpv6Editing
                      ? null
                      : Theme.of(context).colorScheme.primary,
            onTap: isBridgeMode || isRemote || isIpv6Locked
                  ? null
                  : isIpv6Editing
                      ? () {
                          setState(() {
                            isIpv6Editing = false;
                          });
                        _notifier.updateIpv6Settings(originalState.ipv6Setting);
                          if (!isEditing) {
                          _notifier.updateIpv4Settings(
                            state.ipv4Setting.copyWith(
                              mtu: originalState.ipv4Setting.mtu,
                            ),
                          );
                            _notifier.updateMacAddressCloneEnable(
                            originalState.macClone,
                          );
                            _notifier.updateMacAddressClone(
                            originalState.macCloneAddress,
                          );
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
      },
    );
  }

  Widget _internetSettingInfoCard({
    required String title,
    required String description,
  }) {
    return AppSettingCard.noBorder(
      title: title,
      description: description,
      padding: const EdgeInsets.symmetric(vertical: Spacing.small3),
    );
  }

  List<Widget> buildInfoCards(
    InternetSettingsViewType viewType,
    InternetSettingsState state,
    AutoIPoEState autoIPoEState,
  ) {
    return switch (viewType) {
      InternetSettingsViewType.ipv4 => isIpv4Editing
          ? _buildIpv4EditingCards(state, autoIPoEState)
          : _buildIpv4InfoCards(state, autoIPoEState),
      InternetSettingsViewType.ipv6 =>
        isIpv6Editing && !_isIPv6LockedByAutoIPoE(state, autoIPoEState)
          ? _buildIpv6EditingCards(state)
            : _buildIpv6InfoCards(state, autoIPoEState),
    };
  }

  List<Widget> _buildIpv4InfoCards(
    InternetSettingsState state,
    AutoIPoEState autoIPoEState,
  ) {
    final ipv4Setting = state.ipv4Setting;
    final type = _effectiveIpv4WanType(state);
    final infoCards = switch (type) {
      WanType.dhcp => [],
      WanType.ipoe => [
          AutoIPoESection(
            settings: autoIPoEState.settings,
            status: autoIPoEState.status,
            capabilities: autoIPoEState.capabilities,
            isEditing: false,
            onChanged: (_) {},
          ),
        ],
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
        description: type?.type ?? ipv4Setting.ipv4ConnectionType,
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
          ipv4Setting.networkPrefixLength ?? 24,
        ),
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
        padding: const EdgeInsets.symmetric(vertical: Spacing.small3),
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
              'http://${_notifier.hostname}.local',
              icon: Icons.open_in_new,
              onTap: () {
                openUrl('http://${_notifier.hostname}.local');
              },
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildIpv6InfoCards(
    InternetSettingsState state,
    AutoIPoEState autoIPoEState,
  ) {
    if (_isIPv6LockedByAutoIPoE(state, autoIPoEState)) {
      return [
        _internetSettingInfoCard(
          title: loc(context).connectionType,
          description: state.ipv6Setting.ipv6ConnectionType,
        ),
        _internetSettingInfoCard(
          title: loc(context).autoIpoeIpv6Controls,
          description: loc(context).autoIpoeIpv6ManagedAutomatically,
        ),
      ];
    }
    final ipv6Setting = state.ipv6Setting;
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
      padding: EdgeInsets.symmetric(vertical: Spacing.small3),
      child: Divider(),
    );
  }

  Widget _optinalView(
    InternetSettingsState state,
    AutoIPoEState autoIPoEState,
  ) {
    final showAutoIPoEPane = _effectiveIpv4WanType(state) == WanType.ipoe ||
        _awaitingAutoIPoECompletion;
    if (showAutoIPoEPane) {
      return AutoIPoEOptionalPane(
        state: autoIPoEState,
        shouldTrackRuntime: showAutoIPoEPane && !_isCheckingAutoIPoE,
        awaitingCompletion: _awaitingAutoIPoECompletion,
        issue: _autoIPoEIssue,
        isChecking: _isCheckingAutoIPoE,
        // Advanced setup reports progress and failures in modal dialogs. Keep
        // this pane dedicated to the collapsed, user-expandable IPoE log.
        showRecovery: false,
        expectedMode: autoIPoEState.settings.selectedMode,
        onContinueChecking: _checkAdvancedAutoIPoE,
        onRetry: _retryAdvancedAutoIPoESetup,
        onEditSettings: _editAdvancedAutoIPoESettings,
        onCompleted: (nextState) {
          unawaited(_completeAdvancedAutoIPoE(nextState));
        },
        onIssue: (issue) {
          if (_awaitingAutoIPoECompletion) {
            _handleAdvancedAutoIPoEIssue(issue);
          }
        },
        onAwaitingCompletionChanged: (value) {
          if (!mounted) {
            return;
          }
          setState(() {
            _awaitingAutoIPoECompletion = value;
          });
        },
      );
    }
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
      _ => false,
    };
    return isEditing && isDomainNameEditable
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.small3),
            child: AppTextField(
              headerText: loc(context).domainName,
              hintText: '',
              semanticLabel: 'domain name',
              controller: _staticDomainNameController,
              border: const OutlineInputBorder(),
              onChanged: (value) {
                _notifier.updateIpv4Settings(
                  ipv4Setting.copyWith(
                  domainName: () => value.isEmpty ? null : value,
                  ),
                );
              },
            ),
          )
        : _internetSettingInfoCard(
            title: loc(context).domainName.capitalizeWords(),
            description: ipv4Setting.domainName ?? '-',
          );
  }

  Widget _mtu(Ipv4Setting ipv4Setting) {
    return isEditing && !isBridgeMode
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.small3),
            child: AppDropdownButton<String>(
              key: const ValueKey('mtuDropdown'),
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
    return isEditing && !isBridgeMode
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.small3),
            child: AppTextField.minMaxNumber(
              key: const ValueKey('mtuManualSizeText'),
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
                padding: const EdgeInsets.symmetric(vertical: Spacing.small3),
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
            padding: const EdgeInsets.symmetric(vertical: Spacing.small3),
            child: Row(
              children: [
                Expanded(
                  child: AppText.titleMedium(
                    loc(context).macAddressClone.capitalizeWords(),
                  ),
                ),
                AppGap.small1(),
                AppSwitch(
                  semanticLabel: 'mac address clone',
                  value: state.macClone,
                  onChanged: isEditing && !isBridgeMode
                      ? (value) {
                          _notifier.updateMacAddressCloneEnable(value);
                          _notifier.updateMacAddressClone(
                            value ? originalState.macCloneAddress ?? '' : null,
                          );
                          setState(() {
                            _macAddressCloneController.text = value
                                ? originalState.macCloneAddress ?? ''
                                : '';
                          });
                        }
                      : null,
                ),
              ],
            ),
          ),
          _divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.small3),
            child: AppTextField.macAddress(
              semanticLabel: 'mac address',
              controller: _macAddressCloneController,
              border: const OutlineInputBorder(),
              errorText: isEditing && state.macClone && !isBridgeMode
                  ? macAddressCloneErrorText
                  : null,
              enable: isEditing && state.macClone && !isBridgeMode,
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
            padding: const EdgeInsets.symmetric(vertical: Spacing.small3),
            child: AppTextButton.noPadding(
              loc(context).cloneCurrentClientMac,
              icon: LinksysIcons.duplicateControl,
              onTap: isEditing && state.macClone && !isBridgeMode
                  ? () {
                      _notifier.getMyMACAddress().then((value) {
                        _notifier.updateMacAddressClone(value);
                        setState(() {
                          _macAddressCloneController.text = value ?? '';
                          final isValid = _macValidator.validate(
                            _macAddressCloneController.text,
                          );
                          if (isValid) {
                            macAddressCloneErrorText = null;
                          } else {
                            macAddressCloneErrorText = loc(
                              context,
                            ).invalidMACAddress;
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

  List<Widget> _buildIpv4EditingCards(
    InternetSettingsState state,
    AutoIPoEState autoIPoEState,
  ) {
    final ipv4Setting = state.ipv4Setting;
    final supportedWanTypes = _effectiveSupportedIpv4ConnectionTypes(state);
    final effectiveType = _effectiveIpv4WanType(state) ??
        WanType.resolve(ipv4Setting.ipv4ConnectionType);
    final type = effectiveType ?? WanType.dhcp;
    final selectedWanType =
        type.type.isNotEmpty ? type.type : ipv4Setting.ipv4ConnectionType;
    final infoCards = switch (type) {
      WanType.dhcp => [],
      WanType.ipoe => [
          AutoIPoESection(
            settings: autoIPoEState.settings,
            status: autoIPoEState.status,
            capabilities: autoIPoEState.capabilities,
            isEditing: true,
            highlightedFieldGroup:
                _autoIPoEIssue?.fieldGroup ?? AutoIPoEFieldGroup.none,
            onChanged: (settings) {
              _autoIPoENotifier.updateSettings(settings);
              if (_autoIPoEIssue != null) {
                setState(() {
                  _autoIPoEIssue = null;
                });
              }
            },
          ),
        ],
      WanType.pppoe => _pppoeEditing(ipv4Setting),
      WanType.static => _staticIpEditing(ipv4Setting),
      WanType.pptp => _tpEditing(ipv4Setting, type),
      WanType.l2tp => _tpEditing(ipv4Setting, type),
      WanType.bridge => _bridgeEditing(),
      _ => [],
    };
    return [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.small3),
        child: AppDropdownButton<String>(
          key: const ValueKey('ipv4ConnectionDropdown'),
          selected: selectedWanType,
          items: supportedWanTypes,
          label: (item) {
            return _getWanConnectedTypeText(item);
          },
          onChanged: (value) {
            final selectedType = WanType.resolve(value);
            if (selectedType == WanType.ipoe) {
              final selectedMode =
                  autoIPoEState.settings.selectedMode == AutoIPoEMode.disabled
                      ? AutoIPoEMode.auto
                      : autoIPoEState.settings.selectedMode;
              _autoIPoENotifier.updateSettings(
                autoIPoEState.settings.copyWith(
                  isEnabled: true,
                  selectedMode: selectedMode,
                ),
              );
            }
            _notifier.updateIpv4Settings(
                value == originalState.ipv4Setting.ipv4ConnectionType
                    ? originalState.ipv4Setting.copyWith(mtu: ipv4Setting.mtu)
                    : Ipv4Setting(
                        ipv4ConnectionType: value,
                      supportedIPv4ConnectionType: supportedWanTypes,
                        supportedWANCombinations:
                            ipv4Setting.supportedWANCombinations,
                        mtu: ipv4Setting.mtu,
                    ),
            );
            // Set settings to default if ipv4 set to bridge
            if (selectedType == WanType.bridge) {
              _setSettingsDefaultOnBrigdeMode(state);
            }
            if (selectedType == WanType.ipoe) {
              setState(() {
                isIpv6Editing = false;
              });
            }
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
            _notifier.updateIpv4Settings(
              ipv4Setting.copyWith(username: () => value),
            );
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
            _notifier.updateIpv4Settings(
              ipv4Setting.copyWith(password: () => value),
            );
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
            _notifier.updateIpv4Settings(
              ipv4Setting.copyWith(
              vlanId: () => value.isEmpty ? null : int.parse(value),
              ),
            );
          },
          onFocusChanged: (hasFocus) {
            if (!hasFocus) {
              final value = _pppoeVLANIDController.text;
              if (value.isNotEmpty && int.parse(value) < 5) {
                _pppoeVLANIDController.text = '5';
                _notifier.updateIpv4Settings(
                  ipv4Setting.copyWith(vlanId: () => 5),
                );
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
            _notifier.updateIpv4Settings(
              ipv4Setting.copyWith(serviceName: () => value),
            );
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
          header: AppText.bodySmall(loc(context).internetIpv4Address),
          controller: _staticIpAddressController,
          border: const OutlineInputBorder(),
          onChanged: (value) {
            _notifier.updateIpv4Settings(
              ipv4Setting.copyWith(staticIpAddress: () => value),
            );
          },
        ),
      ),
      Padding(
        padding: inputPadding,
        child: AppIPFormField(
          key: const Key('staticSubnet'),
          semanticLabel: 'subnet mask',
          header: AppText.bodySmall(loc(context).subnetMask.capitalizeWords()),
          controller: _staticSubnetController,
          errorText: subnetMaskErrorText,
          border: const OutlineInputBorder(),
          onChanged: (value) {
            // override default of 30 for WAN Static IP settings (QUALITY-439)
            final subnetMaskValidator = SubnetMaskValidator(max: 31);
            final isValidSubnetMask = subnetMaskValidator.validate(value);
            if (isValidSubnetMask) {
              _notifier.updateIpv4Settings(
                ipv4Setting.copyWith(
                networkPrefixLength: () =>
                    NetworkUtils.subnetMaskToPrefixLength(value),
                ),
              );
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
          header: AppText.bodySmall(loc(context).defaultGateway),
          controller: _staticGatewayController,
          border: const OutlineInputBorder(),
          onChanged: (value) {
            _notifier.updateIpv4Settings(
              ipv4Setting.copyWith(staticGateway: () => value),
            );
          },
        ),
      ),
      Padding(
        padding: inputPadding,
        child: AppIPFormField(
          semanticLabel: 'dns 1',
          header: AppText.bodySmall(loc(context).dns1),
          controller: _staticDns1Controller,
          border: const OutlineInputBorder(),
          onChanged: (value) {
            _notifier.updateIpv4Settings(
              ipv4Setting.copyWith(staticDns1: () => value),
            );
          },
        ),
      ),
      Padding(
        padding: inputPadding,
        child: AppIPFormField(
          semanticLabel: 'dns 2 optional',
          header: AppText.bodySmall(loc(context).dns2Optional),
          controller: _staticDns2Controller,
          border: const OutlineInputBorder(),
          onChanged: (value) {
            _notifier.updateIpv4Settings(
              ipv4Setting.copyWith(
              staticDns2: () => value.isEmpty ? null : value,
              ),
            );
          },
        ),
      ),
      Padding(
        padding: inputPadding,
        child: AppIPFormField(
          semanticLabel: 'dns 3 optional',
          header: AppText.bodySmall(loc(context).dns3Optional),
          controller: _staticDns3Controller,
          border: const OutlineInputBorder(),
          onChanged: (value) {
            _notifier.updateIpv4Settings(
              ipv4Setting.copyWith(
              staticDns3: () => value.isEmpty ? null : value,
              ),
            );
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
        padding: const EdgeInsets.symmetric(vertical: Spacing.small3),
        child: AppIPFormField(
          key: const ValueKey('ipv4ServerAddressField'),
          header: AppText.bodySmall(loc(context).serverIpv4Address),
          controller: _tpServerIpController,
          border: const OutlineInputBorder(),
          onChanged: (value) {
            _notifier.updateIpv4Settings(
              ipv4Setting.copyWith(serverIp: () => value),
            );
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
            _notifier.updateIpv4Settings(
              ipv4Setting.copyWith(username: () => value),
            );
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
            _notifier.updateIpv4Settings(
              ipv4Setting.copyWith(password: () => value),
            );
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
      padding: const EdgeInsets.symmetric(vertical: Spacing.small3),
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
                        key: const ValueKey('maxIdleTimeText'),
                        max: 9999,
                        min: 1,
                        controller: _idleTimeController,
                        border: const OutlineInputBorder(),
                        onChanged: (value) {
                          _notifier.updateIpv4Settings(
                            ipv4Setting.copyWith(
                            behavior: () =>
                                PPPConnectionBehavior.connectOnDemand,
                            maxIdleMinutes: () =>
                                int.parse(_idleTimeController.text),
                            ),
                          );
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
                        key: const ValueKey('redialPeriodText'),
                        max: 180,
                        min: 20,
                        controller: _redialPeriodController,
                        border: const OutlineInputBorder(),
                        onChanged: (value) {
                          _notifier.updateIpv4Settings(
                            ipv4Setting.copyWith(
                            behavior: () => PPPConnectionBehavior.keepAlive,
                            reconnectAfterSeconds: () =>
                                int.parse(_redialPeriodController.text),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
            onChanged: (index, type) {
              if (type == PPPConnectionBehavior.connectOnDemand) {
                _notifier.updateIpv4Settings(
                  ipv4Setting.copyWith(
                  behavior: () => PPPConnectionBehavior.connectOnDemand,
                  maxIdleMinutes: () => int.parse(_idleTimeController.text),
                  ),
                );
              } else {
                _notifier.updateIpv4Settings(
                  ipv4Setting.copyWith(
                  behavior: () => PPPConnectionBehavior.keepAlive,
                  reconnectAfterSeconds: () =>
                      int.parse(_redialPeriodController.text),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _pptpIpAddressMode(bool useStaticSettings, Ipv4Setting ipv4Setting) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.small3),
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
              _notifier.updateIpv4Settings(
                ipv4Setting.copyWith(
                useStaticSettings: () => type == PPTPIpAddressMode.specify,
                ),
              );
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
        padding: const EdgeInsets.symmetric(vertical: Spacing.small3),
        child: AppDropdownButton<String>(
          key: const ValueKey('ipv6ConnectionDropdown'),
          selected: state.ipv6Setting.ipv6ConnectionType,
          items: allowedTypeList,
          label: (item) {
            return _getWanConnectedTypeText(item);
          },
          onChanged: (value) {
            _notifier.updateIpv6Settings(
                value == originalState.ipv6Setting.ipv6ConnectionType
                    ? originalState.ipv6Setting
                    : Ipv6Setting(
                        ipv6ConnectionType: value,
                        supportedIPv6ConnectionType:
                            state.ipv6Setting.supportedIPv6ConnectionType,
                        duid: state.ipv6Setting.duid,
                        isIPv6AutomaticEnabled:
                            state.ipv6Setting.isIPv6AutomaticEnabled,
                        ipv6rdTunnelMode: state.ipv6Setting.ipv6rdTunnelMode,
                    ),
            );
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
                  _notifier.updateIpv6Settings(
                    Ipv6Setting(
                    ipv6ConnectionType: ipv6Setting.ipv6ConnectionType,
                    supportedIPv6ConnectionType:
                        ipv6Setting.supportedIPv6ConnectionType,
                    duid: ipv6Setting.duid,
                    isIPv6AutomaticEnabled: true,
                    ),
                  );
                } else {
                  _notifier.updateIpv6Settings(
                    ipv6Setting.copyWith(
                      isIPv6AutomaticEnabled: value,
                      ipv6rdTunnelMode: () =>
                          ipv6Setting.ipv6rdTunnelMode ??
                          IPv6rdTunnelMode.disabled,
                    ),
                  );
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
      padding: const EdgeInsets.only(
        top: Spacing.small1,
        bottom: Spacing.small3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: inputPadding,
            child: AppDropdownButton<IPv6rdTunnelMode>(
              key: const ValueKey('ipv6TunnelDropdown'),
              title: loc(context).sixrdTunnel,
              selected:
                  ipv6Setting.ipv6rdTunnelMode ?? IPv6rdTunnelMode.disabled,
              items: const [
                IPv6rdTunnelMode.disabled,
                IPv6rdTunnelMode.automatic,
                IPv6rdTunnelMode.manual,
              ],
              label: (item) {
                return getIpv6rdTunnelModeLoc(item);
              },
              onChanged: ipv6Setting.isIPv6AutomaticEnabled
                  ? null
                  : (value) {
                      _notifier.updateIpv6Settings(
                        ipv6Setting.copyWith(ipv6rdTunnelMode: () => value),
                      );
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
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
            padding: inputPadding,
            child: AppTextField(
              headerText: loc(context).prefix,
              hintText: '',
              controller: _ipv6PrefixController,
              enable: isEnable,
              errorText: ipv6PrefixErrorText,
              border: const OutlineInputBorder(),
              onChanged: (value) {
                setState(() {
                  if (_ipv6PrefixValidator.validate(value)) {
                    ipv6PrefixErrorText = null;
                    _notifier.updateIpv6Settings(
                    ipv6Setting.copyWith(ipv6Prefix: () => value),
                  );
                  } else {
                    ipv6PrefixErrorText = loc(context).invalidIpAddress;
                  }
                });
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
              _notifier.updateIpv6Settings(
                ipv6Setting.copyWith(ipv6PrefixLength: () => int.parse(value)),
              );
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
            errorText: borderRelayErrorText,
            border: const OutlineInputBorder(),
            onChanged: (value) {
              setState(() {
                if (_borderRelayValidator.validate(value)) {
                  borderRelayErrorText = null;
                  _notifier.updateIpv6Settings(
                    ipv6Setting.copyWith(ipv6BorderRelay: () => value),
                  );
                } else {
                  borderRelayErrorText = loc(context).invalidIpAddress;
                }
              });
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
              _notifier.updateIpv6Settings(
                ipv6Setting.copyWith(
                  ipv6BorderRelayPrefixLength: () => int.parse(value),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  int _getMaxMtu(String wanType) {
    return NetworkUtils.getMaxMtu(wanType);
  }

  String _getWanConnectedTypeText(String type) {
    return switch (WanType.resolve(type)) {
      WanType.dhcp => loc(context).connectionTypeDhcp,
      WanType.ipoe => 'IPoE',
      WanType.static => loc(context).connectionTypeStatic,
      WanType.pppoe => loc(context).connectionTypePppoe,
      WanType.pptp => loc(context).connectionTypePptp,
      WanType.l2tp => loc(context).connectionTypeL2tp,
      WanType.bridge => loc(context).connectionTypeBridge,
      _ => switch (type) {
      'Automatic' => loc(context).connectionTypeAutomatic,
      'Pass-through' => loc(context).connectionTypePassThrough,
          _ => '',
        },
    };
  }

  bool _isEdited(InternetSettingsState state, AutoIPoEState autoIPoEState) {
    return state != originalState ||
        autoIPoEState.settings != originalAutoIPoEState.settings;
  }

  bool _isIPv6LockedByAutoIPoE(
    InternetSettingsState state,
    AutoIPoEState autoIPoEState,
  ) {
    return isAutoIPoEManagingIPv6(
      configuredWanType: state.ipv4Setting.ipv4ConnectionType,
      status: autoIPoEState.status,
    );
  }

  void _setSettingsDefaultOnBrigdeMode(InternetSettingsState state) {
    setState(() {
      // Editing state
      isIpv6Editing = false;
      // Set ipv6 to automatic
      _notifier.updateIpv6Settings(
        Ipv6Setting(
        ipv6ConnectionType: WanIPv6Type.automatic.type,
        supportedIPv6ConnectionType:
            state.ipv6Setting.supportedIPv6ConnectionType,
        duid: state.ipv6Setting.duid,
        isIPv6AutomaticEnabled: state.ipv6Setting.isIPv6AutomaticEnabled,
        ),
      );
      // Mtu
      _notifier.updateMtu(0);
      _mtuSizeController.text = '0';
      // Mac address clone
      _notifier.updateMacAddressCloneEnable(false);
      _notifier.updateMacAddressClone(null);
      _macAddressCloneController.text = '';
    });
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

  void _onSaveButtonTap() {
    final state = ref.read(internetSettingsProvider);
    if (_effectiveIpv4WanType(state) == WanType.ipoe) {
      // Auto-IPoE performs its own WAN and Wi-Fi restart. Do not ask the user
      // to confirm a second, generic restart before saving.
      _onRestartButtonTap();
      return;
    }
    _showRestartAlert();
  }

  _onRestartButtonTap() {
    final state = ref.read(internetSettingsProvider);
    if (_effectiveIpv4WanType(state) == WanType.ipoe) {
      return _saveChange();
    }
    // Show error if WAN combinations are invalid
    final isValidCombination = state.ipv4Setting.supportedWANCombinations.any(
        (combine) =>
            combine.wanType == state.ipv4Setting.ipv4ConnectionType &&
          combine.wanIPv6Type == state.ipv6Setting.ipv6ConnectionType,
    );
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
                const TableRow(
                  children: [
                  AppText.labelLarge('IPv4'),
                  AppText.labelLarge('IPv6'),
                  ],
                ),
                ...state.ipv4Setting.supportedWANCombinations.map((combine) {
                  return TableRow(
                    children: [
                    AppText.bodyMedium(combine.wanType),
                    AppText.bodyMedium(combine.wanIPv6Type),
                    ],
                  );
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

  void _editAdvancedAutoIPoESettings() {
    if (!mounted) {
      return;
    }
    final operationMayStillBeRunning = _awaitingAutoIPoECompletion &&
        (_autoIPoEIssue == null ||
            _autoIPoEIssue?.recoveryAction ==
                AutoIPoERecoveryAction.continueChecking);
    _advancedRecoveryGeneration++;
    setState(() {
      // Keep Save gated while the accepted Apply has an ambiguous outcome.
      // The editor remains available, but only a terminal retry state can
      // authorize a fresh, user-initiated Apply.
      _awaitingAutoIPoECompletion = operationMayStillBeRunning;
      _isCheckingAutoIPoE = false;
      if (!operationMayStillBeRunning) {
        _autoIPoEIssue = null;
      }
      isIpv4Editing = true;
    });
  }

  void _retryAdvancedAutoIPoESetup() {
    if (!mounted) {
      return;
    }
    // A retryable Failed status means the backend worker has ended. Restore
    // the populated editor and require an explicit Save press for exactly one
    // fresh Apply; this callback itself remains side-effect free.
    _advancedRecoveryGeneration++;
    setState(() {
      _awaitingAutoIPoECompletion = false;
      _isCheckingAutoIPoE = false;
      _autoIPoEIssue = null;
      isIpv4Editing = true;
    });
  }

  Future<void> _checkAdvancedAutoIPoE() async {
    if (_isCheckingAutoIPoE || _isFinalizingAutoIPoE) {
      return;
    }
    final generation = _advancedRecoveryGeneration;
    setState(() {
      _isCheckingAutoIPoE = true;
    });
    try {
      final nextState = await _autoIPoENotifier.refreshRuntime();
      if (!mounted || generation != _advancedRecoveryGeneration) {
        return;
      }
      if (AutoIPoEIssueMapper.isVerifiedActive(
        nextState.status,
        expectedMode: ref.read(autoIPoEProvider).settings.selectedMode,
      )) {
        await _completeAdvancedAutoIPoE(nextState);
      } else if (nextState.status.hasTerminalApplyOutcome) {
        _handleAdvancedAutoIPoEIssue(
          AutoIPoEIssueMapper.from(status: nextState.status),
        );
      }
    } catch (error) {
      if (!mounted || generation != _advancedRecoveryGeneration) {
        return;
      }
      _handleAdvancedAutoIPoEIssue(
        AutoIPoEIssueMapper.from(
          status: ref.read(autoIPoEProvider).status,
          error: error,
        ),
      );
    } finally {
      if (mounted && generation == _advancedRecoveryGeneration) {
        setState(() {
          _isCheckingAutoIPoE = false;
        });
      }
    }
  }

  void _handleAdvancedAutoIPoEIssue(AutoIPoEIssue issue) {
    if (!mounted || _isFinalizingAutoIPoE) {
      return;
    }
    setState(() {
      _autoIPoEIssue = issue;
      _awaitingAutoIPoECompletion =
          issue.recoveryAction == AutoIPoERecoveryAction.continueChecking ||
              issue.hasScheduledRecovery;
    });
    if ((issue.isTerminal ||
            issue.requiresFreshApply ||
            issue.hasScheduledRecovery) &&
        !_autoIPoETerminalDialogVisible) {
      unawaited(_showAdvancedAutoIPoETerminalDialog(issue));
    }
  }

  Future<void> _showAdvancedAutoIPoETerminalDialog(
    AutoIPoEIssue issue,
  ) async {
    _autoIPoETerminalDialogVisible = true;
    AutoIPoERetryScheduledDialogAction? scheduledAction;
    try {
      if (issue.hasScheduledRecovery) {
        scheduledAction = await showAutoIPoERetryScheduledDialog(
          context,
          issue,
        );
      } else {
        await showAutoIPoETerminalFailureDialog(context, issue);
      }
    } finally {
      _autoIPoETerminalDialogVisible = false;
    }
    switch (scheduledAction) {
      case AutoIPoERetryScheduledDialogAction.continueChecking:
        await _checkAdvancedAutoIPoE();
        break;
      case AutoIPoERetryScheduledDialogAction.editSettings:
        _editAdvancedAutoIPoESettings();
        break;
      case null:
        break;
    }
  }

  Future<void> _completeAdvancedAutoIPoE(AutoIPoEState nextState) async {
    if (!mounted || !_awaitingAutoIPoECompletion || _isFinalizingAutoIPoE) {
      return;
    }
    _isFinalizingAutoIPoE = true;
    try {
      if (!mounted) {
        return;
      }
      // Keep the submitted IPoE selection as the display baseline. Ordinary
      // WAN read-back can briefly report the pre-apply type while Linksys
      // services settle, even though the Auto-IPoE status is already Active.
      setState(() {
        _awaitingAutoIPoECompletion = false;
        _isCheckingAutoIPoE = false;
        _autoIPoEIssue = null;
        _advancedRecoveryGeneration++;
        isIpv4Editing = false;
        isIpv6Editing = false;
        originalState = ref.read(internetSettingsProvider).copyWith();
        originalAutoIPoEState = nextState.copyWith();
        initUI(originalState);
      });
      showSuccessSnackBar(context, loc(context).changesSaved);
    } finally {
      _isFinalizingAutoIPoE = false;
    }
  }

  Future<void> _saveAdvancedAutoIPoE() async {
    if (_awaitingAutoIPoECompletion || _isCheckingAutoIPoE) {
      return;
    }
    final autoIPoEState = ref.read(autoIPoEProvider);
    final bridge = ref.read(autoIPoEInternetSettingsBridgeProvider);
    _advancedAutoIPoEProgress.value =
        const AutoIPoEReconciliationProgress.initial();
    setState(() {
      loadingTitle = loc(context).savingChanges;
      _autoIPoEIssue = null;
      _isCheckingAutoIPoE = true;
    });
    var reconciledState = autoIPoEState;

    Future<AutoIPoEState> applyAndReconcile() async {
      try {
        await bridge.saveIPoEInternetSettings(
          settings: autoIPoEState.settings,
          originalWanType: WanType.resolve(
            originalState.ipv4Setting.ipv4ConnectionType,
          ),
          originalStatus: originalAutoIPoEState.status,
        );
      } on AutoIPoEApplyOutcomeUnknown catch (error) {
        // Apply may have interrupted JNAP while WAN/WiFi restarted. Keep the
        // same modal open and reconcile that operation without resubmitting.
        logger.w(
          '[Auto-IPoE]: Apply response interrupted; reconciling the existing operation: ${error.cause}',
        );
      }

      if (mounted) {
        setState(() {
          _awaitingAutoIPoECompletion = true;
        });
      }
      while (mounted) {
        try {
          await bridge.waitForPnpIPoESetupCompletion(
            expectedMode: autoIPoEState.settings.selectedMode,
            useStructuredProgress: true,
            onReconciliationProgress: _updateAdvancedAutoIPoEProgress,
            onProgress: (status, log) {
              reconciledState = reconciledState.copyWith(
                status: status,
                log: log,
              );
              if (mounted) {
                _autoIPoENotifier.updateRuntime(status, log);
              }
            },
          );
          break;
        } on AutoIPoERecoveryPending catch (error) {
          if (error.issue.recoveryAction !=
              AutoIPoERecoveryAction.continueChecking) {
            rethrow;
          }
          // Keep this modal open across bounded read-only polling windows.
          // Apply has already been dispatched and is never repeated here.
        }
      }
      return reconciledState;
    }

    try {
      final nextState = await doSomethingWithSpinner(
        context,
        applyAndReconcile(),
        title: loadingTitle,
        titleTextAlign: TextAlign.center,
        messages: const [],
        loadingWidget: ValueListenableBuilder<AutoIPoEReconciliationProgress>(
          valueListenable: _advancedAutoIPoEProgress,
          builder: (context, progress, child) => AutoIPoECompactProgressContent(
            progress: progress,
            centered: true,
          ),
        ),
      );
      if (!mounted || nextState == null) {
        return;
      }
      await _completeAdvancedAutoIPoE(nextState);
    } on AutoIPoETerminalFailure catch (error) {
      if (mounted) {
        _handleAdvancedAutoIPoEIssue(error.issue);
      }
    } on AutoIPoERecoveryPending catch (error) {
      if (mounted) {
        _handleAdvancedAutoIPoEIssue(error.issue);
      }
    } catch (error, stackTrace) {
      logger.e(
        '[Auto-IPoE]: Failed to start IPoE apply',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) {
        return;
      }
      _handleAdvancedAutoIPoEIssue(
        AutoIPoEIssueMapper.from(
          status: reconciledState.status,
          error: error,
          mode: autoIPoEState.settings.selectedMode,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          loadingTitle = '';
          _isCheckingAutoIPoE = false;
        });
      }
    }
  }

  void _updateAdvancedAutoIPoEProgress(
    AutoIPoEReconciliationProgress next,
  ) {
    if (!mounted) {
      return;
    }
    final advanced = _advancedAutoIPoEProgress.value.advanceTo(next);
    if (advanced == _advancedAutoIPoEProgress.value) {
      return;
    }
    _advancedAutoIPoEProgress.value = advanced;
  }

  void _saveChange() {
    final selectedState = ref.read(internetSettingsProvider);
    if (_effectiveIpv4WanType(selectedState) == WanType.ipoe) {
      unawaited(_saveAdvancedAutoIPoE());
      return;
    }
    setState(() {
      loadingTitle = loc(context).restarting;
    });
    final state = ref.read(internetSettingsProvider);
    final autoIPoEState = ref.read(autoIPoEProvider);
    final bridge = ref.read(autoIPoEInternetSettingsBridgeProvider);
    final isAutoIPoE = _effectiveIpv4WanType(state) == WanType.ipoe;
    doSomethingWithSpinner(
      context,
      () async {
        if (isAutoIPoE) {
          await bridge.saveIPoEInternetSettings(
            settings: autoIPoEState.settings,
            originalWanType: WanType.resolve(
              originalState.ipv4Setting.ipv4ConnectionType,
            ),
            originalStatus: originalAutoIPoEState.status,
          );
        } else {
          await bridge.resetIfNeededBeforeSaving(
            originalWanType: WanType.resolve(
              originalState.ipv4Setting.ipv4ConnectionType,
            ),
            originalStatus: originalAutoIPoEState.status,
          );
          await _notifier.saveInternetSettings(
            state,
            originalState,
          );
        }
        try {
          await Future.wait([
            _notifier.fetch(fetchRemote: true),
            _autoIPoENotifier.fetchAll(),
          ]);
        } catch (error, stackTrace) {
          // The Apply response means settings are committed. QSDK then
          // restarts WAN/WiFi, so an immediate read-back may be temporarily
          // unreachable. Keep the saved in-memory selection and let runtime
          // polling reconcile when JNAP returns.
          logger.w(
            '[Auto-IPoE]: Saved; deferred read-back until network restart completes',
            error: error,
            stackTrace: stackTrace,
          );
        }
      }(),
    ).then((value) {
      setState(() {
        isIpv4Editing = false;
        isIpv6Editing = false;
        originalState = ref.read(internetSettingsProvider).copyWith();
        originalAutoIPoEState = ref.read(autoIPoEProvider).copyWith();
        initUI(originalState);
        if (isAutoIPoE) {
          _awaitingAutoIPoECompletion = true;
        } else {
          _awaitingAutoIPoECompletion = false;
        }
      });
      showSuccessSnackBar(context, loc(context).changesSaved);
    }).catchError((error) {
      _awaitingAutoIPoECompletion = false;
      showRouterNotFoundAlert(
        context,
        ref,
        onComplete: () async {
        await _notifier.fetch(fetchRemote: true);
          await _autoIPoENotifier.fetchAll();
        setState(() {
          isIpv4Editing = false;
          isIpv6Editing = false;
          originalState = ref.read(internetSettingsProvider).copyWith();
            originalAutoIPoEState = ref.read(autoIPoEProvider).copyWith();
          initUI(originalState);
            if (isAutoIPoE) {
              _awaitingAutoIPoECompletion = true;
            }
        });
          showSuccessSnackBar(context, loc(context).changesSaved);
        },
        );
    }, test: (error) => error is JNAPSideEffectError).onError(
        (error, stackTrace) {
      _awaitingAutoIPoECompletion = false;
      final jnapError = error is JNAPError ? error : null;
      final errorMsg = switch (error.runtimeType) {
        JNAPError => errorCodeHelper(context, jnapError?.result),
        TimeoutException => loc(context).generalError,
        _ => loc(context).unknownError,
      };
      showFailedSnackBar(
        context,
        errorMsg ?? loc(context).unknownErrorCode(jnapError?.result ?? ''),
      );
    }).whenComplete(() {
        setState(() {
          loadingTitle = '';
        });
    });
  }

  _showRenewIPAlert(InternetSettingsViewType type) {
    showSimpleAppDialog(
      context,
      dismissible: false,
      title: loc(context).releaseAndRenewIpAddress,
      content: AppText.bodyMedium(
        loc(context).releaseAndRenewIpAddressDescription,
      ),
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
  }

  void _releaseAndRenewIpv4() {
    doSomethingWithSpinner(
      context,
      _notifier.renewDHCPWANLease().then((value) {
        showSuccessSnackBar(context, loc(context).successExclamation);
      }).catchError((error) {
        showRouterNotFoundAlert(
            context,
          ref,
          onComplete: () async {
          await ref.read(pollingProvider.notifier).forcePolling();
            showSuccessSnackBar(context, loc(context).successExclamation);
          },
          );
      }, test: (error) => error is JNAPSideEffectError).onError(
          (error, stackTrace) {
        final jnapError = error is JNAPError ? error : null;
        final errorMsg = switch (error.runtimeType) {
          JNAPError => jnapError?.result == 'ErrorInvalidWANType'
              ? loc(context).currentWanTypeIsNotDhcp
              : errorCodeHelper(context, jnapError?.result),
          TimeoutException => loc(context).generalError,
          _ => loc(context).unknownError,
        };
        showFailedSnackBar(
          context,
          errorMsg ?? loc(context).unknownErrorCode(jnapError?.result ?? ''),
        );
      }),
    );
  }

  void _releaseAndRenewIpv6() {
    doSomethingWithSpinner(
      context,
      _notifier.renewDHCPIPv6WANLease().then((value) {
        showSuccessSnackBar(context, loc(context).successExclamation);
      }).catchError((error) {
        showRouterNotFoundAlert(
            context,
          ref,
          onComplete: () async {
          await ref.read(pollingProvider.notifier).forcePolling();
            showSuccessSnackBar(context, loc(context).successExclamation);
          },
          );
      }, test: (error) => error is JNAPSideEffectError).onError(
          (error, stackTrace) {
        final jnapError = error is JNAPError ? error : null;
        final errorMsg = switch (error.runtimeType) {
          JNAPError => jnapError?.result == 'ErrorInvalidIPv6WANType'
              ? loc(context).currentIPv6ConnectionTypeIsNotAutomatic
              : errorCodeHelper(context, jnapError?.result),
          TimeoutException => loc(context).generalError,
          _ => loc(context).unknownError,
        };
        showFailedSnackBar(
          context,
          errorMsg ?? loc(context).unknownErrorCode(jnapError?.result ?? ''),
        );
      }),
    );
  }
}
