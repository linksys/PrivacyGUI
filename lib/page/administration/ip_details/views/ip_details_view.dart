import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:linksys_app/core/utils/extension.dart';
import 'package:linksys_app/providers/connectivity/_connectivity.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/shortcuts/snack_bar.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/page/administration/ip_details/providers/_providers.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/panel/general_section.dart';

class IpDetailsView extends ArgumentsConsumerStatelessView {
  const IpDetailsView({super.key, super.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IpDetailsContentView(
      args: super.args,
    );
  }
}

class IpDetailsContentView extends ArgumentsConsumerStatefulView {
  const IpDetailsContentView({super.key, super.args});

  @override
  ConsumerState<IpDetailsContentView> createState() =>
      _IpDetailsContentViewState();
}

class _IpDetailsContentViewState extends ConsumerState<IpDetailsContentView> {
  late final IpDetailsNotifier _notifier;

  bool _isBehindRouter = false;

  @override
  void initState() {
    _notifier = ref.read(ipDetailsProvider.notifier);
    _notifier.fetch();

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ipDetailsProvider);
    final connectivityState = ref.watch(connectivityProvider);
    _isBehindRouter = connectivityState.connectivityInfo.routerType ==
        RouterType.behindManaged;
    return StyledAppPageView(
      scrollable: true,
      title: getAppLocalizations(context).ip_details,
      child: AppBasicLayout(
        content: Column(
          children: [
            const AppGap.semiBig(),
            _checkRenewAvailable(),
            _wanSection(state),
            const AppGap.semiBig(),
            _lanSection(state),
          ],
        ),
      ),
    );
  }

  Widget _wanSection(IpDetailsState state) {
    return AppSection(
      header: AppText.labelLarge(
          getAppLocalizations(context).node_detail_label_wan),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSimplePanel(
            title: getAppLocalizations(context).connectionType,
            description: state.ipv4WANType,
          ),
          AppSimplePanel(
            title: getAppLocalizations(context).connectionType,
            description: state.ipv6WANType,
          ),
          AppPanelWithTrailWidget(
            title: loc(context).ipAddress.capitalizeWords(),
            description: state.ipv4WANAddress,
            trailing: _checkIpIsRenewIng(state),
          ),
          AppPanelWithTrailWidget(
            title: getAppLocalizations(context).ipv6_address,
            description: state.ipv6WANAddress,
            trailing: _checkIpv6IsRenewIng(state),
          ),
        ],
      ),
    );
  }

  Widget _checkIpIsRenewIng(IpDetailsState state) {
    if (state.ipv4Renewing) {
      return _buildRenewingSpinner();
    } else {
      return _buildRenewButton(false);
    }
  }

  Widget _checkIpv6IsRenewIng(IpDetailsState state) {
    if (state.ipv6Renewing) {
      return _buildRenewingSpinner();
    } else {
      return _buildRenewButton(true);
    }
  }

  _buildRenewButton(bool isIPv6) {
    return AppTextButton.noPadding(
      getAppLocalizations(context).release_and_renew,
      onTap: _isBehindRouter
          ? () {
              _notifier.renewIp(isIPv6).then((value) => showSuccessSnackBar(
                  context, getAppLocalizations(context).ip_address_renewed));
            }
          : null,
    );
  }

  _buildRenewingSpinner() {
    return Row(
      children: [
        const SizedBox(
            width: 18, height: 18, child: CircularProgressIndicator()),
        const AppGap.small(),
        AppText.bodyMedium(
          getAppLocalizations(context).ip_renewing,
        ),
      ],
    );
  }

  Widget _checkRenewAvailable() {
    if (!_isBehindRouter) {
      final ssid = ref
              .read(dashboardManagerProvider)
              .mainRadios
              .firstOrNull
              ?.settings
              .ssid ??
          '';
      return Container(
          width: double.infinity,
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: AppText.bodyLarge(
              getAppLocalizations(context).release_ip_description(ssid),
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ));
    }
    return const Center();
  }

  Widget _lanSection(IpDetailsState state) {
    return AppSection(
        header: AppText.labelLarge(
            getAppLocalizations(context).lan),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSimplePanel(
              title: loc(context).ipAddress.capitalizeWords(),
              description:
                  state.masterNode?.connections.firstOrNull?.ipAddress ?? '',
            ),
          ],
        ));
  }
}