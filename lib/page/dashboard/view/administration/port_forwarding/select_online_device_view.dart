import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class SelectOnlineDeviceView extends ArgumentsConsumerStatelessView {
  const SelectOnlineDeviceView({super.key, super.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SelectOnlineDeviceContentView(
      args: super.args,
    );
  }
}

class SelectOnlineDeviceContentView extends ArgumentsConsumerStatefulView {
  const SelectOnlineDeviceContentView({super.key, super.args});

  @override
  ConsumerState<SelectOnlineDeviceContentView> createState() =>
      _SelectOnlineDeviceContentViewState();
}

class _SelectOnlineDeviceContentViewState
    extends ConsumerState<SelectOnlineDeviceContentView> {
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
      title: getAppLocalizations(context).single_port_forwarding,
      child: AppBasicLayout(
        content: Column(
          children: [
            const AppGap.semiBig(),
            AppPanelWithInfo(
              title: getAppLocalizations(context).single_port_forwarding,
              infoText: '',
              onTap: () {},
            ),
            AppPanelWithInfo(
              title: getAppLocalizations(context).port_range_forwarding,
              infoText: '',
              onTap: () {},
            ),
            AppPanelWithInfo(
              title: getAppLocalizations(context).port_range_triggering,
              infoText: '',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
