import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/card_density_scope.dart';
import 'package:privacy_gui/page/_shared/components/card_popup_form.dart';
import 'package:privacy_gui/page/dashboard/models/card_density.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// A section within a multi-section dashboard card.
///
/// Used with [DashboardCardTemplate.multiSection] for cards that have
/// multiple independent content areas (e.g., DHCP Reservations + Active Leases).
class CardSection {
  const CardSection({
    required this.title,
    this.titleBadge,
    this.trailing,
    required this.content,
    this.emptyMessage,
    this.isEmpty = false,
  });

  /// Section title.
  final String title;

  /// Optional badge next to the title (e.g., count).
  final Widget? titleBadge;

  /// Optional trailing widget (e.g., action buttons).
  final Widget? trailing;

  /// Section content.
  final Widget content;

  /// Message to show when section is empty.
  final String? emptyMessage;

  /// Whether this section has no content.
  final bool isEmpty;
}

/// A tab definition for tabbed dashboard cards.
///
/// Used with [DashboardCardTemplate.tabbed] for cards with tab navigation.
class CardTab {
  const CardTab({
    required this.label,
    required this.content,
    this.scrollable = false,
  });

  /// Tab label displayed in the tab bar.
  final String label;

  /// Tab content widget.
  final Widget content;

  /// Whether [content] scrolls when it is taller than the card (#1267).
  ///
  /// Per tab, not per card, because the property that decides it is per tab:
  /// content can only scroll if it shrink-wraps, and a tab that fills the card
  /// with a vertical `Expanded` cannot (see [_ScrollableCardContent]). Within one
  /// card, `wifi_performance`'s Channels tab shrink-wraps while its Signal and
  /// Speed tabs still hand a `ListView` and a bar chart the whole box — a
  /// card-level flag would have forced all three to convert together, or none.
  final bool scrollable;
}

/// Standardized dashboard card template with fixed header, flexible body,
/// and fixed footer that fills bottom space to prevent "top-heavy" appearance.
///
/// Supports three modes:
/// - **Single content**: Standard card with one content area
/// - **Multi-section**: Card with multiple titled sections separated by dividers
/// - **Tabbed**: Card with tab navigation between views
///
/// Layout: Fixed header + scrollable content + fixed footer.
/// Footer is always present (aggressive strategy) — shows "View details" link
/// when [detailRoute] is provided, or a subtle divider as placeholder.
class DashboardCardTemplate extends StatelessWidget {
  /// Creates a standard single-content dashboard card.
  const DashboardCardTemplate({
    super.key,
    // Header
    this.leading,
    required this.title,
    this.titleBadge,
    this.trailing,
    // Content
    required Widget content,
    this.scrollable = true,
    this.scrollPhysics,
    this.contentPadding,
    // Degraded form
    this.popupValue,
    // Footer
    this.footer,
    this.detailRoute,
    this.itemCount,
    this.detailLabel,
  })  : _content = content,
        _sections = null,
        _tabs = null,
        _selectedTabIndex = null,
        _onTabChanged = null,
        _tabDisplayMode = null;

  /// Creates a multi-section dashboard card.
  ///
  /// Use this for composite cards like DHCP (Reservations + Clients) or
  /// Port Forwarding (Forwarding Rules + Triggering Rules).
  const DashboardCardTemplate.multiSection({
    super.key,
    // Header
    this.leading,
    required this.title,
    this.titleBadge,
    this.trailing,
    // Sections
    required List<CardSection> sections,
    this.scrollable = true,
    this.scrollPhysics,
    this.contentPadding,
    // Degraded form
    this.popupValue,
    // Footer
    this.footer,
    this.detailRoute,
    this.itemCount,
    this.detailLabel,
  })  : _content = null,
        _sections = sections,
        _tabs = null,
        _selectedTabIndex = null,
        _onTabChanged = null,
        _tabDisplayMode = null;

  /// Creates a tabbed dashboard card with tab navigation.
  ///
  /// Use this for cards like System Status, Device Analytics, Traffic Analysis
  /// that have multiple views accessible via tabs.
  const DashboardCardTemplate.tabbed({
    super.key,
    // Header
    this.leading,
    required this.title,
    this.titleBadge,
    this.trailing,
    // Tabs
    required List<CardTab> tabs,
    required int selectedTabIndex,
    required ValueChanged<int> onTabChanged,
    TabDisplayMode tabDisplayMode = TabDisplayMode.segmented,
    // In tabbed mode this is an "all tabs" shortcut; the per-tab
    // [CardTab.scrollable] is the finer grain and the one #1267 uses, because
    // whether content *can* scroll is a property of the tab, not the card.
    this.scrollable = false,
    this.scrollPhysics,
    this.contentPadding,
    // Degraded form
    this.popupValue,
    // Footer
    this.footer,
    this.detailRoute,
    this.itemCount,
    this.detailLabel,
  })  : _content = null,
        _sections = null,
        _tabs = tabs,
        _selectedTabIndex = selectedTabIndex,
        _onTabChanged = onTabChanged,
        _tabDisplayMode = tabDisplayMode;

  /// Optional leading widget (icon or status indicator) before the title.
  final Widget? leading;

  /// Card title (required).
  final String title;

  /// Optional badge widget displayed next to the title (e.g., count badge).
  final Widget? titleBadge;

  /// Optional trailing widget(s) in the header (e.g., action buttons, menu).
  final Widget? trailing;

  /// Main card content (for single-content mode).
  final Widget? _content;

  /// Sections (for multi-section mode).
  final List<CardSection>? _sections;

  /// Tabs (for tabbed mode).
  final List<CardTab>? _tabs;

  /// Selected tab index (for tabbed mode).
  final int? _selectedTabIndex;

  /// Tab change callback (for tabbed mode).
  final ValueChanged<int>? _onTabChanged;

  /// Tab display mode (for tabbed mode).
  final TabDisplayMode? _tabDisplayMode;

  /// Whether content should be scrollable. Defaults to true.
  /// Set to false for visualization cards (e.g., Topology) that need full space.
  final bool scrollable;

  /// Custom scroll physics. Defaults to [ClampingScrollPhysics].
  final ScrollPhysics? scrollPhysics;

  /// Optional padding override for the content area.
  final EdgeInsets? contentPadding;

  /// The one value this card shows when it is too narrow for its full form.
  ///
  /// Below [kPopupBelow] the card renders [leading] over this string and nothing
  /// else (#1239). Which value that is, is the card's own judgement — the
  /// template knows the card's title and icon but not which of its numbers is
  /// the one worth seeing at a glance — so it is declared here rather than
  /// guessed from the content.
  ///
  /// Only reached by a card that declares a `normalAbove` on its `WidgetSpec`;
  /// with none declared the card is never below its own threshold, so leaving
  /// this out is correct for every card that fits. Left out by a card that
  /// *does* degrade, the title stands in.
  final String? popupValue;

  /// Custom footer widget. Takes precedence over [detailRoute].
  final Widget? footer;

  /// Route name for "View details" navigation link.
  /// When provided without [footer], displays a default "View details →" link.
  final String? detailRoute;

  /// Item count to display in footer (e.g., "5 items · View all →").
  /// Only used when [detailRoute] is also provided.
  final int? itemCount;

  /// Custom label for the detail link. Defaults to "View details" or
  /// "View all" when [itemCount] is provided.
  final String? detailLabel;

  bool get _isMultiSection => _sections != null;
  bool get _isTabbed => _tabs != null;

  @override
  Widget build(BuildContext context) {
    // Below the popup threshold the card stops arranging its content and shows
    // one value instead (#1239). Decided here rather than in each card because
    // the header — the icon and title the degraded form is built from — is the
    // template's, and every card goes through it, so no card can miss the
    // behaviour or implement it differently.
    if (CardDensityScope.of(context) == CardDensity.popup) {
      return CardPopupForm(
        title: title,
        leading: leading,
        value: popupValue,
        // `this` is the card's full form: the same widget, rendered under a
        // normal-density scope, is what the tap opens. Nothing is rebuilt or
        // re-specified, so the two forms cannot drift apart.
        normalForm: this,
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Fixed header
          _buildHeader(context),
          if (_isTabbed) ...[
            AppGap.md(),
            _buildTabBar(context),
          ],
          AppGap.lg(),
          // Scrollable content area
          Expanded(
            child: _buildScrollableContent(context),
          ),
          // Fixed footer (always present - aggressive strategy)
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    // LayoutBuilder so the trailing cap below is a fraction of the row rather
    // than a magic pixel width.
    return LayoutBuilder(
      builder: (context, constraints) => Row(
        children: [
          if (leading != null) ...[
            leading!,
            AppGap.sm(),
          ],
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: AppText.titleMedium(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (titleBadge != null) ...[
                  AppGap.sm(),
                  titleBadge!,
                ],
              ],
            ),
          ),
          if (trailing != null) _boundTrailing(trailing!, constraints.maxWidth),
        ],
      ),
    );
  }

  /// Bounds a header's trailing widget to half of the header row.
  ///
  /// The trailing stays *inflexible*, so it keeps its intrinsic width, stays
  /// flush right, and leaves every unneeded pixel to the `Expanded` title —
  /// making it `Flexible` instead would split the row 50/50 with the title and
  /// strand the trailing's unused share between the two. The cap only binds
  /// when a trailing is genuinely oversized: nearly every one is a ~40px icon
  /// button, and the one text button (network_status' renew-lease) was the sole
  /// cause of this row's overflow at the narrowest grid width (#1227).
  /// `AppButton` already ellipsizes its own label once bounded.
  Widget _boundTrailing(Widget trailing, double rowWidth) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: rowWidth / 2),
      child: trailing,
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final tabs = _tabs!;
    return AppTabs(
      tabs: tabs.map((t) => TabItem(label: t.label)).toList(),
      initialIndex: _selectedTabIndex!,
      displayMode: _tabDisplayMode ?? TabDisplayMode.segmented,
      isScrollable: true,
      showBorder: false,
      onTabChanged: _onTabChanged,
    );
  }

  Widget _buildScrollableContent(BuildContext context) {
    final Widget bodyContent;
    // Tabbed content fills the card by design — its charts, donuts and lists sit
    // in `Expanded`, which asserts under the unbounded height a
    // `SingleChildScrollView` hands its child. That is why tabbed mode shipped
    // with `scrollable: false` and why its content had nowhere to go: the card's
    // height is fixed by the grid, so anything taller was painted outside the
    // box — over the text above it, since a `Center`ed child spills in *both*
    // directions (#1267, measured on the tri-band profile at the 261px card).
    //
    // So a tab scrolls when *it* says it shrink-wraps, independently of its
    // neighbours in the same card.
    bool shouldScroll = scrollable;

    if (_isTabbed) {
      final tab = _tabs![_selectedTabIndex!];
      bodyContent = tab.content;
      shouldScroll = shouldScroll || tab.scrollable;
    } else if (_isMultiSection) {
      bodyContent = _buildMultiSectionContent(context);
    } else {
      bodyContent = contentPadding != null
          ? Padding(padding: contentPadding!, child: _content!)
          : _content!;
    }

    // Return content directly if scrollable is false (e.g., Topology)
    if (!shouldScroll) {
      return bodyContent;
    }

    // [_ScrollableCardContent] takes the fill-viewport route for tabbed content,
    // so a tab that used to overflow scrolls instead and nothing paints on top of
    // anything.
    return _ScrollableCardContent(
      physics: scrollPhysics,
      fillViewport: _isTabbed,
      child: bodyContent,
    );
  }

  Widget _buildMultiSectionContent(BuildContext context) {
    final sections = _sections!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < sections.length; i++) ...[
          if (i > 0) ...[
            AppGap.lg(),
            const Divider(),
            AppGap.md(),
          ],
          _buildSectionHeader(context, sections[i]),
          AppGap.md(),
          if (sections[i].isEmpty && sections[i].emptyMessage != null)
            AppText.bodyMedium(sections[i].emptyMessage!)
          else
            sections[i].content,
        ],
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, CardSection section) {
    return LayoutBuilder(
      builder: (context, constraints) => Row(
        children: [
          Expanded(
            child: Row(
              children: [
                // Same treatment the card title gets above: the section title
                // is the part that yields, so the badge beside it stays whole.
                Flexible(
                  child: AppText.titleSmall(
                    section.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (section.titleBadge != null) ...[
                  AppGap.sm(),
                  section.titleBadge!,
                ],
              ],
            ),
          ),
          // `trailing` is caller-supplied and can be a text button here too, so
          // it gets the same cap as the card header's.
          if (section.trailing != null)
            _boundTrailing(section.trailing!, constraints.maxWidth),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    if (footer != null) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: footer,
      );
    }

    if (detailRoute != null) {
      return _buildDetailFooter(context);
    }

    // Aggressive strategy: always show placeholder footer
    return _buildPlaceholderFooter(context);
  }

  Widget _buildDetailFooter(BuildContext context) {
    final label = detailLabel ??
        (itemCount != null ? loc(context).viewAll : loc(context).viewDetails);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppDivider(),
          AppGap.md(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (itemCount != null) ...[
                AppText.labelSmall(
                  loc(context).nItems(itemCount!),
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                AppGap.sm(),
                AppText.labelSmall(
                  '·',
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                AppGap.sm(),
              ],
              // Only the link is Flexible, and deliberately so: it is the last
              // child of an end-aligned row, so it absorbs whatever the item
              // count and the separators leave behind and nothing overflows —
              // while a row that already fits is laid out exactly as before.
              // Making both children Flexible would instead hand each a fixed
              // half of the free space and clip them at widths where the whole
              // row still fits (#1227).
              Flexible(
                child: Semantics(
                  button: true,
                  label: label,
                  child: InkWell(
                    onTap: () => context.pushNamed(detailRoute!),
                    borderRadius: BorderRadius.circular(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // The arrow keeps its 14px; the label is what shortens.
                        Flexible(
                          child: AppText.labelMedium(
                            label,
                            color: Theme.of(context).colorScheme.primary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        AppGap.xs(),
                        Icon(
                          Icons.arrow_forward,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppDivider(),
          AppGap.md(),
          // Empty row to match detail footer height
          SizedBox(
            height: 20, // Matches labelMedium line height
          ),
        ],
      ),
    );
  }
}

/// The card's scrolling content region, and the affordance that says so (#1267).
///
/// ## Why the region scrolls at all
///
/// A dashboard card's height is fixed by the grid, so "the content is taller than
/// the card" is a state every card can reach — a longer locale, a third radio, one
/// more port. Single-content and multi-section cards have always scrolled in that
/// state ([DashboardCardTemplate.scrollable] defaults to `true`); tabbed cards did
/// not, and paid for it by painting outside their box: at the 261px card in `tr`,
/// on a tri-band router, the Channels donut was drawn over the radio block above
/// it and bled 9px out of the bottom (#1267, and a `Center`ed child spills in both
/// directions, which is why the text above was the casualty). A user who would
/// rather not scroll can enlarge the card — the grid already allows that, and it
/// is a choice, where painting over text is not.
///
/// ## Why `Expanded` fills and scrolling are mutually exclusive
///
/// [fillViewport] gives the content the viewport height as a **floor** so a
/// shrink-wrapping `Column` still fills the card as it used to, instead of
/// collapsing to its children. What it cannot do is keep a vertical `Expanded`
/// working: flex needs a bounded height to divide, and a scroll view's is
/// unbounded by definition. There is no third option —
/// `SliverFillRemaining(hasScrollBody: false)` looks like one (tight
/// `max(viewport, intrinsic)` height), and it was tried and reverted: it queries
/// `getMaxIntrinsicHeight`, which throws through the `LayoutBuilder`s that
/// `LayoutBlock`, the charts and `CardDensityHost` are built from. 784 gate cases
/// failed on that assertion, measured, not guessed.
///
/// So a tab opts in **after** its content is given real heights — which is why
/// [CardTab.scrollable] is per tab. `wifi_performance`'s Channels tab is
/// converted (#1267). Its Signal and Speed tabs, and every tab of
/// `firewall_overview`, `network_health`, `device_analytics`, `system_status` and
/// `traffic_analysis`, still hand a list or a chart the whole box with `Expanded`
/// and stay opted out. Each needs an explicit height decided by measurement
/// rather than a mechanical edit, and that is tracked separately.
///
/// ## The affordance
///
/// A card that scrolls with no sign of it is the "clean but unreadable" failure
/// this epic keeps meeting: nothing looks broken, so nobody knows to look.
/// `Scrollbar` with `thumbVisibility` is that sign, and it costs nothing on cards
/// that fit: `thumbVisibility` pins the fade-out animation open, but
/// `ScrollbarPainter.paint` still returns early unless
/// `maxScrollExtent - minScrollExtent > precisionErrorTolerance`, so no thumb is
/// painted while the content fits. It is the framework's scrollbar rather than a
/// hand-rolled fade edge because `ui_kit_library` exports no scroll-affordance
/// component (Article XIV — searched: `AppTooltip` is the only near neighbour, and
/// ui_kit uses the raw `Scrollbar` internally too). A gradient edge is a component
/// to propose upstream, not to invent here.
class _ScrollableCardContent extends StatefulWidget {
  const _ScrollableCardContent({
    required this.child,
    required this.fillViewport,
    this.physics,
  });

  final Widget child;

  /// Whether the content gets the viewport's height as a minimum. See the class
  /// doc: tab content is written to fill the card, and would otherwise collapse
  /// to its children's height the moment it became scrollable.
  final bool fillViewport;

  final ScrollPhysics? physics;

  @override
  State<_ScrollableCardContent> createState() => _ScrollableCardContentState();
}

class _ScrollableCardContentState extends State<_ScrollableCardContent> {
  // Owned here rather than passed in: the scrollbar and the scroll view must
  // share one controller, and the template is a StatelessWidget with no place to
  // dispose one.
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final physics = widget.physics ?? const ClampingScrollPhysics();

    Widget scrollView(Widget child) => SingleChildScrollView(
          controller: _controller,
          physics: physics,
          child: child,
        );

    return Scrollbar(
      controller: _controller,
      thumbVisibility: true,
      child: widget.fillViewport
          // `maxHeight` is left unbounded on purpose: the floor is what keeps a
          // fitting layout identical to the fixed box it replaces, and the
          // absence of a ceiling is what lets the content grow instead of
          // overflowing.
          ? LayoutBuilder(
              builder: (context, constraints) => scrollView(
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: widget.child,
                ),
              ),
            )
          : scrollView(widget.child),
    );
  }
}
