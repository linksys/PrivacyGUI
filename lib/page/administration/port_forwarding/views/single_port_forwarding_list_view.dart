import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/administration/port_forwarding/_port_forwarding.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

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

  @override
  void initState() {
    _notifier = ref.read(singlePortForwardingListProvider.notifier);
    _notifier.fetch();

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
      title: getAppLocalizations(context).single_port_forwarding,
      actions: [
        AppTextButton(
          getAppLocalizations(context).edit,
          onTap: () {
            // TODO
          },
        ),
      ],
      scrollable: true,
      child: AppBasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppGap.semiBig(),
            AppText.bodyLarge(getAppLocalizations(context)
                .single_port_forwarding_description),
            if (!_notifier.isExceedMax())
              AppTextButton(
                getAppLocalizations(context).add_rule,
                onTap: () {
                  context.pushNamed<bool?>(RouteNamed.singlePortForwardingRule,
                      extra: {'rules': state.rules}).then((value) {
                    if (value ?? false) {
                      _notifier.fetch();
                    }
                  });
                },
              ),
            const AppGap.semiBig(),
            ...state.rules.map(
              (e) => AppPanelWithInfo(
                title: e.description,
                infoText: e.isEnabled
                    ? getAppLocalizations(context).on
                    : getAppLocalizations(context).off,
                forcedHidingAccessory: true,
                onTap: () {
                  context.pushNamed<bool?>(RouteNamed.singlePortForwardingRule,
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
            ),
          ],
        ),
      ),
    );
  }
}
