import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/providers/apps_and_gaming_provider.dart';
import 'package:privacy_gui/page/components/mixin/page_snackbar_mixin.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/styled/styled_tab_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/_ddns.dart';

class AppsGamingSettingsView extends ArgumentsConsumerStatefulView {
  const AppsGamingSettingsView({super.key, super.args});

  @override
  ConsumerState<AppsGamingSettingsView> createState() =>
      _AppsGamingSettingsViewState();
}

class _AppsGamingSettingsViewState extends ConsumerState<AppsGamingSettingsView>
    with PageSnackbarMixin {
  @override
  void initState() {
    super.initState();

    doSomethingWithSpinner(
        context, ref.read(appsAndGamingProvider.notifier).fetch());
  }

  @override
  void dispose() {
    super.dispose();
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
      appBarStyle: AppBarStyle.none,
      bottomBar: PageBottomBar(
        isPositiveEnabled: ref.read(appsAndGamingProvider.notifier).isChanged(),
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
      child: StyledAppTabPageView(
        title: loc(context).appsGaming,
        padding: EdgeInsets.zero,
        useMainPadding: false,
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
        expandedHeight: 120,
        onTap: (index) {},
      ),
    );
  }
}
