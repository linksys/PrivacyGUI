import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/widgets/_widgets.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_state.dart';
import 'package:privacy_gui/providers/redirection/redirection_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/input_field/ip_form_field.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:privacygui_widgets/widgets/progress_bar/full_screen_spinner.dart';
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
  bool _isLoading = true;
  late LocalNetworkSettingsState originalSettings;

  @override
  void initState() {
    super.initState();
    ref.read(localNetworkSettingProvider.notifier).fetch().then((value) {
      setState(() {
        originalSettings =
            ref.read(localNetworkSettingProvider.notifier).currentSettings();
        _isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
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
      bottomBar: PageBottomBar(
        isPositiveEnabled: _isEdited(),
        onPositiveTap: _saveSettings,
      ),
      onBackTap: _isEdited()
          ? () async {
              final goBack = await showUnsavedAlert(context);
              if (goBack == true) {
                context.pop();
              }
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
                _showHostNameEditDialog(state.hostName);
              },
            ),
            InternetSettingCard(
              title: loc(context).ipAddress.capitalizeWords(),
              description: state.ipAddress,
              onTap: () {
                _showIpAddressEditDialog(state.ipAddress);
              },
            ),
            InternetSettingCard(
              title: loc(context).subnetMask,
              description: state.subnetMask,
              onTap: () {
                _showSubnetMaskEditDialog(state.subnetMask);
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
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
              trailing: Row(
                children: [
                  AppText.labelLarge('${state.dhcpReservationList.length}'),
                  const Icon(LinksysIcons.chevronRight),
                ],
              ),
              onTap: () async {
                await context.pushNamed(RouteNamed.dhcpReservation);
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

  void _showHostNameEditDialog(String hostName) {
    final textController = TextEditingController();
    textController.text = hostName;
    String? errorDesc;
    bool enableButton = false;
    showSubmitAppDialog(
      context,
      title: loc(context).hostName.capitalizeWords(),
      contentBuilder: (context, setState) {
        return AppTextField(
          headerText: loc(context).hostName.capitalizeWords(),
          controller: textController,
          errorText: errorDesc,
          border: const OutlineInputBorder(),
          onChanged: (value) {
            if (value.isEmpty) {
              setState(() {
                enableButton = false;
                errorDesc = loc(context).hostNameCannotEmpty;
              });
            } else if (value != hostName) {
              setState(() {
                enableButton = true;
                errorDesc = null;
              });
            } else {
              setState(() {
                enableButton = false;
                errorDesc = null;
              });
            }
          },
        );
      },
      event: () async {
        ref
            .read(localNetworkSettingProvider.notifier)
            .updateHostName(textController.text);
      },
      checkPositiveEnabled: () => enableButton,
    );
  }

  void _showIpAddressEditDialog(String ipAddress) {
    final textController = TextEditingController();
    textController.text = ipAddress;
    String? errorDesc;
    bool enableButton = false;
    showSubmitAppDialog(
      context,
      title: loc(context).ipAddress.capitalizeWords(),
      contentBuilder: (context, setState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIPFormField(
              controller: textController,
              errorText: errorDesc,
              border: const OutlineInputBorder(),
              onChanged: (value) {
                if (value.isEmpty) {
                  setState(() {
                    enableButton = false;
                    errorDesc = loc(context).invalidIpAddress;
                  });
                } else if (value == ipAddress) {
                  setState(() {
                    enableButton = false;
                    errorDesc = null;
                  });
                } else {
                  final result = routerIpAddressFinished(textController.text);
                  if (result.$1 == false) {
                    setState(() {
                      errorDesc = loc(context).invalidIpAddress;
                      enableButton = false;
                    });
                  } else {
                    setState(() {
                      enableButton = true;
                      errorDesc = null;
                    });
                  }
                }
              },
            ),
          ],
        );
      },
      event: () async {
        // Host IP input finishes
        final result = routerIpAddressFinished(textController.text);
        if (result.$1 == false) {
          setState(() {
            errorDesc = loc(context).invalidIpAddress;
          });
        } else {
          ref.read(localNetworkSettingProvider.notifier).updateState(result.$2);
        }
      },
      checkPositiveEnabled: () => enableButton,
    );
  }

  (bool, LocalNetworkSettingsState) routerIpAddressFinished(String ipAddress) {
    final state = ref.read(localNetworkSettingProvider);
    // Host IP input finishes
    return ref
        .read(localNetworkSettingProvider.notifier)
        .routerIpAddressFinished(
          ipAddress,
          state,
        );
  }

  void _showSubnetMaskEditDialog(String subnetMask) {
    final textController = TextEditingController();
    textController.text = subnetMask;
    String? errorDesc;
    bool enableButton = false;
    showSubmitAppDialog(
      context,
      title: loc(context).ipAddress.capitalizeWords(),
      contentBuilder: (context, setState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIPFormField(
              octet1ReadOnly: true,
              octet2ReadOnly: true,
              controller: textController,
              errorText: errorDesc,
              border: const OutlineInputBorder(),
              onChanged: (value) {
                if (value.isEmpty) {
                  setState(() {
                    enableButton = false;
                    errorDesc = loc(context).invalidIpAddress;
                  });
                } else if (value == subnetMask) {
                  setState(() {
                    enableButton = false;
                    errorDesc = null;
                  });
                } else {
                  final result = subnetMaskFinished(textController.text);
                  if (result.$1 == false) {
                    setState(() {
                      enableButton = false;
                      errorDesc = loc(context).invalidSubnetMask;
                    });
                  } else {
                    setState(() {
                      enableButton = true;
                      errorDesc = null;
                    });
                  }
                }
              },
            ),
          ],
        );
      },
      event: () async {
        final result = subnetMaskFinished(textController.text);
        if (result.$1 == false) {
          setState(() {
            errorDesc = loc(context).invalidSubnetMask;
          });
        } else {
          ref.read(localNetworkSettingProvider.notifier).updateState(result.$2);
        }
      },
      checkPositiveEnabled: () => enableButton,
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
    setState(() {
      _isLoading = true;
    });
    final state = ref.read(localNetworkSettingProvider);
    ref.read(localNetworkSettingProvider.notifier).saveSettings(state).then(
      (value) {
        originalSettings = state;
        showSuccessSnackBar(context, loc(context).changesSaved);
      },
    ).catchError(
      (error, stackTrace) {
        final err = error as JNAPError;
        showFailedSnackBar(context, err.result);
      },
      test: (error) => error is JNAPError,
    ).whenComplete(() {
      setState(() {
        _isLoading = false;
      });
    });
  }
}
