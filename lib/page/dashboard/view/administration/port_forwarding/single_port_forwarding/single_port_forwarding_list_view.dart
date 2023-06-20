import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/dashboard/view/administration/port_forwarding/single_port_forwarding/bloc/single_port_forwarding_list_cubit.dart';
import 'package:linksys_moab/core/jnap/router_repository.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class SinglePortForwardingListView extends ArgumentsConsumerStatelessView {
  const SinglePortForwardingListView({super.key, super.next, super.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BlocProvider<SinglePortForwardingListCubit>(
      create: (context) => SinglePortForwardingListCubit(
          repository: context.read<RouterRepository>()),
      child: SinglePortForwardingListContentView(
        next: super.next,
        args: super.args,
      ),
    );
  }
}

class SinglePortForwardingListContentView
    extends ArgumentsConsumerStatefulView {
  const SinglePortForwardingListContentView(
      {super.key, super.next, super.args});

  @override
  ConsumerState<SinglePortForwardingListContentView> createState() =>
      _SinglePortForwardingContentViewState();
}

class _SinglePortForwardingContentViewState
    extends ConsumerState<SinglePortForwardingListContentView> {
  late final SinglePortForwardingListCubit _cubit;

  @override
  void initState() {
    _cubit = context.read<SinglePortForwardingListCubit>();
    _cubit.fetch();

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SinglePortForwardingListCubit,
        SinglePortForwardingListState>(builder: (context, state) {
      return StyledAppPageView(
        title: getAppLocalizations(context).single_port_forwarding,
        actions: [
          AppTertiaryButton(
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
              AppText.descriptionMain(getAppLocalizations(context)
                  .single_port_forwarding_description),
              if (!_cubit.isExceedMax())
                AppTertiaryButton(
                  getAppLocalizations(context).add_rule,
                  onTap: () {
                    ref
                        .read(navigationsProvider.notifier)
                        .pushAndWait(SinglePortForwardingRulePath()
                          ..args = {'rules': state.rules})
                        .then((value) {
                      if (value ?? false) {
                        _cubit.fetch();
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
                    ref
                        .read(navigationsProvider.notifier)
                        .pushAndWait(SinglePortForwardingRulePath()
                          ..args = {'rules': state.rules, 'edit': e})
                        .then((value) {
                      if (value ?? false) {
                        _cubit.fetch();
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
