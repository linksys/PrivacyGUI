import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_app/page/components/styled/consts.dart';
import 'package:linksys_app/page/pnp/data/pnp_provider.dart';
import 'package:linksys_app/page/pnp/model/impl/guest_wifi_step.dart';
import 'package:linksys_app/page/pnp/model/impl/night_mode_step.dart';
import 'package:linksys_app/page/pnp/model/impl/personal_wifi_step.dart';
import 'package:linksys_app/page/pnp/model/impl/safe_browsing_step.dart';
import 'package:linksys_app/page/pnp/model/pnp_step.dart';
import 'package:linksys_app/page/pnp/pnp_stepper.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/icons/linksys_icons.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/card/card.dart';
import 'package:linksys_widgets/widgets/container/responsive_layout.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_widgets/widgets/progress_bar/spinner.dart';

enum _PnpSetupStep {
  init,
  config,
  saving,
  saved,
  showWiFi,
  finish,
  ;
}

class PnpSetupView extends ConsumerStatefulWidget {
  const PnpSetupView({Key? key}) : super(key: key);

  @override
  ConsumerState<PnpSetupView> createState() => _PnpSetupViewState();
}

class _PnpSetupViewState extends ConsumerState<PnpSetupView> {
  late final List<PnpStep> steps;
  _PnpSetupStep _setupStep = _PnpSetupStep.init;
  String _loadingMessage = '';
  String _loadingMessageSub = '';

  @override
  void initState() {
    super.initState();
    setState(() {
      _loadingMessage = 'Collecting data...';
      _setupStep = _PnpSetupStep.init;
    });
    Future.doWhile(() => !mounted).then((_) async {
      /// Do something before the pnp wizard start
      /// Check internet connection, isPasswordUserDefault, etc

      // await ref.read(pnpProvider.notifier).fetchDeviceInfo();
      await Future.delayed(const Duration(seconds: 1));
    }).then((_) {
      int index = 0;
      steps = [
        PersonalWiFiStep(index: index++),
        GuestWiFiStep(index: index++),
        NightModeStep(index: index++),
      ];
      setState(() {
        _setupStep = _PnpSetupStep.config;
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
      padding: EdgeInsets.zero,
      child: AppBasicLayout(
        content: Center(
          child: AppCard(
            showBorder: false,
            color: Theme.of(context).colorScheme.background,
            padding: EdgeInsets.zero,
            child: _buildPnpSetupView(),
          ),
        ),
      ),
    );
  }

  Widget _buildPnpSetupView() {
    switch (_setupStep) {
      case _PnpSetupStep.init:
        return _loadingSpinner();
      case _PnpSetupStep.config:
        return _configView();
      case _PnpSetupStep.saving:
        return _loadingSpinner();
      case _PnpSetupStep.saved:
        return _showSaved();
      case _PnpSetupStep.showWiFi:
        return _showWiFi();
      case _PnpSetupStep.finish:
        return _showAllDone();
    }
  }

  Widget _configView() => AppBasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        content: LayoutBuilder(builder: (context, constraints) {
          return PnpStepper(
            steps: steps,
            stepperType: StepperType.horizontal,
            onLastStep: _saveChanges,
          );
        }),
      );

  Widget _loadingSpinner() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppSpinner(),
            const AppGap.regular(),
            AppText.labelMedium(_loadingMessage),
            const AppGap.regular(),
            AppText.labelSmall(_loadingMessageSub),
          ],
        ),
      );
  Widget _showSaved() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppText.labelLarge('Saved'),
            AppGap.regular(),
            Icon(
              LinksysIcons.checkCircle,
            ),
          ],
        ),
      );

  Widget _showWiFi() {
    final wifiSSID = ref
            .read(pnpProvider)
            .stepStateList[steps.indexWhere((element) =>
                element.runtimeType.toString() ==
                (PersonalWiFiStep).toString())]
            ?.data['ssid'] as String? ??
        '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          LinksysIcons.wifi,
        ),
        const AppGap.regular(),
        AppText.titleMedium('$wifiSSID is ready'),
        const AppText.bodyMedium('Connect your devices to your new Wi-Fi'),
        const AppGap.extraBig(),
        Container(
          constraints: const BoxConstraints(maxWidth: 480),
          child: AppFilledButton.fillWidth(
            'Finish',
            onTap: () {
              setState(() {
                _setupStep = _PnpSetupStep.finish;
              });
            },
          ),
        )
      ],
    );
  }

  Widget _showAllDone() {
    return AppBasicLayout(
      crossAxisAlignment: CrossAxisAlignment.start,
      header: const AppText.headlineMedium('Enjoy your Wi-Fi'),
      content: Center(
        child: Column(
          children: [
            const AppGap.regular(),
            AppStyledText.link(
              'To configure advanced settings, visit <link href="www.myrouter.info">www.myrouter.info</link> on a desktop computer',
              defaultTextStyle: Theme.of(context).textTheme.bodyMedium!,
              color: Theme.of(context).primaryColor,
              tags: const ['link'],
              callbackTags: {
                'link': (String? text, Map<String?, String?> attrs) {
                  String? link = attrs['href'];
                  print('The "$link" link is tapped.');
                }
              },
            ),
            const AppGap.regular(),
            Center(
                child: SvgPicture(
                    CustomTheme.of(context).images.pnpFinishDesktop)),
          ],
        ),
      ),
    );
  }

  void _saveChanges() async {
    logger.d('PNP: save changes');
    setState(() {
      _loadingMessage = 'Saving changes...';
      _setupStep = _PnpSetupStep.saving;
    });
    await Future.delayed(const Duration(seconds: 3));
    setState(() {
      _setupStep = _PnpSetupStep.saved;
    });
    await Future.delayed(const Duration(seconds: 3));
    setState(() {
      _setupStep = _PnpSetupStep.showWiFi;
    });
  }
}
