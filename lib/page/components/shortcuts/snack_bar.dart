import 'package:flutter/material.dart';
import 'sized_box.dart';

showSuccessSnackBar(BuildContext context, String message) {
  showSimpleSnackBar(
    context,
    Image.asset('assets/images/icon_check_green.png'),
    message,
  );
}

showSimpleSnackBar(BuildContext context, Image? image, String message) {
  showSnackBar(
    context,
    SizedBox(
      height: 48,
      child: Row(
        children: [
          image ?? const Center(),
          box16(),
          Text(message),
        ],
      ),
    ),
  );
}

showSnackBar(BuildContext context, Widget content) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      content: content,
    ),
  );
}
