import 'package:flutter/material.dart';
import 'package:linksys_moab/bloc/profiles/state.dart';

Widget createStatusButton(BuildContext context, FilterStatus status,
    {Function()? onPressed}) {
  Widget text = Text(
    'Allowed',
    style: Theme.of(context)
        .textTheme
        .button
        ?.copyWith(color: Colors.green, fontWeight: FontWeight.w700, fontSize: 11),
  );
  if (status == FilterStatus.someAllowed) {
    text = Text(
      'Some allowed',
      style: Theme.of(context)
          .textTheme
          .button
          ?.copyWith(color: Colors.yellow, fontWeight: FontWeight.w700, fontSize: 11),
    );
  } else if (status == FilterStatus.notAllowed) {
    text = Text(
      'Not allowed',
      style: Theme.of(context)
          .textTheme
          .button
          ?.copyWith(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 11),
    );
  } else if (status == FilterStatus.force) {
    text = Text(
      'Not allowed',
      style: Theme.of(context)
          .textTheme
          .button
          ?.copyWith(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 11),
    );
  }
  return InkWell(
    onTap: status == FilterStatus.force ? null : onPressed,
    child: Container(
      padding: const EdgeInsets.all(8),
      child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: status == FilterStatus.force ? Colors.white30 : Colors.white, borderRadius: BorderRadius.all(Radius.circular(4))),
          child: text),
    ),
  );
}
