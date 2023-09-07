import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/utils/icon_rules.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_app/page/components/styled/consts.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/provider/auth/auth_provider.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/provider/network/_network.dart';
import 'package:linksys_app/provider/select_network/select_network_provider.dart';
import 'package:linksys_app/util/analytics.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/theme/data/colors.dart';
import 'package:linksys_widgets/theme/theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class SelectNetworkView extends ArgumentsConsumerStatefulView {
  const SelectNetworkView({super.key});

  @override
  ConsumerState<SelectNetworkView> createState() => _SelectNetworkViewState();
}

class _SelectNetworkViewState extends ConsumerState<SelectNetworkView> {
  /// Will used to access the Animated list
  final GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();
  final List<CloudNetworkModel> _items = [];
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(selectNetworkProvider, (_, data) {
      setState(() {
        _isLoading = data.isLoading || (data.value?.isCheckingOnline ?? false);
      });
      if (data.value != null) {
        final state = data.value;
        final networks = state?.networks ?? [];

        for (final network in networks) {
          Future.delayed(const Duration(milliseconds: 500)).then((_) {
            final target = _items.firstWhereOrNull((element) =>
                element.network.networkId == network.network.networkId);
            if (target != null) {
              if (network.isOnline != target.isOnline) {
                int index = _items.indexOf(target);
                logger.d(
                    '<${network.network.friendlyName}> Network goes online!!!! <$index>');
                removeItem(index, network).then((_) => insertItem(0, network));
              }
            } else {
              insertItem(_items.length, network);
            }
          });
        }
      }
    });
    return StyledAppPageView(
      scrollable: true,
      appBarStyle: AppBarStyle.close,
      onBackTap: ref.read(networkProvider).selected != null
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

  Future<void> insertItem(int index, CloudNetworkModel network) async {
    listKey.currentState
        ?.insertItem(index, duration: const Duration(milliseconds: 300));
    _items.insert(index, network);
  }

  Future<void> removeItem(int index, CloudNetworkModel network) async {
    listKey.currentState?.removeItem(
        index, (_, animation) => _networkItem(network),
        duration: const Duration(milliseconds: 300));
    _items.removeAt(index);
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
          child: AnimatedList(
            key: listKey,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            initialItemCount: 0,
            itemBuilder: (context, index, animation) =>
                slideIt(animation, networks[index]),
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
        if (isLoading)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }

  Widget slideIt(animation, CloudNetworkModel network) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-1, 0),
        end: const Offset(0, 0),
      ).animate(animation),
      child: _networkItem(network),
    );
  }

  Widget _networkItem(CloudNetworkModel network) {
    return InkWell(
      onTap: network.isOnline
          ? () async {
              await ref.read(networkProvider.notifier).selectNetwork(network);
              // _navigationNotifier.clearAndPush(PrepareDashboardPath());
              logEvent(
                eventName: 'ActionSelectNetwork',
                parameters: {
                  'networkId': network.network.networkId,
                },
              );
              context.goNamed('prepareDashboard');
            }
          : null,
      child: Opacity(
        opacity: network.isOnline ? 1 : 0.4,
        child: AppPadding(
          padding: const AppEdgeInsets.symmetric(
            vertical: AppGapSize.regular,
          ),
          child: Row(
            children: [
              Image(
                image: AppTheme.of(context).images.devices.getByName(
                      routerIconTest(
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
                  AppText.bodyLarge(
                    network.network.friendlyName,
                    color: network.isOnline
                        ? null
                        : ConstantColors.textBoxTextGray,
                  ),
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
