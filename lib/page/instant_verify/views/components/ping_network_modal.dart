import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/models/ping_status.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_provider.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/input_field/ip_form_field.dart';

class PingNetworkModal extends ConsumerStatefulWidget {
  const PingNetworkModal({
    super.key,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _PingNetworkModalState();
}

class _PingNetworkModalState extends ConsumerState<PingNetworkModal> {
  final TextEditingController _controller = TextEditingController();
  String _pingLog = '';
  StreamSubscription<PingStatus>? _subscription;

  @override
  void initState() {
    super.initState();

    _pingLog = '';
  }

  @override
  void dispose() {
    super.dispose();

    _subscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = ref.watch(instantVerifyProvider).isRunning;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText.bodySmall(loc(context).dnsIpAddress),
        const AppGap.small2(),
        AppIPFormField(
          semanticLabel: 'dns ip address',
          border: const OutlineInputBorder(),
          controller: _controller,
        ),
        const AppGap.large1(),
        if (_pingLog.isNotEmpty)
          SingleChildScrollView(
            child: AppText.bodySmall(_pingLog),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AppTextButton(
              loc(context).close,
              onTap: () {
                ref.read(instantVerifyProvider.notifier).stopPing();
                context.pop();
              },
            ),
            AppTextButton(
              loc(context).ping,
              onTap: isRunning
                  ? null
                  : () {
                      ref
                          .read(instantVerifyProvider.notifier)
                          .ping(host: _controller.text, pingCount: 5);
                      _getPingStatus();
                    },
            )
          ],
        ),
      ],
    );
  }

  void _getPingStatus() {
    _subscription?.cancel();
    _subscription = ref
        .read(instantVerifyProvider.notifier)
        .getPingStatus()
        .listen((pingStatus) {
      setState(() {
        _pingLog = pingStatus.pingLog;
      });
    });
  }
}
