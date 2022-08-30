import 'package:flutter/material.dart';

import 'model.dart';

Widget createStatusButton(BuildContext context, FilterStatus status) {
  Widget text = Text(
    'Allowed',
    style: Theme.of(context)
        .textTheme
        .button
        ?.copyWith(color: Colors.green, fontWeight: FontWeight.w700),
  );
  if (status == FilterStatus.someAllowed) {
    text = Text(
      'Some allowed',
      style: Theme.of(context)
          .textTheme
          .button
          ?.copyWith(color: Colors.yellow, fontWeight: FontWeight.w700),
    );
  } else if (status == FilterStatus.notAllowed) {
    text = Text(
      'Not allowed',
      style: Theme.of(context)
          .textTheme
          .button
          ?.copyWith(color: Colors.black, fontWeight: FontWeight.w700),
    );
  } else if (status == FilterStatus.force) {
    text = Text(
      'Not allowed',
      style: Theme.of(context)
          .textTheme
          .button
          ?.copyWith(color: Colors.black, fontWeight: FontWeight.w700),
    );
  }
  return ElevatedButton(
      onPressed: status == FilterStatus.force ? null : () {}, child: text);
}