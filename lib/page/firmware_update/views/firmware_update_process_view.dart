import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_ui_model.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:ui_kit_library/ui_kit.dart';

enum FirmwareUpdateStep {
  checking,
  downloading,
  installing,
  rebooting,
  ;

  static FirmwareUpdateStep resolve(String value) =>
      values
          .firstWhereOrNull((element) => element.name == value.toLowerCase()) ??
      FirmwareUpdateStep.checking;

  String getTitle(BuildContext context) => switch (this) {
        checking => loc(context).firmwareDownloadingTitle,
        downloading => loc(context).firmwareDownloadingTitle,
        installing => loc(context).firmwareInstallingTitle,
        rebooting => loc(context).firmwareRebootingTitle,
      };
  List<String> getMessages(BuildContext context) => switch (this) {
        checking => [
            loc(context).firmwareDownloadingMessage1,
            loc(context).firmwareDownloadingMessage2,
            loc(context).firmwareDownloadingMessage3,
          ],
        downloading => [
            loc(context).firmwareDownloadingMessage1,
            loc(context).firmwareDownloadingMessage2,
            loc(context).firmwareDownloadingMessage3,
          ],
        installing => [
            loc(context).firmwareDownloadingMessage1,
            loc(context).firmwareDownloadingMessage2,
            loc(context).firmwareDownloadingMessage3,
          ],
        rebooting => [
            loc(context).firmwareRestartingMessage1,
            loc(context).firmwareRestartingMessage2,
            loc(context).firmwareRestartingMessage3,
          ],
      };
}

class FirmwareUpdateProcessView extends ConsumerStatefulWidget {
  final FirmwareUpdateUIModel? current;
  const FirmwareUpdateProcessView({super.key, this.current});

  @override
  ConsumerState<FirmwareUpdateProcessView> createState() =>
      _FirmwareUpdateProcessViewState();
}

class _FirmwareUpdateProcessViewState
    extends ConsumerState<FirmwareUpdateProcessView> {
  @override
  Widget build(BuildContext context) {
    final step = FirmwareUpdateStep.resolve(widget.current?.operation ?? '0');
    final percent = widget.current?.progressPercent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(child: AppLoader()),
        AppGap.lg(),
        if (percent != null) ...[
          AppText.labelLarge('${widget.current?.deviceName ?? ''} - $percent%'),
          AppGap.lg(),
          AppText.titleSmall(step.getTitle(context)),
          AppGap.lg(),
          ...step.getMessages(context).map((e) => AppText.bodySmall(e)),
        ],
      ],
    );
  }
}
