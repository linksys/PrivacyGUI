import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/bloc/profiles/cubit.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/model/profile_service_data.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';

import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/components/picker/time_picker_view.dart';
import 'package:linksys_moab/route/model/internet_schedule_path.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

import '../../../components/picker/day_picker_view.dart';

class AddSchedulePauseView extends ArgumentsConsumerStatefulView {
  const AddSchedulePauseView({
    Key? key,
    super.args,
    super.next,
  }) : super(key: key);

  @override
  ConsumerState<AddSchedulePauseView> createState() =>
      _AddSchedulePauseViewState();
}

class _AddSchedulePauseViewState extends ConsumerState<AddSchedulePauseView> {
  bool _isCustomizeTime = false;
  List<bool> weeklySet = [];
  late final ScheduledPausedRule _rule;
  late String _profileId;
  late Duration _startTimeInSeconds;
  late Duration _endTimeInSeconds;
  bool _isEdit = false;

  @override
  void initState() {
    _rule = widget.args['rule'] ?? ScheduledPausedRule.empty();
    _isEdit = widget.args.containsKey('rule');
    _profileId = widget.args['profileId'] ?? '';
    _startTimeInSeconds = Duration(seconds: _rule.pauseStartTime);
    _endTimeInSeconds = Duration(seconds: _rule.pauseEndTime);
    _isCustomizeTime = !_rule.isAllDay;
    weeklySet = _rule.weeklySet;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
        title: 'Add schedule',
        actions: [
          AppTertiaryButton(
            'Save',
            onTap: () {
              context
                  .read<ProfilesCubit>()
                  .updateSchedulePausesDetail(
                    _profileId,
                    _rule,
                    weeklySet,
                    _startTimeInSeconds.inSeconds,
                    _endTimeInSeconds.inSeconds,
                    !_isCustomizeTime,
                  )
                  .then((value) => ref
                      .read(navigationsProvider.notifier)
                      .popTo(SchedulePauseListPath()));
            },
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppGap.semiBig(),
            const AppText.descriptionMain(
              'Internet access will be paused on these days/times.',
            ),
            const AppGap.semiSmall(),
            DayPickerView(
              weeklyBool: weeklySet,
              onChanged: (changed) {
                weeklySet = changed;
              },
            ),
            const AppGap.extraBig(),
            if (_isCustomizeTime) ...[
              Row(
                children: [
                  TimePickerView(
                    title: 'start',
                    current: _startTimeInSeconds,
                    isNextDay: false,
                    onChanged: (newTime) {
                      setState(() {
                        _startTimeInSeconds = newTime;
                      });
                    },
                  ),
                  const AppGap.semiBig(),
                  TimePickerView(
                    title: 'end',
                    current: _endTimeInSeconds,
                    isNextDay: _startTimeInSeconds > _endTimeInSeconds,
                    onChanged: (newTime) {
                      setState(() {
                        _endTimeInSeconds = newTime;
                      });
                    },
                  ),
                  const Spacer(),
                  AppTertiaryButton(
                    'Remove',
                    onTap: () {
                      setState(() {
                        _isCustomizeTime = false;
                      });
                    },
                  ),
                ],
              )
            ] else ...[
              GestureDetector(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppText.descriptionMain(
                      'Start and end time',
                    ),
                    const AppGap.regular(),
                    Image.asset('assets/images/add.png'),
                  ],
                ),
                onTap: () {
                  setState(() {
                    _isCustomizeTime = true;
                  });
                },
              )
            ],
            const AppGap.extraBig(),
            TextButton(
                onPressed: () {
                  context
                      .read<ProfilesCubit>()
                      .deleteSchedulePausesRule(_profileId, _rule)
                      .then((value) =>
                          ref.read(navigationsProvider.notifier).pop());
                },
                style: TextButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 0)),
                child: const Text('Delete',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color.fromRGBO(207, 26, 26, 1.0)))),
            const AppGap.semiBig(),
            const AppText.descriptionSub(
              'Router time: 5:05pm',
              color: Color.fromRGBO(0, 0, 0, 0.5),
            ),
          ],
        ));
  }
}
