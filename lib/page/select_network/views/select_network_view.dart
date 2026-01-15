import 'package:animated_list_plus/animated_list_plus.dart';
import 'package:animated_list_plus/transitions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/data/providers/session_provider.dart';
import 'package:privacy_gui/core/utils/device_image_helper.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/select_network/_select_network.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:ui_kit_library/ui_kit.dart';

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

    return UiKitPageView(
      scrollable: true,
      appBarStyle: UiKitAppBarStyle.close,
      onBackTap: ref.read(selectedNetworkIdProvider) != null
          ? null
          : () {
              logger.i(
                  '[Auth]: Force to log out because the user does not select a network');
              ref.read(authProvider.notifier).logout();
            },
      child: (context, constraints) =>
          _networkSection(_items, _isLoading, title: 'Network'),
    );
  }

  Widget _networkSection(List<CloudNetworkModel> networks, bool isLoading,
      {String title = ''}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(isLoading, title: title),
        AppGap.md(),
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
        AppGap.lg(),
        _checkLoadingStatus(isLoading),
      ],
    );
  }

  Widget _checkLoadingStatus(bool isLoading) {
    if (isLoading) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: AppLoader(),
      );
    } else {
      return Semantics(
        label: 'refresh',
        child: AppIconButton(
          icon: const AppIcon.font(AppFontIcons.refresh),
          onTap: () {
            ref.read(selectNetworkProvider.notifier).refreshCloudNetworks();
          },
        ),
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
                await ref.read(sessionProvider.notifier).saveSelectedNetwork(
                    network.network.routerSerialNumber,
                    network.network.networkId);
                goRouter.goNamed('prepareDashboard');
              }
            }
          : null,
      child: Opacity(
        opacity: network.isOnline ? 1 : 0.8,
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: AppSpacing.lg,
          ),
          child: Row(
            children: [
              Image(
                image: DeviceImageHelper.getRouterImage(
                  network.network.routerModelNumber,
                ),
                semanticLabel: 'router image',
                width: 60,
                height: 60,
              ),
              AppGap.xxl(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.bodyLarge(network.network.friendlyName,
                      color: network.isOnline
                          ? null
                          : Theme.of(context).colorScheme.onInverseSurface),
                  AppGap.md(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
