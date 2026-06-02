import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks/status_blocks.dart';
import 'package:ui_kit_library/ui_kit.dart';

// =============================================================================
// IpAddressBlock - Prominent IP address display
// =============================================================================

class IpAddressBlock extends StatelessWidget {
  final String label;
  final String address;
  final String? subtitle;
  final bool copyable;

  const IpAddressBlock({
    super.key,
    required this.label,
    required this.address,
    this.subtitle,
    this.copyable = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Block(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          AppText.labelSmall(label, color: colorScheme.onSurfaceVariant),
          AppGap.xs(),
          if (copyable)
            _CopyableValue(value: address)
          else
            AppText.titleLarge(address),
          if (subtitle != null) ...[
            AppGap.xs(),
            AppText.bodySmall(subtitle!, color: colorScheme.onSurfaceVariant),
          ],
        ],
      ),
    );
  }
}

class _CopyableValue extends StatelessWidget {
  final String value;

  const _CopyableValue({required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied: $value'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      borderRadius: BorderRadius.circular(AppSpacing.xxs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppText.titleLarge(value),
          AppGap.sm(),
          AppIcon.font(Icons.copy, size: 16, color: colorScheme.primary),
        ],
      ),
    );
  }
}

// =============================================================================
// ProgressBlock - Usage/progress visualization
// =============================================================================

enum ProgressBlockSeverity { normal, warning, error }

class ProgressBlock extends StatelessWidget {
  final String title;
  final double value; // 0.0 to 1.0
  final String? subtitle;
  final ProgressBlockSeverity severity;

  const ProgressBlock({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.severity = ProgressBlockSeverity.normal,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorScheme>();

    final progressColor = switch (severity) {
      ProgressBlockSeverity.normal =>
        appColors?.semanticSuccess ?? colorScheme.primary,
      ProgressBlockSeverity.warning => Colors.orange,
      ProgressBlockSeverity.error => colorScheme.error,
    };

    final percentage = (value * 100).toInt();

    return Block(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.labelMedium(title),
              AppText.labelMedium('$percentage%', color: progressColor),
            ],
          ),
          AppGap.sm(),
          AppLoader(
            variant: LoaderVariant.linear,
            value: value.clamp(0.0, 1.0),
            color: progressColor,
          ),
          if (subtitle != null) ...[
            AppGap.sm(),
            AppText.bodySmall(subtitle!, color: colorScheme.onSurfaceVariant),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// QuotaBlock - X of Y visual indicator with dots
// =============================================================================

class QuotaBlock extends StatelessWidget {
  final int used;
  final int total;
  final String label;
  final Color? activeColor;

  const QuotaBlock({
    super.key,
    required this.used,
    required this.total,
    required this.label,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = activeColor ?? colorScheme.primary;

    return Block(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(total, (index) {
              final isFilled = index < used;
              return Container(
                width: 12,
                height: 12,
                margin: EdgeInsets.only(right: index < total - 1 ? 4 : 0),
                decoration: BoxDecoration(
                  color: isFilled ? color : colorScheme.surfaceContainer,
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
          AppGap.md(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.titleSmall('$used / $total'),
                AppText.bodySmall(label, color: colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// RangeBlock - Range visualization (start to end)
// =============================================================================

class RangeBlock extends StatelessWidget {
  final IconData? icon;
  final String? label;
  final String start;
  final String end;

  const RangeBlock({
    super.key,
    this.icon,
    this.label,
    required this.start,
    required this.end,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Block(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null || label != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  if (icon != null) ...[
                    AppIcon.font(icon!,
                        size: 18, color: colorScheme.onSurfaceVariant),
                    AppGap.sm(),
                  ],
                  if (label != null) AppText.labelMedium(label!),
                ],
              ),
            ),
          Row(
            children: [
              AppSurface(
                variant: SurfaceVariant.elevated,
                borderRadius: AppRadius.xs,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: AppText.labelMedium(start),
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 2,
                      margin:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                      color: colorScheme.primary,
                    ),
                    Positioned(
                      left: AppSpacing.xs,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      right: AppSpacing.xs,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AppSurface(
                variant: SurfaceVariant.elevated,
                borderRadius: AppRadius.xs,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: AppText.labelMedium(end),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
