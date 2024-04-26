import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/models/health_check_result.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/page/health_check/providers/health_check_provider.dart';
import 'package:linksys_app/page/health_check/providers/health_check_state.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/animation/breath_dot.dart';
import 'package:linksys_widgets/widgets/container/animated_meter.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

import 'speed_test_button.dart';

class SpeedTestView extends ArgumentsConsumerStatefulView {
  const SpeedTestView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<SpeedTestView> createState() => _SpeedTestViewState();
}

class _SpeedTestViewState extends ConsumerState<SpeedTestView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  List<String> _markers = [];

  String _status = "IDLE";

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 45));
    _animation = Tween(begin: 0.0, end: 1.0).animate(_controller)
      ..addListener(() {
        if (_controller.isCompleted) {
          setState(() {
            _status = "COMPLETE";
          });
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final healthCheck = ref.watch(healthCheckProvider);
    return StyledAppPageView(
      title: 'Speed Test',
      child: AppBasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        content: switch (_status) {
          "RUNNING" =>
            _runningView(healthCheck.result.firstOrNull?.speedTestResult),
          "COMPLETE" =>
            _finishView(healthCheck.result.firstOrNull?.speedTestResult),
          _ => _initView()
        },
      ),
    );
  }

  Widget _gradientBackground() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
            colors: [
              Color(0xffeff3ff),
              Color(0xffd8e2ff),
              Color(0xff005bc1),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
                radius: 0.3,
                center: Alignment.center,
                colors: [Color(0xffe9efff), Color(0x00ffffff)]),
          ),
        ),
      ],
    );
  }

  Widget _initView() {
    return Stack(children: [
      _gradientBackground(),
      Container(
        alignment: Alignment.bottomCenter,
        padding: EdgeInsets.only(bottom: 24),
        child: Image(
          image: CustomTheme.of(context).images.speedtestPowered,
          fit: BoxFit.fitWidth,
        ),
      ),
      Container(
        alignment: Alignment.center,
        child: InkWell(
          onTap: () {
            Future.delayed(const Duration(milliseconds: 500), () {
              setState(() {
                _status = "RUNNING";
                _controller.forward();
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
                'GO',
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _runningView(SpeedTestResult? result) {
    final (latency, downloadBandWidth, uploadBandWidth) = _getDataText(result);
    final isDownload = uploadBandWidth == '0';
    final value = uploadBandWidth == '0' ? downloadBandWidth : uploadBandWidth;
    return AnimatedMeter(
      value: double.parse(value),
      markers: _markers,
      centerBuilder: (context, value) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText.labelMedium(isDownload ? 'Download' : 'Upload'),
            AppText.titleLarge((100 * value).toStringAsFixed(2)),
            AppText.bodySmall('Mbps')
          ],
        );
      },
      bottomBuilder: (context, value) {
        return Wrap(
          alignment: WrapAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: BreathDot(
                breathSpeed: const Duration(seconds: 1),
                lightColor: Theme.of(context).colorScheme.primary,
                borderColor: Theme.of(context).colorScheme.primary,
                size: 12,
                dotSize: 8,
              ),
            ),
            AppText.labelMedium(
              'Ping:',
              color: Theme.of(context).colorScheme.primary,
            ),
            AppText.bodySmall(
              '--ms',
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        );
      },
    );
  }

  Widget _finishView(SpeedTestResult? result) {
    final (latency, downloadBandWidth, uploadBandWidth) = _getDataText(result);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const AppText.displaySmall("Latency"),
            const AppGap.regular(),
            AppText.displaySmall(latency),
          ],
        ),
        const AppGap.regular(),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AppText.displaySmall('Upload'),
            AppText.displaySmall('Download'),
          ],
        ),
        const AppGap.regular(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AppText.displaySmall(uploadBandWidth),
            AppText.displaySmall(downloadBandWidth),
          ],
        ),
      ],
    );
  }

  (String, String, String) _getDataText(SpeedTestResult? result) {
    var latency = result?.latency?.toStringAsFixed(2) ?? '--';
    var downloadBandWidth =
        ((result?.downloadBandwidth ?? 0) / 1000.0).toStringAsFixed(2);
    var uploadBandWidth =
        ((result?.uploadBandwidth ?? 0) / 1000.0).toStringAsFixed(2);
    return (latency, downloadBandWidth, uploadBandWidth);
  }

  Widget _content(BuildContext context, HealthCheckState state) {
    return Stack(children: [
      Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
          colors: [
            Color(0xffeff3ff),
            Color(0xffd8e2ff),
            Color(0xff005bc1),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        )),
      ),
      Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
              radius: 0.3,
              center: Alignment.center,
              colors: [Color(0xffe9efff), Color(0x00ffffff)]),
        ),
      ),
      Container(
        alignment: Alignment.bottomCenter,
        padding: EdgeInsets.only(bottom: 24),
        child: Image(
          image: CustomTheme.of(context).images.speedtestPowered,
          fit: BoxFit.fitWidth,
        ),
      ),
      Container(
          alignment: Alignment.center,
          child: speedTestSection(context, _status, state))
    ]);
  }

  Widget speedTestSection(
      BuildContext context, String status, HealthCheckState state) {
    if (state.result.isNotEmpty) {
      logger.d('XXXXX health check - ${state.result.first}');
    }

    var downloadBandWidth = '0';
    if (state.result.isNotEmpty &&
        state.result.first.speedTestResult?.downloadBandwidth != null) {
      downloadBandWidth =
          state.result.first.speedTestResult!.downloadBandwidth.toString();
    }
    downloadBandWidth = (int.parse(downloadBandWidth) ~/ 1000).toString();
    var uploadBandWidth = '0';
    if (state.result.isNotEmpty &&
        state.result.first.speedTestResult?.uploadBandwidth != null) {
      uploadBandWidth =
          state.result.first.speedTestResult!.uploadBandwidth.toString();
    }
    uploadBandWidth = (int.parse(uploadBandWidth) ~/ 1000).toString();
    var latency = '0';
    if (state.result.isNotEmpty &&
        state.result.first.speedTestResult?.latency != null) {
      latency = state.result.first.speedTestResult!.latency.toString();
    }
    final defaultMarkers = ['1', '5', '10', '20', '30', '50', '75', '100'];
    if (_markers.isEmpty) {
      _markers = defaultMarkers;
    }
    var dl = int.parse(downloadBandWidth);
    var ul = int.parse(uploadBandWidth);
    var valueMax = max(dl, ul);
    var isDownload = dl > 0 && ul == 0;
    if (valueMax > 0 && valueMax > int.parse(_markers.last)) {
      // rearrange markers
    }

    switch (status) {
      case "IDLE":
        return InkWell(
          onTap: () {
            Future.delayed(const Duration(milliseconds: 500), () {
              setState(() {
                _status = "RUNNING";
                _controller.forward();
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
                'GO',
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        );
      case "RUNNING":
        var value = Random().nextDouble();
        logger.d('XXXXX: meter value : $value');

        return AnimatedMeter(
          value: value,
          markers: _markers,
          centerBuilder: (context, value) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText.labelMedium(isDownload ? 'Download' : 'Upload'),
                AppText.titleLarge((100 * value).toStringAsFixed(2)),
                AppText.bodySmall('Mbps')
              ],
            );
          },
          bottomBuilder: (context, value) {
            return Wrap(
              alignment: WrapAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: BreathDot(
                    breathSpeed: const Duration(seconds: 1),
                    lightColor: Theme.of(context).colorScheme.primary,
                    borderColor: Theme.of(context).colorScheme.primary,
                    size: 12,
                    dotSize: 8,
                  ),
                ),
                AppText.labelMedium(
                  'Ping:',
                  color: Theme.of(context).colorScheme.primary,
                ),
                AppText.bodySmall(
                  '--ms',
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            );
          },
        );
      case "COMPLETE":
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const AppText.displaySmall("Latency"),
                const AppGap.regular(),
                AppText.displaySmall(latency),
              ],
            ),
            const AppGap.regular(),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppText.displaySmall('Upload'),
                AppText.displaySmall('Download'),
              ],
            ),
            const AppGap.regular(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppText.displaySmall(uploadBandWidth),
                AppText.displaySmall(downloadBandWidth),
              ],
            ),
          ],
        );
      default:
        return Container();
    }
  }

  //TODO: Create a speed test provider and move this function into it
  /*
  Future<void> runHealthCheck() async {
    final repo = ref.read(routerRepositoryProvider);
    final result = await repo.send(JNAPAction.runHealthCheck);
    if (result.output['resultID'] != null) {
      Timer.periodic(const Duration(seconds: 5), (timer) async {
        final speedTestResult = await getHealthCheckStatus();
        if (speedTestResult.exitCode != 'Unavailable') {
          final selected = state.selected!;
          MoabNetwork selectedCopy = MoabNetwork(
              id: selected.id,
              deviceInfo: selected.deviceInfo,
              // wanStatus: selected.wanStatus,
              radioInfo: selected.radioInfo,
              devices: selected.devices,
              healthCheckResults: selected.healthCheckResults,
              currentSpeedTestStatus: null);
          state = state.copyWith(selected: selectedCopy);
          getHealthCheckResults();
          timer.cancel();
        }
      });
    }
  }
  //TODO: Integrate the following with DashboardManagerProvider
  Future<void> getHealthCheckResults() async {
    final repo = ref.read(routerRepositoryProvider);
    final result = await repo.send(JNAPAction.getHealthCheckResults);
    final healthCheckResults = List.from(result.output['healthCheckResults'])
        .map((e) => HealthCheckResult.fromJson(e))
        .toList();
    _handleHealthCheckResults(healthCheckResults);
  }

  _handleHealthCheckResults(List<HealthCheckResult> healthCheckResults) {
    state = state.copyWith(
      selected: 
        state.selected!.copyWith(healthCheckResults: healthCheckResults));
  }
  */
}
