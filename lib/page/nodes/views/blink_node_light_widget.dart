import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/nodes/_nodes.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

class BlinkNodeLightWidget extends ConsumerStatefulWidget {
  final int max;
  final EdgeInsets? padding;
  const BlinkNodeLightWidget({
    super.key,
    this.max = 20,
    this.padding,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _BlinkNodeLightWidgetState();
}

class _BlinkNodeLightWidgetState extends ConsumerState<BlinkNodeLightWidget> {
  int _count = 0;
  bool _isBlinking = false;
  StreamSubscription? subscription;
  late final NodeDetailNotifier _notifier;

  Stream<int> startCounting() =>
      Stream<int>.periodic(const Duration(seconds: 1), (count) => count)
          .take(widget.max);

  @override
  void initState() {
    super.initState();
    _notifier = ref.read(nodeDetailProvider.notifier);
  }

  @override
  void dispose() {
    super.dispose();
    _stopBlink();
  }

  @override
  Widget build(BuildContext context) {
    return _isBlinking
        ? AppStyledText.link(
            loc(context).nodeDetailBlinkingCounting(_count),
            defaultTextStyle: Theme.of(context).textTheme.bodySmall!,
            tags: const ['u'],
            callbackTags: {
              'u': (String? text, Map<String?, String?> attrs) {
                _stopBlink();
              }
            },
          )
        : AppTextButton.noPadding(
            loc(context).nodeDetailBlinkNodeLightBtn,
            onTap: () {
              _startBlink();
            },
          );
  }

  _startBlink() async {
    await _notifier.toggleBlinkNode();
    setState(() {
      _count = widget.max;
      _isBlinking = true;
    });
    subscription =
        startCounting().map((event) => widget.max - event).listen((event) {
      setState(() {
        _count = event;
      });
    }, onDone: () {
      _stopBlink();
    });
  }

  _stopBlink() async {
    await _notifier.toggleBlinkNode();
    if (mounted) {
      setState(() {
        _isBlinking = false;
      });
    }
    subscription?.cancel();
  }
}
