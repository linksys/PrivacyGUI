import 'package:flutter/material.dart';

Widget box8() {
  return const SizedBox(
    width: 8,
    height: 8,
  );
}

Widget box16() {
  return const SizedBox(
    width: 16,
    height: 16,
  );
}

Widget box24() {
  return const SizedBox(
    width: 24,
    height: 24,
  );
}

Widget box36() {
  return const SizedBox(
    width: 36,
    height: 36,
  );
}

Widget box48() {
  return const SizedBox(
    width: 48,
    height: 48,
  );
}

Widget box4() {
  return const SizedBox(
    width: 4,
    height: 4,
  );
}

Widget box12() {
  return const SizedBox(
    width: 12,
    height: 12,
  );
}

Widget box(double space, {Widget? child}) {
  return SizedBox(
    width: space,
    height: space,
    child: child,
  );
}

Widget infinityBox({Axis axis = Axis.horizontal, Widget? child}) {
  if (axis == Axis.horizontal) {
    return SizedBox(
      width: double.infinity,
      child: child,
    );
  } else {
    return SizedBox(
      height: double.infinity,
      child: child,
    );
  }
}

Widget dividerWithPadding(
    {Divider divider = const Divider(
      height: 1, color: Colors.black,
    ),
    EdgeInsets? padding}) {
  return Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 16.0),
      child: divider);
}
