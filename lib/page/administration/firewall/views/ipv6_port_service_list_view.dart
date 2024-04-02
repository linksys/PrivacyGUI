import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/page/administration/firewall/providers/ipv6_port_service_list_provider.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class Ipv6PortServiceListView extends ArgumentsConsumerStatelessView {
  const Ipv6PortServiceListView({super.key, super.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Ipv6PortServiceListContentView(
      args: super.args,
    );
  }
}

class Ipv6PortServiceListContentView extends ArgumentsConsumerStatefulView {
  const Ipv6PortServiceListContentView({super.key, super.args});

  @override
  ConsumerState<Ipv6PortServiceListContentView> createState() =>
      _Ipv6PortServiceListContentViewState();
}

class _Ipv6PortServiceListContentViewState
    extends ConsumerState<Ipv6PortServiceListContentView> {
  late final Ipv6PortServiceListNotifier _notifier;

  @override
  void initState() {
    _notifier = ref.read(ipv6PortServiceListProvider.notifier);
    _notifier.fetch();

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ipv6PortServiceListProvider);
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
            const AppText.bodyLarge('Ipv6 port service'),
            if (!_notifier.isExceedMax())
              AppTextButton(
                getAppLocalizations(context).add_rule,
                onTap: () {
                  context.pushNamed<bool?>(RouteNamed.ipv6PortServiceRule,
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
                    context.pushNamed<bool?>(RouteNamed.ipv6PortServiceRule,
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
