import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/route/route.dart';

import '../../../route/model/dashboard_path.dart';

typedef ValueChanged<T> = void Function(T value);

class ProfileSettingsView extends StatelessWidget {
  const ProfileSettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BasePageView.onDashboardSecondary(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Timmy', style: TextStyle(fontSize: 15)),
        leading: BackButton(onPressed: () {
          NavigationCubit.of(context).pop();
        }),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          timeLimitSettingsItem(context, (context) {
            NavigationCubit.of(context).push(AddDailyTimeLimitPath());
          }),
          schedulePauseSettingsItem(context, (context) {
            NavigationCubit.of(context).push(AddSchedulePausePath());
          })
        ],
      ),
    );
  }
}

Widget timeLimitSettingsItem(BuildContext context, ValueChanged onTap) {
  return GestureDetector(
      child: SizedBox(
        height: 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('Daily time limit'),
                  SizedBox(height: 4),
                  Text('none', style: TextStyle(color: Color(0xff666666)))
                ]),
            Expanded(child: Container()),
            Image.asset('assets/images/right_compact_wire.png')
          ],
        ),
      ),
      onTap: () => onTap(context));
}

Widget schedulePauseSettingsItem(BuildContext context, ValueChanged onTap) {
  return Container(
      height: 64,
      width: double.infinity,
      child: GestureDetector(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text('Scheduled pauses'),
                    SizedBox(height: 4),
                    Text('none', style: TextStyle(color: Color(0xff666666)))
                  ]),
              Image.asset('assets/images/right_compact_wire.png')
            ],
          ),
          onTap: () => onTap(context)));
}
