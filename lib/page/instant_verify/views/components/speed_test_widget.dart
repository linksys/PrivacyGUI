import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:privacy_gui/core/jnap/models/health_check_result.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/customs/animated_digital_text.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/health_check/_health_check.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacy_gui/page/health_check/models/health_check_server.dart';
import 'package:privacy_gui/page/health_check/views/components/speed_test_server_selection_dialog.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart'; // For serviceHelper
import 'package:privacy_gui/di.dart'; // For getIt
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/animation/breath_dot.dart';
import 'package:privacygui_widgets/widgets/container/animated_meter.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/progress_bar/spinner.dart';

enum SpeedTestLayout {
  vertical,
  horizontal,
}

class SpeedTestWidget extends ConsumerStatefulWidget {
  final bool showDetails;
  final SpeedTestLayout layout;
  const SpeedTestWidget({
    super.key,
    this.showDetails = true,
    this.layout = SpeedTestLayout.vertical,
  });

  @override
  ConsumerState<SpeedTestWidget> createState() => _SpeedTestWidgetState();
}

class _SpeedTestWidgetState extends ConsumerState<SpeedTestWidget> {
  bool _loading = false;
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(healthCheckProvider);
    final latestSpeedTest = ref.watch(
        dashboardManagerProvider.select((state) => state.latestSpeedTest));
    final supportedBy = ref.watch(dashboardHomeProvider).healthCheckModule;

    final result =
        state.status == 'IDLE' ? latestSpeedTest : state.result.firstOrNull;

    final bandwidth = NetworkUtils.formatBitsWithUnit(
        state.status == 'COMPLETE'
            ? (result?.speedTestResult?.uploadBandwidth ?? 0) * 1000
            : (state.meterValue * 1000).toInt(),
        decimals: 1);

    final latency = result?.speedTestResult?.latency?.toStringAsFixed(0) ?? '0';

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.layout == SpeedTestLayout.vertical
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  meterView(state, result?.speedTestResult, bandwidth.value,
                      bandwidth.unit, latency),
                  if (widget.showDetails) const AppGap.large5(),
                  infoView(state),
                ],
              )
            : Row(
                children: [
                  meterView(state, result?.speedTestResult, bandwidth.value,
                      bandwidth.unit, latency),
                  if (widget.showDetails) const AppGap.large5(),
                  Expanded(child: infoView(state)),
                ],
              ),
        if (supportedBy == 'Ookla') ...[
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: Spacing.medium),
              child: Image(
                image: CustomTheme.of(context).images.speedtestPowered,
                fit: BoxFit.fitWidth,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget meterView(
    HealthCheckState state,
    SpeedTestResult? result,
    String bandwidthValue,
    String bandwidthUnit,
    String latency,
  ) {
    final defaultMarkers = <double>[0, 1, 5, 10, 20, 30, 50, 75, 100];

    return _loading
        ? const Center(
            child: SizedBox(
              height: 220,
              width: 220,
              child: AppSpinner(),
            ),
          )
        : state.status == 'IDLE'
            ? _startButton()
            : Center(
                child: AnimatedMeter(
                  size: 3.col,
                  value: double.tryParse(bandwidthValue) ?? 0,
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
                        AppText.displayLarge(
                            state.step == 'latency' ? '—' : bandwidthValue),
                        if (state.step == 'downloadBandwidth' ||
                            state.step == 'uploadBandwidth')
                          AppText.bodyMedium('${bandwidthUnit}ps'),
                      ],
                    );
                  },
                  bottomBuilder: (context, value) {
                    return state.status == 'COMPLETE'
                        ? AppTextButton(
                            key: const Key('speedTestTestAgain'),
                            loc(context).testAgain,
                            onTap: () {
                              run();
                            },
                          )
                        : pingView(state.step, latency);
                  },
                ),
              );
  }

  Widget pingView(String step, String latency) {
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

  Widget infoView(HealthCheckState state) {
    final latestSpeedTest = ref.watch(
        dashboardManagerProvider.select((state) => state.latestSpeedTest));

    final result =
        state.status == 'IDLE' ? latestSpeedTest : state.result.firstOrNull;

    final latency = result?.speedTestResult?.latency?.toStringAsFixed(0) ?? '-';

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.showDetails) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.medium),
            child: Wrap(
              direction: Axis.vertical,
              children: [
                AppText.bodySmall(loc(context).dateAndTime),
                AppText.labelMedium(
                    key: ValueKey('speedTestDateTime'),
                    result?.timestamp == null
                        ? '--'
                        : _getDateTimeText(result?.timestamp)),
              ],
            ),
          ),
          AppGap.small2(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.medium),
            child: Wrap(
              direction: Axis.horizontal,
              runSpacing: Spacing.small2,
              spacing: Spacing.small2,
              children: [
                AppText.bodySmall(loc(context).latency),
                AppText.labelMedium('$latency ms'),
              ],
            ),
          ),
          AppGap.medium()
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.medium),
          child: _resultCard(result?.speedTestResult),
        ),
        if (widget.showDetails) ...[
          const Divider(
            thickness: 1,
            height: Spacing.large5,
          ),
          Wrap(
            direction: Axis.vertical,
            children: [
              AppText.bodySmall(loc(context).dateAndTime),
              AppText.labelMedium(
                  key: ValueKey('speedTestDateTime'),
                  result?.timestamp == null
                      ? '--'
                      : _getDateTimeText(result?.timestamp)),
            ],
          ),
          const AppGap.large2(),
          Wrap(
            direction: Axis.vertical,
            children: [
              AppText.bodySmall(loc(context).serverId),
              AppText.labelMedium('${result?.resultID ?? '--'}'),
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
        ],
      ],
    );
  }

  Future<void> run() async {
    setState(() {
      _loading = true;
    });

    final notifier = ref.read(healthCheckProvider.notifier);
    final serviceHelper = getIt<ServiceHelper>();
    HealthCheckServer? targetServer;

    try {
      if (serviceHelper.isSupportHealthCheckManager2()) {
        final servers = await notifier.updateServers();
        // Check state after fetch
        if (servers.isNotEmpty) {
          if (mounted) {
            final selectionNotifier =
                ValueNotifier<HealthCheckServer?>(servers.firstOrNull);

            final selected = await showSimpleAppDialog<HealthCheckServer>(
              context,
              title: 'Select Speed Test Server',
              content: SpeedTestServerSelectionList(
                servers: servers,
                notifier: selectionNotifier,
              ),
              actions: [
                AppTextButton(
                  loc(context).cancel,
                  onTap: () => context.pop(),
                ),
                ValueListenableBuilder<HealthCheckServer?>(
                    valueListenable: selectionNotifier,
                    builder: (context, value, child) {
                      return AppTextButton(
                        loc(context).ok,
                        onTap: value != null ? () => context.pop(value) : null,
                      );
                    })
              ],
            );

            if (selected == null) {
              // User cancelled
              setState(() {
                _loading = false;
              });
              return;
            }
            targetServer = selected;
          } else {
            setState(() {
              _loading = false;
            });
            return;
          }
        }
      }

      int? serverId;
      if (targetServer != null) {
        serverId = int.tryParse(targetServer.serverID);
      }

      notifier.runHealthCheck(Module.speedtest, serverId: serverId);

      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _loading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String _getDateTimeText(String? timestamp) {
    final speedTestTimeStamp = DateFormat("yyyy-MM-ddThh:mm:ssZ")
        .tryParse(timestamp ?? '', true)
        ?.millisecondsSinceEpoch;
    final dateTime = speedTestTimeStamp == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(speedTestTimeStamp);
    return dateTime == null
        ? ''
        : '${loc(context).systemTestDateFormat(dateTime)} ${loc(context).systemTestDateTime(dateTime)}';
  }

  Widget _startButton() {
    return Container(
      alignment: Alignment.center,
      child: AnimatedMeter.withDefaultMarks(
        size: 220,
        displayIndicatorValues: false,
        indicatorPathStrokeWidth: 8,
        markerRadius: 2,
        centerBuilder: (context, value) {
          return Container(
            width: 102,
            height: 102,
            child: InkWell(
              key: const Key('goBtn'),
              borderRadius:
                  CustomTheme.of(context).radius.asBorderRadius().extraLarge,
              onTap: () {
                final isSpeedCheckSupported = ref
                    .read(dashboardManagerProvider.notifier)
                    .isHealthCheckModuleSupported('SpeedTest');
                if (isSpeedCheckSupported) {
                  run();
                } else {
                  context.pushNamed(RouteNamed.speedTestExternal);
                }
              },
              child: Ink(
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary),
                child: Center(
                  child: AppText.bodyLarge(
                    loc(context).go,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          );
        },
        value: 0,
      ),
    );
  }

  Widget _resultCard(SpeedTestResult? result) {
    final downloadBandWidthIntBits = (result?.downloadBandwidth ?? 0) * 1000;
    final uploadBandWidthIntBits = (result?.uploadBandwidth ?? 0) * 1000;
    final downloadFormat =
        NetworkUtils.formatBitsWithUnit(downloadBandWidthIntBits, decimals: 1);
    final uploadFormat =
        NetworkUtils.formatBitsWithUnit(uploadBandWidthIntBits, decimals: 1);
    final downloadBandWidthView = FittedBox(
      fit: BoxFit.scaleDown,
      child: AppText.displaySmall(
          key: ValueKey('downloadBandWidth'),
          downloadBandWidthIntBits == 0 ? '—' : downloadFormat.value),
    );
    final uploadBandWidthView = FittedBox(
      fit: BoxFit.scaleDown,
      child: AppText.displaySmall(
          key: ValueKey('uploadBandWidth'),
          uploadBandWidthIntBits == 0 ? '—' : uploadFormat.value),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppText.bodyExtraSmall(loc(context).download),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(Spacing.small2),
                    child: Icon(
                      LinksysIcons.arrowDownward,
                      semanticLabel: 'download icon',
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Expanded(child: downloadBandWidthView),
                ],
              ),
              AppText.bodyExtraSmall(downloadBandWidthIntBits > 0
                  ? '${downloadFormat.unit}ps'
                  : ''),
            ],
          ),
        ),
        const AppGap.large2(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppText.bodyExtraSmall(loc(context).upload),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(Spacing.small2),
                    child: Icon(
                      LinksysIcons.arrowUpward,
                      semanticLabel: 'upload icon',
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Expanded(child: uploadBandWidthView),
                ],
              ),
              AppText.bodyExtraSmall(
                  uploadBandWidthIntBits > 0 ? '${uploadFormat.unit}ps' : ''),
            ],
          ),
        ),
      ],
    );
  }
}
