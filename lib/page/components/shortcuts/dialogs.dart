import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/util/semantic.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/bullet_list/bullet_list.dart';
import 'package:privacygui_widgets/widgets/progress_bar/spinner.dart';

const kDefaultDialogWidth = 328.0;

String _dialogSemanticIdentifier({required String description}) {
  return semanticIdentifier(
    tag: 'dialog',
    description: description,
  );
}

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
                        child: AppText.titleLarge(title,
                            identifier: _dialogSemanticIdentifier(
                                description: 'title')))
                    : null,
                content: SizedBox(
                    width: width ?? kDefaultDialogWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        loadingWidget ?? const AppSpinner(),
                        if (snapshot.hasData)
                          AppText.labelLarge(snapshot.data!,
                              identifier: _dialogSemanticIdentifier(
                                  description: 'content'))
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
                  child: AppText.titleLarge(title,
                      identifier:
                          _dialogSemanticIdentifier(description: 'title')))
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
                    identifier:
                        _dialogSemanticIdentifier(description: 'negitive'),
                    color: Theme.of(context).colorScheme.onSurface,
                    onTap: () {
                      context.pop();
                    },
                  ),
                  AppTextButton(
                    positiveLabel ?? loc(context).save,
                    identifier:
                        _dialogSemanticIdentifier(description: 'positive'),
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
      return Semantics(
        identifier: _dialogSemanticIdentifier(description: 'dialog'),
        label: 'dialog',
        child: AlertDialog(
          icon: icon,
          title: title != null
              ? SizedBox(
                  width: width ?? kDefaultDialogWidth,
                  child: AppText.titleLarge(title,
                      identifier:
                          _dialogSemanticIdentifier(description: 'title')))
              : null,
          content:
              SizedBox(width: width ?? kDefaultDialogWidth, child: content),
          actions: actions,
        ),
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
        identifier: _dialogSemanticIdentifier(description: 'ok'),
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
    content: AppText.bodyMedium(
      message,
      identifier: _dialogSemanticIdentifier(description: 'content'),
    ),
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
        identifier: _dialogSemanticIdentifier(description: 'ok'),
        onTap: () {
          context.pop();
        },
      )
    ],
  );
}

Future<T?> showSpinnerDialog<T>(BuildContext context) {
  return showSimpleAppDialog<T?>(context,
      dismissible: false,
      content: Semantics(
          identifier: _dialogSemanticIdentifier(description: 'spinner'),
          label: 'dialog spinner',
          child: const AppSpinner()));
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
        identifier: _dialogSemanticIdentifier(description: 'goBack'),
        color: Theme.of(context).colorScheme.onSurface,
        onTap: () {
          context.pop();
        },
      ),
      AppTextButton(
        loc(context).discardChanges,
        identifier: _dialogSemanticIdentifier(description: 'discardChanges'),
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
          AppText.bodyLarge(
            loc(context).notConnectedToRouter,
            identifier:
                _dialogSemanticIdentifier(description: 'notConnectedToRouter'),
          ),
          const AppGap.medium(),
          AppBulletList(children: [
            AppText.bodySmall(
              loc(context).routerNotFoundDesc1,
              identifier:
                  _dialogSemanticIdentifier(description: 'routerNotFoundDesc1'),
            ),
            AppText.bodySmall(
              loc(context).routerNotFoundDesc2,
              identifier:
                  _dialogSemanticIdentifier(description: 'routerNotFoundDesc2'),
            ),
            AppText.bodySmall(
              loc(context).routerNotFoundDesc3,
              identifier:
                  _dialogSemanticIdentifier(description: 'routerNotFoundDesc3'),
            ),
          ])
        ],
      ),
      actions: [
        AppFilledButton(
          loc(context).tryAgain,
          identifier: _dialogSemanticIdentifier(description: 'tryAgain'),
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
