import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

OverlayEntry showFullScreenSpinner(
  BuildContext context, {
  Color? background,
  Color? color,
  String? title,
  List<String> messages = const [],
  Duration? period,
}) {
  final entry = _buildOverlayEntry(
      background: background,
      color: color,
      title: title,
      messages: messages,
      period: period);

  Overlay.of(context).insert(entry);
  return entry;
}

OverlayEntry _buildOverlayEntry({
  Color? background,
  Color? color,
  String? title,
  List<String> messages = const [],
  Duration? period,
}) {
  int currentIndex = 0;
  final stream = Stream.periodic(period ?? const Duration(seconds: 3))
      .map((_) => messages[currentIndex++ % messages.length]);

  final entry = OverlayEntry(builder: (context) {
    return StreamBuilder<String>(
        stream: stream,
        initialData: messages.firstOrNull,
        builder: (context, snapshot) {
          return Container(
            color: background ?? Colors.black54,
            width: double.infinity,
            height: double.infinity,
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const AppLoader(),
                  if (title != null) ...[
                    AppGap.lg(),
                    AppText.titleLarge(
                      title,
                      color: Colors.white,
                    ),
                  ],
                  if (snapshot.data != null) ...[
                    AppGap.md(),
                    AppText.bodyMedium(
                      snapshot.data!,
                      color: Colors.white,
                    ),
                  ],
                ],
              ),
            ),
          );
        });
  });
  return entry;
}
