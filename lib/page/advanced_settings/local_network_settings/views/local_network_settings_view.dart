import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/views/dhcp_server_view.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/styled/styled_tab_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_state.dart';
import 'package:privacy_gui/page/instant_safety/providers/instant_safety_provider.dart';
import 'package:privacy_gui/providers/redirection/redirection_provider.dart';
import 'package:privacy_gui/util/error_code_helper.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/input_field/ip_form_field.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
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
    extends ConsumerState<LocalNetworkSettingsView> {
  late LocalNetworkSettingsState originalSettings;
  late LocalNetworkSettingsNotifier _notifier;
  final hostNameController = TextEditingController();
  final ipAddressController = TextEditingController();
  final subnetMaskController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _notifier = ref.read(localNetworkSettingProvider.notifier);
    originalSettings = _notifier.currentSettings();
    doSomethingWithSpinner(
      context,
      _notifier.fetch(fetchRemote: true).then(
        (value) {
          setState(
            () {
              originalSettings = _notifier.currentSettings();
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
    final state = ref.watch(localNetworkSettingProvider);
    final tabs = [
      loc(context).hostName,
      loc(context).wanIPAddress,
      loc(context).dhcpServer,
    ];
    final tabContents = [
      _hostNameView(state),
      _ipAddressView(state),
      _dhcpServerView(),
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

  Widget _hostNameView(LocalNetworkSettingsState state) {
    return _viewLayout(
      child: AppCard(
        padding: const EdgeInsets.symmetric(
            vertical: Spacing.large3, horizontal: Spacing.large2),
        child: AppTextField(
          headerText: loc(context).hostName.capitalizeWords(),
          controller: hostNameController,
          errorText: state.errorTextMap['hostName'],
          border: const OutlineInputBorder(),
          onChanged: (value) {
            _notifier.updateHostName(value);
            _notifier.updateErrorPrompts(
              'hostName',
              value.isEmpty ? loc(context).hostNameCannotEmpty : null,
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
              errorText: state.errorTextMap['ipAddress'],
              border: const OutlineInputBorder(),
              onChanged: (value) {
                setState(() {
                  final result = routerIpAddressFinished(value);
                  _notifier.updateState(result.$2);
                  _notifier.updateErrorPrompts(
                    'ipAddress',
                    result.$1 ? null : loc(context).invalidIpAddress,
                  );
                });
              },
            ),
            const AppGap.large2(),
            AppIPFormField(
              header: AppText.bodySmall(loc(context).subnetMask),
              semanticLabel: 'subnet mask',
              octet1ReadOnly: true,
              octet2ReadOnly: true,
              controller: subnetMaskController,
              errorText: state.errorTextMap['subnetMask'],
              border: const OutlineInputBorder(),
              onChanged: (value) {
                setState(() {
                  final result = subnetMaskFinished(value);
                  _notifier.updateState(result.$2);
                  _notifier.updateErrorPrompts(
                    'subnetMask',
                    result.$1 ? null : loc(context).invalidSubnetMask,
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _dhcpServerView() {
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

  bool _isEdited(LocalNetworkSettingsState state) {
    return !originalSettings.isEqualStateWithoutDhcpReservationList(state);
  }

  bool _hasError(LocalNetworkSettingsState state) {
    return state.errorTextMap.isNotEmpty;
  }

  (bool, LocalNetworkSettingsState) routerIpAddressFinished(String ipAddress) {
    final state = ref.read(localNetworkSettingProvider);
    // Host IP input finishes
    return _notifier.routerIpAddressFinished(
      ipAddress,
      state,
    );
  }

  (bool, LocalNetworkSettingsState) subnetMaskFinished(String subnetMask) {
    final state = ref.read(localNetworkSettingProvider);
    return ref.read(localNetworkSettingProvider.notifier).subnetMaskFinished(
          subnetMask,
          state,
        );
  }

  void _saveSettings() {
    final state = ref.read(localNetworkSettingProvider);
    doSomethingWithSpinner(
      context,
      _notifier
          .saveSettings(state, previousIPAddress: originalSettings.ipAddress)
          .then(
        (value) {
          setState(() {
            originalSettings = state;
          });
          showSuccessSnackBar(context, loc(context).changesSaved);
        },
      ).catchError((error) {
        showRouterNotFoundAlert(context, ref, onComplete: () async {
          // Update the state
          await _notifier.fetch(fetchRemote: true);
          // Update instant safety
          await ref.read(instantSafetyProvider.notifier).fetchLANSettings();
          setState(() {
            originalSettings = state;
          });
          showSuccessSnackBar(context, loc(context).changesSaved);
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
      }),
    );
  }
}
