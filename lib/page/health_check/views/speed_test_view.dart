import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:privacy_gui/core/jnap/models/health_check_result.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/dashboard/_dashboard.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_provider.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/animation/breath_dot.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/container/animated_meter.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';

class SpeedTestView extends ArgumentsConsumerStatefulView {
  const SpeedTestView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<SpeedTestView> createState() => _SpeedTestViewState();
}

class _SpeedTestViewState extends ConsumerState<SpeedTestView> {
  String _status = "IDLE";
  double _meterValue = 0.0;
  double _randomValue = 0.0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(healthCheckProvider);
    final supportedBy = ref.watch(dashboardHomeProvider).healthCheckModule;
    ref.listen(healthCheckProvider.select((value) => value.step),
        (previous, next) {
      if (next == previous) {
        return;
      }
      if ((previous == 'latency' && next == 'downloadBandwidth')) {
        setState(() {
          _meterValue = 0;
          _randomValue = 0;
        });
      } else if ((previous == 'downloadBandwidth' &&
          next == 'uploadBandwidth')) {
        setState(() {
          final downloadBandwidth = ((ref
                      .read(healthCheckProvider)
                      .result
                      .firstOrNull
                      ?.speedTestResult
                      ?.downloadBandwidth ??
                  0) /
              1000.0);
          _meterValue = downloadBandwidth;
          _randomValue = 0;
        });
        Future.delayed(const Duration(seconds: 1), () {
          setState(() {
            _meterValue = 0;
            _randomValue = 0;
          });
        });
      }
      if (next == 'success' || next == 'error') {
        setState(() {
          _meterValue = 0;
          _randomValue = 0;
          _status = 'COMPLETE';
        });
      }
    });
    return StyledAppPageView(
      scrollable: true,
      title: loc(context).speedTest,
      bottomBar: _status == 'COMPLETE'
          ? PageBottomBar(
              positiveLabel: loc(context).testAgain,
              isPositiveEnabled: true,
              onPositiveTap: () {
                ref
                    .read(healthCheckProvider.notifier)
                    .runHealthCheck(Module.speedtest);
                setState(() {
                  _status = 'RUNNING';
                });
              },
            )
          : null,
      child: (context, constraints) => switch (_status) {
        'RUNNING' => ResponsiveLayout(
            desktop: Container(
              margin: const EdgeInsets.fromLTRB(0, 0, 0, 40),
              child: Center(
                child: _runningView(
                  state.step,
                  state.result.firstOrNull?.speedTestResult,
                ),
              ),
            ),
            mobile: _runningView(
              state.step,
              state.result.firstOrNull?.speedTestResult,
            ),
          ),
        'COMPLETE' => ResponsiveLayout(
            desktop: Container(
              margin: const EdgeInsets.fromLTRB(0, 0, 0, 40),
              child: Container(
                alignment: state.step != 'error'
                    ? Alignment.topCenter
                    : Alignment.topLeft,
                child: _finishView(
                  state.step,
                  state.result.firstOrNull?.speedTestResult,
                  state.timestamp,
                  state.error,
                ),
              ),
            ),
            mobile: _finishView(
              state.step,
              state.result.firstOrNull?.speedTestResult,
              state.timestamp,
              state.error,
            ),
          ),
        _ => ResponsiveLayout(
            desktop: AppCard(
              showBorder: false,
              margin: const EdgeInsets.fromLTRB(0, 0, 0, 40),
              padding: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: _initView(supportedBy),
            ),
            mobile: _initView(supportedBy),
          ),
      },
    );
  }

  Widget _gradientBackground() {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(
            colors: [
              Color(0xffeff3ff),
              Color(0xffd8e2ff),
              Color(0xff005bc1),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0, 0.515, 1],
          )),
        ),
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              radius: 0.3,
              center: Alignment.center,
              colors: [
                Color(0xffe9efff),
                Color(0x00ffffff),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _initView(String? supportedBy) {
    final background = ResponsiveLayout.isMobileLayout(context)
        ? OverflowBox(
            maxWidth: MediaQuery.of(context).size.width,
            child: _gradientBackground(),
          )
        : _gradientBackground();
    return Stack(
      children: [
        background,
        Container(
          alignment: Alignment.center,
          child: InkWell(
            key: const Key('goBtn'),
            onTap: () {
              Future.delayed(const Duration(milliseconds: 500), () {
                setState(() {
                  _status = 'RUNNING';
                });
              });
              ref
                  .read(healthCheckProvider.notifier)
                  .runHealthCheck(Module.speedtest);
            },
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary),
              child: Center(
                child: AppText.displayLarge(
                  loc(context).go,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ),
        if (supportedBy == 'Ookla')
          Container(
            alignment: Alignment.bottomCenter,
            padding: const EdgeInsets.only(bottom: 40),
            child: Image(
              image: CustomTheme.of(context).images.speedtestPowered,
              fit: BoxFit.fitWidth,
            ),
          ),
      ],
    );
  }

  Widget _runningView(String step, SpeedTestResult? result) {
    final (latency, downloadBandWidth, uploadBandWidth) = _getDataText(result);
    final value =
        step == 'downloadBandwidth' ? downloadBandWidth : uploadBandWidth;
    final meterValue =
        step == 'latency' ? 0.0 : _getRandomMeterValue(double.parse(value));
    return ResponsiveLayout(
      desktop: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 7.col,
            child: _meterView(step, meterValue, latency),
          ),
          const AppGap.gutter(),
          SizedBox(
            width: 5.col,
            child: _infoView(step, downloadBandWidth, uploadBandWidth),
          ),
        ],
      ),
      mobile: Column(
        children: [
          _meterView(step, meterValue, latency),
          const AppGap.medium(),
          const Spacer(),
          _infoView(step, downloadBandWidth, uploadBandWidth),
          const AppGap.medium(),
        ],
      ),
    );
  }

  Widget _meterView(String step, double value, String latency) {
    final defaultMarkers = <double>[0, 1, 5, 10, 20, 30, 50, 75, 100];
    return AnimatedMeter(
      size: ResponsiveLayout.isMobileLayout(context) ? 4.col : 5.col,
      value: value,
      markers: defaultMarkers,
      centerBuilder: (context, value) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText.titleSmall(switch (step) {
              'latency' => '',
              'downloadBandwidth' => loc(context).download,
              'uploadBandwidth' => loc(context).upload,
              _ => '',
            }),
            AppText.displayLarge(
                step == 'latency' ? '—' : (value).toStringAsFixed(1)),
            const AppText.bodyMedium('Mbps'),
          ],
        );
      },
      bottomBuilder: (context, value) {
        return _pingView(step, latency);
      },
    );
  }

  Widget _pingView(String step, String latency) {
    return Column(
      mainAxisAlignment:
          step != 'success' ? MainAxisAlignment.end : MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: step != 'success'
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 9),
              child: BreathDot(
                breathSpeed: const Duration(seconds: 1),
                lightColor: Theme.of(context).colorScheme.primary,
                borderColor: Theme.of(context).colorScheme.primary,
                size: 12,
                dotSize: 6,
                animated: latency == '—',
              ),
            ),
            AppText.titleSmall(
              step == 'latency' ? 'Ping: —' : 'Ping: ',
              color: Theme.of(context).colorScheme.primary,
            ),
            AppText.bodyMedium(
              step == 'latency' ? 'ms' : '${latency}ms',
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
        if (step != 'success') const AppGap.large2(),
      ],
    );
  }

  Widget _infoView(
      String step, String downloadBandWidth, String uploadBandWidth) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _descriptionCard(step),
        if (step != 'latency') const AppGap.small3(),
        if (step != 'latency') _resultCard(downloadBandWidth, uploadBandWidth),
      ],
    );
  }

  Widget _descriptionCard(String step) {
    List<Widget> children = [];
    final setpTitle = switch (step) {
      'latency' => loc(context).testingPing,
      'downloadBandwidth' => loc(context).testingDownloadSpeed,
      'uploadBandwidth' => loc(context).testingUploadSpeed,
      _ => '',
    };
    final setpDesc = switch (step) {
      'latency' => null,
      'downloadBandwidth' => loc(context).testingDownloadSpeedDescription,
      'uploadBandwidth' => loc(context).testingUploadSpeedDescription,
      _ => null,
    };
    children.add(AppText.titleSmall(
      setpTitle,
      textAlign: TextAlign.center,
    ));
    if (setpDesc != null) {
      children.add(const AppGap.small2());
      children.add(AppText.bodyMedium(
        setpDesc,
        textAlign: TextAlign.center,
      ));
    }
    return SizedBox(
      width: double.infinity,
      child: AppCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }

  Widget _resultCard(String downloadBandWidth, String uploadBandWidth) {
    final downloadBandWidthView =
        _status == 'RUNNING' && !ResponsiveLayout.isMobileLayout(context)
            ? AppText.displaySmall(
                double.parse(downloadBandWidth) == 0 ? '—' : downloadBandWidth)
            : AppText.displayLarge(
                double.parse(downloadBandWidth) == 0 ? '—' : downloadBandWidth);
    final uploadBandWidthView =
        _status == 'RUNNING' && !ResponsiveLayout.isMobileLayout(context)
            ? AppText.displaySmall(
                double.parse(uploadBandWidth) == 0 ? '—' : uploadBandWidth)
            : AppText.displayLarge(
                double.parse(uploadBandWidth) == 0 ? '—' : uploadBandWidth);
    return Row(
      children: [
        Expanded(
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(LinksysIcons.download),
                const AppGap.small2(),
                AppText.titleSmall(loc(context).download),
                const AppGap.small2(),
                downloadBandWidthView,
                const AppGap.small2(),
                const AppText.bodyMedium('Mbps'),
              ],
            ),
          ),
        ),
        const AppGap.gutter(),
        Expanded(
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(LinksysIcons.upload),
                const AppGap.small2(),
                AppText.titleSmall(loc(context).upload),
                const AppGap.small2(),
                uploadBandWidthView,
                const AppGap.small2(),
                const AppText.bodyMedium('Mbps'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _finishView(String step, SpeedTestResult? result, String? timestamp,
      JNAPError? error) {
    final (latency, downloadBandWidth, uploadBandWidth) = _getDataText(result);
    final (resultTitle, resultDesc) = _getTestResultDesc(result);
    final date = _getTestResultDate(timestamp);
    return switch (step) {
      'error' => SizedBox(
          width: ResponsiveLayout.isMobileLayout(context)
              ? double.infinity
              : 7.col,
          child: AppCard(
            color: ResponsiveLayout.isMobileLayout(context)
                ? Theme.of(context).colorScheme.background
                : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.titleSmall(loc(context).generalError),
                const AppGap.small2(),
                AppText.bodyMedium(error?.result ?? loc(context).unknownError),
              ],
            ),
          ),
        ),
      _ => ResponsiveLayout(
          desktop: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 7.col,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppCard(
                      child: _pingView(step, latency),
                    ),
                    const AppGap.small2(),
                    _resultCard(downloadBandWidth, uploadBandWidth),
                    // ISP info
                  ],
                ),
              ),
              const AppGap.gutter(),
              SizedBox(
                width: 5.col,
                child:
                    _performanceDescriptionCard(resultTitle, resultDesc, date),
              ),
            ],
          ),
          mobile: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(
                child: _pingView(step, latency),
              ),
              const AppGap.small2(),
              _resultCard(downloadBandWidth, uploadBandWidth),
              // ISP info
              const AppGap.small3(),
              SizedBox(
                width: double.infinity,
                child:
                    _performanceDescriptionCard(resultTitle, resultDesc, date),
              ),
            ],
          ),
        ),
    };
  }

  Widget _performanceDescriptionCard(
      String resultTitle, String resultDesc, String date) {
    return AppCard(
      color: ResponsiveLayout.isMobileLayout(context)
          ? Theme.of(context).colorScheme.background
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LinksysIcons.bolt),
          const AppGap.medium(),
          AppText.titleSmall(resultTitle),
          const AppGap.small2(),
          AppText.bodyMedium(resultDesc),
          const AppGap.small2(),
          AppText.bodySmall(date),
        ],
      ),
    );
  }

  double _getRandomMeterValue(double value) {
    if (value == 0) {
      _meterValue = _meterValue + _randomValue;
      _randomValue = _randomDouble(-10, 15);
    } else {
      return value;
    }
    if (_meterValue < 0) {
      _meterValue = 0;
    }
    return _meterValue;
  }

  double _randomDouble(double min, double max) {
    return (Random().nextDouble() * (max - min) + min);
  }

  (String, String, String) _getDataText(SpeedTestResult? result) {
    var latency = result?.latency?.toStringAsFixed(0) ?? '—';
    var downloadBandWidth =
        ((result?.downloadBandwidth ?? 0) / 1000.0).toStringAsFixed(1);
    var uploadBandWidth =
        ((result?.uploadBandwidth ?? 0) / 1000.0).toStringAsFixed(1);
    return (latency, downloadBandWidth, uploadBandWidth);
  }

  (String, String) _getTestResultDesc(SpeedTestResult? result) {
    var downloadBandWidth = (result?.downloadBandwidth ?? 0) / 1000.0;
    var resultTitle = switch (downloadBandWidth) {
      < 50 => loc(context).speedOkay,
      < 100 => loc(context).speedGood,
      < 150 => loc(context).speedOptimal,
      _ => loc(context).speedUltra,
    };
    var resultDesc = switch (downloadBandWidth) {
      < 50 => loc(context).speedOkayDescription,
      < 100 => loc(context).speedGoodDescription,
      < 150 => loc(context).speedOptimalDescription,
      _ => loc(context).speedUltraDescription,
    };
    return (resultTitle, resultDesc);
  }

  String _getTestResultDate(String? timestamp) {
    var date = '—';
    if (timestamp != null) {
      final millisecondsSinceEpoch = DateFormat("yyyy-MM-ddThh:mm:ssZ")
          .parse(timestamp, true)
          .millisecondsSinceEpoch;
      DateTime tempDate =
          DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
      // Convert to date string
      date = loc(context).speedCheckLatestTime(tempDate, tempDate);
    }
    return date;
  }
}
