import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/provider/port_forwarding/port_range_forwarding_list/port_range_forwarding_list_provider.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class PortRangeForwardingListView extends ArgumentsConsumerStatelessView {
  const PortRangeForwardingListView({super.key, super.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PortRangeForwardingListContentView(
      args: super.args,
    );
  }
}

class PortRangeForwardingListContentView extends ArgumentsConsumerStatefulView {
  const PortRangeForwardingListContentView({super.key, super.args});

  @override
  ConsumerState<PortRangeForwardingListContentView> createState() =>
      _PortRangeForwardingContentViewState();
}

class _PortRangeForwardingContentViewState
    extends ConsumerState<PortRangeForwardingListContentView> {
  late final PortRangeForwardingListNotifier _notifier;

  @override
  void initState() {
    _notifier = ref.read(portRangeForwardingListProvider.notifier);
    _notifier.fetch();

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(portRangeForwardingListProvider);
    return StyledAppPageView(
      scrollable: true,
      title: getAppLocalizations(context).port_range_forwarding,
      actions: [
        AppTextButton(
          getAppLocalizations(context).edit,
          onTap: () {
            // TODO
          },
        ),
      ],
      child: AppBasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppGap.semiBig(),
            AppText.bodyLarge(
                getAppLocalizations(context).port_range_forwarding_description),
            if (!_notifier.isExceedMax())
              AppTextButton(
                getAppLocalizations(context).add_rule,
                onTap: () {
                  context.pushNamed<bool?>(RouteNamed.portRangeForwardingRule,
                      extra: {'rules': state.rules}).then((value) {
                    if (value ?? false) {
                      _notifier.fetch();
                    }
                  });
                },
              ),
            const AppGap.semiBig(),
            ...state.rules.map((e) => AppPanelWithInfo(
                  onTap: () {
                    context.pushNamed<bool?>(RouteNamed.portRangeForwardingRule,
                        extra: {'rules': state.rules, 'edit': e}).then((value) {
                      if (value ?? false) {
                        _notifier.fetch();
                      }
                    });
                  },
                  title: e.description,
                  infoText: e.isEnabled
                      ? getAppLocalizations(context).on
                      : getAppLocalizations(context).off,
                )),
          ],
        ),
      ),
    );
  }
}
