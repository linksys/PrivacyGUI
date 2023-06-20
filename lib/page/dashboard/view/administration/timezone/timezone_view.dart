import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/shortcuts/snack_bar.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/dashboard/view/administration/timezone/bloc/cubit.dart';
import 'package:linksys_moab/page/dashboard/view/administration/timezone/bloc/state.dart';
import 'package:linksys_moab/core/jnap/router_repository.dart';
import 'package:linksys_moab/util/timezone.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class TimezoneView extends ArgumentsConsumerStatelessView {
  const TimezoneView({super.key, super.next, super.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BlocProvider(
      create: (context) => TimezoneCubit(context.read<RouterRepository>()),
      child: TimezoneContentView(
        next: super.next,
        args: super.args,
      ),
    );
  }
}

class TimezoneContentView extends ArgumentsConsumerStatefulView {
  const TimezoneContentView({Key? key, super.args, super.next})
      : super(key: key);

  @override
  ConsumerState<TimezoneContentView> createState() =>
      _TimezoneContentViewState();
}

class _TimezoneContentViewState extends ConsumerState<TimezoneContentView> {
  late final TimezoneCubit _cubit;

  @override
  void initState() {
    _cubit = context.read<TimezoneCubit>();
    _cubit.fetch();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TimezoneCubit, TimezoneState>(builder: (context, state) {
      return StyledAppPageView(
        scrollable: true,
        title: getAppLocalizations(context).timezone,
        actions: [
          AppTertiaryButton(
            getAppLocalizations(context).save,
            onTap: () {
              _cubit.save().then((_) => showSuccessSnackBar(
                  context, getAppLocalizations(context).timezone_updated));
            },
          ),
        ],
        child: AppBasicLayout(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppGap.semiBig(),
              AppPanelWithSwitch(
                title: getAppLocalizations(context).daylight_savings_time,
                value: state.isDaylightSaving,
                onChangedEvent: _cubit.isSupportDaylightSaving()
                    ? (value) {
                        _cubit.setDaylightSaving(value);
                      }
                    : null,
              ),
              const AppGap.big(),
              SizedBox(
                height: (70.0) * state.supportedTimezones.length,
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.supportedTimezones.length,
                  itemBuilder: (context, index) => InkWell(
                    child: AppPanelWithValueCheck(
                      title: getTimeZoneRegionName(
                          context, state.supportedTimezones[index].timeZoneID),
                      description: getTimezoneGMT(
                          state.supportedTimezones[index].description),
                      valueText: '',
                      isChecked: _cubit.isSelectedTimezone(index),
                    ),
                    onTap: () {
                      _cubit.setSelectedTimezone(index);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
