import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/instant_safety/providers/_providers.dart';
import 'package:privacy_gui/page/instant_topology/providers/instant_topology_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacygui_widgets/widgets/label/status_label.dart';

import 'package:privacygui_widgets/widgets/panel/general_section.dart';

class DashboardMenuView extends ConsumerStatefulWidget {
  const DashboardMenuView({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardMenuView> createState() => _DashboardMenuViewState();
}

class _DashboardMenuViewState extends ConsumerState<DashboardMenuView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      // scrollable: true,
      backState: StyledBackState.none,
      title: loc(context).menu,
      menu: PageMenu(title: loc(context).myNetwork, items: [
        PageMenuItem(
            label: loc(context).restartNetwork,
            icon: LinksysIcons.restartAlt,
            onTap: () {
              _restartNetwork();
            }),
        PageMenuItem(
            label: loc(context).menuSetupANewProduct,
            icon: LinksysIcons.add,
            onTap: () {
              context.pushNamed(RouteNamed.addNodes);
            })
      ]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildMenuGridView(createMenuItems())),
          // const Spacer(),
          // AppTextButton.noPadding('About Linksys', onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildMenuGridView(List<AppSectionItemData> items) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveLayout.isOverMedimumLayout(context) ? 3 : 1,
        mainAxisSpacing: ResponsiveLayout.isOverMedimumLayout(context)
            ? Spacing.medium
            : Spacing.small2,
        crossAxisSpacing: ResponsiveLayout.columnPadding(context),
        childAspectRatio: (205 / 152),
        mainAxisExtent:
            ResponsiveLayout.isOverMedimumLayout(context) ? 152 : 112,
      ),
      physics: const ScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildDeviceGridCell(items[index]);
      },
    );
  }

  Widget _buildDeviceGridCell(AppSectionItemData item) {
    return AppMenuCard(
      iconData: item.iconData,
      title: item.title,
      description: item.description,
      status: item.status,
      onTap: item.onTap,
    );
  }

  List<AppSectionItemData> createMenuItems() {
    // final isCloudLogin =
    //     ref.watch(authProvider).value?.loginType == LoginType.remote;
    final safetyState = ref.watch(instantSafetyProvider);
    final privacyState = ref.watch(instantPrivacyProvider);
    return [
      AppSectionItemData(
          title: loc(context).incredibleWiFi,
          description: loc(context).incredibleWiFiDesc,
          iconData: LinksysIcons.wifi,
          onTap: () {
            _navigateTo(RouteNamed.menuIncredibleWiFi);
          }),
      AppSectionItemData(
          title: loc(context).instantAdmin,
          description: loc(context).instantAdminDesc,
          iconData: LinksysIcons.accountCircle,
          onTap: () {
            _navigateTo(RouteNamed.menuInstantAdmin);
          }),
      AppSectionItemData(
          title: loc(context).instantTopology,
          description: loc(context).instantTopologyDesc,
          iconData: LinksysIcons.router,
          onTap: () {
            _navigateTo(RouteNamed.menuInstantTopology);
          }),
      AppSectionItemData(
          title: loc(context).instantSafety,
          description: loc(context).instantSafetyDesc,
          iconData: LinksysIcons.encrypted,
          status: safetyState.safeBrowsingType == InstantSafetyType.off,
          onTap: () {
            _navigateTo(RouteNamed.menuInstantSafety);
          }),
      AppSectionItemData(
          title: loc(context).instantPrivacy,
          description: loc(context).instantPrivacyDesc,
          iconData: LinksysIcons.smartLock,
          status: privacyState.mode != MacFilterMode.allow,
          onTap: () {
            _navigateTo(RouteNamed.menuInstantPrivacy);
          }),
      AppSectionItemData(
          title: loc(context).instantDevices,
          description: loc(context).instantDevicesDesc,
          iconData: LinksysIcons.devices,
          onTap: () {
            _navigateTo(RouteNamed.menuInstantDevices);
          }),

      AppSectionItemData(
          title: loc(context).advancedSettings,
          iconData: LinksysIcons.settings,
          onTap: () {
            _navigateTo(RouteNamed.menuAdvancedSettings);
          }),

      AppSectionItemData(
          title: loc(context).instantVerify,
          description: loc(context).instantVerifyDesc,
          iconData: LinksysIcons.technician,
          onTap: () {
            _navigateTo(RouteNamed.menuInstantVerify);
          }),
      // if (isCloudLogin)
      //   AppSectionItemData(
      //       title: loc(context).account,
      //       description: 'This is a description for this tile',
      //       iconData: LinksysIcons.accountCircle,
      //       onTap: () {
      //         _navigateTo(RouteNamed.accountInfo);
      //       }),
      // AppSectionItemData(
      //     title: 'Linksys LinkUp',
      //     iconData: getCharactersIcons(context).bellDefault,
      //     onTap: () {
      //       _navigateTo(RouteNamed.linkup);
      //     }),
    ];
  }

  void _navigateTo(String name) {
    if (kIsWeb) {
      if (shellNavigatorKey.currentContext!.canPop()) {
        shellNavigatorKey.currentContext!.pushReplacementNamed(name);
      } else {
        shellNavigatorKey.currentContext!.pushNamed(name);
      }
    } else {
      shellNavigatorKey.currentContext!.pushNamed(name);
    }
  }

  void _restartNetwork() {
    if (ResponsiveLayout.isMobileLayout(context)) {
      context.pop();
    }
    showMessageAppDialog(
      context,
      dismissible: true,
      title: loc(context).alertExclamation,
      message: loc(context).menuRestartNetworkMessage,
      actions: [
        AppFilledButton(
          loc(context).ok,
          onTap: () {
            context.pop();

            final reboot = Future.sync(
                    () => ref.read(pollingProvider.notifier).stopPolling())
                .then(
                    (_) => ref.read(instantTopologyProvider.notifier).reboot());
            doSomethingWithSpinner(context, reboot, messages: [
              '${loc(context).restarting}.',
              '${loc(context).restarting}..',
              '${loc(context).restarting}...'
            ]).then((value) {
              ref.read(pollingProvider.notifier).startPolling();
              showSuccessSnackBar(context, loc(context).successExclamation);
            }).catchError((error) {
              showRouterNotFoundAlert(context, ref);
            }, test: (error) => error is JNAPSideEffectError);
          },
        ),
        AppOutlinedButton(
          loc(context).cancel,
          onTap: () {
            context.pop();
          },
        )
      ],
    );
  }
}

class AppMenuCard extends StatelessWidget {
  const AppMenuCard({
    super.key,
    this.iconData,
    this.title,
    this.description,
    this.onTap,
    this.color,
    this.borderColor,
    this.status,
  });

  final IconData? iconData;
  final String? title;
  final String? description;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final bool? status;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      color: color,
      borderColor: borderColor,
      explicitChildNodes: false,
      identifier: 'now-menu-${title?.kebab()}',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FittedBox(
                fit: BoxFit.fill,
                child: Icon(
                  iconData,
                  size: 24,
                ),
              ),
              if (status != null)
                AppStatusLabel(
                  isOff: status!,
                )
            ],
          ),
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(top: Spacing.small2),
              child: AppText.titleSmall(
                title ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (description != null)
            Padding(
              padding: const EdgeInsets.only(top: Spacing.small1),
              child: AppText.bodyMedium(
                description ?? '',
                overflow: TextOverflow.ellipsis,
                maxLines: ResponsiveLayout.isOverMedimumLayout(context) ? 3 : 1,
                color:
                    Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
              ),
            ),
        ],
      ),
    );
  }
}
