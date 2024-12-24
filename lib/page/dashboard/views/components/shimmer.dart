import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerContainer extends ConsumerWidget {
  final Widget child;
  final bool isLoading;
  final double? loadingHeight;
  const ShimmerContainer({
    super.key,
    required this.child,
    this.isLoading = false,
    this.loadingHeight,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return isLoading ? shimmerWidget : child;
  }

  get shimmerWidget => Shimmer(
        gradient: _shimmerGradient,
        // child: AppCard(
        //   child: Container(
        //     height: 200,
        //   ),
        // ),
        child: loadingHeight != null ? SizedBox(height: loadingHeight, child: child,): child,
      );
  get _shimmerGradient => LinearGradient(
        colors: [
          Colors.grey,
          Colors.grey[300]!,
          Colors.grey,
        ],
        stops: const [
          0.1,
          0.3,
          0.4,
        ],
        begin: const Alignment(-1.0, -0.3),
        end: const Alignment(1.0, 0.3),
        tileMode: TileMode.clamp,
      );
}
