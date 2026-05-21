import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      title: 'Choose Specific Issue',
      description:
          'Experiencing a specific problem? Select from common scenarios.',
      onTap: notifier.startWithPreQualifier,
    );
    final manualTools = _SecondaryAction(
      icon: Icons.terminal,
      iconTint: _SecondaryTint.tertiary,
      title: 'Manual Tools',
      description: 'Run ping, traceroute, or NS lookup against any host.',
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: AppCard(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Row(
              children: [
                Icon(Icons.rocket_launch, size: 40, color: colorScheme.primary),
                AppGap.xl(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.titleLarge('Run Full Diagnostic'),
                      AppGap.xs(),
                      AppText.bodySmall(
                        'Automatically check every component of your network '
                        'to find and fix issues.',
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
                AppGap.lg(),
                AppButton(label: 'Start Now', onTap: onTap),
              ],
            ),
          ),
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

    return AppCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
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
          child: AppText.bodySmall('OR', color: colorScheme.onSurfaceVariant),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
