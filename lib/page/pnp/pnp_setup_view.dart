import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_app/page/components/styled/consts.dart';
import 'package:linksys_app/page/pnp/model/impl/account_step.dart';
import 'package:linksys_app/page/pnp/model/impl/guest_wifi_step.dart';
import 'package:linksys_app/page/pnp/model/impl/local_login_step.dart';
import 'package:linksys_app/page/pnp/model/impl/night_mode_step.dart';
import 'package:linksys_app/page/pnp/model/impl/personal_wifi_step.dart';
import 'package:linksys_app/page/pnp/model/impl/safe_browsing_step.dart';
import 'package:linksys_app/page/pnp/model/pnp_step.dart';
import 'package:linksys_app/page/pnp/pnp_stepper.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';

class PnpSetupView extends ConsumerStatefulWidget {
  const PnpSetupView({Key? key}) : super(key: key);

  @override
  ConsumerState<PnpSetupView> createState() => _PnpSetupViewState();
}

class _PnpSetupViewState extends ConsumerState<PnpSetupView> {
  late final List<PnpStep> steps;
  bool _isLoading = false;
  bool _isAllDone = false;
  String _loadingMessage = '';
  String _loadingMessageSub = '';

  @override
  void initState() {
    super.initState();

    setState(() {
      _loadingMessage = 'Checking your internet...';
      _isLoading = true;
    });
    Future.doWhile(() => !mounted).then((_) async {
      // Do something before the pnp wizard start
      // await ref.read(pnpProvider.notifier).fetchDeviceInfo();
      await Future.delayed(const Duration(seconds: 3));
    }).then((_) {
      steps = [
        LocalLoginStep(index: 0),
        PersonalWiFiStep(index: 1),
        GuestWiFiStep(index: 2),
        NightModeStep(index: 3),
        SafeBrowsingStep(index: 4),
        AccountStep(index: 5),
      ];
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    for (var element in steps) {
      element.onDispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      backState: StyledBackState.none,
      child: AppBasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        header: SvgPicture(
          AppTheme.of(context).images.linksysBlackLogo,
          width: 32,
          height: 32,
        ),
        content: LayoutBuilder(builder: (context, constraints) {
          if (_isLoading) {
            return _loadingSpinner();
          } else if (_isAllDone) {
            return _showAllDone();
          } else {
            return PnpStepper(
              steps: steps,
              stepperType: constraints.maxWidth <= 768
                  ? StepperType.vertical
                  : StepperType.horizontal,
              onLastStep: _saveChanges,
            );
          }
        }),
      ),
    );
  }

  Widget _loadingSpinner() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const AppGap.regular(),
            AppText.labelMedium(_loadingMessage),
            const AppGap.regular(),
            AppText.labelSmall(_loadingMessageSub),
          ],
        ),
      );

  Widget _showAllDone() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText.labelLarge('You\'re all set'),
          const AppText.titleSmall(
              'Revisit your settings, access more features'),
          const AppText.bodyMedium('* Download the Linksys App or'),
          AppStyledText.bodyMedium(
            '* Visit <link>myrouter.info</link>',
            tags: {
              'link': (String? text, Map<String?, String?> attrs) {
                context.goNamed(RouteNamed.home);
              }
            },
          )
        ],
      );

  void _saveChanges() async {
    logger.d('PNP: save changes');
    setState(() {
      _loadingMessage = 'Saving changes...';
      _isLoading = true;
    });
    await Future.delayed(const Duration(seconds: 3));
    setState(() {
      _loadingMessageSub =
          'Your settings changes may have caused a disconnection, please ensure you are connected to your Wi-Fi network:\nSSID: <Your SSID>\nPassword: <Your Password>';
    });
    await Future.delayed(const Duration(seconds: 3));
    setState(() {
      _isAllDone = true;
      _isLoading = false;
    });
  }
}
