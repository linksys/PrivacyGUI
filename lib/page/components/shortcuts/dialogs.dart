import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacygui_widgets/widgets/buttons/button.dart';
import 'package:privacygui_widgets/widgets/progress_bar/spinner.dart';
import 'package:privacygui_widgets/widgets/text/app_text.dart';

const kDefaultDialogWidth = 328.0;

Future<T?> showSubmitAppDialog<T>(
  BuildContext context, {
  Widget? icon,
  String? title,
  required Widget Function(BuildContext, StateSetter) contentBuilder,
  Widget? loadingWidget,
  double? width,
  String? negitiveLabel,
  String? positiveLabel,
  bool Function()? checkPositiveEnabled,
  required Future<T> Function() event,
}) {
  bool isLoading = false;
  return showDialog<T?>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
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
                false => contentBuilder(context, setState),
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
                            setState(() {
                              isLoading = true;
                            });
                            event.call().then((value) {
                              setState(() {
                                isLoading = false;
                              });
                              context.pop(value);
                            });
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
    content: AppText.bodyMedium(loc(context).modalDFSDesc),
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

Future<bool?> showUnsavedAlert(BuildContext context, {String? title, String? message}) {
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
