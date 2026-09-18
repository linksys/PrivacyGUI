import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/notification_history/models/notification_history_ui_model.dart';

/// Everything the notification history page renders, in one value.
///
/// The whole retention window is in [entries] because the endpoint is
/// deliberately unpaged — Guardian serves the lot and expects the client to page
/// and filter. [visibleEntries] is what that produces; nothing here triggers a
/// read.
///
/// Read-only, so none of the `Preservable` / dirty-guard machinery applies: there
/// is nothing on this page a user can edit and therefore nothing to lose.
class NotificationHistoryState extends Equatable {
  /// How many rows a page shows before the viewer asks for more.
  ///
  /// A client-side number, not a server one. Guardian returns the whole window
  /// in a single response and #1580 forbids paging it over the wire.
  static const pageSize = 25;

  /// Guardian's per-device state, read once when the page opened.
  ///
  /// Its two timestamps therefore **freeze** for as long as the page is open.
  /// That is the decision #1580 asks to be made explicitly: a reconnect does not
  /// re-read them, because `lastBoot` moving is not something a support engineer
  /// is watching this page for, and re-reading on reconnect would put a read on
  /// an edge the spec's no-polling rule exists to keep quiet. The pull-to-refresh
  /// gesture re-reads history only.
  final SessionUspStateUIModel? sessionState;

  /// The whole window, newest first.
  final List<NotificationHistoryEntryUIModel> entries;

  /// The `notificationType` the viewer narrowed to, or null for all.
  final String? typeFilter;

  /// How many rows of the filtered list are shown.
  final int visibleCount;

  const NotificationHistoryState({
    this.sessionState,
    this.entries = const [],
    this.typeFilter,
    this.visibleCount = pageSize,
  });

  /// The filtered window, newest first.
  ///
  /// Sorted here rather than trusted from the response: newest-first is a server
  /// behaviour, and this page reads `originTs` for its own ordering so a change
  /// on that side cannot silently reverse the list.
  List<NotificationHistoryEntryUIModel> get filteredEntries {
    final rows = typeFilter == null
        ? [...entries]
        : entries.where((e) => e.notificationType == typeFilter).toList();
    rows.sort((a, b) => b.originTs.compareTo(a.originTs));
    return rows;
  }

  List<NotificationHistoryEntryUIModel> get visibleEntries {
    final rows = filteredEntries;
    return rows.length <= visibleCount ? rows : rows.sublist(0, visibleCount);
  }

  bool get hasMore => filteredEntries.length > visibleCount;

  /// The types actually present in the window, sorted for a stable dropdown.
  ///
  /// Built from the data rather than from a fixed list of the six USP variants,
  /// because `Unknown` is a real stored value and the cloud may store a seventh
  /// before this app knows about it. A filter offering a type with no rows is
  /// worse than one that only offers what is there.
  List<String> get availableTypes {
    final types = entries.map((e) => e.notificationType).toSet().toList();
    types.sort();
    return types;
  }

  NotificationHistoryState copyWith({
    SessionUspStateUIModel? sessionState,
    List<NotificationHistoryEntryUIModel>? entries,
    String? typeFilter,
    bool clearTypeFilter = false,
    int? visibleCount,
  }) =>
      NotificationHistoryState(
        sessionState: sessionState ?? this.sessionState,
        entries: entries ?? this.entries,
        typeFilter: clearTypeFilter ? null : (typeFilter ?? this.typeFilter),
        visibleCount: visibleCount ?? this.visibleCount,
      );

  @override
  List<Object?> get props => [sessionState, entries, typeFilter, visibleCount];
}
