import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/data/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/data/providers/polling_provider.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_state.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/views/internet_settings_view.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/providers/remote_access/remote_access_provider.dart';
import 'package:privacy_gui/util/error_code_helper.dart';
import 'package:ui_kit_library/ui_kit.dart';

class ReleaseAndRenewView extends ConsumerWidget {
  final InternetSettingsState internetSettingsState;
  final InternetSettingsNotifier notifier;
  final bool isBridgeMode;

  const ReleaseAndRenewView({
    Key? key,
    required this.internetSettingsState,
    required this.notifier,
    required this.isBridgeMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wanStatus =
        ref.watch(deviceManagerProvider.select((state) => state.wanStatus));
    final wanIpv6Type = WanIPv6Type.resolve(
        internetSettingsState.settings.current.ipv6Setting.ipv6ConnectionType);
    final isRemoteReadOnly = ref.watch(
      remoteAccessProvider.select((state) => state.isRemoteReadOnly),
    );

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: context.isMobileLayout ? 16.0 : 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText.titleMedium(loc(context).internetIPAddress),
            AppGap.md(),
            SizedBox(
              width: context.colWidth(9),
              child: AppCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.bodyMedium(loc(context).ipv4),
                          AppText.labelLarge(
                              wanStatus?.wanConnection?.ipAddress ?? '-'),
                        ],
                      ),
                    ),
                    AppButton.text(
                      key: const ValueKey('ipv4ReleaseRenewButton'),
                      label: loc(context).releaseAndRenew,
                      onTap: isBridgeMode || isRemoteReadOnly
                          ? null
                          : () {
                              _showRenewIPAlert(
                                  context, ref, InternetSettingsViewType.ipv4);
                            },
                    ),
                  ],
                ),
              ),
            ),
            AppGap.sm(),
            SizedBox(
              width: context.colWidth(9),
              child: AppCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.bodyMedium(loc(context).ipv6),
                          AppText.labelLarge(wanStatus
                                  ?.wanIPv6Connection?.networkInfo?.ipAddress ??
                              '-'),
                        ],
                      ),
                    ),
                    AppButton.text(
                      key: const ValueKey('ipv6ReleaseRenewButton'),
                      label: loc(context).releaseAndRenew,
                      onTap: isBridgeMode ||
                              wanIpv6Type == WanIPv6Type.passThrough ||
                              isRemoteReadOnly
                          ? null
                          : () {
                              _showRenewIPAlert(
                                  context, ref, InternetSettingsViewType.ipv6);
                            },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenewIPAlert(
      BuildContext context, WidgetRef ref, InternetSettingsViewType type) {
    showSimpleAppDialog(
      context,
      dismissible: false,
      title: loc(context).releaseAndRenewIpAddress,
      content:
          AppText.bodyMedium(loc(context).releaseAndRenewIpAddressDescription),
      actions: [
        AppButton.text(
          key: const ValueKey('rrCancelButton'),
          label: loc(context).cancel,
          onTap: () {
            context.pop();
          },
        ),
        AppButton.text(
          key: const ValueKey('rrConfirmButton'),
          label: loc(context).releaseAndRenew,
          onTap: () {
            context.pop();

            if (type == InternetSettingsViewType.ipv4) {
              _releaseAndRenewIpv4(context, ref);
            } else {
              _releaseAndRenewIpv6(context, ref);
            }
          },
        ),
      ],
    );
  }

  void _releaseAndRenewIpv4(BuildContext context, WidgetRef ref) {
    doSomethingWithSpinner(
      context,
      notifier.renewDHCPWANLease().then(
        (value) {
          if (!context.mounted) return;
          showSuccessSnackBar(
            context,
            loc(context).successExclamation,
          );
        },
      ).catchError((error) {
        if (!context.mounted) return;
        showRouterNotFoundAlert(context, ref, onComplete: () async {
          await ref.read(pollingProvider.notifier).forcePolling();

          if (!context.mounted) return;
          showSuccessSnackBar(
            context,
            loc(context).successExclamation,
          );
        });
      }, test: (error) => error is ServiceSideEffectError).onError(
          (error, stackTrace) {
        if (!context.mounted) return;
        final errorMsg = switch (error) {
          JNAPError e => e.result == 'ErrorInvalidWANType'
              ? loc(context).currentWanTypeIsNotDhcp
              : errorCodeHelper(context, e.result),
          TimeoutException => loc(context).generalError,
          _ => loc(context).unknownError,
        };

        showFailedSnackBar(
          context,
          errorMsg ??
              loc(context).unknownErrorCode((error as JNAPError).result),
        );
      }),
    );
  }

  void _releaseAndRenewIpv6(BuildContext context, WidgetRef ref) {
    doSomethingWithSpinner(
      context,
      notifier.renewDHCPIPv6WANLease().then(
        (value) {
          if (!context.mounted) return;
          showSuccessSnackBar(
            context,
            loc(context).successExclamation,
          );
        },
      ).catchError((error) {
        if (!context.mounted) return;
        showRouterNotFoundAlert(context, ref, onComplete: () async {
          await ref.read(pollingProvider.notifier).forcePolling();

          if (!context.mounted) return;
          showSuccessSnackBar(
            context,
            loc(context).successExclamation,
          );
        });
      }, test: (error) => error is ServiceSideEffectError).onError(
          (error, stackTrace) {
        if (!context.mounted) return;
        final errorMsg = switch (error) {
          JNAPError e => e.result == 'ErrorInvalidIPv6WANType'
              ? loc(context).currentIPv6ConnectionTypeIsNotAutomatic
              : errorCodeHelper(context, e.result),
          TimeoutException => loc(context).generalError,
          _ => loc(context).unknownError,
        };

        showFailedSnackBar(
          context,
          errorMsg ??
              loc(context).unknownErrorCode((error as JNAPError).result),
        );
      }),
    );
  }
}
