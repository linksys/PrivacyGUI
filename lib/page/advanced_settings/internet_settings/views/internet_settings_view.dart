import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/internet_settings_enums.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_form_provider.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/views/ipv4_connection_view.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/views/ipv6_connection_view.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/views/release_and_renew_view.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/providers/redirection/redirection_provider.dart';
import 'package:privacy_gui/util/error_code_helper.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/core/jnap/providers/assign_ip/base_assign_ip.dart'
    if (dart.library.html) 'package:privacy_gui/core/jnap/providers/assign_ip/web_assign_ip.dart';

enum InternetSettingsViewType {
  ipv4,
  ipv6,
}

class InternetSettingsView extends ArgumentsConsumerStatefulView {
  const InternetSettingsView({super.key, super.args});

  @override
  ConsumerState<InternetSettingsView> createState() =>
      _InternetSettingsViewState();
}

class _InternetSettingsViewState extends ConsumerState<InternetSettingsView>
    with SingleTickerProviderStateMixin {
  late InternetSettingsNotifier _notifier;
  bool isEditing = false;
  String loadingTitle = '';
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _notifier = ref.read(internetSettingsProvider.notifier);
    doSomethingWithSpinner(
      context,
      _notifier.fetch(),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleEditing() {
    setState(() {
      isEditing = !isEditing;
    });
    if (!isEditing) {
      _notifier.revert();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(redirectionProvider, (previous, next) {
      if (kIsWeb && previous != next && next != null) {
        logger.d('Redirect to $next');
        assignWebLocation(next);
      }
    });

    final state = ref.watch(internetSettingsProvider);
    final isIpv4FormValid = ref.watch(internetSettingsIPv4FormValidityProvider);
    final isIpv6FormValid = ref.watch(internetSettingsIPv6FormValidityProvider);
    final isOptionalFormValid = ref.watch(optionalSettingsFormValidityProvider);

    final selectedType =
        WanType.resolve(state.settings.current.ipv4Setting.ipv4ConnectionType);
    final isBridgeMode = selectedType == WanType.bridge;
    final tabs = [
      loc(context).ipv4,
      loc(context).ipv6,
      loc(context).releaseAndRenew,
    ];
    final tabContents = [
      Ipv4ConnectionView(
        isEditing: isEditing,
        isBridgeMode: isBridgeMode,
        internetSettingsState: state,
        notifier: _notifier,
        onEditToggle: _toggleEditing,
      ),
      Ipv6ConnectionView(
        isEditing: isEditing,
        isBridgeMode: isBridgeMode,
        internetSettingsState: state,
        notifier: _notifier,
        onEditToggle: _toggleEditing,
      ),
      ReleaseAndRenewView(
        internetSettingsState: state,
        notifier: _notifier,
        isBridgeMode: isBridgeMode,
      ),
    ];
    final isDirty = ref.read(internetSettingsProvider.notifier).isDirty();
    return UiKitPageView.withSliver(
      padding: EdgeInsets.zero,
      useMainPadding: false,
      title: loc(context).internetSettings.capitalizeWords(),
      bottomBar: isEditing
          ? UiKitBottomBarConfig(
              isPositiveEnabled: isDirty &&
                  isIpv4FormValid &&
                  isIpv6FormValid &&
                  isOptionalFormValid,
              onPositiveTap: _showRestartAlert,
            )
          : null,
      tabs: tabs
          .map((e) => Tab(
                text: e,
              ))
          .toList(),
      tabContentViews: tabContents,
      tabController: _tabController,
    );
  }

  _showRestartAlert() {
    final state = ref.read(internetSettingsProvider);

    final isValidCombination = state.status.supportedWANCombinations.any(
        (combine) =>
            combine.wanType ==
                state.settings.current.ipv4Setting.ipv4ConnectionType &&
            combine.wanIPv6Type ==
                state.settings.current.ipv6Setting.ipv6ConnectionType);

    if (!isValidCombination) {
      return showSimpleAppOkDialog(
        context,
        title: loc(context).error,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText.bodyMedium('${loc(context).selectedCombinationNotValid}:'),
            AppGap.md(),
            Table(
              border: const TableBorder(),
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(1),
              },
              children: [
                TableRow(children: [
                  AppText.labelLarge('IPv4'),
                  AppText.labelLarge('IPv6'),
                ]),
                ...state.status.supportedWANCombinations.map((combine) {
                  return TableRow(children: [
                    AppText.bodyMedium(combine.wanType),
                    AppText.bodyMedium(combine.wanIPv6Type),
                  ]);
                }).toList(),
              ],
            ),
          ],
        ),
      );
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: AppText.titleLarge(loc(context).restartWifiAlertTitle),
          content: AppText.bodyMedium(loc(context).restartWifiAlertDesc),
          actions: [
            AppButton.text(
              label: loc(context).cancel,
              onTap: () {
                context.pop();
              },
            ),
            AppButton.text(
              label: loc(context).restart,
              onTap: () {
                context.pop();

                _onRestartButtonTap();
              },
            ),
          ],
        );
      },
    );
  }

  _onRestartButtonTap() {
    _saveChange();
  }

  void _saveChange() {
    // Store localizations and context-dependent values before the async gap
    final restartingTitle = loc(context).restarting;
    final changesSavedMessage = loc(context).changesSaved;
    final generalErrorMessage = loc(context).generalError;
    final unknownErrorMessage = loc(context).unknownError;
    final unknownErrorCode = loc(context).unknownErrorCode;

    setState(() {
      loadingTitle = restartingTitle;
    });

    doSomethingWithSpinner(
      context,
      _notifier.save(),
    ).then((value) {
      if (!mounted) return;
      setState(() {
        isEditing = false;
      });

      showSuccessSnackBar(
        context,
        changesSavedMessage,
      );
    }).catchError((error) {
      if (!mounted) return;
      showRouterNotFoundAlert(context, ref, onComplete: () async {
        await _notifier.fetch(forceRemote: true);

        if (!mounted) return;
        setState(() {
          isEditing = false;
        });

        showSuccessSnackBar(
          context,
          changesSavedMessage,
        );
      });
    }, test: (error) => error is JNAPSideEffectError).onError(
        (error, stackTrace) {
      if (!mounted) return;
      final errorMsg = switch (error.runtimeType) {
        JNAPError => errorCodeHelper(context, (error as JNAPError).result),
        TimeoutException => generalErrorMessage,
        _ => unknownErrorMessage,
      };

      showFailedSnackBar(
        context,
        errorMsg ?? unknownErrorCode((error as JNAPError).result),
      );
    }).whenComplete(
      () {
        if (!mounted) return;
        setState(() {
          loadingTitle = '';
        });
      },
    );
  }
}
