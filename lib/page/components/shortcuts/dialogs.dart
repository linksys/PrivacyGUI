import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/providers/redirection/redirection_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

const kDefaultDialogWidth = 328.0;

Future<T?> doSomethingWithSpinner<T>(
  BuildContext context,
  Future<T> task, {
  IconData? icon,
  String? title,
  List<String>? messages,
  Duration? period,
}) async {
  NavigatorState? navigator;
  final completer = Completer();
  Future.delayed(Duration.zero, () {
    try {
      if (context.mounted) {
        navigator = Navigator.of(context, rootNavigator: true);
        showAppSpinnerDialog(
          context,
          title: title,
          icon: icon,
          messages: messages ?? [loc(context).processing],
          period: period,
        );
      }
    } catch (e) {
      logger.w('Could not show spinner dialog: $e');
    }
    completer.complete();
  });

  await completer.future;
  await Future.delayed(const Duration(milliseconds: 100));
  return task.then((value) {
    return value;
  }).onError((error, stackTrace) {
    throw error ?? '';
  }).whenComplete(() {
    try {
      navigator?.pop();
    } catch (e) {
      logger.w(
          'doSomethingWithSpinner failed to pop. This might be intentional if the caller pops a page. Error: $e');
    }
  });
}

Future<T?> showAppSpinnerDialog<T>(
  BuildContext context, {
  IconData? icon,
  String? title,
  Widget? loadingWidget,
  double? width,
  List<String> messages = const [],
  Duration? period,
  List<Widget>? actions = const [],
}) {
  return showDialog<T?>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        int currentIndex = 0;
        final stream = Stream.periodic(period ?? const Duration(seconds: 3))
            .map((_) => messages[currentIndex++ % messages.length]);

        return StreamBuilder<String>(
            stream: stream,
            initialData: messages.firstOrNull,
            builder: (context, snapshot) {
              return AppDialog(
                icon: icon,
                title: title != null
                    ? SizedBox(
                        width: width ?? kDefaultDialogWidth,
                        child: AppText.titleLarge(title))
                    : null,
                content: SizedBox(
                  width: width ?? kDefaultDialogWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      loadingWidget ?? const AppLoader(),
                      if (snapshot.hasData) ...[
                        AppGap.md(),
                        AppText.labelLarge(snapshot.data!)
                      ]
                    ],
                  ),
                ),
                actions: actions,
              );
            });
      });
    },
  );
}

Future<T?> showSubmitAppDialog<T>(
  BuildContext context, {
  IconData? icon,
  String? title,
  required Widget Function(BuildContext, StateSetter, void Function())
      contentBuilder,
  Widget? loadingWidget,
  double? width,
  String? negitiveLabel,
  String? positiveLabel,
  bool Function()? checkPositiveEnabled,
  bool scrollable = false,
  bool useRootNavigator = true,
  required Future<T> Function() event,
  void Function(Object? error, StackTrace stackTrace)? onError,
}) {
  bool isLoading = false;
  return showDialog<T?>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        void onSubmit() {
          setState(() {
            isLoading = true;
          });
          event.call().then((value) {
            setState(() {
              isLoading = false;
            });
            if (context.mounted) {
              context.pop(value);
            }
          }).onError((error, stackTrace) {
            logger.e('submit app error: $error', stackTrace: stackTrace);
            setState(() {
              isLoading = false;
            });
            onError?.call(error, stackTrace);
          });
        }

        return AppDialog(
          icon: icon,
          title: title != null
              ? SizedBox(
                  width: width ?? kDefaultDialogWidth,
                  child: AppText.titleLarge(title))
              : null,
          scrollable: scrollable,
          content: SizedBox(
              width: width ?? kDefaultDialogWidth,
              child: switch (isLoading) {
                true => loadingWidget ?? const AppLoader(),
                false => contentBuilder(context, setState, onSubmit),
              }),
          actions: isLoading
              ? []
              : [
                  AppButton.text(
                    label: negitiveLabel ?? loc(context).cancel,
                    key: const Key('alertNegativeButton'),
                    onTap: () {
                      context.pop();
                    },
                  ),
                  AppButton.text(
                    label: positiveLabel ?? loc(context).save,
                    key: const Key('alertPositiveButton'),
                    onTap: checkPositiveEnabled?.call() ?? true
                        ? () {
                            onSubmit();
                          }
                        : null,
                  )
                ],
        );
      });
    },
  );
}

Future<T?> showSimpleAppDialog<T>(
  BuildContext context, {
  bool dismissible = true,
  IconData? icon,
  String? title,
  Widget? content,
  bool scrollable = false,
  bool useRootNavigator = true,
  List<Widget>? actions,
  double? width,
}) {
  return showDialog<T?>(
    context: context,
    barrierDismissible: dismissible,
    useRootNavigator: useRootNavigator,
    builder: (context) {
      return AppDialog(
        semanticLabel: title,
        scrollable: scrollable,
        icon: icon,
        title: title != null
            ? SizedBox(
                width: width ?? kDefaultDialogWidth,
                child: AppText.titleLarge(title))
            : null,
        content: SizedBox(width: width ?? kDefaultDialogWidth, child: content),
        actions: actions,
      );
    },
  );
}

Future<T?> showSimpleAppOkDialog<T>(
  BuildContext context, {
  bool dismissible = true,
  bool scrollable = false,
  bool useRootNavigator = true,
  IconData? icon,
  String? title,
  Widget? content,
  double? width,
  String? okLabel,
}) {
  return showSimpleAppDialog<T?>(
    context,
    title: title,
    dismissible: dismissible,
    scrollable: scrollable,
    useRootNavigator: useRootNavigator,
    content: content,
    icon: icon,
    width: width,
    actions: [
      AppButton.text(
        label: okLabel ?? loc(context).ok,
        onTap: () {
          context.pop();
        },
      )
    ],
  );
}

Future<T?> showMessageAppDialog<T>(
  BuildContext context, {
  bool dismissible = true,
  bool scrollable = false,
  bool useRootNavigator = true,
  IconData? icon,
  String? title,
  required String message,
  List<Widget>? actions,
  double? width,
}) {
  return showSimpleAppDialog<T?>(
    context,
    dismissible: dismissible,
    scrollable: scrollable,
    useRootNavigator: useRootNavigator,
    width: width,
    icon: icon,
    title: title,
    content: AppText.bodyMedium(message),
    actions: actions,
  );
}

Future<T?> showMessageAppOkDialog<T>(
  BuildContext context, {
  bool dismissible = true,
  bool scrollable = false,
  bool useRootNavigator = true,
  IconData? icon,
  String? title,
  String? message,
  String? okLabel,
  double? width,
}) {
  return showSimpleAppDialog<T?>(
    context,
    dismissible: dismissible,
    scrollable: scrollable,
    useRootNavigator: useRootNavigator,
    title: title,
    icon: icon,
    content: AppText.bodyMedium(message ?? ''),
    width: width,
    actions: [
      AppButton.text(
        label: okLabel ?? loc(context).ok,
        onTap: () {
          context.pop();
        },
      )
    ],
  );
}

Future<T?> showSpinnerDialog<T>(BuildContext context) {
  return showSimpleAppDialog<T?>(context,
      dismissible: false, content: const AppLoader());
}

Future<bool?> showUnsavedAlert(BuildContext context,
    {String? title, String? message}) {
  return showMessageAppDialog<bool>(
    context,
    title: title ?? loc(context).unsavedChangesTitle,
    message: message ?? loc(context).unsavedChangesDesc,
    actions: [
      AppButton.text(
        label: loc(context).goBack,
        onTap: () {
          context.pop();
        },
      ),
      AppButton.dangerText(
        label: loc(context).discardChanges,
        onTap: () {
          context.pop(true);
        },
      ),
    ],
  );
}

Future<T?> showRouterNotFoundAlert<T>(BuildContext context, WidgetRef ref,
    {FutureOr<T?> Function()? onComplete}) {
  logger.d('[RouterNotFound] show Router not found alert');
  return showSimpleAppDialog<T>(context,
      dismissible: false,
      title: loc(context).routerNotFound,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.bodyLarge(loc(context).notConnectedToRouter),
          AppGap.md(),
          _buildBulletList([
            loc(context).routerNotFoundDesc1,
            loc(context).routerNotFoundDesc2,
            loc(context).routerNotFoundDesc3,
          ]),
        ],
      ),
      actions: [
        _AsyncLoadingButton(
          label: loc(context).tryAgain,
          onTap: () async {
            await ref
                .read(dashboardManagerProvider.notifier)
                .checkRouterIsBack()
                .then((_) {
              logger.d('[RouterNotFound] Found!');
              return onComplete?.call();
            }).then((value) {
              ref.read(pollingProvider.notifier).startPolling();
              if (context.mounted) {
                context.pop(value);
              }
            }).onError((_, __) {
              logger.d('[RouterNotFound] Try again failed');
            });
          },
        ),
      ]);
}

Future<T?> showRedirectNewIpAlert<T>(
    BuildContext context, WidgetRef ref, String ip) {
  logger.d('[RedirectNewIpAlert] show Redirect new IP alert');
  return showSimpleAppDialog<T>(context,
      dismissible: false,
      title: loc(context).redirect,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.bodyLarge(loc(context).redirectDescription(ip)),
        ],
      ),
      actions: [
        AppButton.primary(
          label: loc(context).redirect,
          onTap: () {
            ref.read(redirectionProvider.notifier).state = 'https://$ip';
          },
        ),
      ]);
}

Future<bool?> showFactoryResetModal(
    BuildContext context, bool isParent, isLast) {
  final type = isParent
      ? 'Master'
      : isLast
          ? 'Last'
          : 'Child';

  return showMessageAppDialog<bool>(context,
      icon: AppFontIcons.resetWrench,
      message: loc(context).factoryResetDesc,
      title: type == 'Master'
          ? loc(context).factoryResetParentTitle
          : type == 'Child'
              ? loc(context).factoryResetChildTitle
              : loc(context).factoryResetTitle,
      actions: [
        AppButton.text(
          label: loc(context).cancel,
          onTap: () {
            context.pop();
          },
        ),
        AppButton.dangerText(
          label: isLast
              ? loc(context).factoryResetOkSingle
              : loc(context).factoryResetOk,
          onTap: () {
            context.pop(true);
          },
        ),
      ]);
}

Future<bool?> showRebootModal(
    BuildContext context, bool isParent, bool isLast) {
  final type = isParent
      ? 'Master'
      : isLast
          ? 'Last'
          : 'Child';

  return showMessageAppDialog<bool>(context,
      icon: AppFontIcons.restartAlt,
      message: type == 'Master'
          ? loc(context).menuRestartNetworkMessage
          : type == 'Last'
              ? loc(context).menuRestartNetworkLastMessage
              : loc(context).menuRestartNetworkChildMessage,
      title: type == 'Master'
          ? loc(context).rebootParentTitle
          : type == 'Last'
              ? loc(context).rebootUnit
              : loc(context).rebootChildTitle,
      actions: [
        AppButton.text(
          label: loc(context).cancel,
          onTap: () {
            context.pop();
          },
        ),
        AppButton.dangerText(
          label: isLast ? loc(context).rebootOkSingle : loc(context).rebootOk,
          onTap: () {
            context.pop(true);
          },
        ),
      ]);
}

Future showMLOCapableModal(BuildContext context) {
  return showMessageAppOkDialog(context,
      title: loc(context).mlo,
      message:
          '${loc(context).mloCapableModalDesc1}\n\n${loc(context).mloCapableModalDesc2}');
}

Future<bool?> showInstantPrivacyConfirmDialog(
    BuildContext context, bool enable) {
  return showSimpleAppDialog<bool>(
    context,
    dismissible: false,
    title: enable
        ? loc(context).turnOnInstantPrivacy
        : loc(context).turnOffInstantPrivacy,
    content: AppText.bodyMedium(enable
        ? loc(context).instantPrivacyDescription
        : loc(context).turnOffInstantPrivacyDesc),
    actions: [
      AppButton.text(
        label: loc(context).cancel,
        onTap: () {
          context.pop();
        },
      ),
      AppButton.text(
        label: enable ? loc(context).turnOn : loc(context).turnOff,
        onTap: () {
          context.pop(true);
        },
      ),
    ],
  );
}

Future<bool?> showMacFilteringConfirmDialog(BuildContext context, bool enable) {
  return showSimpleAppDialog<bool>(
    context,
    dismissible: false,
    title: enable
        ? loc(context).turnOnMacFiltering
        : loc(context).turnOffMacFiltering,
    content: AppText.bodyMedium(enable
        ? loc(context).turnOnMacFilteringDesc
        : loc(context).turnOffMacFilteringDesc),
    actions: [
      AppButton.text(
        label: loc(context).cancel,
        onTap: () {
          context.pop();
        },
      ),
      AppButton.text(
        label: enable ? loc(context).turnOn : loc(context).turnOff,
        onTap: () {
          context.pop(true);
        },
      ),
    ],
  );
}

// Private helper to mimic BulletList using Column/Row
Widget _buildBulletList(List<String> items) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: items.map((item) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.bodySmall('• '),
            Expanded(
              child: AppText.bodySmall(item),
            ),
          ],
        ),
      );
    }).toList(),
  );
}

class _AsyncLoadingButton extends StatefulWidget {
  final String label;
  final Future<void> Function() onTap;

  const _AsyncLoadingButton({
    required this.label,
    required this.onTap,
  });

  @override
  State<_AsyncLoadingButton> createState() => _AsyncLoadingButtonState();
}

class _AsyncLoadingButtonState extends State<_AsyncLoadingButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // Assuming AppButton does not support isLoading property directly
    // based on migration usage pattern.
    if (_isLoading) {
      return AppButton.primary(
          label: '',
          onTap: null); // Or specific loading button if provided by UI Kit
    }
    return AppButton.primary(
      label: widget.label,
      onTap: () async {
        setState(() {
          _isLoading = true;
        });
        try {
          await widget.onTap();
        } finally {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      },
    );
  }
}
