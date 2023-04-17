import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/route/model/internet_check_path.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';
import 'package:linksys_moab/utils.dart';

class WaitModemDisconnectView extends ConsumerStatefulWidget {
  const WaitModemDisconnectView({Key? key}) : super(key: key);

  @override
  ConsumerState<WaitModemDisconnectView> createState() =>
      _WaitModemDisconnectViewState();
}

class _WaitModemDisconnectViewState
    extends ConsumerState<WaitModemDisconnectView> {
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
    ref.read(navigationsProvider.notifier).push(PlugModemBackPath());
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
        header: BasicHeader(
          title: getAppLocalizations(context).wait_modem_disconnect_title,
        ),
        content: Column(
          children: [
            Text(
              timeText,
              style: Theme.of(context)
                  .textTheme
                  .headline1
                  ?.copyWith(color: Theme.of(context).primaryColor),
            ),
          ],
        ),
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
    );
  }
}
