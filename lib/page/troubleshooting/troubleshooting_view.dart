import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/provider/troubleshooting/device_status.dart';
import 'package:linksys_app/provider/troubleshooting/troubleshooting_provider.dart';
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
                  Align(
                      alignment: Alignment.centerLeft,
                      child: AppTextButton(
                        'Ping',
                        onTap: () {
                          context.pushNamed(RouteNamed.troubleshootingPing);
                        },
                      )),
                  const AppGap.big(),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AppTextButton(
                      'DHCP Client',
                      onTap: () {
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
                                      icon: getCharactersIcons(context)
                                          .crossDefault,
                                      onTap: () {
                                        context.pop();
                                      },
                                    ),
                                  ),
                                  const AppGap.big(),
                                  Table(
                                    border: TableBorder.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onBackground),
                                    children: [
                                      TableRow(
                                        children: [
                                          _paddingTableCell(
                                            child: const AppText.labelMedium(
                                                'Name'),
                                          ),
                                          _paddingTableCell(
                                            child: const AppText.labelMedium(
                                                'Interface'),
                                          ),
                                          _paddingTableCell(
                                            child: const AppText.labelMedium(
                                                'Ip Address'),
                                          ),
                                          _paddingTableCell(
                                            child: const AppText.labelMedium(
                                                'MAC Address'),
                                          ),
                                          _paddingTableCell(
                                            child: const AppText.labelMedium(
                                                'Expires Time'),
                                          ),
                                        ],
                                      ),
                                      ...state.dhchClientList.map(
                                        (e) => TableRow(
                                          children: [
                                            _paddingTableCell(
                                                child:
                                                    AppText.bodyMedium(e.name)),
                                            _paddingTableCell(
                                                child: AppText.bodyMedium(
                                                    e.interface)),
                                            _paddingTableCell(
                                                child: AppText.bodyMedium(
                                                    e.ipAddress)),
                                            _paddingTableCell(
                                                child:
                                                    AppText.bodyMedium(e.mac)),
                                            _paddingTableCell(
                                                child: AppText.bodyMedium(
                                                    e.expires)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            });
                      },
                    ),
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
}
