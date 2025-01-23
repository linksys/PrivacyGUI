import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/customs/rotating_icon.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/instant_admin/providers/manual_firmware_update_provider.dart';
import 'package:privacy_gui/page/instant_admin/providers/manual_firmware_update_state.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

class ManualFirmwareUpdateView extends ArgumentsConsumerStatefulView {
  const ManualFirmwareUpdateView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<ManualFirmwareUpdateView> createState() =>
      _ManualFirmwareUpdateViewState();
}

class _ManualFirmwareUpdateViewState
    extends ConsumerState<ManualFirmwareUpdateView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(manualFirmwareUpdateProvider);
    return state.status == null
        ? _mainContent(state.file)
        : _processingView(state.status);
  }

  Widget _mainContent(FileInfo? file) {
    return StyledAppPageView(
      title: getAppLocalizations(context).manualFirmwareUpdate,
      child: AppBasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppListCard(
              title: AppText.bodyLarge(loc(context).manual),
              description: AppText.labelMedium(
                  file == null ? loc(context).noFileChosen : file.name),
              trailing: AppTextButton.noPadding(
                file == null ? loc(context).chooseFile : loc(context).remove,
                icon: file == null ? LinksysIcons.upload : LinksysIcons.delete,
                color: file == null
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.error,
                onTap: () async {
                  if (file == null) {
                    final result = await FilePicker.platform.pickFiles();
                    if (result != null) {
                      ref.read(manualFirmwareUpdateProvider.notifier).setFile(
                          result.files.first.name, result.files.first.bytes!);
                      logger.d(
                          '[Manual Firmware update]: selected file: ${file?.name}');
                    }
                  } else {
                    ref
                        .read(manualFirmwareUpdateProvider.notifier)
                        .removeFile();
                  }
                },
              ),
            ),
            const AppGap.large2(),
            AppFilledButton(
              loc(context).start,
              onTap: file == null
                  ? null
                  : () {
                      ManualUpdateStatus? status = ManualUpdateInstalling(0);
                      ref
                          .read(manualFirmwareUpdateProvider.notifier)
                          .setStatus(status);
                      status.start(setState);
                      ref
                          .read(firmwareUpdateProvider.notifier)
                          .manualFirmwareUpdate(file!.name, file!.bytes ?? [])
                          .then((value) {
                        status?.stop();
                        status = ManualUpdateRebooting();
                        ref
                            .read(manualFirmwareUpdateProvider.notifier)
                            .setStatus(status);
                        ref
                            .read(firmwareUpdateProvider.notifier)
                            .waitForRouterBackOnline()
                            .then((_) {
                          handleSuccessUpdated();
                        }).catchError((error) {
                          setState(() {
                            status?.stop();
                            ref
                                .read(manualFirmwareUpdateProvider.notifier)
                                .setStatus(null);
                          });
                          showRouterNotFoundAlert(context, ref,
                              onComplete: () async {
                            handleSuccessUpdated();
                          });
                        }, test: (error) => error is JNAPSideEffectError);
                      }, onError: (error, stackTrace) {
                        setState(() {
                          status?.stop();
                          ref
                              .read(manualFirmwareUpdateProvider.notifier)
                              .setStatus(null);
                        });
                        if (error is ManualFirmwareUpdateException) {
                          _showErrorSnackbar(error.result);
                        } else {
                          _showErrorSnackbar();
                        }
                      });
                    },
            )
          ],
        ),
      ),
    );
  }

  Widget _processingView(ManualUpdateStatus? status) {
    return StyledAppPageView(
      appBarStyle: AppBarStyle.none,
      child: AppBasicLayout(
        content: Center(
          child: SizedBox(
            width: 6.col,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                status is ManualUpdateRebooting
                    ? RotatingIcon(
                        Icon(_getProcessingIcon(status),
                            size: 64,
                            color: Theme.of(context).colorScheme.primary),
                        reverse: true,
                      )
                    : Icon(_getProcessingIcon(status),
                        size: 64, color: Theme.of(context).colorScheme.primary),
                AppGap.medium(),
                AppText.titleLarge(_getProcessingTitle(status)),
                AppGap.medium(),
                AppText.bodyMedium(_getProcessingMessage(status)),
              ],
            ),
          ),
        ),
        footer: status is ManualUpdateInstalling
            ? Center(
                child: SizedBox(
                  width: 6.col,
                  child: Column(
                    children: [
                      LinearProgressIndicator(
                          value: double.tryParse(status.value) ?? 0,
                          backgroundColor: Theme.of(context)
                              .colorSchemeExt
                              .surfaceContainerHighest),
                      AppGap.small2(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText.bodyMedium(
                              loc(context).manualFirmwareEstimatedTime),
                          AppText.bodyMedium(DateFormatUtils.formatDuration(
                              Duration(
                                  seconds: (60 *
                                          (1 -
                                              (double.tryParse(status.value) ??
                                                  1)))
                                      .round()))),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            : Center(),
      ),
    );
  }

  void handleSuccessUpdated() {
    ref.read(manualFirmwareUpdateProvider.notifier).reset();
    _showSuccessSnackbar();
  }

  IconData _getProcessingIcon(ManualUpdateStatus? status) =>
      status is ManualUpdateInstalling
          ? LinksysIcons.cloudDownload
          : LinksysIcons.restartAlt;
  String _getProcessingTitle(ManualUpdateStatus? status) {
    return status is ManualUpdateInstalling
        ? loc(context).firmwareInstallingTitle
        : loc(context).firmwareRebootingTitle;
  }

  String _getProcessingMessage(ManualUpdateStatus? status) {
    return status is ManualUpdateInstalling
        ? '${loc(context).firmwareDownloadingMessage1}\n${loc(context).firmwareDownloadingMessage2}\n${loc(context).firmwareDownloadingMessage3}'
        : '${loc(context).firmwareRestartingMessage1}\n${loc(context).firmwareRestartingMessage2}\n${loc(context).firmwareRestartingMessage3}';
  }

  void _showSuccessSnackbar() {
    showSuccessSnackBar(context, loc(context).successExclamation);
  }

  void _showErrorSnackbar([String? error]) {
    final errorMessage = switch (error) {
      'ErrorSignatureCheckFailed' =>
        loc(context).errorManualUpdateSignatureCheckFailed,
      _ => loc(context).errorManualUpdateFailed,
    };
    showFailedSnackBar(context, errorMessage);
  }
}
