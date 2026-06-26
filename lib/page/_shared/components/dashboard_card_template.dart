import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
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
  });

  /// Tab label displayed in the tab bar.
  final String label;

  /// Tab content widget.
  final Widget content;
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
    this.scrollable = false,
    this.scrollPhysics,
    this.contentPadding,
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
    return Row(
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
        if (trailing != null) trailing!,
      ],
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

    if (_isTabbed) {
      // Tab content - don't wrap in scroll (charts need fixed space)
      return _tabs![_selectedTabIndex!].content;
    } else if (_isMultiSection) {
      bodyContent = _buildMultiSectionContent(context);
    } else {
      bodyContent = contentPadding != null
          ? Padding(padding: contentPadding!, child: _content!)
          : _content!;
    }

    // Return content directly if scrollable is false (e.g., Topology)
    if (!scrollable) {
      return bodyContent;
    }

    return SingleChildScrollView(
      physics: scrollPhysics ?? const ClampingScrollPhysics(),
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
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              AppText.titleSmall(section.title),
              if (section.titleBadge != null) ...[
                AppGap.sm(),
                section.titleBadge!,
              ],
            ],
          ),
        ),
        if (section.trailing != null) section.trailing!,
      ],
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
              Semantics(
                button: true,
                label: label,
                child: InkWell(
                  onTap: () => context.pushNamed(detailRoute!),
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText.labelMedium(
                        label,
                        color: Theme.of(context).colorScheme.primary,
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
