import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/_providers.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_provider.dart';
import 'package:privacy_gui/route/constants.dart';
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
    ref.read(internetSettingsProvider.notifier).fetch().then((state) {
      setState(() {
        _hasVLan = state.ipv4Setting.wanTaggingSettingsEnable ?? false;
        _isLoading = false;
      });
    });
    super.initState();
  }

  void _showDHCPAlert() {
    //TODO: Not from UI spec
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: AppText.titleLarge(loc(context).settingsSaved),
          content: const AppText.bodyMedium(
              'Are you sure you want to switch to DHCP mode?'),
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
                context.pop();
                _saveToDHCP();
              },
            ),
          ],
        );
      },
    );
  }

  void _saveToDHCP() async {
    logger.i('[PnP Troubleshooter]: Set the router into DHCP mode');
    var newState = ref.read(internetSettingsProvider).copyWith();
    newState = newState.copyWith(
      ipv4Setting: newState.ipv4Setting.copyWith(
        ipv4ConnectionType: WanType.dhcp.type,
      ),
    );
    // ALT, check router is configured and ignore the exception, check only
    await ref
        .read(pnpProvider.notifier)
        .checkRouterConfigured()
        .onError((_, __) {});
    if (ref.read(pnpProvider).isUnconfigured) {
      // ALT, check router admin password is default one and ignore the exception, check only
      await ref
          .read(pnpProvider.notifier)
          .checkAdminPassword(defaultAdminPassword)
          .onError((_, __) {});
    }
    context.pushNamed(
      RouteNamed.pnpIspSettingsAuth,
      extra: {'newSettings': newState},
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(internetSettingsProvider);
    final wanType = WanType.resolve(state.ipv4Setting.ipv4ConnectionType);
    return _isLoading
        ? const AppFullScreenSpinner()
        : StyledAppPageView(
            title: loc(context).pnpIspTypeSelectionTitle,
            child: ListView(
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
                    context.goNamed(RouteNamed.pnpStaticIp);
                  },
                ),
                const AppGap.small1(),
                ISPTypeCard(
                  title: loc(context).connectionTypePppoe,
                  description: loc(context).pnpIspTypeSelectionPppoeDesc,
                  isCurrentlyApplying: (wanType == WanType.pppoe && !_hasVLan),
                  tapAction: () {
                    context.goNamed(RouteNamed.pnpPPPOE,
                        extra: {'needVlanId': false});
                  },
                ),
                const AppGap.small1(),
                ISPTypeCard(
                  title: loc(context).pppoeVlan,
                  description: loc(context).pnpIspTypeSelectionPppoeVlanDesc,
                  isCurrentlyApplying: (wanType == WanType.pppoe && _hasVLan),
                  tapAction: () {
                    context.goNamed(RouteNamed.pnpPPPOE,
                        extra: {'needVlanId': true});
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
