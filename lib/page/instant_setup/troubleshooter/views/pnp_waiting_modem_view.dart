import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

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
    return UiKitPageView(
      backState: UiKitBackState.none,
      title: loc(context).pnpWaitingModemTitle,
      child: (context, constraints) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppGap.xxl(),
          AppText.bodyLarge(loc(context).pnpWaitingModemDesc),
          AppGap.xxxl(),
          Center(
            child: _createCircleTimer(),
          ),
        ],
      ),
    );
  }

  Widget _plugBackPage() {
    return UiKitPageView(
      backState: UiKitBackState.none,
      title: _isPlugged
          ? _isCheckingInternet
              ? loc(context).pnpWaitingModemCheckingInternet
              : loc(context).pnpWaitingModemWaitStartUp
          : loc(context).pnpWaitingModemPlugBack,
      child: (context, constraints) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isCheckingInternet) ...[
            Center(
              child: AppLoader(),
            ),
          ],
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: AppSpacing.xxxl + AppSpacing.xxl,
            ),
            child: _isPlugged
                ? Assets.images.modemWaiting.svg(
                    semanticsLabel: 'modem Waiting image', fit: BoxFit.fitWidth)
                : Assets.images.modemPlugged.svg(
                    semanticsLabel: 'modem Plugged image',
                    fit: BoxFit.fitWidth),
          ),
          if (!_isPlugged)
            AppButton(
              label: loc(context).pnpWaitingModemPluggedIn,
              variant: SurfaceVariant.highlight,
              onTap: () {
                logger.i(
                    '[PnP Troubleshooter]: Waiting for the modem to start up after plugging it back');
                setState(() {
                  _isPlugged = true;
                });
                Future.delayed(const Duration(seconds: 5)).then((value) {
                  setState(() {
                    _isCheckingInternet = true;
                  });
                  ref
                      .read(pnpProvider.notifier)
                      .checkInternetConnection(30)
                      .then((value) {
                    if (context.mounted) {
                      logger.i(
                          '[PnP Troubleshooter]: Internet connection is OK after resetting the modem');
                      context.goNamed(RouteNamed.pnp);
                    } else {
                      logger.e(
                          '[PnP Troubleshooter]: Internet connection is OK after resetting the modem, but the view is not mounted');
                    }
                  }).catchError((error, stackTrace) {
                    if (context.mounted) {
                      logger.e(
                          '[PnP Troubleshooter]: Internet connection still fails after resetting the modem');
                      context.goNamed(RouteNamed.pnpNoInternetConnection);
                    } else {
                      logger.e(
                          '[PnP Troubleshooter]: Internet connection still fails after resetting the modem, but the view is not mounted');
                    }
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
            child: AppLoader(
              semanticLabel: 'timer',
              duration: Duration(seconds: _maxTime),
              strokeWidth: 1.0,
              repeat: false,
              onProgress: (value) {
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
