import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/models/health_check_result.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/health_check/_health_check.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/container/animated_meter.dart';

class SpeedTestWidget extends ConsumerStatefulWidget {
  const SpeedTestWidget({super.key});

  @override
  ConsumerState<SpeedTestWidget> createState() => _SpeedTestWidgetState();
}

class _SpeedTestWidgetState extends ConsumerState<SpeedTestWidget> {
  String _status = 'IDLE';
  double _meterValue = 0.0;
  double _randomValue = 0.0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(healthCheckProvider);
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
        Future.delayed(const Duration(seconds: 5)).then((value) {
          setState(() {
            _status = 'IDLE';
          });
        });
      }
    });
    final (latency, downloadBandWidth, uploadBandWidth) =
        _getDataText(state.result.firstOrNull?.speedTestResult);
    final value =
        state.step == 'downloadBandwidth' ? downloadBandWidth : uploadBandWidth;
    final meterValue = state.step == 'latency'
        ? 0.0
        : _getRandomMeterValue(double.parse(value));
    final defaultMarkers = <double>[0, 1, 5, 10, 20, 30, 50, 75, 100];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_status == 'IDLE') _startButton(),
        if (_status != 'IDLE')
          Center(
            child: AnimatedMeter(
              size: 3.col,
              value: meterValue,
              markers: defaultMarkers,
              centerBuilder: (context, value) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText.titleSmall(switch (state.step) {
                      'latency' => '',
                      'downloadBandwidth' => loc(context).download,
                      'uploadBandwidth' => loc(context).upload,
                      _ => '',
                    }),
                    AppText.displayLarge(state.step == 'latency'
                        ? '—'
                        : (value).toStringAsFixed(1)),
                    const AppText.bodyMedium('Mbps'),
                  ],
                );
              },
              bottomBuilder: (context, value) {
                return const Center();
              },
            ),
          ),
        const AppGap.large5(),
        _resultCard(downloadBandWidth, uploadBandWidth),
        const AppGap.large3(),
        Wrap(
          direction: Axis.vertical,
          children: [
            AppText.bodySmall('Date & Time'),
            AppText.labelMedium(state.result.firstOrNull?.timestamp == null
                ? '--'
                : '${loc(context).systemTestDateFormat(DateTime.now())}|${loc(context).systemTestDateTime(DateTime.now())}'),
          ],
        ),
        const AppGap.large2(),
        Wrap(
          direction: Axis.vertical,
          children: [
            AppText.bodySmall('Server ID'),
            AppText.labelMedium(
                '${state.result.firstOrNull?.resultID ?? '--'}'),
          ],
        ),
        const AppGap.large2(),
        Wrap(
          direction: Axis.vertical,
          children: [
            AppText.bodySmall(loc(context).latency),
            AppText.labelMedium('$latency ms'),
          ],
        ),
        const AppGap.large5(),
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

  (String, String, String) _getDataText(SpeedTestResult? result) {
    var latency = result?.latency?.toStringAsFixed(0) ?? '-';
    var downloadBandWidth =
        ((result?.downloadBandwidth ?? 0) / 1000.0).toStringAsFixed(1);
    var uploadBandWidth =
        ((result?.uploadBandwidth ?? 0) / 1000.0).toStringAsFixed(1);
    return (latency, downloadBandWidth, uploadBandWidth);
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

  Widget _startButton() {
    return Container(
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
    );
  }

  Widget _resultCard(String downloadBandWidth, String uploadBandWidth) {
    final downloadBandWidthView = AppText.displaySmall(
        double.parse(downloadBandWidth) == 0 ? '—' : downloadBandWidth);
    final uploadBandWidthView = AppText.displaySmall(
        double.parse(uploadBandWidth) == 0 ? '—' : uploadBandWidth);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppText.titleSmall(loc(context).download),
              const AppGap.small2(),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Icon(LinksysIcons.download),
                  downloadBandWidthView,
                ],
              ),
              const AppGap.small2(),
              const AppText.bodyMedium('Mbps'),
            ],
          ),
        ),
        const AppGap.large2(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppText.titleSmall(loc(context).upload),
              const AppGap.small2(),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Icon(LinksysIcons.upload),
                  uploadBandWidthView,
                ],
              ),
              const AppGap.small2(),
              const AppText.bodyMedium('Mbps'),
            ],
          ),
        ),
      ],
    );
  }
}
