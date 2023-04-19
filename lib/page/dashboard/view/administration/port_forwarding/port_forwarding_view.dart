import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class PortForwardingView extends ArgumentsConsumerStatelessView {
  const PortForwardingView({super.key, super.next, super.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PortForwardingContentView(
      next: super.next,
      args: super.args,
    );
  }
}

class PortForwardingContentView extends ArgumentsConsumerStatefulView {
  const PortForwardingContentView({super.key, super.next, super.args});

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
                ref
                    .read(navigationsProvider.notifier)
                    .push(SinglePortForwardingListPath());
              },
            ),
            AppSimplePanel(
              title: getAppLocalizations(context).port_range_forwarding,
              onTap: () {
                ref
                    .read(navigationsProvider.notifier)
                    .push(PortRangeForwardingListPath());
              },
            ),
            AppSimplePanel(
              title: getAppLocalizations(context).port_range_triggering,
              onTap: () {
                ref
                    .read(navigationsProvider.notifier)
                    .push(PortRangeTriggeringListPath());
              },
            ),
          ],
        ),
      ),
    );
  }
}
