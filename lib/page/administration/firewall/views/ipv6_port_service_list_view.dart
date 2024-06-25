import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/administration/firewall/providers/ipv6_port_service_list_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

import '../../port_forwarding/views/widgets/_widgets.dart';

class Ipv6PortServiceListView extends ArgumentsConsumerStatefulView {
  const Ipv6PortServiceListView({super.key, super.args});

  @override
  ConsumerState<Ipv6PortServiceListView> createState() =>
      _Ipv6PortServiceListViewState();
}

class _Ipv6PortServiceListViewState
    extends ConsumerState<Ipv6PortServiceListView> {
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
      title: loc(context).ipv6PortServices,
      child: AppBasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.bodyLarge(loc(context).ipv6PortServices),
            if (!_notifier.isExceedMax()) ...[
              const AppGap.large2(),
              AddRuleCard(
                onTap: () {
                  context.pushNamed<bool?>(RouteNamed.ipv6PortServiceRule,
                      extra: {'rules': state.rules}).then((value) {
                    if (value ?? false) {
                      _notifier.fetch(true);
                    }
                  });
                },
              ),
            ],
            const AppGap.large2(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.labelLarge(loc(context).rules),
                const AppGap.medium(),
                if (state.rules.isNotEmpty)
                  ...state.rules.map(
                    (e) => RuleItemCard(
                      title: e.description,
                      isEnabled: e.isEnabled,
                      onTap: () {
                        context.pushNamed<bool?>(RouteNamed.ipv6PortServiceRule,
                            extra: {
                              'rules': state.rules,
                              'edit': e
                            }).then((value) {
                          if (value ?? false) {
                            _notifier.fetch(true);
                          }
                        });
                      },
                    ),
                  ),
                if (state.rules.isEmpty) const EmptyRuleCard(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
