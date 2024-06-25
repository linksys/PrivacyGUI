import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

class PortForwardingView extends ArgumentsConsumerStatelessView {
  const PortForwardingView({super.key, super.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PortForwardingContentView(
      args: super.args,
    );
  }
}

class PortForwardingContentView extends ArgumentsConsumerStatefulView {
  const PortForwardingContentView({super.key, super.args});

  @override
  ConsumerState<PortForwardingContentView> createState() =>
      _PortForwardingContentViewState();
}

class _PortForwardingContentViewState
    extends ConsumerState<PortForwardingContentView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      title: loc(context).portSettings,
      child: AppBasicLayout(
        content: Column(
          children: [
            AppListCard(
              padding: const EdgeInsets.all(Spacing.large2),
              title: AppText.labelLarge(loc(context).singlePortForwarding),
              trailing: const Icon(LinksysIcons.chevronRight),
              onTap: () {
                context.pushNamed(RouteNamed.singlePortForwardingList);
              },
            ),
            AppListCard(
              padding: const EdgeInsets.all(Spacing.large2),
              title: AppText.labelLarge(loc(context).portRangeForwarding),
              trailing: const Icon(LinksysIcons.chevronRight),
              onTap: () {
                context.pushNamed(RouteNamed.portRangeForwardingList);
              },
            ),
            AppListCard(
              padding: const EdgeInsets.all(Spacing.large2),
              title: AppText.labelLarge(loc(context).portRangeTriggering),
              trailing: const Icon(LinksysIcons.chevronRight),
              onTap: () {
                context.pushNamed(RouteNamed.portRangeTriggeringList);
              },
            ),
          ],
        ),
      ),
    );
  }
}
