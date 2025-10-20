import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/views/dhcp_server_view.dart';
import 'package:privacy_gui/page/components/mixin/page_snackbar_mixin.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_state.dart';
import 'package:privacy_gui/page/instant_safety/providers/instant_safety_provider.dart';
import 'package:privacy_gui/providers/redirection/redirection_provider.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/input_field/ip_form_field.dart';
import 'package:privacy_gui/core/jnap/providers/assign_ip/base_assign_ip.dart'
    if (dart.library.html) 'package:privacy_gui/core/jnap/providers/assign_ip/web_assign_ip.dart';
import 'package:privacy_gui/core/jnap/providers/ip_getter/get_local_ip.dart'
    if (dart.library.io) 'package:privacy_gui/core/jnap/providers/ip_getter/mobile_get_local_ip.dart'
    if (dart.library.html) 'package:privacy_gui/core/jnap/providers/ip_getter/web_get_local_ip.dart';

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
    extends ConsumerState<LocalNetworkSettingsView>
    with PageSnackbarMixin, SingleTickerProviderStateMixin {
  late TabController _tabController;

  late LocalNetworkSettingsNotifier _notifier;
  final hostNameController = TextEditingController();
  final ipAddressController = TextEditingController();
  final subnetMaskController = TextEditingController();
  int _selectedTabIndex = 0;
  final _https = 'https://';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _notifier = ref.read(localNetworkSettingProvider.notifier);
    doSomethingWithSpinner(
      context,
      _notifier.fetch(true).then(
        (value) {
          if (mounted) {
            final state = ref.read(localNetworkSettingProvider);
            hostNameController.text = state.settings.hostName;
            ipAddressController.text = state.settings.ipAddress;
            subnetMaskController.text = state.settings.subnetMask;
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    hostNameController.dispose();
    ipAddressController.dispose();
    subnetMaskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!BuildConfig.isRemote()) {
      ref.listen(redirectionProvider, (previous, next) {
        final state = ref.read(localNetworkSettingProvider);
        if (kIsWeb && next != null && '$_https${state.settings.ipAddress}' != next) {
          logger.d('Redirect to $next');
          assignWebLocation(next);
        }
      });
    }
    final state = ref.watch(localNetworkSettingProvider);
    final notifier = ref.watch(localNetworkSettingProvider.notifier);
    final tabContents = [
      _hostNameView(state),
      _ipAddressView(state),
      _dhcpServerView(state),
    ];
    return StyledAppPageView(
      padding: EdgeInsets.zero,
      useMainPadding: false,
      tabController: _tabController,
      bottomBar: PageBottomBar(
        isPositiveEnabled: notifier.isDirty && !_hasError(state),
        onPositiveTap: _saveSettings,
      ),
      title: loc(context).localNetwork,
      onBackTap: notifier.isDirty
          ? () async {
              final goBack = await showUnsavedAlert(context);
              if (goBack == true) {
                notifier.restore();
                context.pop();
              }
            }
          : null,
      tabs: [
        tab(
          loc(context).hostName,
          selected: _selectedTabIndex == 0,
          hasError: state.settings.hasErrorOnHostNameTab,
        ),
        tab(
          loc(context).lanIPAddress,
          selected: _selectedTabIndex == 1,
          hasError: state.settings.hasErrorOnIPAddressTab,
        ),
        tab(
          loc(context).dhcpServer,
          selected: _selectedTabIndex == 2,
          hasError: state.settings.hasErrorOnDhcpServerTab,
        ),
      ],
      tabContentViews: tabContents,
      onTabTap: (index) {
        setState(() {
          _selectedTabIndex = index;
        });
      },
    );
  }

  Widget _hostNameView(LocalNetworkSettingsState state) {
    return _viewLayout(
      child: AppCard(
        padding: const EdgeInsets.symmetric(
            vertical: Spacing.large3, horizontal: Spacing.large2),
        child: AppTextField(
          key: Key('hostNameTextField'),
          headerText: loc(context).hostName.capitalizeWords(),
          controller: hostNameController,
          errorText: LocalNetworkErrorPrompt.getErrorText(
              context: context,
              error: LocalNetworkErrorPrompt.resolve(state
                  .settings.errorTextMap[LocalNetworkErrorPrompt.hostName.name])),
          border: const OutlineInputBorder(),
          focusNode: FocusNode()..requestFocus(),
          onChanged: (value) {
            _notifier.updateHostName(value);
          },
        ),
      ),
    );
  }

  Widget _ipAddressView(LocalNetworkSettingsState state) {
    return _viewLayout(
      col: 6.col,
      child: AppCard(
        padding: const EdgeInsets.symmetric(
            vertical: Spacing.large3, horizontal: Spacing.large2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIPFormField(
              key: Key('lanIpAddressTextField'),
              header: AppText.bodySmall(loc(context).ipAddress),
              semanticLabel: 'ip address',
              controller: ipAddressController,
              errorText: LocalNetworkErrorPrompt.getErrorText(
                  context: context,
                  error: LocalNetworkErrorPrompt.resolve(state.settings
                      .errorTextMap[LocalNetworkErrorPrompt.ipAddress.name])),
              border: const OutlineInputBorder(),
              autoFocus: true,
              onChanged: (value) {
                _notifier.routerIpAddressChanged(
                    context, value, state.settings);
              },
            ),
            const AppGap.large2(),
            AppIPFormField(
              key: Key('lanSubnetMaskTextField'),
              header: AppText.bodySmall(loc(context).subnetMask),
              semanticLabel: 'subnet mask',
              octet1ReadOnly: true,
              octet2ReadOnly: true,
              controller: subnetMaskController,
              errorText: LocalNetworkErrorPrompt.getErrorText(
                  context: context,
                  error: LocalNetworkErrorPrompt.resolve(state.settings
                      .errorTextMap[LocalNetworkErrorPrompt.subnetMask.name])),
              border: const OutlineInputBorder(),
              onChanged: (value) {
                _notifier.subnetMaskChanged(context, value, state.settings);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _dhcpServerView(LocalNetworkSettingsState state) {
    return _viewLayout(
      child: DHCPServerView(
        isEdited: () => ref.read(localNetworkSettingProvider.notifier).isDirty,
        onSaveSettings: () async {
          _saveSettings();
        },
      ),
    );
  }

  Widget _viewLayout({double? col, required Widget child}) {
    col = col ?? 9.col;
    return StyledAppPageView.innerPage(
      child: (context, constraints) => ResponsiveLayout.isMobileLayout(context)
          ? child
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: col,
                  child: child,
                ),
              ],
            ),
    );
  }

  Widget tab(
    String title, {
    required bool selected,
    bool hasError = false,
  }) {
    return Tab(
      child: Row(
        children: [
          if (hasError) ...[
            Icon(
              LinksysIcons.error,
              color: Theme.of(context).colorScheme.error,
            ),
            AppGap.small1(),
          ],
          AppText.titleSmall(
            title,
            color: selected ? Theme.of(context).colorScheme.primary : null,
          ),
        ],
      ),
    );
  }

  bool _hasError(LocalNetworkSettingsState state) {
    return state.settings.errorTextMap.isNotEmpty;
  }

  void _saveSettings() {
    doSomethingWithSpinner(
      context,
      _notifier.save(),
    ).then(
      (value) {
        _finishSaveSettings();
      },
    ).catchError((error) {
      final currentUrl = ref.read(routerRepositoryProvider).getLocalIP();
      final regex = RegExp(r'(www\.)?myrouter\.info');

      if (regex.hasMatch(currentUrl)) {
        _showRouterNotFoundModal();
      } else {
        final state = ref.read(localNetworkSettingProvider);
        if (currentUrl != state.settings.ipAddress) {
          showRedirectNewIpAlert(context, ref, state.settings.ipAddress);
        } else {
          _finishSaveSettings();
        }
      }
    }, test: (error) => error is JNAPSideEffectError).onError(
        (error, stackTrace) {
      showErrorMessageSnackBar(error);
    });
  }

  void _showRouterNotFoundModal() {
    showRouterNotFoundAlert(context, ref, onComplete: () async {
      await _notifier.fetch();
      await ref.read(instantSafetyProvider.notifier).fetch();
      _finishSaveSettings();
    });
  }

  void _finishSaveSettings() {
    showChangesSavedSnackBar();
    if (!kIsWeb) {
      return;
    }
    final state = ref.read(localNetworkSettingProvider);
    final currentUrl = ref.read(routerRepositoryProvider).getLocalIP();
    final regex = RegExp(r'(www\.)?myrouter\.info');
    if (regex.hasMatch(currentUrl)) {
      return;
    }
    if (state.settings.ipAddress != currentUrl && !BuildConfig.isRemote()) {
      _doRedirect(state.settings.ipAddress);
    }
  }

  void _doRedirect(String ip) {
    ref.read(redirectionProvider.notifier).state = '$_https$ip';
  }
}
