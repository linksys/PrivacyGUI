import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../providers/unified_diagnostics_notifier.dart';

class DiagnosticStartView extends ConsumerWidget {
  const DiagnosticStartView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(unifiedDiagnosticsProvider.notifier);

    final primary = _PrimaryAction(onTap: notifier.runFullDiagnostic);
    final chooseIssue = _SecondaryAction(
      icon: Icons.search,
      iconTint: _SecondaryTint.secondary,
      title: loc(context).chooseSpecificIssue,
      description: loc(context).chooseSpecificIssueDesc,
      onTap: notifier.startWithPreQualifier,
    );
    final manualTools = _SecondaryAction(
      icon: Icons.terminal,
      iconTint: _SecondaryTint.tertiary,
      title: loc(context).manualTools,
      description: loc(context).manualToolsDesc,
      onTap: notifier.openManualTools,
    );

    return AppResponsiveLayout(
      mobile: (_) => _MobileLayout(
        primary: primary,
        chooseIssue: chooseIssue,
        manualTools: manualTools,
      ),
      desktop: (_) => _DesktopLayout(
        primary: primary,
        chooseIssue: chooseIssue,
        manualTools: manualTools,
      ),
    );
  }
}

class _MobileLayout extends StatelessWidget {
  final Widget primary;
  final Widget chooseIssue;
  final Widget manualTools;

  const _MobileLayout({
    required this.primary,
    required this.chooseIssue,
    required this.manualTools,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        primary,
        AppGap.xl(),
        const _OrDivider(),
        AppGap.xl(),
        chooseIssue,
        AppGap.lg(),
        manualTools,
        AppGap.xxl(),
      ],
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  final Widget primary;
  final Widget chooseIssue;
  final Widget manualTools;

  const _DesktopLayout({
    required this.primary,
    required this.chooseIssue,
    required this.manualTools,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        primary,
        AppGap.xl(),
        const _OrDivider(),
        AppGap.xl(),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: chooseIssue),
              AppGap.gutter(),
              Expanded(child: manualTools),
            ],
          ),
        ),
        AppGap.xxl(),
      ],
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  final VoidCallback onTap;

  const _PrimaryAction({required this.onTap});

  /// Card-content width below which the action button moves under the text.
  ///
  /// The row is icon (40px), text, and a button whose width is a localized label
  /// plus padding. The text is `Expanded`, so it yields all of its width before the
  /// row overflows — and then the two fixed children still do not fit: at 320px the
  /// card grants ~256px and `fr` needed 74px more (#1380, 9 of 234 cells).
  ///
  /// Constraining the button instead of moving it is the wrong trade here. Its label
  /// is already `Flexible` with `TextOverflow.ellipsis` inside ui_kit, so a
  /// `Flexible` on the outside buys a green sweep and an ellipsized call to action —
  /// "Commencer maintenant" as "Comm…" — which is a defect the sweep cannot see.
  ///
  /// 360 rather than the 600px mobile breakpoint so that only the widths that
  /// actually overflow reflow: the card grants ~256px at a 320px screen and ~416px
  /// at 480px, and 480px was clean in all 26 locales. The gate pins both halves of
  /// that claim — see `test/page/_shared/page_surface_overflow_test.dart`.
  static const _reflowBelow = 360.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: loc(context).runFullDiagnostic,
      child: AppCard(
        isSelected: true,
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final icon =
                Icon(Icons.rocket_launch, size: 40, color: colorScheme.primary);
            final text = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.titleLarge(loc(context).runFullDiagnostic),
                AppGap.xs(),
                AppText.bodySmall(
                  loc(context).runFullDiagnosticDesc,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            );
            final button =
                AppButton(label: loc(context).startNow, onTap: onTap);

            if (constraints.maxWidth < _reflowBelow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [icon, AppGap.xl(), Expanded(child: text)],
                  ),
                  AppGap.lg(),
                  SizedBox(width: double.infinity, child: button),
                ],
              );
            }

            return Row(
              children: [
                icon,
                AppGap.xl(),
                Expanded(child: text),
                AppGap.lg(),
                button,
              ],
            );
          },
        ),
      ),
    );
  }
}

enum _SecondaryTint { secondary, tertiary }

class _SecondaryAction extends StatelessWidget {
  final IconData icon;
  final _SecondaryTint iconTint;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _SecondaryAction({
    required this.icon,
    required this.iconTint,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tint = iconTint == _SecondaryTint.secondary
        ? colorScheme.secondary
        : colorScheme.tertiary;

    return Semantics(
      button: true,
      label: title,
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: tint),
            ),
            AppGap.lg(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.titleMedium(title),
                  AppGap.xs(),
                  AppText.bodySmall(
                    description,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: AppText.bodySmall(loc(context).or,
              color: colorScheme.onSurfaceVariant),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
