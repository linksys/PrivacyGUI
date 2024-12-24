import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/providers/pnp_troubleshooter_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/theme/custom_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacygui_widgets/widgets/progress_bar/spinner.dart';

class PnpWaitingModemView extends ConsumerStatefulWidget {
  const PnpWaitingModemView({Key? key}) : super(key: key);

  @override
  ConsumerState<PnpWaitingModemView> createState() =>
      _PnpWaitingModemViewState();
}

class _PnpWaitingModemViewState extends ConsumerState<PnpWaitingModemView> {
  final int _maxTime = 150;
  late int _countDown;
  bool _isPlugged = false;
  bool _isCheckingInternet = false;

  @override
  void initState() {
    super.initState();
    _countDown = _maxTime;
  }

  @override
  Widget build(BuildContext context) {
    if (_countDown != 0) {
      return _countdownPage();
    } else {
      return _plugBackPage();
    }
  }

  Widget _countdownPage() {
    return StyledAppPageView(
      backState: StyledBackState.none,
      title: loc(context).pnpWaitingModemTitle,
      child: AppBasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppGap.large3(),
            AppText.bodyLarge(loc(context).pnpWaitingModemDesc),
            Expanded(
              child: Center(
                child: _createCircleTimer(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _plugBackPage() {
    return StyledAppPageView(
      backState: StyledBackState.none,
      title: _isPlugged
          ? _isCheckingInternet
              ? loc(context).pnpWaitingModemCheckingInternet
              : loc(context).pnpWaitingModemWaitStartUp
          : loc(context).pnpWaitingModemPlugBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isCheckingInternet) ...[
            Center(
              child: AppSpinner(),
            ),
          ],
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: Spacing.large5 + Spacing.large3,
              ),
              child: SvgPicture(
                _isPlugged
                    ? CustomTheme.of(context).images.modemWaiting
                    : CustomTheme.of(context).images.modemPlugged,
                semanticsLabel:
                    _isPlugged ? 'modem Waiting image' : 'modem Plugged image',
                fit: BoxFit.fitWidth,
              ),
            ),
          ),
          if (!_isPlugged)
            AppFilledButton(
              loc(context).pnpWaitingModemPluggedIn,
              onTap: () {
                logger.i(
                    '[PnP Troubleshooter]: Waiting for the modem to start up after plugging it back');
                setState(() {
                  _isPlugged = true;
                });
                Future.delayed(const Duration(seconds: 5)).then((value) {
                  setState(() {
                    _isCheckingInternet = true;
                    ref
                        .read(pnpTroubleshooterProvider.notifier)
                        .resetModem(true);
                  });
                  ref
                      .read(pnpProvider.notifier)
                      .checkInternetConnection(30)
                      .then((value) {
                    logger.i(
                        '[PnP Troubleshooter]: Internet connection is OK after resetting the modem');
                    context.goNamed(RouteNamed.pnp);
                  }).catchError((error, stackTrace) {
                    logger.e(
                        '[PnP Troubleshooter]: Internet connection still fails after resetting the modem');
                    context.goNamed(RouteNamed.pnpNoInternetConnection);
                  }, test: (error) {
                    return error is ExceptionNoInternetConnection;
                  });
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _createCircleTimer() {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        children: [
          Positioned.fill(
            child: AppProgressBar(
              semanticLabel: 'timer',
              style: AppProgressBarStyle.circular,
              duration: Duration(seconds: _maxTime),
              stroke: 1.0,
              repeat: false,
              callback: (value) {
                setState(() {
                  _countDown = (_maxTime * (1 - value)).toInt();
                });
              },
            ),
          ),
          Center(
            child: AppText.displaySmall(
              _timeFormat(Duration(seconds: _countDown)),
            ),
          ),
        ],
      ),
    );
  }

  String _timeFormat(Duration duration) {
    return (duration.toString().split('.').first.padLeft(8, "0").split(':')
          ..removeAt(0))
        .join(':');
  }
}
