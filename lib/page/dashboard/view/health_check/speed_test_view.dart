import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
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
  String _status = "IDLE";

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 5));
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
    return StyledAppPageView(
      child: AppBasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        header: const Text(
          'Speed Test',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: _content(context),
      ),
    );
  }

  Widget _content(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          image: DecorationImage(
              image: AppTheme.of(context).images.speedtestBg,
              fit: BoxFit.fitWidth)),
      child: Stack(children: [
        Container(
          alignment: Alignment.bottomLeft,
          child: Image(
            image: AppTheme.of(context).images.speedtestPowered,
            fit: BoxFit.fitWidth,
          ),
        ),
        Container(
            alignment: Alignment.center,
            child: speedTestSection(context, _status))
      ]),
    );
  }

  Widget speedTestSection(BuildContext context, String status) {
    switch (status) {
      case "IDLE":
        return TriLayerButton(
          child: const Text('START'),
          onPressed: () {
            Future.delayed(const Duration(milliseconds: 500), () {
              setState(() {
                _status = "RUNNING";
                _controller.forward();
              });
              //TODO: Build RunSpeedTest function
            });
          },
        );
      case "RUNNING":
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return CircleProgressBar(
              progress: _animation.value,
              strokeWidth: 8.0,
              backgroundColor: Colors.white,
            );
          },
        );
      case "COMPLETE":
        return const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppText.displaySmall('Upload'),
                AppText.displaySmall('Download'),
              ],
            ),
            AppGap.regular(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppText.displaySmall('98Mbps'),
                AppText.displaySmall('24Mpbs'),
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
