import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/components/views/service_error_view.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
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
          error: (error, stack) => ServiceErrorView(
            error: error is ServiceError ? error : null,
            title: loc(context).failedToLoadSettings,
            onRetry: () => ref.invalidate(uspSystemLogProvider),
          ),
          data: (logFiles) => _buildContent(context, logFiles),
        );
      },
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
          // A `Wrap` around two groups, not a `Row` of four children with a
          // `Spacer` between them — the same fix and the same idiom as
          // `instant_privacy_view.dart:172` and `usp_apps_view.dart:90`, and this
          // was the worst instance of the three: the metadata, the badge and the
          // export button overflowed a 320px phone in **all 26 locales**, by +20.0px
          // (`fi`) to +85.0px (`ja`), on both log cards (#1380). A `Spacer` takes the
          // free space when there is some and contributes nothing when there is not,
          // so the row simply ran off the edge.
          //
          // Grouped rather than flattened into three `Wrap` children on purpose. The
          // size and the badge belong together at the left and the action belongs at
          // the right; three children under `spaceBetween` would park the badge in
          // the middle of every wide row, which is a visual change this fix has no
          // reason to make. Two children reproduce the `Spacer` exactly — child 0
          // left, child 1 right — so every width from 480px up is pixel-identical to
          // what shipped, and only 320px reflows, where the button drops onto its own
          // run.
          //
          // `MainAxisSize.min` on the inner `Row` is load-bearing: a `Wrap` offers its
          // children unbounded main-axis space, and a `max` row would try to fill it.
          // Both directions are guarded in
          // test/page/_shared/page_surface_overflow_test.dart.
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText.bodySmall(
                      'Max Size: ${logFile.formattedSize}',
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    AppGap.lg(),
                    _PersistentBadge(persistent: logFile.persistent),
                  ],
                ),
                AppButton.text(
                  label: loc(context).export,
                  icon: AppIcon.font(Icons.upload, size: 16),
                  onTap: null, // Upload() requires destination URL
                ),
              ],
            ),
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
        // The kit's container-tint alpha, which it only spells for the disabled
        // case — this badge is never disabled, it just wants the same 0.12 rather
        // than a fourth copy of it.
        color: color.withValues(alpha: AppStateTokens.disabledContainerAlpha),
        borderRadius: BorderRadius.circular(4),
      ),
      child: AppText.labelSmall(label, color: color),
    );
  }
}
