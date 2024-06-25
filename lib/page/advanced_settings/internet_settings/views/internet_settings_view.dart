// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/advanced_settings/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/gap/gap.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:privacygui_widgets/widgets/progress_bar/full_screen_spinner.dart';

import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/_internet_settings.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/route/constants.dart';

enum InternetSettingsViewType {
  ipv4,
  ipv6,
}

enum PPTPIpAddressMode {
  dhcp,
  specify,
}

class InternetSettingsView extends ArgumentsConsumerStatelessView {
  const InternetSettingsView({super.key, super.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InternetSettingsContentView(
      args: super.args,
    );
  }
}

class InternetSettingsContentView extends ArgumentsConsumerStatefulView {
  const InternetSettingsContentView({super.key, super.args});

  @override
  ConsumerState<InternetSettingsContentView> createState() =>
      _InternetSettingsContentViewState();
}

class _InternetSettingsContentViewState
    extends ConsumerState<InternetSettingsContentView> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    ref.read(internetSettingsProvider.notifier).fetch().then((value) {
      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(internetSettingsProvider);
    return isLoading
        ? const AppFullScreenSpinner()
        : StyledAppPageView(
            scrollable: true,
            title: loc(context).internetSettings,
            child: AppBasicLayout(
              content: Column(
                children: [
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        InternetSettingCard(
                          title: loc(context).ipv4,
                          showBorder: false,
                          onTap: () {
                            context
                                .pushNamed(RouteNamed.connectionType, extra: {
                              'viewType': InternetSettingsViewType.ipv4,
                            });
                          },
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: Spacing.large2),
                          child: Divider(),
                        ),
                        InternetSettingCard(
                          title: loc(context).ipv6,
                          showBorder: false,
                          onTap: () {
                            context.pushNamed(
                              RouteNamed.connectionType,
                              extra: {
                                'viewType': InternetSettingsViewType.ipv6,
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const AppGap.medium(),
                  InternetSettingCard(
                    title: loc(context).macAddressClone.capitalizeWords(),
                    description:
                        state.macClone ? loc(context).on : loc(context).off,
                    onTap: state.ipv4Setting.ipv4ConnectionType ==
                            WanType.bridge.type
                        ? null
                        : () {
                            context.pushNamed(RouteNamed.macClone);
                          },
                  ),
                ],
              ),
            ),
          );
  }
}
