import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/channel_finder/providers/channel_finder_provider.dart';
import 'package:privacy_gui/page/channel_finder/views/components/channel_finder_content.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Shows how busy each Wi-Fi channel is around the router (#1778).
///
/// Only shows; it changes no setting. Reached from the dashboard's Channel
/// Finder card, from the diagnostics congestion step and from Wi-Fi Settings →
/// Advanced. The scan belongs to the session ([channelFinderProvider]), so it
/// keeps running when the user leaves, and the card shows the same one.
class ChannelFinderView extends ConsumerWidget {
  const ChannelFinderView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(channelFinderProvider);
    final content = ChannelFinderContent(
      state: state,
      onScan: ref.read(channelFinderProvider.notifier).scan,
    );

    return UiKitPageView(
      identifier: 'channel-finder',
      scrollable: true,
      title: loc(context).channelFinder,
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      backFallback: RouteNamed.uspMenu,
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: (childContext, constraints) => content,
    );
  }
}
