import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/data/providers/polling_provider.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/styled/menus/menu_consts.dart';
import 'package:privacy_gui/page/components/styled/menus/widgets/menu_holder.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/dashboard/_dashboard.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/instant_safety/providers/_providers.dart';
import 'package:privacy_gui/page/instant_topology/providers/instant_topology_provider.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_info.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/page/models/app_section_item_data.dart';

class DashboardMenuView extends ConsumerStatefulWidget {
  const DashboardMenuView({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardMenuView> createState() => _DashboardMenuViewState();
}

class _DashboardMenuViewState extends ConsumerState<DashboardMenuView> {
  @override
  void initState() {
    super.initState();
    ref.read(menuController).setTo(NaviType.menu);
  }

  @override
  Widget build(BuildContext context) {
    return UiKitPageView.withSliver(
      scrollable: true,
      backState: UiKitBackState.none,
      title: loc(context).menu,
      menuView: _buildMenuView(context),
      menuPosition: MenuPosition.left,
      child: (context, constraints) => Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMenuGridView(createMenuItems()),
          AppGap.xxl(),
          // const Spacer(),
          // AppTextButton.noPadding('About Linksys', onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildMenuGridView(List<AppSectionItemData> items) {
    final isDesktop = !context.isMobileLayout;
    return Scrollbar(
      thickness: 0,
      child: SizedBox(
        height: (items.length / (isDesktop ? 3 : 1)).ceil() *
                (isDesktop ? 152 : 112) +
            kDefaultToolbarHeight,
        child: GridView.builder(
          controller: Scrollable.maybeOf(context)?.widget.controller,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isDesktop ? 3 : 1,
            mainAxisSpacing: isDesktop ? AppSpacing.md : AppSpacing.sm,
            crossAxisSpacing: AppSpacing.lg,
            childAspectRatio: (205 / 152),
            mainAxisExtent: isDesktop ? 152 : 112,
          ),
          clipBehavior: Clip.none,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: items.length,
          itemBuilder: (context, index) {
            return _buildDeviceGridCell(items[index]);
          },
        ),
      ),
    );
  }

  Widget _buildDeviceGridCell(AppSectionItemData item) {
    final isBridge =
        ref.watch(dashboardHomeProvider).isBridgeMode && item.disabledOnBridge;
    return Opacity(
      opacity: isBridge ? .3 : 1,
      child: AbsorbPointer(
        absorbing: isBridge,
        child: AppMenuCard(
          iconData: item.iconData,
          title: item.title,
          description: item.description,
          status: item.status,
          isBeta: item.isBeta,
          onTap: item.onTap,
        ),
      ),
    );
  }

  PageMenuView _buildMenuView(BuildContext context) {
    return PageMenuView(
      icon: Icons.menu,
      label: loc(context).myNetwork,
      content: AppCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppListTile(
              title: AppText.bodyMedium(loc(context).restartNetwork),
              leading: const AppIcon.font(AppFontIcons.restartAlt),
              onTap: () {
                Navigator.of(context).maybePop();
                _restartNetwork();
              },
            ),
            AppListTile(
              title: AppText.bodyMedium(loc(context).menuSetupANewProduct),
              leading: const AppIcon.font(AppFontIcons.add),
              onTap: () {
                Navigator.of(context).maybePop();
                context.pushNamed(RouteNamed.addNodes);
              },
            ),
          ],
        ),
      ),
    );
  }

  List<AppSectionItemData> createMenuItems() {
    // final isCloudLogin =
    //     ref.watch(authProvider).value?.loginType == LoginType.remote;
    final safetyState = ref.watch(instantSafetyProvider);
    final privacyState = ref.watch(instantPrivacyProvider);
    // External Speed test check
    final routerType = ref.watch(connectivityProvider
        .select((value) => value.connectivityInfo.routerType));
    final isBehindRouter = routerType == RouterType.behindManaged ||
        BuildConfig.forceCommandType == ForceCommand.local;
    final isSupportHealthCheck =
        ref.watch(healthCheckProvider).isSpeedTestModuleSupported;
    final isSupportVPN = getIt.get<ServiceHelper>().isSupportVPN();
    return [
      AppSectionItemData(
          title: loc(context).incredibleWiFi,
          description: loc(context).incredibleWiFiDesc,
          iconData: AppFontIcons.wifi,
          onTap: () {
            _navigateTo(RouteNamed.menuIncredibleWiFi);
          }),
      AppSectionItemData(
          title: loc(context).instantAdmin,
          description: loc(context).instantAdminDesc,
          iconData: AppFontIcons.accountCircle,
          onTap: () {
            _navigateTo(RouteNamed.menuInstantAdmin);
          }),
      AppSectionItemData(
          title: loc(context).instantTopology,
          description: loc(context).instantTopologyDesc,
          iconData: AppFontIcons.router,
          onTap: () {
            _navigateTo(RouteNamed.menuInstantTopology);
          }),
      AppSectionItemData(
          title: loc(context).instantSafety,
          description: loc(context).instantSafetyDesc,
          iconData: AppFontIcons.encrypted,
          disabledOnBridge: true,
          status: safetyState.settings.current.safeBrowsingType ==
              InstantSafetyType.off,
          onTap: () {
            _navigateTo(RouteNamed.menuInstantSafety);
          }),
      AppSectionItemData(
          title: loc(context).instantPrivacy,
          description: loc(context).instantPrivacyDesc,
          iconData: AppFontIcons.smartLock,
          status: privacyState.status.mode != MacFilterMode.allow,
          isBeta: true,
          onTap: () {
            _navigateTo(RouteNamed.menuInstantPrivacy);
          }),
      AppSectionItemData(
          title: loc(context).instantDevices,
          description: loc(context).instantDevicesDesc,
          iconData: AppFontIcons.devices,
          onTap: () {
            _navigateTo(RouteNamed.menuInstantDevices);
          }),
      AppSectionItemData(
          title: loc(context).advancedSettings,
          iconData: AppFontIcons.settings,
          onTap: () {
            _navigateTo(RouteNamed.menuAdvancedSettings);
          }),
      AppSectionItemData(
          title: loc(context).instantVerify,
          description: loc(context).instantVerifyDesc,
          iconData: AppFontIcons.technician,
          onTap: () {
            _navigateTo(RouteNamed.menuInstantVerify);
          }),
      if (isSupportVPN)
        AppSectionItemData(
            title: loc(context).vpn,
            description: loc(context).vpnDesc,
            iconData: AppFontIcons.smartLock,
            onTap: () {
              _navigateTo(RouteNamed.settingsVPN);
            }),
      if (!isSupportHealthCheck && isBehindRouter)
        AppSectionItemData(
            title: loc(context).externalSpeedText,
            description: loc(context).speedTestInternetToDeviceDesc,
            iconData: AppFontIcons.networkCheck,
            onTap: () {
              _navigateTo(RouteNamed.speedTestExternal);
            }),
      if (isSupportHealthCheck)
        AppSectionItemData(
            title: loc(context).speedTest,
            description: loc(context).speedTestInternetToRouterDesc,
            iconData: AppFontIcons.networkCheck,
            onTap: () {
              _navigateTo(RouteNamed.dashboardSpeedTest);
            }),
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
    if (context.isMobileLayout) {
      context.pop();
    }
    showMessageAppDialog(
      context,
      dismissible: true,
      title: loc(context).alertExclamation,
      message: loc(context).menuRestartNetworkMessage,
      actions: [
        AppButton(
          label: loc(context).ok,
          variant: SurfaceVariant.highlight,
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
              if (mounted) {
                showSuccessSnackBar(context, loc(context).successExclamation);
              }
            }).catchError((error) {
              if (mounted) {
                showRouterNotFoundAlert(context, ref);
              }
            }, test: (error) => error is ServiceSideEffectError);
          },
        ),
        AppButton(
          label: loc(context).cancel,
          variant: SurfaceVariant.tonal,
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
    this.status,
    this.isBeta = false,
  });

  final IconData? iconData;
  final String? title;
  final String? description;
  final VoidCallback? onTap;
  final bool? status;
  final bool isBeta;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FittedBox(
                fit: BoxFit.fill,
                child: iconData != null
                    ? AppIcon.font(
                        iconData!,
                        size: 24,
                      )
                    : null,
              ),
              if (status != null)
                AppBadge(
                  label: status! ? 'Off' : 'On',
                  color: status!
                      ? Theme.of(context).colorScheme.outline
                      : Theme.of(context)
                              .extension<AppColorScheme>()
                              ?.semanticSuccess ??
                          Colors.green,
                )
            ],
          ),
          if (title != null)
            Padding(
              padding: EdgeInsets.only(top: AppSpacing.sm),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.start,
                spacing: AppSpacing.sm,
                children: [
                  AppText.titleSmall(title ?? ''),
                  if (isBeta) ...[
                    AppBadge(
                      label: 'BETA',
                      color: Theme.of(context)
                              .extension<AppColorScheme>()
                              ?.semanticWarning ??
                          Colors.orange,
                    ),
                  ],
                ],
              ),
            ),
          if (description != null)
            Padding(
              padding: EdgeInsets.only(top: AppSpacing.xs),
              child: AppText.bodySmall(
                description ?? '',
                overflow: TextOverflow.ellipsis,
                maxLines: !context.isMobileLayout ? 3 : 1,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
        ],
      ),
    );
  }
}
