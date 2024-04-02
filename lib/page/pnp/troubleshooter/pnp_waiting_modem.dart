import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/page/components/styled/consts.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/theme/custom_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';

class PnpWaitingModemView extends ConsumerStatefulWidget {
  const PnpWaitingModemView({Key? key}) : super(key: key);

  @override
  ConsumerState<PnpWaitingModemView> createState() =>
      _PnpWaitingModemViewState();
}

class _PnpWaitingModemViewState extends ConsumerState<PnpWaitingModemView> {
  final int _maxTime = 10;
  late int _totalTime;
  late int _countDown;
  bool _isPlugged = false;
  bool _isCheckingInternet = false;

  @override
  void initState() {
    super.initState();
    _totalTime = _maxTime;
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
      backState: StyledBackState.none,
      child: AppBasicLayout(
        content: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppGap.big(),
              const AppText.headlineMedium(
                'Giving your modem time to contact your ISP',
              ),
              const AppGap.big(),
              const AppText.bodyMedium(
                  'Your ISP needs time to issue a new IP address to your router to connect to the internet.'),
              Expanded(
                child: Center(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _totalTime = 10;
                      });
                    },
                    child: _createCircleTimer(),
                  ),
                ),
              ),
            ]),
      ),
    );
  }

  Widget _plugBackPage() {
    return StyledAppPageView(
      backState: StyledBackState.none,
      child: AppBasicLayout(
        content: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppGap.big(),
              AppText.headlineMedium(
                _isPlugged
                    ? _isCheckingInternet
                        ? 'Checking for internet...'
                        : 'Waiting for your modem to start up'
                    : 'Plug your modem back in',
              ),
              Expanded(
                child: Center(
                  child: SvgPicture(
                    CustomTheme.of(context).images.unplugModem,
                    fit: BoxFit.fitWidth,
                  ),
                ),
              ),
            ]),
        footer: _isPlugged
            ? null
            : Column(children: [
                AppFilledButton.fillWidth(
                  'It\'s plugged in',
                  onTap: () {
                    setState(() {
                      _isPlugged = true;
                    });
                    Future.delayed(const Duration(seconds: 3)).then((value) {
                      setState(() {
                        _isCheckingInternet = true;
                      });
                      Future.delayed(const Duration(seconds: 3)).then((value) {
                        context.goNamed(RouteNamed.pnp);
                      });
                    });
                  },
                ),
                const AppGap.regular(),
              ]),
      ),
    );
  }

  Widget _createCircleTimer() {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        children: [
          Positioned.fill(
            child: AppProgressBar(
              style: AppProgressBarStyle.circular,
              duration: Duration(seconds: _totalTime),
              stroke: 2.0,
              repeat: false,
              callback: (value) {
                setState(() {
                  _countDown = (_maxTime * (1 - value)).toInt();
                });
              },
            ),
          ),
          Center(
              child: AppText.labelLarge(
                  _timeFormat(Duration(seconds: _countDown)))),
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
