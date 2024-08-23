import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/port_forwarding/_port_forwarding.dart';
import 'package:privacy_gui/page/advanced_settings/port_forwarding/views/widgets/_widgets.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';

import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/util/semantic.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

class SinglePortForwardingListView extends ArgumentsConsumerStatelessView {
  const SinglePortForwardingListView({super.key, super.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SinglePortForwardingListContentView(
      args: super.args,
    );
  }
}

class SinglePortForwardingListContentView
    extends ArgumentsConsumerStatefulView {
  const SinglePortForwardingListContentView({super.key, super.args});

  @override
  ConsumerState<SinglePortForwardingListContentView> createState() =>
      _SinglePortForwardingContentViewState();
}

class _SinglePortForwardingContentViewState
    extends ConsumerState<SinglePortForwardingListContentView> {
  late final SinglePortForwardingListNotifier _notifier;
  final String _tag = 'single-port-forwarding';

  @override
  void initState() {
    _notifier = ref.read(singlePortForwardingListProvider.notifier);
    doSomethingWithSpinner(
      context,
      _notifier.fetch(),
    );

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(singlePortForwardingListProvider);
    return StyledAppPageView(
      title: loc(context).singlePortForwarding,
      scrollable: true,
      child: AppBasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppGap.large2(),
            AppText.bodyLarge(
              loc(context).singlePortForwardingDescription,
              identifier: semanticIdentifier(
                  tag: _tag, description: 'singlePortForwardingDescription'),
            ),
            if (!_notifier.isExceedMax()) ...[
              const AppGap.large2(),
              AddRuleCard(
                identifier: semanticIdentifier(
                    tag: _tag, description: 'singlePortForwardingRule'),
                semanticLabel: '${loc(context).forwardedRange} add',
                onTap: () {
                  context.pushNamed<bool?>(RouteNamed.singlePortForwardingRule,
                      extra: {'rules': state.rules}).then((value) {
                    if (value ?? false) {
                      _notifier.fetch();
                    }
                  });
                },
              ),
            ],
            const AppGap.large2(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.labelLarge(
                  loc(context).rules,
                  identifier: semanticIdentifier(
                      tag: _tag, description: 'rules'),
                ),
                const AppGap.medium(),
                if (state.rules.isNotEmpty)
                  ...state.rules
                      .map(
                    (e) => RuleItemCard(
                      title: e.description,
                      identifier: semanticIdentifier(
                          tag: _tag, description: e.description),
                      semanticLabel: 'edit ${e.description}',
                      isEnabled: e.isEnabled,
                      onTap: () {
                        context.pushNamed<bool?>(
                            RouteNamed.singlePortForwardingRule,
                            extra: {
                              'rules': state.rules,
                              'edit': e
                            }).then((value) {
                          if (value ?? false) {
                            _notifier.fetch();
                          }
                        });
                      },
                    ),
                  )
                      .expand((element) sync* {
                    yield element;
                    yield const AppGap.small2();
                  }),
                if (state.rules.isEmpty) const EmptyRuleCard(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
