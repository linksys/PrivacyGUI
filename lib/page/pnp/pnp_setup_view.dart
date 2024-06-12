import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/pnp/data/pnp_exception.dart';
import 'package:privacy_gui/page/pnp/data/pnp_provider.dart';
import 'package:privacy_gui/page/pnp/model/impl/guest_wifi_step.dart';
import 'package:privacy_gui/page/pnp/model/impl/night_mode_step.dart';
import 'package:privacy_gui/page/pnp/model/impl/personal_wifi_step.dart';
import 'package:privacy_gui/page/pnp/model/impl/your_network_step.dart';
import 'package:privacy_gui/page/pnp/model/pnp_step.dart';
import 'package:privacy_gui/page/pnp/widgets/pnp_stepper.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/const/spacing.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacygui_widgets/widgets/progress_bar/spinner.dart';

enum _PnpSetupStep {
  init,
  config,
  saving,
  saved,
  showWiFi,
  needReconnect,
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
  bool _isUnconfigured = false;
  bool _needToReconnect = false;
  PnpStep? _currentStep;
  ({void Function() stepCancel, void Function() stepContinue})? _stepController;

  @override
  void initState() {
    super.initState();

    Future.doWhile(() => !mounted).then((_) async {
      setState(() {
        _loadingMessage = loc(context).collectingData;
        _setupStep = _PnpSetupStep.init;
      });
      await ref.read(pnpProvider.notifier).fetchData();
    }).then((_) {
      _isUnconfigured = ref.read(pnpProvider).isUnconfigured;
      int index = 0;
      steps = [
        PersonalWiFiStep(index: index++),
        GuestWiFiStep(index: index++),
        NightModeStep(
            index: index++, saveChanges: _isUnconfigured ? _saveChanges : null),
        if (_isUnconfigured)
          YourNetworkStep(index: index++, saveChanges: _finishAddNodes),
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
      appBarStyle: AppBarStyle.none,
      backState: StyledBackState.none,
      padding: EdgeInsets.zero,
      enableSafeArea: (bottom: true, top: false, left: true, right: false),
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
    return switch (_setupStep) {
      _PnpSetupStep.init => _loadingSpinner(),
      _PnpSetupStep.showWiFi => _showWiFi(),
      _ => Stack(
          children: [
            _configView(),
            switch (_setupStep) {
              _PnpSetupStep.saving => _loadingSpinner(),
              _PnpSetupStep.saved => _showSaved(),
              _PnpSetupStep.needReconnect => _showNeedReconnect(),
              _ => const Center(),
            }
          ],
        ),
    };
  }

  Widget _configView() => AppBasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        content: LayoutBuilder(builder: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.extraBig),
            child: PnpStepper(
              steps: steps,
              stepperType: StepperType.horizontal,
              onLastStep: _isUnconfigured ? _finishAddNodes : _saveChanges,
              onStepChanged: ((index, step, controller) {
                _currentStep = step;
                _stepController = controller;
              }),
            ),
          );
        }),
      );

  Widget _loadingSpinner() => Container(
        color: Theme.of(context).colorScheme.background,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: AppSpinner()),
              const AppGap.regular(),
              AppText.headlineSmall(_loadingMessage),
              const AppGap.regular(),
              AppText.bodyLarge(_loadingMessageSub),
            ],
          ),
        ),
      );
  Widget _showSaved() => Container(
        color: Theme.of(context).colorScheme.background,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppText.labelLarge(loc(context).saved),
              const AppGap.regular(),
              const Icon(
                LinksysIcons.checkCircle,
              ),
            ],
          ),
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
    return Center(
      child: AppCard(
        padding: const EdgeInsets.all(24.0),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LinksysIcons.wifi,
                color: Theme.of(context).colorScheme.primary,
                size: 48,
              ),
              const AppGap.regular(),
              AppText.headlineSmall(loc(context).pnpWiFiReady(wifiSSID)),
              const AppGap.regular(),
              if (_needToReconnect)
                AppText.bodyMedium(loc(context).pnpWiFiReadyConnectToNewWiFi),
              const AppGap.extraBig(),
              AppFilledButton(
                loc(context).done,
                onTap: () {
                  // Check router connected propor, then go to dashboard
                  testConnection(success: () {
                    context.goNamed(RouteNamed.prepareDashboard);
                  });
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _showNeedReconnect() {
    return Container(
      color: Theme.of(context).colorScheme.background,
      child: Center(
        child: AppCard(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LinksysIcons.wifi,
                color: Theme.of(context).colorScheme.primary,
                size: 48,
              ),
              const AppGap.regular(),
              AppText.headlineSmall(loc(context).pnpReconnectWiFi),
              const AppGap.extraBig(),
              AppFilledButton(
                loc(context).next,
                onTap: () {
                  testConnection(success: () async {
                    final password = ref
                        .read(pnpProvider.notifier)
                        .getDefaultWiFiNameAndPassphrase()
                        .password;
                    await ref
                        .read(pnpProvider.notifier)
                        .checkAdminPassword(password)
                        .then((value) => _stepController?.stepContinue());
                    setState(() {
                      _setupStep = _PnpSetupStep.config;
                    });
                  });
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  Future _saveChanges() async {
    logger.d('[pnp] save changes');
    final isUnconfigured = ref.read(pnpProvider).isUnconfigured;

    setState(() {
      _loadingMessage = loc(context).savingChanges;
      _loadingMessageSub = loc(context).pnpSavingChangesDesc;
      _setupStep = _PnpSetupStep.saving;
    });
    await ref.read(pnpProvider.notifier).save().catchError((error) {
      logger.d('[pnp] Need to reconnect!');
      setState(() {
        _needToReconnect = true;
      });
      if (isUnconfigured) {
        // if in unconfigured scenario, display the reconnect prompt
        _currentStep?.canGoNext(false);
        setState(() {
          _setupStep = _PnpSetupStep.needReconnect;
        });
      }
    }, test: (error) => error is ExceptionNeedToReconnect).catchError((error) {
      logger.d('[pnp] Saving Error, $error');
      setState(() {
        _setupStep = _PnpSetupStep.config;
      });
      final err = error is ExceptionSavingChanges ? error.error : error;
      showSimpleSnackBar(
          context, 'Unexceped error! <$err}>');
    }, test: (error) => error is ExceptionSavingChanges).whenComplete(() async {
      logger.d('[pnp] Save complete, $isUnconfigured, $_setupStep');

      if (isUnconfigured) {
        // if is unconfigured scenario and no need to reconnect to the router, continue add nodes flow
        if (_setupStep != _PnpSetupStep.needReconnect) {
          _stepController?.stepContinue();
          setState(() {
            _setupStep = _PnpSetupStep.config;
          });
        }
      } else {
        // if is configured scenario, go display WiFi page
        setState(() {
          _setupStep = _PnpSetupStep.saved;
        });
        await Future.delayed(const Duration(seconds: 3));
        setState(() {
          _setupStep = _PnpSetupStep.showWiFi;
        });
      }
    });
  }

  Future _finishAddNodes() async {
    logger.d('[pnp] finish add nodes');
    setState(() {
      _setupStep = _PnpSetupStep.showWiFi;
    });
  }

  void testConnection({required void Function() success}) {
    // Check router connected propor, then go to dashboard
    ref.read(pnpProvider.notifier).testConnectionReconnected().then((value) {
      success.call();
    }).onError((error, stackTrace) {
      showSimpleSnackBar(
          context, 'Please connect your devices to your new WiFi');
    });
  }
}
