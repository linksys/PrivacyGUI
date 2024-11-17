import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/models/traceroute_status.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_provider.dart';
import 'package:privacy_gui/validator_rules/input_validators.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/input_field/ip_form_field.dart';

class TracerouteModal extends ConsumerStatefulWidget {
  const TracerouteModal({
    super.key,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _TracerouteModalState();
}

class _TracerouteModalState extends ConsumerState<TracerouteModal> {
  final TextEditingController _controller = TextEditingController();
  String _tracerouteLog = '';
  StreamSubscription<TracerouteStatus>? _subscription;
  bool _validIP = false;

  @override
  void initState() {
    super.initState();

    _tracerouteLog = '';
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
          border: const OutlineInputBorder(),
          controller: _controller,
          onChanged: (value) {
            setState(() {
              _validIP = IpAddressValidator().validate(value);
            });
          },
        ),
        const AppGap.large1(),
        if (_tracerouteLog.isNotEmpty)
          SingleChildScrollView(
            child: AppText.bodySmall(_tracerouteLog),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AppTextButton(
              loc(context).close,
              onTap: () {
                ref.read(instantVerifyProvider.notifier).stopTraceroute();
                context.pop();
              },
            ),
            AppTextButton(
              loc(context).execute,
              onTap: isRunning || !_validIP
                  ? null
                  : () {
                      ref
                          .read(instantVerifyProvider.notifier)
                          .traceroute(host: _controller.text, pingCount: 5);
                      _getTracerouteStatus();
                    },
            )
          ],
        ),
      ],
    );
  }

  void _getTracerouteStatus() {
    _subscription?.cancel();
    _subscription = ref
        .read(instantVerifyProvider.notifier)
        .getTracerouteStatus()
        .listen((tracerouteStatus) {
      setState(() {
        _tracerouteLog = tracerouteStatus.tracerouteLog;
      });
    });
  }
}
