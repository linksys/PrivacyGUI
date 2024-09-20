import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/models/ping_status.dart';
import 'package:privacy_gui/core/jnap/models/traceroute_status.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_provider.dart';
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
  bool _isRunning = false;
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TracerouteStatus>(
        stream: _isRunning
            ? ref.read(instantVerifyProvider.notifier).getTracerouteStatus()
            : null,
        builder: (context, snapshot) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText.bodySmall('DNS IP address'),
              const AppGap.small2(),
              AppIPFormField(
                border: const OutlineInputBorder(),
                controller: _controller,
              ),
              const AppGap.large1(),
              if (snapshot.hasData)
                SingleChildScrollView(
                  child: AppText.bodySmall(snapshot.data?.tracerouteLog ?? ''),
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
                    'Ping',
                    onTap: () {
                      ref
                          .read(instantVerifyProvider.notifier)
                          .traceroute(host: _controller.text, pingCount: 5);
                      setState(() {
                        _isRunning = true;
                      });
                    },
                  )
                ],
              ),
            ],
          );
        });
  }
}
