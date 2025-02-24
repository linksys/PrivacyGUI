import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/views/dhcp_server_view.dart';
import 'package:privacy_gui/page/components/mixin/page_snackbar_mixin.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/styled/styled_tab_page_view.dart';
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
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
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
  late LocalNetworkSettingsState originalSettings;
  late LocalNetworkSettingsNotifier _notifier;
  final hostNameController = TextEditingController();
  final ipAddressController = TextEditingController();
  final subnetMaskController = TextEditingController();
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();

    _notifier = ref.read(localNetworkSettingProvider.notifier);
    originalSettings = ref.read(localNetworkSettingProvider);
    doSomethingWithSpinner(
      context,
      _notifier.fetch(fetchRemote: true).then(
        (value) {
          setState(
            () {
              originalSettings = value;
              hostNameController.text = originalSettings.hostName;
              ipAddressController.text = originalSettings.ipAddress;
              subnetMaskController.text = originalSettings.subnetMask;
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();

    hostNameController.dispose();
    ipAddressController.dispose();
    subnetMaskController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(redirectionProvider, (previous, next) {
      if (kIsWeb && next != null && originalSettings.ipAddress != next) {
        logger.d('Redirect to $next');
        assignWebLocation(next);
      }
    });
    ref.listen(localNetworkSettingNeedToSaveProvider, (previous, next) {
      if (previous == false && next == true) {
        _saveSettings();
      }
    });
    final state = ref.watch(localNetworkSettingProvider);
    final tabContents = [
      _hostNameView(state),
      _ipAddressView(state),
      _dhcpServerView(originalSettings),
    ];
    return StyledAppPageView(
      appBarStyle: AppBarStyle.none,
      bottomBar: PageBottomBar(
        isPositiveEnabled: _isEdited(state) && !_hasError(state),
        onPositiveTap: _saveSettings,
      ),
      child: AppBasicLayout(
        content: StyledAppTabPageView(
          padding: EdgeInsets.zero,
          useMainPadding: false,
          title: loc(context).localNetwork,
          onBackTap: _isEdited(state)
              ? () async {
                  final goBack = await showUnsavedAlert(context);
                  if (goBack == true) {
                    _notifier.fetch();
                    context.pop();
                  }
                }
              : null,
          tabs: [
            tab(
              loc(context).hostName,
              selected: _selectedTabIndex == 0,
              hasError: state.hasErrorOnHostNameTab,
            ),
            tab(
              loc(context).lanIPAddress,
              selected: _selectedTabIndex == 1,
              hasError: state.hasErrorOnIPAddressTab,
            ),
            tab(
              loc(context).dhcpServer,
              selected: _selectedTabIndex == 2,
              hasError: state.hasErrorOnDhcpServerTab,
            ),
          ],
          tabContentViews: tabContents,
          expandedHeight: 120,
          onTap: (index) {
            setState(() {
              _selectedTabIndex = index;
            });
          },
        ),
      ),
    );
  }

  Widget _hostNameView(LocalNetworkSettingsState state) {
    return _viewLayout(
      child: AppCard(
        padding: const EdgeInsets.symmetric(
            vertical: Spacing.large3, horizontal: Spacing.large2),
        child: AppTextField(
          headerText: loc(context).hostName.capitalizeWords(),
          controller: hostNameController,
          errorText: LocalNetworkErrorPrompt.getErrorText(
              context: context,
              error: LocalNetworkErrorPrompt.resolve(
                  state.errorTextMap[LocalNetworkErrorPrompt.hostName.name])),
          border: const OutlineInputBorder(),
          focusNode: FocusNode()..requestFocus(),
          onChanged: (value) {
            _notifier.updateHostName(value);
            _notifier.updateErrorPrompts(
              LocalNetworkErrorPrompt.hostName.name,
              value.isEmpty ? LocalNetworkErrorPrompt.hostName.name : null,
            );
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
              header: AppText.bodySmall(loc(context).ipAddress),
              semanticLabel: 'ip address',
              controller: ipAddressController,
              errorText: LocalNetworkErrorPrompt.getErrorText(
                  context: context,
                  error: LocalNetworkErrorPrompt.resolve(state
                      .errorTextMap[LocalNetworkErrorPrompt.ipAddress.name])),
              border: const OutlineInputBorder(),
              autoFocus: true,
              onChanged: (value) {
                _notifier.routerIpAddressChanged(context, value, state);
              },
            ),
            const AppGap.large2(),
            AppIPFormField(
              header: AppText.bodySmall(loc(context).subnetMask),
              semanticLabel: 'subnet mask',
              octet1ReadOnly: true,
              octet2ReadOnly: true,
              controller: subnetMaskController,
              errorText: LocalNetworkErrorPrompt.getErrorText(
                  context: context,
                  error: LocalNetworkErrorPrompt.resolve(state
                      .errorTextMap[LocalNetworkErrorPrompt.subnetMask.name])),
              border: const OutlineInputBorder(),
              onChanged: (value) {
                _notifier.subnetMaskChanged(context, value, state);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _dhcpServerView(LocalNetworkSettingsState? originalSettings) {
    return _viewLayout(
      child: DHCPServerView(originalState: originalSettings),
    );
  }

  Widget _viewLayout({double? col, required Widget child}) {
    col = col ?? 9.col;
    return SingleChildScrollView(
      child: ResponsiveLayout.isMobileLayout(context)
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

  bool _isEdited(LocalNetworkSettingsState state) {
    return !originalSettings.isEqualStateWithoutDhcpReservationList(state);
  }

  bool _hasError(LocalNetworkSettingsState state) {
    return state.errorTextMap.isNotEmpty;
  }

  void _saveSettings() {
    final state = ref.read(localNetworkSettingProvider);
    doSomethingWithSpinner(
      context,
      _notifier.saveSettings(state,
          previousIPAddress: originalSettings.ipAddress),
    ).then(
      (value) {
        ///
        /// Default success case only if
        /// 1) Wired connection and host using myrouter.info
        /// 2) Wireless connection and didn't swap to another WiFi and using myrouter.info
        ///
        _finishSaveSettings(state);
      },
    ).catchError((error) {
      final currentUrl = ref.read(routerRepositoryProvider).getLocalIP();
      final regex = RegExp(r'(www\.)?myrouter\.info');

      // check is url start with www.myrouter.info or myrouter.info
      if (regex.hasMatch(currentUrl)) {
        // url start with myrouter.info, show router not found and wait for connect back
        _showRouterNotFoundModal();
      } else if (currentUrl != state.ipAddress) {
        // ip is changed, show redirect alert to warn user make sure connect back to the router
        showRedirectNewIpAlert(context, ref, state.ipAddress);
      } else {
        // ip is not changed, finish settings
        _finishSaveSettings(state);
      }
    }, test: (error) => error is JNAPSideEffectError).onError(
        (error, stackTrace) {
      showErrorMessageSnackBar(error);
    });
  }

  void _showRouterNotFoundModal() {
    showRouterNotFoundAlert(context, ref, onComplete: () async {
      // Update the state
      final state = await _notifier.fetch(fetchRemote: true);
      // Update instant safety
      await ref.read(instantSafetyProvider.notifier).fetchLANSettings();
      _finishSaveSettings(state);
    });
  }

  void _finishSaveSettings(LocalNetworkSettingsState state) {
    ref.read(localNetworkSettingNeedToSaveProvider.notifier).state = false;
    setState(() {
      originalSettings = state;
    });
    showChangesSavedSnackBar();
    // handle redirect
    if (!kIsWeb) {
      return;
    }
    final currentUrl = ref.read(routerRepositoryProvider).getLocalIP();
    final regex = RegExp(r'(www\.)?myrouter\.info');
    // check is url start with www.myrouter.info or myrouter.info
    if (regex.hasMatch(currentUrl)) {
      return;
    }
    // ip case
    if (state.ipAddress != currentUrl) {
      _doRedirect(state.ipAddress);
    }
  }

  void _doRedirect(String ip) {
    ref.read(redirectionProvider.notifier).state = 'https://$ip';
  }
}
