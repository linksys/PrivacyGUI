import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/troubleshooting/providers/troubleshooting_provider.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/dropdown/dropdown_menu.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

class TroubleshootingPingView extends ArgumentsConsumerStatefulView {
  const TroubleshootingPingView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<TroubleshootingPingView> createState() =>
      _TroubleshootingPingViewState();
}

class _TroubleshootingPingViewState
    extends ConsumerState<TroubleshootingPingView> {
  late TextEditingController _controller;
  int? _pingCount = 5;
  StreamSubscription? _pingSubscription;
  String _log = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      scrollable: true,
      title: 'Troubleshooting',
      child: (context, constraints, scrollController) =>AppBasicLayout(
        content: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.labelLarge('Ping IPv4'),
            const AppGap.medium(),
            AppTextField(
              controller: _controller,
              headerText: 'IP or host name',
            ),
            const AppGap.medium(),
            AppDropdownMenu<String>(
              items: ['5', '10', '15', 'Unlimited'],
              label: (item) => item,
              onChanged: (value) {
                _pingCount = int.tryParse(value);
              },
            ),
            const AppGap.medium(),
            AppFilledButton(
              'Ping',
              onTap: () {
                ref
                    .read(troubleshootingProvider.notifier)
                    .ping(host: _controller.text, pingCount: _pingCount)
                    .then((_) {
                  setState(() {
                    _log = '';
                  });
                  _pingSubscription?.cancel();
                  _pingSubscription = ref
                      .read(troubleshootingProvider.notifier)
                      .getPingStatus()
                      .asBroadcastStream()
                      .listen((event) {
                    if (!event.isRunning) {
                      _pingSubscription?.cancel();
                    }
                    setState(() {
                      _log = event.pingLog;
                    });
                  });
                });
              },
            ),
            const AppGap.large5(),
            AppText.bodySmall(_log),
          ],
        ),
      ),
    );
  }
}
