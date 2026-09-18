import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_issue.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_models.dart';
import 'package:privacy_gui/page/auto_ipoe/providers/auto_ipoe_notifier.dart';
import 'package:privacy_gui/page/auto_ipoe/providers/auto_ipoe_state.dart';
import 'package:privacy_gui/page/auto_ipoe/views/auto_ipoe_recovery_ui.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';

class AutoIPoEOptionalPane extends ConsumerStatefulWidget {
  const AutoIPoEOptionalPane({
    super.key,
    required this.state,
    required this.shouldTrackRuntime,
    required this.awaitingCompletion,
    required this.onAwaitingCompletionChanged,
    this.issue,
    this.isChecking = false,
    this.showRecovery = true,
    this.onContinueChecking,
    this.onRetry,
    this.onEditSettings,
    this.onCompleted,
    this.onIssue,
    this.expectedMode,
    this.compactProgress = false,
    this.progress = const AutoIPoEReconciliationProgress.initial(),
  });

  final AutoIPoEState state;
  final bool shouldTrackRuntime;
  final bool awaitingCompletion;
  final ValueChanged<bool> onAwaitingCompletionChanged;
  final AutoIPoEIssue? issue;
  final bool isChecking;
  final bool showRecovery;
  final VoidCallback? onContinueChecking;
  final VoidCallback? onRetry;
  final VoidCallback? onEditSettings;
  final ValueChanged<AutoIPoEState>? onCompleted;
  final ValueChanged<AutoIPoEIssue>? onIssue;
  final AutoIPoEMode? expectedMode;
  final bool compactProgress;
  final AutoIPoEReconciliationProgress progress;

  @override
  ConsumerState<AutoIPoEOptionalPane> createState() =>
      _AutoIPoEOptionalPaneState();
}

class _AutoIPoEOptionalPaneState extends ConsumerState<AutoIPoEOptionalPane> {
  final TextEditingController _logController = TextEditingController();
  final ScrollController _logScrollController = ScrollController();
  Timer? _pollTimer;
  bool _isRefreshing = false;
  bool _isLogExpanded = false;

  @override
  void initState() {
    super.initState();
    _syncLog(
      widget.state.log.content,
      followTail: widget.state.status.isBusy,
    );
    _startPolling();
  }

  @override
  void didUpdateWidget(covariant AutoIPoEOptionalPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.log.content != widget.state.log.content) {
      _syncLog(
        widget.state.log.content,
        followTail: widget.state.status.isBusy,
      );
    }
    if (oldWidget.shouldTrackRuntime != widget.shouldTrackRuntime) {
      _startPolling();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _logController.dispose();
    _logScrollController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    if (!widget.shouldTrackRuntime) {
      return;
    }

    unawaited(_refreshRuntime());
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      unawaited(_refreshRuntime());
    });
  }

  Future<void> _refreshRuntime() async {
    if (!mounted || _isRefreshing || !widget.shouldTrackRuntime) {
      return;
    }

    _isRefreshing = true;
    try {
      final nextState =
          await ref.read(autoIPoEProvider.notifier).refreshRuntime();
      _syncLog(
        nextState.log.content,
        followTail: nextState.status.isBusy,
      );
      _handleCompletion(nextState);
    } catch (error, stackTrace) {
      // Network and WiFi restart temporarily make JNAP unreachable. Preserve
      // the last visible output and let the next polling interval reconcile.
      logger.w(
        '[Auto-IPoE]: Runtime polling paused during network restart',
        error: error,
        stackTrace: stackTrace,
      );
      if (widget.awaitingCompletion) {
        widget.onIssue?.call(AutoIPoEIssueMapper.from(error: error));
      }
    } finally {
      _isRefreshing = false;
    }
  }

  void _syncLog(String value, {required bool followTail}) {
    if (_logController.text == value) {
      return;
    }
    final currentOffset = _logController.selection.baseOffset;
    final preservedOffset =
        currentOffset < 0 ? 0 : currentOffset.clamp(0, value.length);
    _logController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(
        offset: followTail ? value.length : preservedOffset,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !followTail || !_logScrollController.hasClients) {
        return;
      }
      _logScrollController.jumpTo(
        _logScrollController.position.maxScrollExtent,
      );
    });
  }

  void _handleCompletion(AutoIPoEState nextState) {
    if (!widget.awaitingCompletion || !mounted) {
      return;
    }

    final nextStatus = nextState.status;
    if (AutoIPoEIssueMapper.isVerifiedActive(
      nextStatus,
      expectedMode: widget.expectedMode,
    )) {
      // The apply process already restarted WAN and Wi-Fi. A validated Active
      // tunnel is the only success signal; a normal log footer alone is not.
      widget.onCompleted?.call(nextState);
      widget.onAwaitingCompletionChanged(false);
    } else if (nextStatus.hasTerminalApplyOutcome) {
      final issue = AutoIPoEIssueMapper.from(status: nextStatus);
      if (issue.isTerminal) {
        widget.onAwaitingCompletionChanged(false);
      }
      widget.onIssue?.call(issue);
    }
  }

  Widget _buildLogDisclosure(
    BuildContext context, {
    required bool isPnpProgress,
  }) {
    final l = loc(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buttonText = _isLogExpanded ? l.autoIpoeHideLog : l.autoIpoeShowLog;
    final accessibilityLabel = isPnpProgress
        ? (_isLogExpanded
            ? l.autoIpoePnpHideLogAccessibilityLabel
            : l.autoIpoePnpShowLogAccessibilityLabel)
        : buttonText;
    final logTextStyle = TextStyle(
      fontSize: 13,
      height: 1.45,
      color: isDark ? const Color(0xFFF4E8D0) : const Color(0xFF303030),
      fontFamily: null,
      fontFamilyFallback: fontKeys,
      decoration: TextDecoration.none,
    );
    final logBackgroundColor =
        isDark ? const Color(0xFF242424) : const Color(0xFFF5F5F5);
    final logBorderColor =
        isDark ? const Color(0xFF585858) : const Color(0xFFC2C2C2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          key: const ValueKey('autoIpoeLogDisclosure'),
          container: true,
          button: true,
          expanded: _isLogExpanded,
          label: accessibilityLabel,
          child: ExcludeSemantics(
            child: AppTextButton(
              buttonText,
              onTap: () {
                setState(() {
                  _isLogExpanded = !_isLogExpanded;
                });
              },
            ),
          ),
        ),
        if (_isLogExpanded) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.small3),
            child: AppText.titleMedium(l.autoIpoeLogTitle),
          ),
          Container(
            key: const ValueKey('autoIpoeLogOutput'),
            width: double.infinity,
            constraints: isPnpProgress
                ? const BoxConstraints(minHeight: 160, maxHeight: 200)
                : const BoxConstraints(minHeight: 260, maxHeight: 420),
            padding: const EdgeInsets.all(Spacing.small3),
            decoration: BoxDecoration(
              color: logBackgroundColor,
              border: Border.all(color: logBorderColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _logController,
              scrollController: _logScrollController,
              readOnly: true,
              expands: true,
              maxLines: null,
              minLines: null,
              showCursor: false,
              style: logTextStyle,
              cursorColor:
                  isDark ? const Color(0xFFF4E8D0) : const Color(0xFF303030),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: l.autoIpoeNoLogOutputYet,
                hintStyle: logTextStyle.copyWith(
                  color: isDark
                      ? const Color(0xFFB8AD98)
                      : const Color(0xFF666666),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final canShowRecovery = widget.showRecovery &&
        widget.awaitingCompletion &&
        widget.onContinueChecking != null &&
        widget.onRetry != null &&
        widget.onEditSettings != null;
    if (widget.compactProgress) {
      if (!canShowRecovery) {
        return const SizedBox.shrink();
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AutoIPoERecoveryPanel(
            compactProgress: true,
            progress: widget.progress,
            isChecking: widget.isChecking,
            issue: widget.issue,
            onContinueChecking: widget.onContinueChecking!,
            onRetry: widget.onRetry!,
            onEditSettings: widget.onEditSettings!,
          ),
          const AppGap.medium(),
          _buildLogDisclosure(context, isPnpProgress: true),
        ],
      );
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(
        vertical: Spacing.small1,
        horizontal: Spacing.large2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canShowRecovery) ...[
            AutoIPoERecoveryPanel(
              isChecking: widget.isChecking,
              issue: widget.issue,
              onContinueChecking: widget.onContinueChecking!,
              onRetry: widget.onRetry!,
              onEditSettings: widget.onEditSettings!,
            ),
            const AppGap.large3(),
          ],
          _buildLogDisclosure(context, isPnpProgress: false),
        ],
      ),
    );
  }
}
