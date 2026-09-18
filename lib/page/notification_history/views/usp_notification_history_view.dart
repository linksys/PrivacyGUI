import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/components/views/service_error_view.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/notification_history/models/notification_history_ui_model.dart';
import 'package:privacy_gui/page/notification_history/providers/usp_notification_history_notifier.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// The Remote Assistance notification history — `CLOUD_GUARDIANS#205` Item 7, and
/// the only one of that issue's nine items a user can see.
///
/// Reads Guardian's own store: `usp/state` once for the two timestamps at the top,
/// `usp/notifications/history` for the list, and one entry's `body` when a row is
/// opened. All three work with the device offline, because the store is the
/// cloud's.
///
/// ## Three rules this page is built around
///
/// **Nothing is on a timer.** Refresh is the pull gesture only; the spec
/// prohibits polling these reads because Guardian already polls DynamoDB on our
/// behalf. Asserted in `usp_notification_history_notifier_test.dart` against a
/// mock's call count.
///
/// **An empty list is correct.** History is scoped to one support session, so a
/// fresh session always starts with nothing. The empty state says that, rather
/// than "no data", which reads like a fault.
///
/// **A live SSE event cannot be correlated to a row.** The stream sends the notify
/// body alone — no `msgId`, no `originTs` — so there is no click-through from a
/// notification the app has just received to its stored copy, and none should be
/// designed. The by-`msgId` read is reachable only from this list.
class UspNotificationHistoryView extends ConsumerWidget {
  const UspNotificationHistoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reached by a hand-typed URL in a local build, because the child routes of
    // the shared dashboard are one table. Answering with an explicit state beats
    // the developer error page a missing-params route produces — the mirror of
    // what #1474 phase 9 decided for `localLoginRoute` in a remote build.
    final available = ref.watch(notificationHistoryAvailableProvider);

    return UiKitPageView.withSliver(
      scrollable: true,
      title: loc(context).notificationHistory,
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      backFallback: RouteNamed.uspMenu,
      onRefresh: available
          ? () => ref.read(uspNotificationHistoryProvider.notifier).refresh()
          : null,
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: (childContext, constraints) {
        if (!available) return const _UnavailableState();
        return ref.watch(uspNotificationHistoryProvider).when(
              loading: () => const Center(child: AppLoader()),
              error: (error, stack) => ServiceErrorView(
                error: error is ServiceError ? error : null,
                title: loc(context).failedToLoadSettings,
                onRetry: () => ref.invalidate(uspNotificationHistoryProvider),
              ),
              data: (state) => _Content(state: state),
            );
      },
    );
  }
}

/// The local answer: there is no notification store on the router to read.
class _UnavailableState extends StatelessWidget {
  const _UnavailableState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon.font(
              Icons.cloud_off_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            AppGap.xl(),
            AppText.bodyMedium(
              loc(context).notificationHistoryUnavailable,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  final NotificationHistoryState state;

  const _Content({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SessionStateCard(sessionState: state.sessionState),
        AppGap.md(),
        if (state.entries.isEmpty)
          const _EmptyState()
        else ...[
          NotificationHistoryTypeFilter(state: state),
          AppGap.md(),
          for (final entry in state.visibleEntries) ...[
            _EntryCard(entry: entry),
            AppGap.sm(),
          ],
          if (state.hasMore) ...[
            AppGap.sm(),
            Center(
              child: AppButton.text(
                label: loc(context).notificationHistoryShowMore,
                identifier: 'notification-history-show-more',
                onTap: () => ref
                    .read(uspNotificationHistoryProvider.notifier)
                    .showMore(),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

/// `lastBoot` and `lastUspActivity`, both of which are legitimately null.
class _SessionStateCard extends StatelessWidget {
  /// The em dash both timestamps fall back to.
  ///
  /// Null here means the device has produced nothing yet, which is the normal
  /// state of a device that has just been adopted — not an error, and not a
  /// reason to hide the row.
  static const _absent = '—';

  final SessionUspStateUIModel? sessionState;

  const _SessionStateCard({required this.sessionState});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _labelled(context, loc(context).notificationHistoryLastBoot,
              _format(context, sessionState?.lastBoot)),
          AppGap.sm(),
          _labelled(context, loc(context).notificationHistoryLastActivity,
              _format(context, sessionState?.lastUspActivity)),
        ],
      ),
    );
  }

  String _format(BuildContext context, DateTime? at) =>
      at == null ? _absent : _formatTimestamp(at);

  /// A `Wrap` rather than a `Row`, for the reason the log cards use one: a label
  /// and a value that both grow with the locale overflow a 320px phone as a
  /// `Row`, and reflow onto two runs as a `Wrap`. Guarded by the page-surface
  /// sweep.
  Widget _labelled(BuildContext context, String label, String value) =>
      SizedBox(
        width: double.infinity,
        child: Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppText.bodySmall(
              label,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            AppText.bodyMedium(value),
          ],
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon.font(
            Icons.notifications_none,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          AppGap.xl(),
          AppText.bodyMedium(
            loc(context).notificationHistoryEmpty,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Narrows the list by `notificationType`, client-side.
///
/// The options come from the data rather than from a fixed list of USP's six
/// variants: `Unknown` is a real stored value, and the cloud may store a seventh
/// before this app knows about it. An option with no rows behind it is worse than
/// one that is missing.
/// Public, and named, for one reason worth stating: the layout gate's
/// `requires` premise is a list of `Type`s, and `AppDropdown<String>` cannot be
/// named as `AppDropdown` there — a bare generic resolves to
/// `AppDropdown<dynamic>` and matches nothing. This class is what
/// `kNotificationHistoryPageCase` names to prove a cell rendered the list rather
/// than the empty state, the same way `StatsLegendDot` and `WifiNetworkCard` are
/// named for their pages.
class NotificationHistoryTypeFilter extends ConsumerWidget {
  /// The sentinel for "no filter". `AppDropdown` wants a non-null value, and an
  /// empty string cannot collide with a stored `notificationType`.
  static const _all = '';

  final NotificationHistoryState state;

  const NotificationHistoryTypeFilter({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppDropdown<String>(
      items: [_all, ...state.availableTypes],
      value: state.typeFilter ?? _all,
      label: loc(context).type,
      identifier: 'notification-history-type-filter',
      itemIdentifier: (value) => value == _all
          ? 'notification-history-type-all'
          : 'notification-history-type-$value',
      itemAsString: (value) => value == _all ? loc(context).all : value,
      onChanged: (value) => ref
          .read(uspNotificationHistoryProvider.notifier)
          .setTypeFilter(value == _all ? null : value),
    );
  }
}

/// One history row. Tapping it fetches that entry's body.
class _EntryCard extends ConsumerWidget {
  final NotificationHistoryEntryUIModel entry;

  const _EntryCard({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return AppCard(
      identifier: 'notification-history-row-${entry.msgId}',
      onTap: () => _openDetail(context, ref),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xs,
              children: [
                // The stored type, verbatim and untranslated. It is a protocol
                // identifier the spec and #205 both name in these exact words,
                // and the rest of this row — `msgId`, `commandKey`, the body's
                // `param_path` — is raw for the same reason. Translating one of
                // them would make the page inconsistent and the value
                // un-greppable against the contract; `Unknown` is itself a
                // stored value rather than a UI fallback.
                AppText.titleSmall(entry.notificationType),
                AppText.bodySmall(_formatTimestamp(entry.originTs),
                    color: muted),
              ],
            ),
          ),
          AppGap.sm(),
          _field(
              context, loc(context).notificationHistoryMessageId, entry.msgId),
          // Null on every row but `OperationComplete`, which is the common case
          // and not worth an empty line each time.
          if (entry.commandKey != null) ...[
            AppGap.xs(),
            _field(context, loc(context).notificationHistoryCommandKey,
                entry.commandKey!),
          ],
        ],
      ),
    );
  }

  Widget _field(BuildContext context, String label, String value) => SizedBox(
        width: double.infinity,
        child: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            AppText.bodySmall(
              label,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            AppText.bodySmall(value),
          ],
        ),
      );

  void _openDetail(BuildContext context, WidgetRef ref) {
    showAppDialog<void>(
      context: context,
      builder: (ctx) => AppDialog(
        title: AppText.titleMedium(entry.notificationType),
        content: _DetailContent(msgId: entry.msgId),
        actions: [
          AppButton.text(
            label: loc(ctx).close,
            identifier: 'notification-history-detail-close',
            onTap: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }
}

/// The body of one entry, fetched when the dialog opens.
class _DetailContent extends ConsumerWidget {
  final String msgId;

  const _DetailContent({required this.msgId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(notificationDetailProvider(msgId)).when(
          loading: () => const Center(child: AppLoader()),
          // A 404 is the ordinary case of an entry that has aged out or was
          // never this session's — the spec deliberately does not distinguish
          // them — so it gets its own sentence rather than the generic failure
          // view. Anything else is a fault and reads as one.
          error: (error, stack) => AppText.bodyMedium(
            error is ResourceNotFoundError
                ? loc(context).notificationHistoryGone
                : loc(context).failedToLoadSettings,
          ),
          data: (detail) => _Body(body: detail.body),
        );
  }
}

/// Three shapes plus a fallback, per #1580 — not six widgets.
class _Body extends StatelessWidget {
  final NotificationBodyUIModel body;

  const _Body({required this.body});

  @override
  Widget build(BuildContext context) {
    // Exhaustive over the sealed body, which is what a seventh upstream member
    // arriving cannot silently break: it lands in `RawBodyUIModel` and is still
    // readable.
    final rows = switch (body) {
      ValueChangeBodyUIModel(:final paramPath, :final paramValue) => [
          ('param_path', paramPath),
          ('param_value', paramValue),
        ],
      OperationCompleteBodyUIModel(
        :final commandName,
        :final commandKey,
        :final outputArgs,
        :final errorCode,
        :final errorMessage,
        :final refused,
      ) =>
        [
          ('command_name', commandName),
          ('command_key', commandKey),
          if (refused) ...[
            ('err_code', errorCode ?? '—'),
            ('err_msg', errorMessage ?? '—'),
          ] else
            for (final arg in outputArgs.entries) (arg.key, arg.value),
        ],
      EventBodyUIModel(:final eventName, :final params) => [
          ('event_name', eventName),
          for (final param in params.entries) (param.key, param.value),
        ],
      RawBodyUIModel() => const <(String, String)>[],
    };

    if (body case RawBodyUIModel(:final pretty, :final isEmpty)) {
      return isEmpty
          ? AppText.bodyMedium(loc(context).notificationHistoryGone)
          // Selectable because the only useful thing to do with an unrecognised
          // body is copy it into the ticket. No font override: the app's CJK and
          // Arabic fallbacks are declared per family, and naming one that is not
          // among them drops those scripts to tofu.
          : SelectableText(pretty);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in rows) ...[
          SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                AppText.bodySmall(
                  row.$1,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                AppText.bodySmall(row.$2),
              ],
            ),
          ),
          AppGap.xs(),
        ],
      ],
    );
  }
}

/// `originTs` and the two state timestamps, rendered local.
///
/// A fixed `YYYY-MM-DD HH:MM:SS` rather than a locale format, and deliberately:
/// this is a support tool whose values are correlated against router logs and
/// against Guardian's own records, and a locale-shuffled date is one more thing
/// to reconcile by eye. The value is already local time — the service converts
/// on the way in.
String _formatTimestamp(DateTime at) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${at.year}-${two(at.month)}-${two(at.day)} '
      '${two(at.hour)}:${two(at.minute)}:${two(at.second)}';
}
