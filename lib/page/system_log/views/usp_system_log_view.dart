import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:privacy_gui/page/system_log/models/log_file_ui_model.dart';
import 'package:privacy_gui/page/system_log/providers/usp_system_log_notifier.dart';
import 'package:ui_kit_library/ui_kit.dart';

class UspSystemLogView extends ConsumerWidget {
  const UspSystemLogView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(uspSystemLogProvider);

    return UiKitPageView.withSliver(
      scrollable: true,
      title: loc(context).systemLogs,
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      backFallback: RouteNamed.uspMenu,
      onRefresh: () => ref.refresh(uspSystemLogProvider.future),
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: (childContext, constraints) {
        return asyncState.when(
          loading: () => const Center(child: AppLoader()),
          error: (error, stack) => _buildError(context, ref, error),
          data: (logFiles) => _buildContent(context, logFiles),
        );
      },
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon.font(Icons.error_outline,
              size: 48, color: Theme.of(context).colorScheme.error),
          AppGap.xl(),
          AppText.titleMedium(loc(context).failedToLoadSettings),
          AppGap.md(),
          AppText.bodyMedium(localizeServiceError(context, error)),
          AppGap.xxl(),
          AppButton(
            label: loc(context).retry,
            onTap: () => ref.invalidate(uspSystemLogProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<LogFileUIModel> logFiles) {
    if (logFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon.font(Icons.article_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            AppGap.xl(),
            AppText.bodyMedium(loc(context).noLogFilesAvailable),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (final logFile in logFiles) ...[
          _LogFileCard(logFile: logFile),
          AppGap.md(),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Log File Card
// ---------------------------------------------------------------------------

class _LogFileCard extends StatelessWidget {
  final LogFileUIModel logFile;

  const _LogFileCard({required this.logFile});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                size: 24,
                color: Theme.of(context).colorScheme.primary,
              ),
              AppGap.md(),
              Expanded(
                child: AppText.titleSmall(logFile.name),
              ),
            ],
          ),
          AppGap.md(),
          Row(
            children: [
              AppText.bodySmall(
                'Max Size: ${logFile.formattedSize}',
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              AppGap.lg(),
              _PersistentBadge(persistent: logFile.persistent),
              const Spacer(),
              AppButton.text(
                label: loc(context).export,
                icon: AppIcon.font(Icons.upload, size: 16),
                onTap: null, // Upload() requires destination URL
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Persistent Badge
// ---------------------------------------------------------------------------

class _PersistentBadge extends StatelessWidget {
  final bool persistent;

  const _PersistentBadge({required this.persistent});

  @override
  Widget build(BuildContext context) {
    final color = persistent
        ? Colors.green
        : Theme.of(context).colorScheme.onSurfaceVariant;
    final label = persistent ? 'Persistent' : 'Volatile';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: AppText.labelSmall(label, color: color),
    );
  }
}
