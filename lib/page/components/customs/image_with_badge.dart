import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ImageWithBadge extends ConsumerWidget {
  const ImageWithBadge({
    Key? key,
    required this.imagePath,
    this.badgePath,
    required this.imageSize,
    this.badgeSize,
    this.offset = 8,
    this.fit,
  }) : super(key: key);

  final String imagePath;
  final String? badgePath;
  final double imageSize;
  final double? badgeSize;
  final double offset;
  final BoxFit? fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: imageSize + offset,
      height: imageSize + offset,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Padding(
            padding: EdgeInsets.all(offset),
            child: Image.asset(
              imagePath,
              width: imageSize,
              height: imageSize,
              fit: fit,
            ),
          ),
          if (badgePath != null)
            Image.asset(
              badgePath!,
              width: badgeSize,
              height: badgeSize,
            ),
        ],
      ),
    );
  }
}
