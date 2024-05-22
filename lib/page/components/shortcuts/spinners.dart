import 'package:flutter/material.dart';
import 'package:privacygui_widgets/widgets/progress_bar/full_screen_spinner.dart';

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
          return AppFullScreenSpinner(
            background: background,
            color: color,
            title: title,
            text: snapshot.data,
          );
        });
  });
  return entry;
}
