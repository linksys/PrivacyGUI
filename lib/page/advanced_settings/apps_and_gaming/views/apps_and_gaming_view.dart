import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/providers/apps_and_gaming_provider.dart';
import 'package:privacy_gui/page/components/mixin/page_snackbar_mixin.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/_ddns.dart';

class AppsGamingSettingsView extends ArgumentsConsumerStatefulView {
  const AppsGamingSettingsView({super.key, super.args});

  @override
  ConsumerState<AppsGamingSettingsView> createState() =>
      _AppsGamingSettingsViewState();
}

class _AppsGamingSettingsViewState extends ConsumerState<AppsGamingSettingsView>
    with PageSnackbarMixin, SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    doSomethingWithSpinner(
            context, ref.read(appsAndGamingProvider.notifier).fetch())
        .then((state) {});
  }

  @override
  void dispose() {
    super.dispose();

    _tabController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appsAndGamingProvider);
    ref.watch(singlePortForwardingListProvider);
    ref.watch(portRangeForwardingListProvider);
    ref.watch(portRangeTriggeringListProvider);
    ref.watch(ddnsProvider);
    final tabs = [
      Tab(
        text: loc(context).ddns,
      ),
      Tab(
        text: loc(context).singlePortForwarding,
      ),
      Tab(
        text: loc(context).portRangeForwarding,
      ),
      Tab(
        key: Key('portRangeTriggering'),
        text: loc(context).portRangeTriggering,
      ),
    ];
    final tabContents = [
      DDNSSettingsView(),
      SinglePortForwardingListView(),
      PortRangeForwardingListView(),
      PortRangeTriggeringListView(),
    ];
    return StyledAppPageView(
      title: loc(context).appsGaming,
      padding: EdgeInsets.zero,
      tabController: _tabController,
      bottomBar: PageBottomBar(
        isPositiveEnabled:
            ref.read(appsAndGamingProvider.notifier).isChanged() &&
                ref.watch(appsAndGamingProvider.notifier).isDataValid(),
        onPositiveTap: () {
          doSomethingWithSpinner(
                  context, ref.read(appsAndGamingProvider.notifier).save())
              .then((_) {
            showChangesSavedSnackBar();
          }).onError(
            (error, stackTrace) {
              showErrorMessageSnackBar(error);
            },
          );
        },
      ),
      onBackTap: () async {
        final isCurrentChanged =
            ref.read(appsAndGamingProvider.notifier).isChanged();
        if (isCurrentChanged && (await showUnsavedAlert(context) != true)) {
          return;
        }
        context.pop();
      },
      tabs: tabs,
      tabContentViews: tabContents,
      onTabTap: (index) {},
    );
  }
}
