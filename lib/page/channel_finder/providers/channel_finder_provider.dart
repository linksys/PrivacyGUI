import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/channel_finder/providers/channel_finder_state.dart';
import 'package:privacy_gui/page/channel_finder/services/channel_finder_service.dart';

/// The session's Channel Finder scan (#1778).
///
/// Not autoDispose: the dashboard card, the page and the diagnostics link show
/// the same scan, and a scan started on one keeps running while the user moves
/// to another. A new USP client (a new session) starts it over.
final channelFinderProvider =
    NotifierProvider<ChannelFinderNotifier, ChannelFinderState>(
        ChannelFinderNotifier.new);

class ChannelFinderNotifier extends Notifier<ChannelFinderState> {
  /// Bumped by every [build] and [scan], so a scan that was superseded, or
  /// that belongs to an earlier session, never publishes.
  int _generation = 0;

  @override
  ChannelFinderState build() {
    ref.watch(uspClientProvider);
    _generation++;
    return const ChannelFinderState();
  }

  /// Starts a scan, unless one is running. Ends on [ChannelFinderPhase.done]
  /// or [ChannelFinderPhase.failed] whatever is thrown (constitution
  /// Article XIII §13.4.3): the scanning phase has no way out of its own.
  Future<void> scan() async {
    if (state.isScanning) return;
    final generation = ++_generation;
    state = state.copyWith(
      phase: ChannelFinderPhase.scanning,
      clearStage: true,
      clearError: true,
    );
    try {
      final result = await ref.read(channelFinderServiceProvider).scan(
        onStage: (stage) {
          if (generation == _generation) state = state.copyWith(stage: stage);
        },
      );
      if (generation != _generation) return;
      state = ChannelFinderState(
          phase: ChannelFinderPhase.done, lastResult: result);
    } on ServiceError catch (e) {
      logger.w('[ChannelFinder] Scan failed: $e');
      _fail(generation, e);
    } catch (e, stack) {
      logger.e('[ChannelFinder] Scan failed outside the service',
          error: e, stackTrace: stack);
      _fail(generation, UnexpectedError(originalError: e));
    }
  }

  void _fail(int generation, ServiceError error) {
    if (generation != _generation) return;
    state = state.copyWith(
      phase: ChannelFinderPhase.failed,
      clearStage: true,
      error: error,
    );
  }
}
