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

/// Workflows read top to bottom in one centered column: answered steps sit
/// above the current one, so the next action is always in the same place
/// (QA 2026-10-07 #2, "keep fixed focus"). The same structure is used at every
/// width, so open details retain state while resizing.
class InstantTestFocusColumn extends StatelessWidget {
  const InstantTestFocusColumn({super.key, required this.children});

  /// Readable line length for questions and advice.
  static const maxWidth = 760.0;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      );
}
