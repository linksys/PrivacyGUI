import 'package:flutter/material.dart';

class MobileLayout extends StatelessWidget {
  final Widget child;

  const MobileLayout({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
