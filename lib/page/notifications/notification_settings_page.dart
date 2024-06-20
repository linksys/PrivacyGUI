import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/cloud/model/cloud_event_subscription.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/dashboard/providers/smart_device_provider.dart';

import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/panel/general_section.dart';

class NotificationSettingsView extends ConsumerStatefulWidget {
  const NotificationSettingsView({Key? key}) : super(key: key);

  @override
  ConsumerState<NotificationSettingsView> createState() =>
      _NotificationSettingsViewState();
}

class _NotificationSettingsViewState
    extends ConsumerState<NotificationSettingsView> {
  late final List<(String, String, CloudEventType)> _eventModelList;

  @override
  void initState() {
    super.initState();
    _initNotificationEvents();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(smartDeviceProvider);
    return StyledAppPageView(
        scrollable: true,
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppGap.large1(),
              _title(),
              const AppGap.large1(),
              _createNotificationTiles(state),
              //       .map((e) => AppPanelWithSwitch(value: e.$1, title: title))
            ],
          ),
        ));
  }

  Widget _title() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppText.titleLarge(
              'Notifications',
            ),
          ],
        ),
        AppText.bodyLarge('Send me notifications on this device when:'),
      ],
    );
  }

  void _initNotificationEvents() {
    if (!mounted) {
      return;
    }
    ref.read(smartDeviceProvider.notifier).fetchEventSubscriptions();
  }

  Widget _createNotificationTiles(LinksysSmartDevice state) {
    return AppSection.noHeader(
      content: Column(
        children: state.subscriptions
            .map((event) => AppPanelWithSwitch(
                  value: event.eventAction != null,
                  title: event.type.name,
                  onChangedEvent: (value) {
                    if (value) {
                      ref
                          .read(smartDeviceProvider.notifier)
                          .createNetworkEventAction(event.subscriptionId);
                    } else {
                      ref
                          .read(smartDeviceProvider.notifier)
                          .deleteNetworkEventAction(event.subscriptionId);
                    }
                  },
                ))
            .toList(),
      ),
    );
  }
}
