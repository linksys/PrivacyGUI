import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppText(
      title,
      variant: AppTextVariant.titleSmall,
      fontWeight: FontWeight.bold,
    );
  }
}
