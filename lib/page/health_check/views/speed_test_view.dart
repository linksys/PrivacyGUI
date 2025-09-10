import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:privacy_gui/core/jnap/models/health_check_result.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/dashboard/_dashboard.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_provider.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_state.dart';
import 'package:privacy_gui/page/components/customs/animated_digital_text.dart';
import 'package:privacy_gui/utils.dart';
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

    return StyledAppPageView(
      scrollable: true,
      title: loc(context).speedTest,
      bottomBar: state.status == 'COMPLETE'
          ? PageBottomBar(
              positiveLabel: loc(context).testAgain,
              isPositiveEnabled: true,
              onPositiveTap: () {
                ref
                    .read(healthCheckProvider.notifier)
                    .runHealthCheck(Module.speedtest);
              },
            )
          : null,
      child: (context, constraints) => switch (state.status) {
        'RUNNING' => ResponsiveLayout(
            desktop: Container(
              margin: const EdgeInsets.fromLTRB(0, 0, 0, 40),
              child: Center(
                child: _runningView(
                  state,
                ),
              ),
            ),
            mobile: _runningView(state),
          ),
        'COMPLETE' => ResponsiveLayout(
            desktop: Container(
              margin: const EdgeInsets.fromLTRB(0, 0, 0, 40),
              child: Container(
                alignment: state.step != 'error'
                    ? Alignment.topCenter
                    : Alignment.topLeft,
                child: _finishView(
                  state,
                ),
              ),
            ),
            mobile: _finishView(
              state,
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

  Widget _runningView(HealthCheckState state) {
    final latestSpeedTest = ref.watch(
        dashboardManagerProvider.select((state) => state.latestSpeedTest));

    final result =
        state.status == 'IDLE' ? latestSpeedTest : state.result.firstOrNull;

    final latency = result?.speedTestResult?.latency?.toStringAsFixed(0) ?? '-';

    final bandwidth = NetworkUtils.formatBytesWithUnit(
        state.status == 'COMPLETE'
            ? (result?.speedTestResult?.uploadBandwidth ?? 0) * 1024
            : (state.meterValue * 1024).toInt(),
        decimals: 1);

    return ResponsiveLayout(
      desktop: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 7.col,
            child: _meterView(
                state.step, bandwidth.value, bandwidth.unit, latency),
          ),
          const AppGap.gutter(),
          SizedBox(
            width: 5.col,
            child: _infoView(state),
          ),
        ],
      ),
      mobile: Column(
        children: [
          _meterView(state.step, bandwidth.value, bandwidth.unit, latency),
          const AppGap.medium(),
          const Spacer(),
          _infoView(state),
          const AppGap.medium(),
        ],
      ),
    );
  }

  Widget _meterView(String step, String value, String unit, String latency) {
    final defaultMarkers = <double>[0, 1, 5, 10, 20, 30, 50, 75, 100];
    return AnimatedMeter(
      size: ResponsiveLayout.isMobileLayout(context) ? 4.col : 5.col,
      value: double.tryParse(value) ?? 0,
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
            if (step == 'downloadBandwidth' || step == 'uploadBandwidth')
              AppText.bodyMedium(unit),
          ],
        );
      },
      bottomBuilder: (context, value) {
        return _pingView(step, latency);
      },
    );
  }

  Widget _pingView(String step, String latency) {
    final isLatencyStep = step == 'latency' || latency == '0';
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
                animated: isLatencyStep,
              ),
            ),
            AppText.titleSmall(
              'Ping: ',
              color: Theme.of(context).colorScheme.primary,
            ),
            if (isLatencyStep)
              AnimatedDigitalText(
                fontSize: 12,
                fontColor: Theme.of(context).colorScheme.primary,
              ),
            if (!isLatencyStep) ...[
              AppText.bodyMedium(
                latency,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
            AppText.bodyMedium(
              'ms',
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
        if (step != 'success') const AppGap.large2(),
      ],
    );
  }

  Widget _infoView(HealthCheckState state) {
    final result = state.result.firstOrNull;

    final downloadBandwidth = NetworkUtils.formatBytesWithUnit(
        (result?.speedTestResult?.downloadBandwidth ?? 0) * 1024,
        decimals: 1);
    final uploadBandwidth = NetworkUtils.formatBytesWithUnit(
        (result?.speedTestResult?.uploadBandwidth ?? 0) * 1024,
        decimals: 1);
    final step = state.step;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _descriptionCard(step),
        if (step != 'latency') const AppGap.small3(),
        if (step != 'latency')
          _resultCard(
              state.status,
              downloadBandwidth.value,
              downloadBandwidth.unit,
              uploadBandwidth.value,
              uploadBandwidth.unit),
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

  Widget _resultCard(String status, String downloadValue, String? downloadUnit,
      String uploadValue, String? uploadUnit) {
    final downloadBandWidthView =
        status == 'RUNNING' && !ResponsiveLayout.isMobileLayout(context)
            ? AppText.displaySmall(
                double.parse(downloadValue) == 0 ? '—' : downloadValue,
                key: Key('downloadBandWidth'),
              )
            : AppText.displayLarge(
                double.parse(downloadValue) == 0 ? '—' : downloadValue,
                key: Key('downloadBandWidth'),
              );
    final uploadBandWidthView =
        status == 'RUNNING' && !ResponsiveLayout.isMobileLayout(context)
            ? AppText.displaySmall(
                double.parse(uploadValue) == 0 ? '—' : uploadValue,
                key: Key('uploadBandWidth'),
              )
            : AppText.displayLarge(
                double.parse(uploadValue) == 0 ? '—' : uploadValue,
                key: Key('uploadBandWidth'),
              );
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
                AppText.bodyMedium(downloadUnit ?? ''),
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
                AppText.bodyMedium(uploadUnit ?? ''),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _finishView(HealthCheckState state) {
    final latestSpeedTest = ref.watch(
        dashboardManagerProvider.select((state) => state.latestSpeedTest));

    final result =
        state.status == 'IDLE' ? latestSpeedTest : state.result.firstOrNull;
    final downloadBandWidth = NetworkUtils.formatBytesWithUnit(
        (result?.speedTestResult?.downloadBandwidth ?? 0) * 1024,
        decimals: 1);
    final uploadBandWidth = NetworkUtils.formatBytesWithUnit(
        (result?.speedTestResult?.uploadBandwidth ?? 0) * 1024,
        decimals: 1);
    final latency = result?.speedTestResult?.latency?.toStringAsFixed(0) ?? '-';

    final (resultTitle, resultDesc) =
        _getTestResultDesc(result?.speedTestResult);
    final date = _getTestResultDate(result?.timestamp);
    return switch (state.step) {
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
                AppText.bodyMedium(
                    state.error?.result ?? loc(context).unknownError),
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
                      child: _pingView(state.step, latency),
                    ),
                    const AppGap.small2(),
                    _resultCard(
                        state.status,
                        downloadBandWidth.value,
                        downloadBandWidth.unit,
                        uploadBandWidth.value,
                        uploadBandWidth.unit),
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
                child: _pingView(state.step, latency),
              ),
              const AppGap.small2(),
              _resultCard(
                  state.status,
                  downloadBandWidth.value,
                  downloadBandWidth.unit,
                  uploadBandWidth.value,
                  uploadBandWidth.unit),
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

  (String, String, String) _getDataText(SpeedTestResult? result) {
    var latency = result?.latency?.toStringAsFixed(0) ?? '—';
    var downloadBandWidth =
        ((result?.downloadBandwidth ?? 0) / 1024.0).toStringAsFixed(1);
    var uploadBandWidth =
        ((result?.uploadBandwidth ?? 0) / 1024.0).toStringAsFixed(1);
    return (latency, downloadBandWidth, uploadBandWidth);
  }

  (String, String) _getTestResultDesc(SpeedTestResult? result) {
    var downloadBandWidth = (result?.downloadBandwidth ?? 0) / 1024.0;
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
