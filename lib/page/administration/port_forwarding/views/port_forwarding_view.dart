import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

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
      title: getAppLocalizations(context).port_forwarding,
      child: AppBasicLayout(
        content: Column(
          children: [
            const AppGap.semiBig(),
            AppSimplePanel(
              title: getAppLocalizations(context).single_port_forwarding,
              onTap: () {
                context.pushNamed(RouteNamed.singlePortForwardingList);
              },
            ),
            AppSimplePanel(
              title: getAppLocalizations(context).port_range_forwarding,
              onTap: () {
                context.pushNamed(RouteNamed.portRangeForwardingList);
              },
            ),
            AppSimplePanel(
              title: getAppLocalizations(context).port_range_triggering,
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
