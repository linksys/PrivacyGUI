import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/customs/rotating_icon.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

sealed class ManualUpdateStatus<T> {
  T get value;
  void start(StateSetter setState);
  void stop();
}

class ManualUpdateInstalling implements ManualUpdateStatus<double> {
  int progress;
  StreamSubscription? _sub;

  ManualUpdateInstalling(this.progress);

  @override
  void start(StateSetter setState) {
    _sub = Stream.periodic(Duration(seconds: 1), (value) => value * 4)
        .listen((data) {
      setState(() {
        progress = data;
      });
    });
  }

  @override
  void stop() {
    _sub?.cancel();
  }

  ManualUpdateInstalling copyWith(int? progress) =>
      ManualUpdateInstalling(progress ?? this.progress);

  @override
  double get value => progress / 100.0;
}

class ManualUpdateRebooting implements ManualUpdateStatus<String> {
  @override
  String get value => throw UnimplementedError();

  @override
  void start(StateSetter setState) {}

  @override
  void stop() {}
}

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
  PlatformFile? _file;
  ManualUpdateStatus? _status;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _status == null ? _mainContent() : _processingView();
  }

  Widget _mainContent() {
    return StyledAppPageView(
      title: getAppLocalizations(context).manualFirmwareUpdate,
      bottomBar: PageBottomBar(
          isPositiveEnabled: _file != null,
          onPositiveTap: () {
            if (_file == null) {
              return;
            }

            setState(() {
              _status = ManualUpdateInstalling(0)..start(setState);
            });

            ref
                .read(firmwareUpdateProvider.notifier)
                .manualFirmwareUpdate(_file!.name, _file!.bytes ?? [])
                .then((value) {
              setState(() {
                _status?.stop();
                _status = ManualUpdateRebooting()..start(setState);
              });
              ref
                  .read(firmwareUpdateProvider.notifier)
                  .waitForRouterBackOnline()
                  .then((_) {
                setState(() {
                  _status?.stop();
                  _status = null;
                });
                _showSuccessSnackbar();
              });
            }, onError: (error, stackTrace) {
              setState(() {
                _status?.stop();
                _status = null;
              });
              if (error is ManualFirmwareUpdateException) {
                _showErrorSnackbar(error.result);
              } else {
                _showErrorSnackbar();
              }
            });

            // Future.delayed(Duration(seconds: 10)).then((_) {
            //   setState(() {
            //     _status?.stop();
            //     _status = ManualUpdateRebooting()..start(setState);
            //   });
            // });
          },
          positiveLabel: loc(context).start),
      child: AppBasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppListCard(
              title: AppText.bodyLarge(loc(context).manual),
              description: AppText.labelMedium(
                  _file == null ? loc(context).noFileChosen : _file!.name),
              trailing: AppTextButton.noPadding(
                _file == null ? loc(context).chooseFile : loc(context).remove,
                icon: _file == null ? LinksysIcons.upload : LinksysIcons.delete,
                color: _file == null
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.error,
                onTap: () async {
                  if (_file == null) {
                    final result = await FilePicker.platform.pickFiles();
                    if (result != null) {
                      setState(() {
                        _file = result.files.single;
                      });
                      logger.d(
                          '[Manual Firmware update]: selected file: ${_file?.name}');
                    }
                  } else {
                    setState(() {
                      _file = null;
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _processingView() {
    return StyledAppPageView(
      appBarStyle: AppBarStyle.none,
      child: AppBasicLayout(
        content: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _status is ManualUpdateRebooting
                  ? RotatingIcon(
                      Icon(_getProcessingIcon(),
                          size: 64,
                          color: Theme.of(context).colorScheme.primary),
                    )
                  : Icon(_getProcessingIcon(),
                      size: 64, color: Theme.of(context).colorScheme.primary),
              AppGap.medium(),
              AppText.titleLarge(_getProcessingTitle()),
              AppGap.medium(),
              AppText.bodyMedium(_getProcessingMessage()),
            ],
          ),
        ),
        footer: _status is ManualUpdateInstalling
            ? Column(
                children: [
                  LinearProgressIndicator(
                      value: _status is ManualUpdateInstalling
                          ? _status?.value ?? 0
                          : 1.0,
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
                              seconds:
                                  (60 * (1 - (_status?.value ?? 1))).round()))),
                    ],
                  ),
                ],
              )
            : Center(),
      ),
    );
  }

  IconData _getProcessingIcon() => _status is ManualUpdateInstalling
      ? LinksysIcons.cloudDownload
      : LinksysIcons.restartAlt;
  String _getProcessingTitle() {
    return _status is ManualUpdateInstalling
        ? loc(context).firmwareInstallingTitle
        : loc(context).firmwareRebootingTitle;
  }

  String _getProcessingMessage() {
    return _status is ManualUpdateInstalling
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
