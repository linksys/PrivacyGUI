import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/advanced_settings/internet_settings/providers/_providers.dart';
import 'package:linksys_app/page/components/styled/consts.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/icons/linksys_icons.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/card/card.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';

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

  @override
  void initState() {
    ref.read(internetSettingsProvider.notifier).fetch().then((state) {
      setState(() {
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
              onTap: _saveToDHCP,
            ),
          ],
        );
      },
    );
  }

  void _saveToDHCP() {
    var newState = ref.read(internetSettingsProvider).copyWith();
    newState = newState.copyWith(
      ipv4Setting: newState.ipv4Setting.copyWith(
        ipv4ConnectionType: WanType.dhcp.type,
      ),
    );
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
            appBarStyle: AppBarStyle.back,
            title:
                'What type of ISP ', //'What type of ISP settings do you have?',
            child: AppBasicLayout(
              content: ListView(
                shrinkWrap: true,
                children: [
                  ISPTypeCard(
                    title: 'DHCP (default)',
                    description:
                        'Dynamic Host Configuration Protocol (DHCP) automatically assigns IP addresses to devices connected to the network.',
                    isCurrentlyApplying: wanType == WanType.dhcp,
                    tapAction: wanType == WanType.dhcp ? null : _showDHCPAlert,
                  ),
                  ISPTypeCard(
                    title: 'Static IP',
                    description:
                        'A static Internet Protocol (IP) address is a permanent number assigned to a computer by an internet Service Provider (ISP).',
                    isCurrentlyApplying: wanType == WanType.static,
                    tapAction: () {
                      context.goNamed(RouteNamed.pnpStaticIp);
                    },
                  ),
                  ISPTypeCard(
                    title: loc(context).pppoe,
                    description:
                        'Point-to-Point Protocol over Ethernet is a specification for connecting multiple computer users on an Ethernet local area network to a remote site.',
                    isCurrentlyApplying: wanType == WanType.pppoe,
                    tapAction: () {
                      context.goNamed(RouteNamed.pnpIspSettings,
                          extra: {'needVlanId': false});
                    },
                  ),
                  ISPTypeCard(
                    title: 'PPPoE over VLAN',
                    description:
                        'Sometimes your ISP may require you to have a PPPoE over VLAN to access the internet.',
                    isCurrentlyApplying: wanType == WanType.pppoe,
                    tapAction: () {
                      context.goNamed(RouteNamed.pnpIspSettings,
                          extra: {'needVlanId': true});
                    },
                  ),
                ],
              ),
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
      child: SizedBox(
        height: 110,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.labelLarge(title),
                  const AppGap.small(),
                  AppText.bodyMedium(description),
                ],
              ),
            ),
            const AppGap.semiSmall(),
            isCurrentlyApplying
                ? const Icon(LinksysIcons.check)
                : const Icon(LinksysIcons.chevronRight),
          ],
        ),
      ),
    );
  }
}
