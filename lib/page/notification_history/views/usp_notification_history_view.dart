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
/// `usp/notifications/history` for the list, and one entry's `body` per row as that
/// row scrolls into view. All three work with the device offline, because the store
/// is the cloud's.
///
/// ## Why a sliver timeline
///
/// The list carries no bodies, and a row with no body is a type name and two UUIDs
/// — nothing a support engineer can scan. So each row reads its own body and shows
/// the part that matters (a path and its value, a command and whether it worked, an
/// event's name) inline; the UUIDs move to the dialog, where they are copied into a
/// ticket. A read per row is only affordable if rows that are never seen are never
/// built, which is what [AppSliverTimeline.builder] guarantees and a `Column` would
/// not: a first page of 25 costs the rows that fit on screen plus the sliver's
/// cache area, not 25. Only the three types that have a line to show read at all —
/// see [_summarisedTypes].
///
/// Rows that share a second share one heading. A subscription commonly lands ~28
/// notifies in the same second, and one stamp over the burst is what makes it read
/// as one thing.
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
      // Entered by a push from the Remote Assistance popup, which can be opened
      // over any page, so back normally pops to wherever that was. This is only
      // what a deep link or a refresh lands on, where there is no page the user
      // came from — so the hub, which is what the navigation invariants require
      // of every page (#1434: none may name the Dashboard).
      backFallback: RouteNamed.uspMenu,
      onRefresh: available
          ? () => ref.read(uspNotificationHistoryProvider.notifier).refresh()
          : null,
      // Slivers get no structural padding from the page (see
      // `UiKitPageView.slivers`), so the page margin is applied here.
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            context.layoutMargin,
            0,
            context.layoutMargin,
            AppSpacing.md,
          ),
          sliver: !available
              ? SliverToBoxAdapter(
                  child: Center(child: _Notice.unavailable(context)),
                )
              : ref.watch(uspNotificationHistoryProvider).when(
                    loading: () => const SliverToBoxAdapter(
                      child: Center(child: AppLoader()),
                    ),
                    error: (error, stack) => SliverToBoxAdapter(
                      child: ServiceErrorView(
                        error: error is ServiceError ? error : null,
                        title: loc(context).failedToLoadSettings,
                        onRetry: () =>
                            ref.invalidate(uspNotificationHistoryProvider),
                      ),
                    ),
                    data: (state) => _Content(state: state),
                  ),
        ),
      ],
    );
  }
}

/// An icon over one centred sentence — the page's two states that are not a list.
///
/// One widget for both, because they are the same shape and differ only in what
/// they say: the **unavailable** state (a local build has no notification store to
/// read) and the **empty** one (this session has produced nothing yet — the normal
/// state at session open, not a fault).
class _Notice extends StatelessWidget {
  final IconData icon;
  final String message;

  const _Notice({required this.icon, required this.message});

  /// The local answer: there is no notification store on the router to read.
  _Notice.unavailable(BuildContext context)
      : this(
          icon: Icons.cloud_off_outlined,
          message: loc(context).notificationHistoryUnavailable,
        );

  /// A fresh session: nothing produced yet.
  _Notice.empty(BuildContext context)
      : this(
          icon: Icons.notifications_none,
          message: loc(context).notificationHistoryEmpty,
        );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xxl,
        horizontal: AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon.font(
            icon,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          AppGap.xl(),
          AppText.bodyMedium(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

/// The loaded page, as one sliver: the header block, the timeline, Show more.
class _Content extends ConsumerWidget {
  final NotificationHistoryState state;

  const _Content({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = _timelineItems(context, state.visibleEntries);

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SessionStateCard(sessionState: state.sessionState),
              AppGap.md(),
              if (state.entries.isEmpty)
                Center(child: _Notice.empty(context))
              else ...[
                NotificationHistoryTypeFilter(state: state),
                AppGap.md(),
              ],
            ],
          ),
        ),
        if (items.isNotEmpty)
          AppSliverTimeline.builder(
            itemCount: items.length,
            itemBuilder: (context, index) => items[index],
            // The stamp is on the group heading above each burst; repeating it
            // on every entry is the noise the grouping exists to remove.
            showTimestamps: false,
          ),
        if (state.hasMore)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Center(
                child: AppButton.text(
                  label: loc(context).notificationHistoryShowMore,
                  identifier: 'notification-history-show-more',
                  onTap: () => ref
                      .read(uspNotificationHistoryProvider.notifier)
                      .showMore(),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The visible entries as timeline rows, a heading opening each distinct second.
///
/// Relies on the entries arriving sorted — `visibleEntries` is newest first — so a
/// burst is contiguous and one pass is enough. Grouped on the rendered stamp rather
/// than on the `DateTime`, because the stamp is what the heading shows: two entries
/// 400ms apart are one second on screen, and two headings reading the same would
/// be a bug a reader could see.
///
/// So a burst that straddles a second boundary — `.900` and the next second's `.200`
/// — is two headings, because it is two different stamps; one heading over both
/// would print a time one of them does not have.
///
/// Built as a list up front, not inside the builder, because a heading depends on
/// the entry before it. The list holds descriptions only — no widget is built and
/// nothing is fetched until the sliver asks for that index.
List<AppTimelineItem> _timelineItems(
  BuildContext context,
  List<NotificationHistoryEntryUIModel> entries,
) {
  final items = <AppTimelineItem>[];
  String? heading;
  for (final entry in entries) {
    final at = entry.originTs;
    final stamp = at == null ? _absentValue : _formatTimestamp(at);
    if (stamp != heading) {
      items.add(AppTimelineGroup(label: stamp));
      heading = stamp;
    }
    items.add(
      AppTimelineEntry(
        identifier: 'notification-history-row-${entry.msgId}',
        // The stored type, verbatim and untranslated. It is a protocol
        // identifier the spec and #205 both name in these exact words, and the
        // rest of this row — `msgId`, `commandKey`, the body's `param_path` —
        // is raw for the same reason. Translating one of them would make the
        // page inconsistent and the value un-greppable against the contract;
        // `Unknown` is itself a stored value rather than a UI fallback.
        title: entry.notificationType,
        detailWidget: _summarisedTypes.contains(entry.notificationType)
            ? _InlineSummary(msgId: entry.msgId)
            : null,
        onTap: () => _openDetail(context, entry),
      ),
    );
  }
  return items;
}

/// `lastBoot` and `lastUspActivity`, both of which are legitimately null.
class _SessionStateCard extends StatelessWidget {
  final SessionUspStateUIModel? sessionState;

  const _SessionStateCard({required this.sessionState});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LabelledValue(
            label: loc(context).notificationHistoryLastBoot,
            value: _format(context, sessionState?.lastBoot),
            emphasised: true,
          ),
          AppGap.sm(),
          _LabelledValue(
            label: loc(context).notificationHistoryLastActivity,
            value: _format(context, sessionState?.lastUspActivity),
            emphasised: true,
          ),
        ],
      ),
    );
  }

  String _format(BuildContext context, DateTime? at) =>
      at == null ? _absentValue : _formatTimestamp(at);
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
          : 'notification-history-type-${notificationTypeIdentifierKey(value)}',
      itemAsString: (value) => value == _all ? loc(context).all : value,
      onChanged: (value) => ref
          .read(uspNotificationHistoryProvider.notifier)
          .setTypeFilter(value == _all ? null : value),
    );
  }
}

/// The stored types whose body has one line worth showing under the type.
///
/// Every other row — `ObjectCreation`, `ObjectDeletion`, `OnBoardRequest`,
/// `Unknown` — is its type alone, and does not read its body until it is opened:
/// a read the row would not draw is a Guardian read spent on nothing, and a
/// "Loading…" under a type that is the whole row is a state with no answer behind
/// it. Keyed on the stored `notificationType`, spelled as stored, because that is
/// what the row has before its body arrives.
const _summarisedTypes = {'ValueChange', 'OperationComplete', 'Event'};

/// What a row shows under its type, read from the entry's body.
///
/// The read happens when the row is built, which in a sliver means when it comes
/// into view. The dialog watches the same family member, so opening a row that is
/// on screen reuses this read rather than making a second one.
///
/// One line of the body, not all of it: the whole body is the dialog's job, and an
/// `OperationComplete` can carry a table of output arguments.
class _InlineSummary extends ConsumerWidget {
  final String msgId;

  const _InlineSummary({required this.msgId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return ref.watch(notificationDetailProvider(msgId)).when(
          // Text rather than `AppSkeleton` or `AppLoader`: both animate forever,
          // and a row that is still loading must not be the one thing keeping
          // the page from settling.
          loading: () => AppText.bodySmall(loc(context).loading, color: muted),
          error: (error, stack) => AppText.bodySmall(
            _bodyErrorText(context, error),
            color: muted,
          ),
          data: (detail) => switch (detail.body) {
            ValueChangeBodyUIModel(:final paramPath, :final paramValue) =>
              _LabelledValue(label: paramPath, value: paramValue),
            // Decided by `refused`, never by `errorCode` — see
            // `OperationCompleteBodyUIModel.refused`.
            OperationCompleteBodyUIModel(:final commandName, :final refused) =>
              _LabelledValue(
                label: commandName,
                value: refused ? loc(context).failed : loc(context).success,
              ),
            EventBodyUIModel(:final eventName) => AppText.bodySmall(eventName),
            // A summarised type whose body did not parse as one: nothing a line
            // can summarise, so the type above is the whole row.
            RawBodyUIModel() => const SizedBox.shrink(),
          },
        );
  }
}

void _openDetail(
  BuildContext context,
  NotificationHistoryEntryUIModel entry,
) {
  showAppDialog<void>(
    context: context,
    builder: (ctx) => AppDialog(
      title: AppText.titleMedium(entry.notificationType),
      content: _DetailContent(entry: entry),
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

/// One entry in full: its two ids, then its body.
class _DetailContent extends ConsumerWidget {
  final NotificationHistoryEntryUIModel entry;

  const _DetailContent({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _LabelledValue(
          label: loc(context).notificationHistoryMessageId,
          value: entry.msgId,
        ),
        // Null on every row but `OperationComplete`, which is the common case
        // and not worth an empty line each time.
        if (entry.commandKey != null) ...[
          AppGap.xs(),
          _LabelledValue(
            label: loc(context).notificationHistoryCommandKey,
            value: entry.commandKey!,
          ),
        ],
        AppGap.md(),
        ref.watch(notificationDetailProvider(entry.msgId)).when(
              loading: () => const Center(child: AppLoader()),
              error: (error, stack) =>
                  AppText.bodyMedium(_bodyErrorText(context, error)),
              data: (detail) => _Body(body: detail.body),
            ),
      ],
    );
  }
}

/// What a failed body read says, in the row and in the dialog alike.
///
/// A 404 is the ordinary case of an entry that has aged out or was never this
/// session's — the spec deliberately does not distinguish them — so it gets its own
/// sentence. Anything else is a fault and reads as one, in words about this row:
/// not the page's "Failed to load settings", because a row is a notification and
/// this page has no settings. Pull-to-refresh re-reads it.
String _bodyErrorText(BuildContext context, Object error) =>
    error is ResourceNotFoundError
        ? loc(context).notificationHistoryGone
        : loc(context).notificationHistoryLoadFailed;

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
      // An em dash, not the "no longer available" sentence. That sentence answers a
      // **404** — the entry is gone or was never this session's — and an entry that
      // was served with no `body` member is a different thing: it is here, it just
      // carries nothing. Reusing the 404 copy would report a fault for a row the
      // server handed us intact. Same em-dash convention as the two null timestamps
      // at the top of the page.
      return isEmpty
          ? AppText.bodyMedium(_absentValue)
          // Selectable because the only useful thing to do with an unrecognised
          // body is copy it into the ticket. `AppText`'s own selectable mode
          // rather than a bare `SelectableText`, so it takes the theme's text
          // style (and its declared CJK / Arabic fallbacks) like every other
          // line on the page.
          : AppText.bodyMedium(pretty, selectable: true);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in rows) ...[
          _LabelledValue(label: row.$1, value: row.$2),
          AppGap.xs(),
        ],
      ],
    );
  }
}

/// A muted label beside its value, which is every row this page draws.
///
/// One widget rather than the near-copies #1580 first shipped — the session-state
/// lines, the message-id/command-key lines, the body's field rows, and now a row's
/// inline summary are the same `SizedBox` + `Wrap` + two `AppText`s, differing only
/// in the value's size and the gap.
///
/// **A `Wrap`, not a `Row`, and that is the load-bearing part.** A label and a value
/// that both grow with the locale overflow a 320px phone as a `Row` — the same defect
/// #1380 fixed across most of wave 4 — and reflow onto two runs as a `Wrap`. The
/// inline summary is the hardest case: a `param_path` has no spaces and can be
/// longer than a phone is wide, and a `Wrap` hands it the full width to break in.
class _LabelledValue extends StatelessWidget {
  final String label;
  final String value;

  /// Renders the value one step larger, for the two session-state lines at the top of
  /// the page. The field rows below are uniform and take the default.
  final bool emphasised;

  const _LabelledValue({
    required this.label,
    required this.value,
    this.emphasised = false,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: Wrap(
          spacing: emphasised ? AppSpacing.md : AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppText.bodySmall(
              label,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            emphasised ? AppText.bodyMedium(value) : AppText.bodySmall(value),
          ],
        ),
      );
}

/// What the page renders where a value is legitimately absent.
///
/// One spelling for the two places that need it — the null timestamps and a body with
/// no members — so "absent" cannot come to look like two different things.
const _absentValue = '—';

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
