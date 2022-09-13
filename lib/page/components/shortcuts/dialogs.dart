import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

showAdaptiveDialog({
  required BuildContext context,
  required Widget title,
  required Widget content,
  List<Widget> actions = const [],
}) {
  if(Platform.isAndroid) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: title,
          content: content,
          actions: actions,
        ));
  } else {
    showDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: title,
          content: content,
          actions: actions,
        ));
  }
}
