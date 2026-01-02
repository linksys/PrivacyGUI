import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_verify/models/instant_verify_ui_models.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_provider.dart';
import 'package:privacy_gui/validator_rules/input_validators.dart';

import 'package:ui_kit_library/ui_kit.dart';

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
  StreamSubscription<TracerouteStatusUIModel>? _subscription;
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
        AppIpv4TextField(
          label: loc(context).ipAddress,
          controller: _controller,
          enabled: !isRunning,
          onChanged: (value) {
            setState(() {
              _validIP = IpAddressValidator().validate(value);
            });
          },
        ),
        AppGap.xl(),
        if (isRunning && _tracerouteLog.isEmpty)
          Center(
              child: SizedBox(
                  width: 36, height: 36, child: CircularProgressIndicator())),
        if (_tracerouteLog.isNotEmpty)
          Expanded(
            child: SingleChildScrollView(
              child: AppText.bodySmall(_tracerouteLog),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AppButton.text(
              label: loc(context).close,
              onTap: () {
                ref.read(instantVerifyProvider.notifier).stopTraceroute();
                context.pop();
              },
            ),
            AppButton.text(
              label: loc(context).execute,
              onTap: isRunning || !_validIP
                  ? null
                  : () {
                      setState(() {
                        _tracerouteLog = '';
                      });
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
