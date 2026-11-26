/// Provider overrides for the Channel Finder dashboard card (#1778).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/channel_finder/providers/channel_finder_provider.dart';
import 'package:privacy_gui/page/channel_finder/providers/channel_finder_state.dart';

import '../test_data/scenes/channel_finder_scene_data.dart';

/// A `channelFinderProvider` pinned to one state, whose [scan] does nothing:
/// a fixture must never start a scan, and a harness that taps the button
/// should see the state it pinned, not one a scan moved it to.
class FixedChannelFinderNotifier extends ChannelFinderNotifier {
  FixedChannelFinderNotifier(this._fixedState);

  final ChannelFinderState _fixedState;

  @override
  ChannelFinderState build() => _fixedState;

  @override
  Future<void> scan() async {}
}

/// Overrides for the Channel Finder card, defaulting to
/// [channelFinderDoneState].
List<Override> channelFinderOverrides([ChannelFinderState? state]) => [
      channelFinderProvider.overrideWith(
          () => FixedChannelFinderNotifier(state ?? channelFinderDoneState)),
    ];
