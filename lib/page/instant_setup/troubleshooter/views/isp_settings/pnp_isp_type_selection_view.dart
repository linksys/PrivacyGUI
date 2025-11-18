import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/internet_settings_enums.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/_providers.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/providers/pnp_isp_settings_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/util/error_code_helper.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/progress_bar/full_screen_spinner.dart';

class PnpIspTypeSelectionView extends ConsumerStatefulWidget {
  const PnpIspTypeSelectionView({
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _PnpIspTypeSelectionViewState();
}

class _PnpIspTypeSelectionViewState extends ConsumerState {
  bool _isLoading = true;
  bool _hasVLan = false;

  @override
  void initState() {
    ref
        .read(internetSettingsProvider.notifier)
        .fetch(forceRemote: true)
        .then((state) {
      if (mounted) {
        setState(() {
          _hasVLan =
              state.current.ipv4Setting.wanTaggingSettingsEnable ?? false;
          _isLoading = false;
        });
      }
    });
    super.initState();
  }

  void _showDHCPAlert() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: AppText.titleLarge(loc(context).settingsSaved),
          content:
              AppText.bodyMedium(loc(context).pnpIspTypeSelectionDhcpConfirm),
          actions: [
            AppTextButton(
              loc(context).cancel,
              color: Theme.of(context).colorScheme.onSurface,
              onTap: () {
                context.pop();
              },
            ),
            AppTextButton(
              loc(context).ok,
              onTap: () {
                logger.i('[PnP]: Troubleshooter -  Save to DHCP');
                context.pop();
                _saveToDHCP();
              },
            ),
          ],
        );
      },
    );
  }

  String _getErrorMessage(WanType wanType) {
    if (wanType == WanType.static || wanType == WanType.dhcp) {
      return loc(context).pnpErrorForStaticIpAndDhcp;
    } else {
      // This case must be PPPOE
      return loc(context).pnpErrorForPppoe;
    }
  }

  void _handleError(Object error, WanType wanType) {
    if (!mounted) return;

    String? errorMessage;

    if (error is JNAPSideEffectError) {
      final lastHandledResult = error.lastHandledResult;
      if (lastHandledResult != null && lastHandledResult is JNAPSuccess) {
        errorMessage = _getErrorMessage(wanType);
      } else {
        showRouterNotFoundAlert(context, ref, onComplete: () async {
          context.goNamed(RouteNamed.pnp);
        });
        return; // Early exit
      }
    } else if (error is JNAPError) {
      errorMessage =
          errorCodeHelper(context, error.result, _getErrorMessage(wanType)) ??
              _getErrorMessage(wanType);
    } else {
      errorMessage = _getErrorMessage(wanType);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: AppText.titleLarge(loc(context).error),
        content: AppText.bodyMedium(errorMessage!),
        actions: [
          AppTextButton(
            loc(context).ok,
            onTap: () => context.pop(),
          ),
        ],
      ),
    );
  }

  void _saveToDHCP() async {
    logger.i('[PnP Troubleshooter]: Set the router into DHCP mode');
    final newState = ref.read(internetSettingsProvider).current.copyWith(
          ipv4Setting:
              ref.read(internetSettingsProvider).current.ipv4Setting.copyWith(
                    ipv4ConnectionType: WanType.dhcp.type,
                  ),
        );

    setState(() {
      _isLoading = true;
    });

    try {
      await ref
          .read(pnpIspSettingsProvider.notifier)
          .saveAndVerifySettings(newState);
      if (mounted) {
        context.goNamed(RouteNamed.pnp);
      }
    } catch (e) {
      final wanType = WanType.resolve(
        newState.ipv4Setting.ipv4ConnectionType,
      )!;
      _handleError(e, wanType);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(internetSettingsProvider);
    final ispState = ref.watch(pnpIspSettingsProvider);
    final wanType =
        WanType.resolve(state.current.ipv4Setting.ipv4ConnectionType);

    if (_isLoading) {
      final message = switch (ispState) {
        PnpIspSettingsStatus.saving => loc(context).savingChanges,
        PnpIspSettingsStatus.checkSettings => loc(context).launchCheckInternet,
        PnpIspSettingsStatus.checkInternetConnection =>
          loc(context).launchCheckInternet,
        PnpIspSettingsStatus.success => loc(context).successExclamation,
        PnpIspSettingsStatus.error => loc(context).error,
        _ => loc(context).processing,
      };
      return AppFullScreenSpinner(text: message);
    }

    return StyledAppPageView.withSliver(
      title: loc(context).pnpIspTypeSelectionTitle,
      child: (context, constraints) => ListView(
        shrinkWrap: true,
        children: [
          ISPTypeCard(
            title: loc(context).dhcpDefault,
            description: loc(context).pnpIspTypeSelectionDhcpDesc,
            isCurrentlyApplying: wanType == WanType.dhcp,
            tapAction: wanType == WanType.dhcp ? null : _showDHCPAlert,
          ),
          const AppGap.small1(),
          ISPTypeCard(
            title: loc(context).connectionTypeStatic,
            description: loc(context).pnpIspTypeSelectionStaticDesc,
            isCurrentlyApplying: wanType == WanType.static,
            tapAction: () {
              logger.i('[PnP]: Troubleshooter -  Go to static IP page');
              context.goNamed(RouteNamed.pnpStaticIp);
            },
          ),
          const AppGap.small1(),
          ISPTypeCard(
            title: loc(context).connectionTypePppoe,
            description: loc(context).pnpIspTypeSelectionPppoeDesc,
            isCurrentlyApplying: (wanType == WanType.pppoe && !_hasVLan),
            tapAction: () {
              logger.i('[PnP]: Troubleshooter -  Go to pppoe page');
              context
                  .goNamed(RouteNamed.pnpPPPOE, extra: {'needVlanId': false});
            },
          ),
          const AppGap.small1(),
          ISPTypeCard(
            title: loc(context).pppoeVlan,
            description: loc(context).pnpIspTypeSelectionPppoeVlanDesc,
            isCurrentlyApplying: (wanType == WanType.pppoe && _hasVLan),
            tapAction: () {
              logger.i('[PnP]: Troubleshooter -  Go to pppoe vlan page');
              context.goNamed(RouteNamed.pnpPPPOE, extra: {'needVlanId': true});
            },
          ),
        ],
      ),
    );
  }
}

class ISPTypeCard extends StatelessWidget {
  final String title;
  final String description;
  final bool isCurrentlyApplying;
  final VoidCallback? tapAction;

  const ISPTypeCard({
    required this.title,
    required this.description,
    required this.isCurrentlyApplying,
    this.tapAction,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: tapAction,
      child: Container(
        constraints: const BoxConstraints(minHeight: 110),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.labelLarge(title),
                  const AppGap.small3(),
                  AppText.bodyMedium(description),
                ],
              ),
            ),
            const AppGap.small2(),
            isCurrentlyApplying
                ? const Icon(LinksysIcons.check)
                : const Icon(LinksysIcons.chevronRight),
          ],
        ),
      ),
    );
  }
}
