import 'package:animated_list_plus/animated_list_plus.dart';
import 'package:animated_list_plus/transitions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/select_network/_select_network.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
// import 'package:privacy_gui/firebase/analytics.dart';
import 'package:privacygui_widgets/hook/icon_hooks.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/theme/const/spacing.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

class SelectNetworkView extends ArgumentsConsumerStatefulView {
  const SelectNetworkView({super.key});

  @override
  ConsumerState<SelectNetworkView> createState() => _SelectNetworkViewState();
}

class _SelectNetworkViewState extends ConsumerState<SelectNetworkView> {
  /// Will used to access the Animated list
  final GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();
  List<CloudNetworkModel> _items = [];
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(selectNetworkProvider);
    _items = state.value?.networks ?? [];
    _isLoading = state.isLoading || (state.value?.isCheckingOnline ?? false);

    return StyledAppPageView(
      scrollable: true,
      appBarStyle: AppBarStyle.close,
      onBackTap: ref.read(selectedNetworkIdProvider) != null
          ? null
          : () {
              ref.read(authProvider.notifier).logout();
            },
      child: AppBasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        content: _networkSection(_items, _isLoading, title: 'Network'),
      ),
    );
  }

  Widget _networkSection(List<CloudNetworkModel> networks, bool isLoading,
      {String title = ''}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(isLoading, title: title),
        const AppGap.small(),
        SizedBox(
          height: 92.0 * networks.length,
          child: ImplicitlyAnimatedList<CloudNetworkModel>(
            physics: const NeverScrollableScrollPhysics(),
            items: _items,
            itemBuilder: (context, animation, item, index) =>
                slideIt(animation, item),
            areItemsTheSame: (a, b) =>
                a.network.networkId == b.network.networkId,
          ),
        ),
      ],
    );
  }

  Widget _title(bool isLoading, {String title = ''}) {
    return Row(
      children: [
        AppText.titleLarge(
          title,
        ),
        const AppGap.regular(),
        _checkLoadingStatus(isLoading),
      ],
    );
  }

  Widget _checkLoadingStatus(bool isLoading) {
    if (isLoading) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(),
      );
    } else {
      return AppIconButton(
        padding: const EdgeInsets.all(0),
        icon: LinksysIcons.refresh,
        onTap: () {
          ref.read(selectNetworkProvider.notifier).refreshCloudNetworks();
        },
      );
    }
  }

  Widget slideIt(animation, CloudNetworkModel network) {
    return SizeFadeTransition(
      sizeFraction: 0.7,
      curve: Curves.easeInOut,
      animation: animation,
      child: _networkItem(network),
    );
    // return SlideTransition(
    //   position: Tween<Offset>(
    //     begin: const Offset(-1, 0),
    //     end: const Offset(0, 0),
    //   ).animate(animation),
    //   child: _networkItem(network),
    // );
  }

  Widget _networkItem(CloudNetworkModel network) {
    return InkWell(
      onTap: network.isOnline
          ? () async {
              final goRouter = GoRouter.of(context);
              if (network.network.networkId ==
                  ref.read(selectedNetworkIdProvider)) {
                // Select the same network
                context.pop();
              } else {
                // Select another network
                await ref
                    .read(dashboardManagerProvider.notifier)
                    .saveSelectedNetwork(network.network.routerSerialNumber,
                        network.network.networkId);
                // logEvent(
                //   eventName: 'ActionSelectNetwork',
                //   parameters: {
                //     'networkId': network.network.networkId,
                //   },
                // );
                goRouter.goNamed('prepareDashboard');
              }
            }
          : null,
      child: Opacity(
        opacity: network.isOnline ? 1 : 0.8,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: Spacing.regular,
          ),
          child: Row(
            children: [
              Image(
                image: CustomTheme.of(context).images.devices.getByName(
                      routerIconTestByModel(
                        modelNumber: network.network.routerModelNumber,
                        hardwareVersion: network.network.routerHardwareVersion,
                      ),
                    ),
                width: 60,
                height: 60,
              ),
              const AppGap.semiBig(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.bodyLarge(network.network.friendlyName,
                      color: network.isOnline
                          ? null
                          : Theme.of(context).colorScheme.onInverseSurface),
                  const AppGap.small(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
