import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

class OptionCard extends ConsumerWidget {
  const OptionCard({
    Key? key,
    required this.title,
    required this.description,
    this.minHeight = 120,
    this.onPress,
  }) : super(key: key);

  final String title;
  final String description;
  final double minHeight;
  final VoidCallback? onPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onPress,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).primaryColor,
          ),
        ),
        constraints: BoxConstraints(
          minHeight: minHeight,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.bodyLarge(
                    title,
                  ),
                  const AppGap.medium(),
                  AppText.bodyMedium(
                    description,
                  ),
                ],
              ),
            ),
            const AppGap.large3(),
            Image.asset(
              'assets/images/arrow_point_to_right.png',
              semanticLabel: 'arrow',
              width: 10,
              height: 10,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
