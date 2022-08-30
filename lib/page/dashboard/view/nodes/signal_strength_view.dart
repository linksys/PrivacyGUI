import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/layout.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/dashboard/view/topology/topology_view.dart';
import 'package:linksys_moab/route/route.dart';

class SignalStrengthView extends ArgumentsStatefulView {
  const SignalStrengthView({Key? key, super.args, super.next})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _SignalStrengthViewState();
}

class _SignalStrengthViewState extends State<SignalStrengthView> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView.onDashboardSecondary(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(getAppLocalizations(context).node_detail_label_signal_strength,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        leading: BackButton(onPressed: () {
          NavigationCubit.of(context).pop();
        }),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              getAppLocalizations(context).signal_strength_description,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
          SizedBox(
            height: 16,
          ),
          Text(getAppLocalizations(context).signal_strength_how_to_measured,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          SizedBox(
            height: 16,
          ),
          Text(
              getAppLocalizations(context).signal_strength_how_to_measured_answer,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
          SizedBox(
            height: 32,
          ),
          Table(
            border: TableBorder.all(color: Colors.transparent),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(children: [
                Center(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Text(
                    getAppLocalizations(context).rssi_with_unit,
                    style: Theme.of(context).textTheme.headline3?.copyWith(
                        color: Colors.black, fontWeight: FontWeight.w700),
                  ),
                ),
                Center()
              ]),
              TableRow(children: [
                Image.asset(
                  'assets/images/icon_signal_weak.png',
                  width: 26,
                  height: 26,
                ),
                Text(getAppLocalizations(context).wifi_signal_weak_rssi_range),
                Text(getAppLocalizations(context).wifi_signal_weak)
              ]),
              TableRow(children: [
                Image.asset(
                  'assets/images/icon_signal_good.png',
                  width: 26,
                  height: 26,
                ),
                Text(getAppLocalizations(context).wifi_signal_good_rssi_range),
                Text(getAppLocalizations(context).wifi_signal_good)
              ]),
              TableRow(children: [
                Image.asset(
                  'assets/images/icon_signal_fair.png',
                  width: 26,
                  height: 26,
                ),
                Text(getAppLocalizations(context).wifi_signal_fair_rssi_range),
                Text(getAppLocalizations(context).wifi_signal_fair)
              ]),
              TableRow(children: [
                Image.asset(
                  'assets/images/icon_signal_excellent.png',
                  width: 26,
                  height: 26,
                ),
                Text(getAppLocalizations(context).wifi_signal_excellent_rssi_range),
                Text(getAppLocalizations(context).wifi_signal_excellent)
              ]),
              TableRow(
                  children: [
                Image.asset(
                  'assets/images/icon_signal_wired.png',
                  width: 26,
                  height: 26,
                ),
                Text(getAppLocalizations(context).wired_device),
                Text('(${getAppLocalizations(context).wifi_signal_no_signal})')
              ]),
            ],
          ),
        ],
      ),
    );
  }
}
