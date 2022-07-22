import 'dart:async';
import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_components.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:moab_poc/route/model/internet_check_path.dart';
import 'package:moab_poc/route/navigation_cubit.dart';
import 'package:moab_poc/utils.dart';

class WaitModemDisconnectView extends StatefulWidget {
  const WaitModemDisconnectView({Key? key}): super(key: key);

  @override
  State<WaitModemDisconnectView> createState() => _WaitModemDisconnectViewState();
}

class _WaitModemDisconnectViewState extends State<WaitModemDisconnectView> {
  String timeText = '';

  void _startTimer() {
    int remainingTime = 120;
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTime > 0) {
        setState(() {
          remainingTime--;
          timeText = Utils.formatTimeMSS(remainingTime);
        });
      } else {
        timer.cancel();
        goToNext();
      }
    });
  }

  void goToNext() {
    //TODO: Go to next page
    NavigationCubit.of(context).push(PlugModemBackPath());
  }

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        header: const BasicHeader(
          title: 'Giving your modem time to fully disconnect from your ISP...',
        ),
        content: Column(
          children: [
            Text(
              timeText,
              style: Theme.of(context).textTheme.headline1?.copyWith(
                  color: Theme.of(context).primaryColor
              ),
            ),
          ],
        ),
        alignment: CrossAxisAlignment.start,
      ),
    );
  }
}