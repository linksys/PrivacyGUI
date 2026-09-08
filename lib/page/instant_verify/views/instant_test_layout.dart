import 'package:flutter/material.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';

/// The normal PrivacyGUI page width, or the wider troubleshooting workspace.
enum InstantTestContentWidth { standard, wide }

/// Owns horizontal page margins once, across home, workflows, and details.
/// Child scroll views retain their vertical padding and scroll ownership.
class InstantTestLayout extends StatelessWidget {
  const InstantTestLayout({
    super.key,
    required this.child,
    this.contentWidth = InstantTestContentWidth.standard,
  });

  final Widget child;
  final InstantTestContentWidth contentWidth;

  static const columnGap = Spacing.large2;

  static bool usesColumns(double availableWidth) =>
      availableWidth >= ResponsiveLayout.medium;

  static int actionColumns(double availableWidth) => usesColumns(availableWidth)
      ? 3
      : availableWidth >= 160 * 2 + Spacing.medium
          ? 2
          : 1;

  /// Standalone legacy views keep their own padding. Hosted views inherit the
  /// shared page margins, so nested scrolling never adds another side gutter.
  static EdgeInsets scrollPadding(BuildContext context) => EdgeInsets.symmetric(
        vertical: Spacing.medium,
        horizontal:
            context.dependOnInheritedWidgetOfExactType<_PageMargins>() == null
                ? Spacing.medium
                : 0,
      );

  static double _wideMargin(double availableWidth) {
    if (availableWidth <= ResponsiveLayout.small) return Spacing.medium;
    if (availableWidth <= ResponsiveLayout.medium) return Spacing.large3;
    if (availableWidth < ResponsiveLayout.large) return Spacing.large2;
    return availableWidth * 0.025;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => Padding(
          padding: EdgeInsets.symmetric(
            horizontal: contentWidth == InstantTestContentWidth.wide
                ? _wideMargin(constraints.maxWidth)
                : ResponsiveLayout.pageHorizontalPadding(context),
          ),
          child: _PageMargins(child: child),
        ),
      );
}

class _PageMargins extends InheritedWidget {
  const _PageMargins({required super.child});

  @override
  bool updateShouldNotify(_PageMargins oldWidget) => false;
}

/// One shared sidebar/content arrangement for diagnostic and device workflows.
/// Keep the same child structure while resizing so open details retain state.
class InstantTestColumns extends StatelessWidget {
  const InstantTestColumns({
    super.key,
    required this.sidebar,
    required this.content,
  });

  final Widget sidebar;
  final Widget content;

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = InstantTestLayout.usesColumns(width);
        final sidebarWidth = columns ? (width / 4).clamp(280.0, 352.0) : width;
        return Wrap(
          spacing: InstantTestLayout.columnGap,
          children: [
            SizedBox(width: sidebarWidth, child: sidebar),
            SizedBox(
              width: columns
                  ? width - sidebarWidth - InstantTestLayout.columnGap
                  : width,
              child: content,
            ),
          ],
        );
      });
}
