import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/dashboard/view/administration/port_forwarding/port_range_triggering/bloc/port_range_triggering_list_cubit.dart';
import 'package:linksys_moab/core/jnap/router_repository.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class PortRangeTriggeringListView extends ArgumentsConsumerStatelessView {
  const PortRangeTriggeringListView({super.key, super.next, super.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BlocProvider<PortRangeTriggeringListCubit>(
      create: (context) => PortRangeTriggeringListCubit(
          repository: context.read<RouterRepository>()),
      child: PortRangeTriggeringListContentView(
        next: super.next,
        args: super.args,
      ),
    );
  }
}

class PortRangeTriggeringListContentView extends ArgumentsConsumerStatefulView {
  const PortRangeTriggeringListContentView({super.key, super.next, super.args});

  @override
  ConsumerState<PortRangeTriggeringListContentView> createState() =>
      _PortRangeTriggeringContentViewState();
}

class _PortRangeTriggeringContentViewState
    extends ConsumerState<PortRangeTriggeringListContentView> {
  late final PortRangeTriggeringListCubit _cubit;

  @override
  void initState() {
    _cubit = context.read<PortRangeTriggeringListCubit>();
    _cubit.fetch();

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PortRangeTriggeringListCubit,
        PortRangeTriggeringListState>(builder: (context, state) {
      return StyledAppPageView(
        scrollable: true,
        title: getAppLocalizations(context).port_range_triggering,
        actions: [
          AppTertiaryButton(
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
              AppText.descriptionMain(getAppLocalizations(context)
                  .port_range_triggering_description),
              if (!_cubit.isExceedMax())
                AppTertiaryButton(
                  getAppLocalizations(context).add_rule,
                  onTap: () {
                    ref
                        .read(navigationsProvider.notifier)
                        .pushAndWait(PortRangeTriggeringRulePath()
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
