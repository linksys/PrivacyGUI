import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_widgets/theme/const/spacing.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

class SignalStrengthView extends ArgumentsConsumerStatefulView {
  const SignalStrengthView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<SignalStrengthView> createState() => _SignalStrengthViewState();
}

class _SignalStrengthViewState extends ConsumerState<SignalStrengthView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      title: getAppLocalizations(context).signalStrength,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.bodyMedium(
            getAppLocalizations(context).signal_strength_description,
          ),
          const AppGap.regular(),
          AppText.bodyMedium(
            getAppLocalizations(context).signal_strength_how_to_measured,
          ),
          const AppGap.regular(),
          AppText.bodyMedium(
            getAppLocalizations(context).signal_strength_how_to_measured_answer,
          ),
          const AppGap.big(),
          Table(
            border: TableBorder.all(color: Colors.transparent),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.big),
                    child: AppText.displayLarge(
                      getAppLocalizations(context).rssi_with_unit,
                    ),
                  ),
                ],
              ),
              TableRow(
                children: [
                  Image.asset(
                    'assets/images/icon_signal_weak.png',
                    width: 26,
                    height: 26,
                  ),
                  AppText.bodyLarge(
                      getAppLocalizations(context).wifi_signal_weak_rssi_range),
                  AppText.bodyLarge(
                      getAppLocalizations(context).wifi_signal_weak)
                ],
              ),
              TableRow(
                children: [
                  Image.asset(
                    'assets/images/icon_signal_good.png',
                    width: 26,
                    height: 26,
                  ),
                  AppText.bodyLarge(
                      getAppLocalizations(context).wifi_signal_good_rssi_range),
                  AppText.bodyLarge(
                      getAppLocalizations(context).wifi_signal_good)
                ],
              ),
              TableRow(
                children: [
                  Image.asset(
                    'assets/images/icon_signal_fair.png',
                    width: 26,
                    height: 26,
                  ),
                  AppText.bodyLarge(
                      getAppLocalizations(context).wifi_signal_fair_rssi_range),
                  AppText.bodyLarge(
                      getAppLocalizations(context).wifi_signal_fair)
                ],
              ),
              TableRow(
                children: [
                  Image.asset(
                    'assets/images/icon_signal_excellent.png',
                    width: 26,
                    height: 26,
                  ),
                  AppText.bodyLarge(getAppLocalizations(context)
                      .wifi_signal_excellent_rssi_range),
                  AppText.bodyLarge(
                      getAppLocalizations(context).wifi_signal_excellent)
                ],
              ),
              TableRow(
                children: [
                  Image.asset(
                    'assets/images/icon_signal_wired.png',
                    width: 26,
                    height: 26,
                  ),
                  AppText.bodyLarge(getAppLocalizations(context).wired_device),
                  AppText.bodyLarge(
                      '(${getAppLocalizations(context).wifi_signal_no_signal})')
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}