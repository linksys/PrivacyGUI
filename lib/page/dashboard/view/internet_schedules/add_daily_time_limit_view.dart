import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/bloc/profiles/cubit.dart';
import 'package:linksys_moab/bloc/profiles/state.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/model/profile_service_data.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/components/picker/number_picker_view.dart';
import 'package:linksys_moab/route/model/internet_schedule_path.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

import '../../../components/picker/day_picker_view.dart';

class AddDailyTimeLimitView extends ArgumentsConsumerStatefulView {
  const AddDailyTimeLimitView({Key? key, super.args, super.next})
      : super(key: key);

  @override
  ConsumerState<AddDailyTimeLimitView> createState() =>
      _AddDailyTimeLimitViewState();
}

class _AddDailyTimeLimitViewState extends ConsumerState<AddDailyTimeLimitView> {
  int hour = 0;
  int minutes = 0;
  List<bool> weeklySet = [];
  late final DateTimeLimitRule _rule;
  late String _profileId;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    _rule = widget.args['rule'] ?? DateTimeLimitRule.empty();
    _isEdit = widget.args.containsKey('rule');

    _profileId = widget.args['profileId'] ?? '';
    hour = (_rule.timeInSeconds ~/ 3600).remainder(24);
    minutes = (_rule.timeInSeconds ~/ 60).remainder(60);
    weeklySet = _rule.weeklySet;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfilesCubit, ProfilesState>(builder: (context, state) {
      return StyledAppPageView(
          title: getAppLocalizations(context).daily_time_limit,
          actions: [
            AppTertiaryButton(
              'Save',
              onTap: () {
                final timeInSeconds = hour * 3600 + minutes * 60;
                context
                    .read<ProfilesCubit>()
                    .updateDetailTimeLimitDetail(
                        _profileId, _rule, weeklySet, timeInSeconds)
                    .then((value) => ref
                        .read(navigationsProvider.notifier)
                        .popTo(DailyTimeLimitListPath()));
              },
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppGap.big(),
              DayPickerView(
                weeklyBool: weeklySet,
                onChanged: (changed) {
                  weeklySet = changed;
                },
              ),
              const AppGap.big(),
              timePicker(hour, minutes, (value) {
                setState(() {
                  hour = value;
                });
              }, (value) {
                setState(() {
                  minutes = value;
                });
              }),
              const AppGap.extraBig(),
              Offstage(
                offstage: !_isEdit,
                child: AppTertiaryButton(
                  'Delete',
                  onTap: () {
                    context
                        .read<ProfilesCubit>()
                        .deleteTimeLimitRule(_profileId, _rule)
                        .then((value) =>
                            ref.read(navigationsProvider.notifier).pop());
                  },
                ),
              )
            ],
          ));
    });
  }

  Widget timePicker(int hour, int minutes, ValueChanged onHourChanged,
      ValueChanged onMinutesChanged) {
    return Row(children: [
      NumberPickerView(
          title: 'Hours',
          value: hour,
          min: 0,
          max: 24,
          step: 1,
          callback: onHourChanged),
      const AppGap.semiBig(),
      NumberPickerView(
          title: 'Minutes',
          value: minutes,
          min: 0,
          max: 60,
          step: 15,
          callback: onMinutesChanged),
    ]);
  }
}
