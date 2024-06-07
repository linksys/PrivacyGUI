import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/pnp/data/pnp_exception.dart';
import 'package:privacy_gui/page/pnp/data/pnp_provider.dart';
import 'package:privacy_gui/page/pnp/troubleshooter/providers/pnp_troubleshooter_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/theme/custom_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';

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
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _countDown != 0 ? _countdownPage() : _plugBackPage();
  }

  Widget _countdownPage() {
    return StyledAppPageView(
      appBarStyle: AppBarStyle.none,
      backState: StyledBackState.none,
      child: AppBasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppText.headlineSmall(
              'Giving your modem time to contact your ISP',
            ),
            const AppGap.big(),
            const AppText.bodyLarge(
                'Your ISP needs time to issue a new IP address to your router to connect to the internet'),
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
      appBarStyle: AppBarStyle.none,
      backState: StyledBackState.none,
      child: AppBasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.headlineMedium(
              _isPlugged
                  ? _isCheckingInternet
                      ? 'Checking for internet...'
                      : 'Waiting for your modem to start up'
                  : 'Plug your modem back in',
            ),
            Expanded(
              child: Center(
                child: _isPlugged
                    ? SvgPicture(
                        CustomTheme.of(context).images.modemWaiting,
                        fit: BoxFit.fitWidth,
                      )
                    : SvgPicture(
                        CustomTheme.of(context).images.modemPlugged,
                        fit: BoxFit.fitWidth,
                      ),
              ),
            ),
          ],
        ),
        footer: _isPlugged
            ? null
            : Column(
                children: [
                  AppFilledButton.fillWidth(
                    'It\'s plugged in',
                    onTap: () {
                      setState(() {
                        _isPlugged = true;
                      });
                      Future.delayed(const Duration(seconds: 3)).then((value) {
                        setState(() {
                          _isCheckingInternet = true;
                          ref
                              .read(pnpTroubleshooterProvider.notifier)
                              .resetModem(true);
                        });
                        ref
                            .read(pnpProvider.notifier)
                            .checkInternetConnection()
                            .then((value) {
                          context.goNamed(RouteNamed.pnp);
                        }).catchError((error, stackTrace) {
                          context.goNamed(RouteNamed.pnpNoInternetConnection);
                        }, test: (error) {
                          return error is ExceptionNoInternetConnection;
                        });
                      });
                    },
                  ),
                  const AppGap.regular(),
                ],
              ),
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
