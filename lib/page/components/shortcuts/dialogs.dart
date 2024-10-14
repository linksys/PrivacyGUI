import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/bullet_list/bullet_list.dart';
import 'package:privacygui_widgets/widgets/buttons/button.dart';
import 'package:privacygui_widgets/widgets/progress_bar/spinner.dart';
import 'package:privacygui_widgets/widgets/text/app_text.dart';

const kDefaultDialogWidth = 328.0;

Future<T?> doSomethingWithSpinner<T>(
  BuildContext context,
  Future<T> task, {
  Widget? icon,
  String? title,
  List<String>? messages,
  Duration? period,
}) {
  Future.delayed(
      Duration.zero,
      () => showAppSpinnerDialog(
            context,
            title: title,
            icon: icon,
            messages: messages ?? [loc(context).processing],
            period: period,
          ));
  return task.then((value) {
    context.pop();
    return value;
  }).onError((error, stackTrace) {
    context.pop();
    throw error ?? '';
  });
}

Future<T?> showAppSpinnerDialog<T>(
  BuildContext context, {
  Widget? icon,
  String? title,
  Widget? loadingWidget,
  double? width,
  List<String> messages = const [],
  Duration? period,
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
              return AlertDialog(
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
                        loadingWidget ?? const AppSpinner(),
                        if (snapshot.hasData) AppText.labelLarge(snapshot.data!)
                      ],
                    )),
              );
            });
      });
    },
  );
}

Future<T?> showSubmitAppDialog<T>(
  BuildContext context, {
  Widget? icon,
  String? title,
  required Widget Function(BuildContext, StateSetter, void Function())
      contentBuilder,
  Widget? loadingWidget,
  double? width,
  String? negitiveLabel,
  String? positiveLabel,
  bool Function()? checkPositiveEnabled,
  required Future<T> Function() event,
  void Function(Object? error, StackTrace stackTrace)? onError,
}) {
  bool isLoading = false;
  return showDialog<T?>(
    context: context,
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
            context.pop(value);
          }).onError((error, stackTrace) {
            setState(() {
              isLoading = false;
            });
            onError?.call(error, stackTrace);
          });
        }

        return AlertDialog(
          icon: icon,
          title: title != null
              ? SizedBox(
                  width: width ?? kDefaultDialogWidth,
                  child: AppText.titleLarge(title))
              : null,
          content: SizedBox(
              width: width ?? kDefaultDialogWidth,
              child: switch (isLoading) {
                true => loadingWidget ?? const AppSpinner(),
                false => contentBuilder(context, setState, onSubmit),
              }),
          actions: isLoading
              ? []
              : [
                  AppTextButton(
                    negitiveLabel ?? loc(context).cancel,
                    color: Theme.of(context).colorScheme.onSurface,
                    onTap: () {
                      context.pop();
                    },
                  ),
                  AppTextButton(
                    positiveLabel ?? loc(context).save,
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
  Widget? icon,
  String? title,
  Widget? content,
  List<Widget>? actions,
  double? width,
}) {
  return showDialog<T?>(
    context: context,
    barrierDismissible: dismissible,
    builder: (context) {
      return AlertDialog(
        semanticLabel: title,
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
  Widget? icon,
  String? title,
  Widget? content,
  double? width,
  String? okLabel,
}) {
  return showSimpleAppDialog<T?>(
    context,
    title: title,
    dismissible: dismissible,
    content: content,
    icon: icon,
    width: width,
    actions: [
      AppTextButton(
        okLabel ?? loc(context).ok,
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
  Widget? icon,
  String? title,
  required String message,
  List<Widget>? actions,
  double? width,
}) {
  return showSimpleAppDialog<T?>(
    context,
    dismissible: dismissible,
    icon: icon,
    title: title,
    content: AppText.bodyMedium(message),
    actions: actions,
  );
}

Future<T?> showMessageAppOkDialog<T>(
  BuildContext context, {
  bool dismissible = true,
  Widget? icon,
  String? title,
  String? message,
  String? okLabel,
  double? width,
}) {
  return showSimpleAppDialog<T?>(
    context,
    dismissible: dismissible,
    title: title,
    icon: icon,
    content: AppText.bodyMedium(message ?? ''),
    width: width,
    actions: [
      AppTextButton(
        okLabel ?? loc(context).ok,
        onTap: () {
          context.pop();
        },
      )
    ],
  );
}

Future<T?> showSpinnerDialog<T>(BuildContext context) {
  return showSimpleAppDialog<T?>(context,
      dismissible: false, content: const AppSpinner());
}

Future<bool?> showUnsavedAlert(BuildContext context,
    {String? title, String? message}) {
  return showMessageAppDialog<bool>(
    context,
    title: title ?? loc(context).unsavedChangesTitle,
    message: message ?? loc(context).unsavedChangesDesc,
    actions: [
      AppTextButton(
        loc(context).goBack,
        color: Theme.of(context).colorScheme.onSurface,
        onTap: () {
          context.pop();
        },
      ),
      AppTextButton(
        loc(context).discardChanges,
        color: Theme.of(context).colorScheme.error,
        onTap: () {
          context.pop(true);
        },
      ),
    ],
  );
}

Future showRouterNotFoundAlert(BuildContext context, WidgetRef ref) {
  return showSimpleAppDialog(context,
      dismissible: false,
      title: loc(context).routerNotFound,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.bodyLarge(loc(context).notConnectedToRouter),
          const AppGap.medium(),
          AppBulletList(children: [
            AppText.bodySmall(loc(context).routerNotFoundDesc1),
            AppText.bodySmall(loc(context).routerNotFoundDesc2),
            AppText.bodySmall(loc(context).routerNotFoundDesc3),
          ])
        ],
      ),
      actions: [
        AppFilledButton(
          loc(context).tryAgain,
          onTap: () {
            ref
                .read(dashboardManagerProvider.notifier)
                .checkDeviceInfo(null)
                .then((value) {
              ref.read(pollingProvider.notifier).startPolling();

              context.pop();
            });
          },
        ),
      ]);
}

Future<bool?> showFactoryResetModal(BuildContext context, bool isParent) {
  return showMessageAppDialog<bool>(context,
      icon: Icon(
        LinksysIcons.resetWrench,
        color: Theme.of(context).colorScheme.error,
        size: 42,
      ),
      message: loc(context).factoryResetDesc,
      title: isParent
          ? loc(context).factoryResetParentTitle
          : loc(context).factoryResetTitle,
      actions: [
        AppTextButton(
          loc(context).cancel,
          onTap: () {
            context.pop();
          },
        ),
        AppTextButton(
          loc(context).factoryResetOk,
          color: Theme.of(context).colorScheme.error,
          onTap: () {
            context.pop(true);
          },
        ),
      ]);
}

Future<bool?> showRebootModal(BuildContext context, bool isParent) {
  return showMessageAppDialog<bool>(context,
      icon: Icon(
        LinksysIcons.restartAlt,
        color: Theme.of(context).colorScheme.error,
        size: 42,
      ),
      message: loc(context).menuRestartNetworkMessage,
      title:
          isParent ? loc(context).rebootParentTitle : loc(context).rebootUnit,
      actions: [
        AppTextButton(
          loc(context).cancel,
          onTap: () {
            context.pop();
          },
        ),
        AppTextButton(
          loc(context).rebootOk,
          color: Theme.of(context).colorScheme.error,
          onTap: () {
            context.pop(true);
          },
        ),
      ]);
}
