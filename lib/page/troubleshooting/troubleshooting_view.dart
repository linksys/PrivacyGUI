import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/constants/build_config.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/provider/auth/auth_provider.dart';
import 'package:linksys_app/provider/troubleshooting/device_status.dart';
import 'package:linksys_app/provider/troubleshooting/troubleshooting_provider.dart';
import 'package:linksys_app/provider/troubleshooting/troubleshooting_state.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/theme/const/spacing.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';

class TroubleshootingView extends ArgumentsConsumerStatefulView {
  const TroubleshootingView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<TroubleshootingView> createState() =>
      _TroubleshootingViewState();
}

class _TroubleshootingViewState extends ConsumerState<TroubleshootingView> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    setState(() {
      _isLoading = true;
    });
    ref.read(troubleshootingProvider.notifier).fetch().then((value) {
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();

    _emailController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(troubleshootingProvider);
    return _isLoading
        ? const AppFullScreenSpinner()
        : StyledAppPageView(
            scrollable: true,
            title: 'Troubleshooting',
            actions: [
              AppIconButton.noPadding(
                icon: getCharactersIcons(context).refreshDefault,
                onTap: () {
                  ref.read(troubleshootingProvider.notifier).fetch(force: true);
                },
              )
            ],
            child: AppBasicLayout(
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Table(
                    border: TableBorder.all(
                        color: Theme.of(context).colorScheme.onBackground),
                    children: [
                      TableRow(
                        children: [
                          _paddingTableCell(
                            child: const AppText.labelMedium('Name'),
                          ),
                          _paddingTableCell(
                            child: const AppText.labelMedium('Mac Address'),
                          ),
                          _paddingTableCell(
                            child: const AppText.labelMedium('Ip Address'),
                          ),
                          _paddingTableCell(
                            child: const AppText.labelMedium('Connection'),
                          ),
                        ],
                      ),
                      ...state.deviceStatusList
                          .where((element) =>
                              element.type == DeviceStatusType.ipv4)
                          .map(
                            (e) => TableRow(
                              children: [
                                _paddingTableCell(
                                    child: AppText.bodyMedium(e.name)),
                                _paddingTableCell(
                                    child: AppText.bodyMedium(e.mac)),
                                _paddingTableCell(
                                    child: AppText.bodyMedium(e.ipAddress)),
                                _paddingTableCell(
                                    child: AppText.bodyMedium(e.connection)),
                              ],
                            ),
                          ),
                    ],
                  ),
                  const AppGap.big(),
                  Table(
                    border: TableBorder.all(
                        color: Theme.of(context).colorScheme.onBackground),
                    children: [
                      TableRow(
                        children: [
                          _paddingTableCell(
                            child: const AppText.labelMedium('Name'),
                          ),
                          _paddingTableCell(
                            child: const AppText.labelMedium('Mac Address'),
                          ),
                          _paddingTableCell(
                            child: const AppText.labelMedium('Ipv6 Address'),
                          ),
                          _paddingTableCell(
                            child: const AppText.labelMedium('Connection'),
                          ),
                        ],
                      ),
                      ...state.deviceStatusList
                          .where((element) =>
                              element.type == DeviceStatusType.ipv6)
                          .map(
                            (e) => TableRow(
                              children: [
                                _paddingTableCell(
                                    child: AppText.bodyMedium(e.name)),
                                _paddingTableCell(
                                    child: AppText.bodyMedium(e.mac)),
                                _paddingTableCell(
                                    child: AppText.bodyMedium(e.ipAddress)),
                                _paddingTableCell(
                                    child: AppText.bodyMedium(e.connection)),
                              ],
                            ),
                          ),
                    ],
                  ),
                  const AppGap.big(),
                  AppTextButton(
                    'Ping',
                    onTap: () {
                      context.pushNamed(RouteNamed.troubleshootingPing);
                    },
                  ),
                  AppTextButton(
                    'DHCP Client',
                    onTap: () => showDhcpSheet(state),
                  ),
                  AppTextButton(
                    'Share router info with Linksys',
                    onTap: () => showSendRouterInfoDialog(),
                  ),
                  if (ref.read(authProvider).value?.loginType ==
                          LoginType.local ||
                      BuildConfig.forceCommandType == ForceCommand.local)
                    AppTextButton(
                      'Factory Reset',
                      onTap: () {
                        showAlertDialog<bool>(
                            context: context,
                            title: 'Important',
                            message:
                                'When you reset your router, it reboots, disconnects from the internet and clears all current settings. All devices connected to the router will also be disconnected. When the reset completes, the router will need to be set up again and then all devices will have to reconnect using the new settings.\n\nDo you want to continue?',
                            actions: [
                              const AlertDialogAction<bool>(
                                  key: true, label: 'Yes'),
                              const AlertDialogAction<bool>(
                                  key: false, label: 'No'),
                            ]).then((value) {
                          if ((value ?? false)) {
                            ref
                                .read(troubleshootingProvider.notifier)
                                .factoryReset()
                                .then((value) {
                              ref.read(authProvider.notifier).logout();
                            });
                          } else {}
                        });
                      },
                    ),
                ],
              ),
            ),
          );
  }

  Widget _paddingTableCell({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.semiSmall),
      child: child,
    );
  }

  void showDhcpSheet(TroubleshootingState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (context) {
        return Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: AppIconButton.noPadding(
                icon: getCharactersIcons(context).crossDefault,
                onTap: () {
                  context.pop();
                },
              ),
            ),
            const AppGap.big(),
            Table(
              border: TableBorder.all(
                  color: Theme.of(context).colorScheme.onBackground),
              children: [
                TableRow(
                  children: [
                    _paddingTableCell(
                      child: const AppText.labelMedium('Name'),
                    ),
                    _paddingTableCell(
                      child: const AppText.labelMedium('Interface'),
                    ),
                    _paddingTableCell(
                      child: const AppText.labelMedium('Ip Address'),
                    ),
                    _paddingTableCell(
                      child: const AppText.labelMedium('MAC Address'),
                    ),
                    _paddingTableCell(
                      child: const AppText.labelMedium('Expires Time'),
                    ),
                  ],
                ),
                ...state.dhchClientList.map(
                  (e) => TableRow(
                    children: [
                      _paddingTableCell(child: AppText.bodyMedium(e.name)),
                      _paddingTableCell(child: AppText.bodyMedium(e.interface)),
                      _paddingTableCell(child: AppText.bodyMedium(e.ipAddress)),
                      _paddingTableCell(child: AppText.bodyMedium(e.mac)),
                      _paddingTableCell(child: AppText.bodyMedium(e.expires)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void showSendRouterInfoDialog() {
    showAdaptiveDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.all(20),
        scrollable: true,
        title: const AppText.titleMedium('Send logs'),
        content: const AppText.bodyMedium(
            "Your logs help the Linksys team improve the app and diagnose your router. Don't worry, no private information is shared."),
        actions: [
          AppTextButton(
            'Share logs',
            onTap: () {
              context.pop();
              showVerifyEmailDialog();
            },
          ),
        ],
      ),
    );
  }

  void showVerifyEmailDialog() {
    showAdaptiveDialog(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        insetPadding: const EdgeInsets.all(20),
        title: const AppText.titleMedium('Verify email'),
        content: Column(
          children: [
            AppTextField(
              controller: _emailController,
              hintText: '(optional)',
              onFocusChanged: (hasFocus) {},
            ),
            const AppGap.small(),
            const AppText.bodyMedium(
                "Send to multiple emails by separating them with a comma."),
          ],
        ),
        actions: [
          AppTextButton(
            'Cancel',
            onTap: () {
              context.pop();
            },
          ),
          AppTextButton(
            'Share logs',
            onTap: () {
              ref
                  .read(troubleshootingProvider.notifier)
                  .sendRouterInfo(userEmailList: _emailController.text);
              context.pop();
            },
          ),
        ],
      ),
    );
  }
}
