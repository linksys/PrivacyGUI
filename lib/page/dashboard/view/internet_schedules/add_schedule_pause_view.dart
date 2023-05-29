import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/bloc/profiles/cubit.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/model/profile_service_data.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/components/picker/time_picker_view.dart';
import 'package:linksys_moab/route/model/internet_schedule_path.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';

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
    return BasePageView.onDashboardSecondary(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Add schedule',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          leading: BackButton(onPressed: () {
            ref.read(navigationsProvider.notifier).pop();
          }),
          actions: [
            TextButton(
                onPressed: () {
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
                child: const Text('Save',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: MoabColor.textButtonBlue))),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 22),
            const Text('Internet access will be paused on these days/times.',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black)),
            const SizedBox(height: 8),
            DayPickerView(
              weeklyBool: weeklySet,
              onChanged: (changed) {
                weeklySet = changed;
              },
            ),
            const SizedBox(height: 49),
            if (_isCustomizeTime) ...[
              Row(children: [
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
                const SizedBox(width: 22),
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
                TextButton(
                    onPressed: () {
                      setState(() {
                        _isCustomizeTime = false;
                      });
                    },
                    child: const Text('Remove',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: MoabColor.textButtonBlue)))
              ])
            ] else ...[
              GestureDetector(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Start and end time',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 19),
                      Image.asset('assets/images/add.png'),
                    ],
                  ),
                  onTap: () {
                    setState(() {
                      _isCustomizeTime = true;
                    });
                  })
            ],
            const SizedBox(height: 63),
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
            const SizedBox(height: 25),
            const Text('Router time: 5:05pm',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color.fromRGBO(0, 0, 0, 0.5)))
          ],
        ));
  }
}
