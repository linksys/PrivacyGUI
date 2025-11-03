import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      _notifier.fetch(forceRemote: true).then((state) {
        setState(
          () {
            hostNameController.text = state.settings.current.hostName;
            ipAddressController.text = state.settings.current.ipAddress;
            subnetMaskController.text = state.settings.current.subnetMask;
          },
        );
      }),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
    hostNameController.dispose();
    ipAddressController.dispose();
    subnetMaskController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!BuildConfig.isRemote()) {
      ref.listen(redirectionProvider, (previous, next) {
        if (kIsWeb &&
            next != null &&
            '$_https${ref.read(localNetworkSettingProvider).settings.original.ipAddress}' !=
                next) {
          logger.d('Redirect to $next');
          assignWebLocation(next);
        }
      });
    }
    final state = ref.watch(localNetworkSettingProvider);
    final notifier = ref.read(localNetworkSettingProvider.notifier);

    ref.listen(localNetworkSettingProvider, (previous, next) {
      if (previous?.settings.current.hostName !=
          next.settings.current.hostName) {
        hostNameController.text = next.settings.current.hostName;
      }
      if (previous?.settings.current.ipAddress !=
          next.settings.current.ipAddress) {
        ipAddressController.text = next.settings.current.ipAddress;
      }
      if (previous?.settings.current.subnetMask !=
          next.settings.current.subnetMask) {
        subnetMaskController.text = next.settings.current.subnetMask;
      }
    });

    final tabContents = [
      _hostNameView(state),
      _ipAddressView(state),
      _dhcpServerView(state),
    ];
    return StyledAppPageView.withSliver(
      padding: EdgeInsets.zero,
      tabController: _tabController,
      bottomBar: PageBottomBar(
        isPositiveEnabled: _notifier.isDirty() && !_hasError(state),
        onPositiveTap: _saveSettings,
      ),
      title: loc(context).localNetwork,
      tabs: [
        tab(
          loc(context).hostName,
          selected: _selectedTabIndex == 0,
          hasError: state.status.hasErrorOnHostNameTab,
        ),
        tab(
          loc(context).lanIPAddress,
          selected: _selectedTabIndex == 1,
          hasError: state.status.hasErrorOnIPAddressTab,
        ),
        tab(
          loc(context).dhcpServer,
          selected: _selectedTabIndex == 2,
          hasError: state.status.hasErrorOnDhcpServerTab,
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
                  .status.errorTextMap[LocalNetworkErrorPrompt.hostName.name])),
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
                  error: LocalNetworkErrorPrompt.resolve(state.status
                      .errorTextMap[LocalNetworkErrorPrompt.ipAddress.name])),
              border: const OutlineInputBorder(),
              autoFocus: true,
              onChanged: (value) {
                _notifier.routerIpAddressChanged(context, value);
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
                  error: LocalNetworkErrorPrompt.resolve(state.status
                      .errorTextMap[LocalNetworkErrorPrompt.subnetMask.name])),
              border: const OutlineInputBorder(),
              onChanged: (value) {
                _notifier.subnetMaskChanged(context, value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _dhcpServerView(LocalNetworkSettingsState state) {
    return _viewLayout(
      child: DHCPServerView(),
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

  bool _hasError(LocalNetworkSettingsState state) {
    return state.status.errorTextMap.isNotEmpty;
  }

  void _saveSettings() {
    final originalIpAddress =
        ref.read(localNetworkSettingProvider).settings.original.ipAddress;
    doSomethingWithSpinner(
      context,
      _notifier.save(),
    ).then(
      (value) {
        _finishSaveSettings();
      },
    ).catchError((error) {
      final state = ref.read(localNetworkSettingProvider);
      final currentUrl = ref.read(routerRepositoryProvider).getLocalIP();
      final regex = RegExp(r'(www\.)?myrouter\.info');

      // check is url start with www.myrouter.info or myrouter.info
      if (regex.hasMatch(currentUrl)) {
        // url start with myrouter.info, show router not found and wait for connect back
        _showRouterNotFoundModal();
      } else if (currentUrl != state.settings.current.ipAddress) {
        // ip is changed, show redirect alert to warn user make sure connect back to the router
        showRedirectNewIpAlert(context, ref, state.settings.current.ipAddress);
      } else {
        // ip is not changed, finish settings
        _finishSaveSettings();
      }
    }, test: (error) => error is JNAPSideEffectError).onError(
        (error, stackTrace) {
      showErrorMessageSnackBar(error);
    });
  }

  void _showRouterNotFoundModal() {
    showRouterNotFoundAlert(context, ref, onComplete: () async {
      // Update the state
      await _notifier.fetch(forceRemote: true);
      // Update instant safety
      await ref.read(instantSafetyProvider.notifier).fetch();
      _finishSaveSettings();
    });
  }

  void _finishSaveSettings() {
    showChangesSavedSnackBar();
    // handle redirect
    if (!kIsWeb) {
      return;
    }
    final state = ref.read(localNetworkSettingProvider);
    final currentUrl = ref.read(routerRepositoryProvider).getLocalIP();
    final regex = RegExp(r'(www\.)?myrouter\.info');
    // check is url start with www.myrouter.info or myrouter.info
    if (regex.hasMatch(currentUrl)) {
      return;
    }
    // ip case
    if (state.settings.current.ipAddress != currentUrl &&
        !BuildConfig.isRemote()) {
      _doRedirect(state.settings.current.ipAddress);
    }
  }

  void _doRedirect(String ip) {
    ref.read(redirectionProvider.notifier).state = '$_https$ip';
  }
}
