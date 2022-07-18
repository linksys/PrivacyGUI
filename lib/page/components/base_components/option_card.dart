import 'package:flutter/material.dart';
import 'package:moab_poc/design/colors.dart';

class OptionCard extends StatelessWidget {
  const OptionCard({
    Key? key,
    required this.title,
    required this.description,
    this.minHeight = 120,
    this.onPress,
  }): super(key: key);

  final String title;
  final String description;
  final double minHeight;
  final VoidCallback? onPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headline3?.copyWith(
                        color: Theme.of(context).primaryColor
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.headline4?.copyWith(
                        color: Theme.of(context).colorScheme.tertiary
                    ),
                  ),
                ],
                crossAxisAlignment: CrossAxisAlignment.start,
              ),
            ),
            const SizedBox(
              width: 20,
            ),
            Image.asset(
              'assets/images/arrow_point_to_right.png',
              width: 10,
              height: 10,
              color: Colors.white,
            ),
          ],
        ),
        color: MoabColor.cardBackground,
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          minHeight: minHeight,
        ),
      ),
      onTap: onPress,
    );
  }
}