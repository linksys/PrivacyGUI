import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/data/providers/polling_provider.dart';
import 'package:privacy_gui/page/dashboard/views/components/core/loading_tile.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// A wrapper widget that shows a loading state while dashboard data is being fetched.
///
/// This widget checks the [pollingProvider] state and displays a [LoadingTile]
/// inside an [AppCard] when data is not ready. Once ready, it renders the
/// child content via the [builder] callback.
///
/// Example usage:
/// ```dart
/// DashboardLoadingWrapper(
///   loadingHeight: 250,
///   builder: (context, ref) {
///     final state = ref.watch(dashboardHomeProvider);
///     return MyContentWidget(state: state);
///   },
/// )
/// ```
class DashboardLoadingWrapper extends ConsumerWidget {
  /// Creates a dashboard loading wrapper.
  const DashboardLoadingWrapper({
    super.key,
    required this.builder,
    this.loadingHeight = 250,
    this.loadingWidth,
  });

  /// Builder callback that creates the content widget when loading is complete.
  final Widget Function(BuildContext context, WidgetRef ref) builder;

  /// Height of the loading placeholder. Defaults to 250.
  final double loadingHeight;

  /// Width of the loading placeholder. Defaults to double.infinity.
  final double? loadingWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading =
        (ref.watch(pollingProvider).value?.isReady ?? false) == false;

    if (isLoading) {
      return AppCard(
        padding: EdgeInsets.zero,
        child: SizedBox(
          width: loadingWidth ?? double.infinity,
          height: loadingHeight,
          child: const LoadingTile(),
        ),
      );
    }

    return builder(context, ref);
  }
}
