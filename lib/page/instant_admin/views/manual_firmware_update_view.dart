import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/customs/rotating_icon.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/instant_admin/providers/manual_firmware_update_provider.dart';
import 'package:privacy_gui/page/instant_admin/providers/manual_firmware_update_state.dart';
import 'package:privacy_gui/page/instant_admin/services/manual_firmware_update_service.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ui_kit_library/ui_kit.dart';

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
    return UiKitPageView.withSliver(
      title: loc(context).manualFirmwareUpdate,
      child: (context, constraints) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildListCard(
            title: loc(context).manual,
            description: file == null ? loc(context).noFileChosen : file.name,
            trailing: AppButton.text(
              label:
                  file == null ? loc(context).chooseFile : loc(context).remove,
              icon: AppIcon.font(
                  file == null ? AppFontIcons.upload : AppFontIcons.delete),
              onTap: () async {
                if (file == null) {
                  final result = await FilePicker.platform.pickFiles();
                  if (!mounted) return;
                  if (result != null) {
                    ref.read(manualFirmwareUpdateProvider.notifier).setFile(
                        result.files.first.name, result.files.first.bytes!);
                    logger.d(
                        '[Manual Firmware update]: selected file: ${file?.name}');
                  }
                } else {
                  ref.read(manualFirmwareUpdateProvider.notifier).removeFile();
                }
              },
            ),
          ),
          AppGap.xxl(),
          AppButton.primary(
            label: loc(context).start,
            onTap: file == null
                ? null
                : () {
                    ManualUpdateStatus? status = ManualUpdateInstalling(0);
                    ref
                        .read(manualFirmwareUpdateProvider.notifier)
                        .setStatus(status);
                    status.start(setState);
                    ref
                        .read(manualFirmwareUpdateProvider.notifier)
                        .manualFirmwareUpdate(file.name, file.bytes)
                        .then((value) {
                      status?.stop();
                      status = ManualUpdateRebooting();
                      ref
                          .read(manualFirmwareUpdateProvider.notifier)
                          .setStatus(status);
                      ref
                          .read(manualFirmwareUpdateProvider.notifier)
                          .waitForRouterBackOnline()
                          .then((_) {
                        handleSuccessUpdated();
                      }).catchError((error) {
                        if (!mounted) return;
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
                      },
                              test: (error) =>
                                  error is ServiceSideEffectError).catchError(
                              (error) {
                        if (!mounted) return;
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
                      }, test: (error) => error is TimeoutException);
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
    );
  }

  Widget _processingView(ManualUpdateStatus? status) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.5,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  status is ManualUpdateRebooting
                      ? RotatingIcon(
                          AppIcon.font(_getProcessingIcon(status),
                              size: 64,
                              color: Theme.of(context).colorScheme.primary),
                          reverse: true,
                        )
                      : Icon(_getProcessingIcon(status),
                          size: 64,
                          color: Theme.of(context).colorScheme.primary),
                  AppGap.lg(),
                  AppText.titleLarge(_getProcessingTitle(status)),
                  AppGap.lg(),
                  AppText.bodyMedium(_getProcessingMessage(status)),
                ],
              ),
            ),
          ),
        ),
        status is ManualUpdateInstalling
            ? Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: Column(
                    children: [
                      AppLoader(
                        variant: LoaderVariant.linear,
                      ),
                    ],
                  ),
                ),
              )
            : Center(),
        AppGap.lg(),
      ],
    );
  }

  /// Composed ListCard
  Widget _buildListCard({
    required String title,
    required String description,
    Widget? trailing,
  }) {
    return AppCard(
      padding: EdgeInsets.symmetric(
        vertical: AppSpacing.lg,
        horizontal: AppSpacing.xxl,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodyLarge(title),
                AppGap.xs(),
                AppText.labelMedium(description),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  void handleSuccessUpdated() {
    if (!mounted) return;
    ref.read(manualFirmwareUpdateProvider.notifier).reset();
    SharedPreferences.getInstance().then((pref) {
      pref.setBool(pFWUpdated, true);
    });
    _showSuccessSnackbar();
    // Navigate to dashboard after firmware update is success
    context.go(RouteNamed.dashboardHome);
  }

  IconData _getProcessingIcon(ManualUpdateStatus? status) =>
      status is ManualUpdateInstalling
          ? AppFontIcons.cloudDownload
          : AppFontIcons.restartAlt;
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
