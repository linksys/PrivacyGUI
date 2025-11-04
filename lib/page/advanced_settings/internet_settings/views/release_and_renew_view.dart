import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/internet_settings_enums.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_state.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/views/internet_settings_view.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/util/error_code_helper.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/buttons/button.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/gap/gap.dart';
import 'package:privacygui_widgets/widgets/text/app_text.dart';

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

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.titleMedium(loc(context).internetIPAddress),
          const AppGap.medium(),
          SizedBox(
            width: 9.col,
            child: AppListCard(
              title: AppText.bodyMedium(loc(context).ipv4),
              description: AppText.labelLarge(
                  wanStatus?.wanConnection?.ipAddress ?? '-'),
              trailing: AppTextButton.noPadding(
                loc(context).releaseAndRenew,
                onTap: isBridgeMode
                    ? null
                    : () {
                        _showRenewIPAlert(
                            context, ref, InternetSettingsViewType.ipv4);
                      },
              ),
            ),
          ),
          const AppGap.small2(),
          SizedBox(
            width: 9.col,
            child: AppListCard(
              title: AppText.bodyMedium(loc(context).ipv6),
              description: AppText.labelLarge(
                  wanStatus?.wanIPv6Connection?.networkInfo?.ipAddress ?? '-'),
              trailing: AppTextButton.noPadding(
                loc(context).releaseAndRenew,
                onTap: isBridgeMode || wanIpv6Type == WanIPv6Type.passThrough
                    ? null
                    : () {
                        _showRenewIPAlert(
                            context, ref, InternetSettingsViewType.ipv6);
                      },
              ),
            ),
          ),
        ],
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
        AppTextButton(
          loc(context).cancel,
          color: Theme.of(context).colorScheme.onSurface,
          onTap: () {
            context.pop();
          },
        ),
        AppTextButton(
          loc(context).releaseAndRenew,
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
          showSuccessSnackBar(
            context,
            loc(context).successExclamation,
          );
        },
      ).catchError((error) {
        showRouterNotFoundAlert(context, ref, onComplete: () async {
          await ref.read(pollingProvider.notifier).forcePolling();

          showSuccessSnackBar(
            context,
            loc(context).successExclamation,
          );
        });
      }, test: (error) => error is JNAPSideEffectError).onError(
          (error, stackTrace) {
        final errorMsg = switch (error.runtimeType) {
          JNAPError => (error as JNAPError).result == 'ErrorInvalidWANType'
              ? loc(context).currentWanTypeIsNotDhcp
              : errorCodeHelper(context, (error as JNAPError).result),
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
          showSuccessSnackBar(
            context,
            loc(context).successExclamation,
          );
        },
      ).catchError((error) {
        showRouterNotFoundAlert(context, ref, onComplete: () async {
          await ref.read(pollingProvider.notifier).forcePolling();

          showSuccessSnackBar(
            context,
            loc(context).successExclamation,
          );
        });
      }, test: (error) => error is JNAPSideEffectError).onError(
          (error, stackTrace) {
        final errorMsg = switch (error.runtimeType) {
          JNAPError => (error as JNAPError).result == 'ErrorInvalidIPv6WANType'
              ? loc(context).currentIPv6ConnectionTypeIsNotAutomatic
              : errorCodeHelper(context, (error as JNAPError).result),
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
