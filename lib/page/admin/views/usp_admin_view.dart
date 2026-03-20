import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/admin/providers/usp_admin_notifier.dart';
import 'package:privacy_gui/page/admin/providers/usp_admin_state.dart';
import 'package:privacy_gui/page/admin/views/components/usp_password_card.dart';
import 'package:privacy_gui/page/admin/views/components/usp_system_actions_card.dart';
import 'package:privacy_gui/page/admin/views/components/usp_timezone_card.dart';
import 'package:privacy_gui/page/admin/views/dialogs/change_password_dialog.dart';
import 'package:privacy_gui/page/admin/views/dialogs/confirm_action_dialog.dart';
import 'package:privacy_gui/page/admin/views/dialogs/timezone_edit_dialog.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:ui_kit_library/ui_kit.dart';

class UspAdminView extends ConsumerWidget {
  const UspAdminView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(uspAdminProvider);

    return UiKitPageView.withSliver(
      scrollable: true,
      title: 'Administration',
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      onBackTap: () => context.canPop()
          ? context.pop()
          : context.goNamed(RouteNamed.uspMenu),
      onRefresh: () => ref.refresh(uspAdminProvider.future),
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: (childContext, constraints) {
        return asyncState.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xxxl),
              child: AppLoader(),
            ),
          ),
          error: (error, stack) => _buildError(childContext, ref, error),
          data: (state) => _buildContent(childContext, ref, state),
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
          AppText.titleMedium('Unable to load admin data'),
          AppGap.md(),
          AppText.bodyMedium(error.toString()),
          AppGap.xxl(),
          AppButton(
            label: 'Retry',
            onTap: () => ref.invalidate(uspAdminProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, UspAdminState state) {
    return AppResponsiveLayout(
      mobile: (ctx) => _buildMobileLayout(ctx, ref, state),
      desktop: (ctx) => _buildDesktopLayout(ctx, ref, state),
    );
  }

  // ---------------------------------------------------------------------------
  // Mobile: single column
  // ---------------------------------------------------------------------------

  Widget _buildMobileLayout(
      BuildContext context, WidgetRef ref, UspAdminState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UspTimezoneCard(
          timeSettings: state.timeSettings,
          onEdit: () => _editTimezone(context, ref, state),
        ),
        AppGap.xl(),
        UspPasswordCard(
          adminUser: state.adminUser,
          onChangePassword: () => _changePassword(context, ref),
        ),
        AppGap.xl(),
        UspSystemActionsCard(
          onReboot: () => _reboot(context, ref),
          onFactoryReset: () => _factoryReset(context, ref),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Desktop: two columns
  // ---------------------------------------------------------------------------

  Widget _buildDesktopLayout(
      BuildContext context, WidgetRef ref, UspAdminState state) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column
        SizedBox(
          width: context.colWidth(6),
          child: Column(
            children: [
              UspTimezoneCard(
                timeSettings: state.timeSettings,
                onEdit: () => _editTimezone(context, ref, state),
              ),
              AppGap.xl(),
              UspSystemActionsCard(
                onReboot: () => _reboot(context, ref),
                onFactoryReset: () => _factoryReset(context, ref),
              ),
            ],
          ),
        ),
        AppGap.gutter(),
        // Right column
        SizedBox(
          width: context.colWidth(6),
          child: Column(
            children: [
              UspPasswordCard(
                adminUser: state.adminUser,
                onChangePassword: () => _changePassword(context, ref),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _editTimezone(
      BuildContext context, WidgetRef ref, UspAdminState state) async {
    final result = await showTimezoneEditDialog(
      context,
      current: state.timeSettings,
    );
    if (result == null || !context.mounted) return;
    try {
      await ref.read(uspAdminProvider.notifier).updateTimezone(
            localTimeZone: result.localTimeZone,
            ntpServer1: result.ntpServer1,
            ntpServer2: result.ntpServer2,
          );
      if (context.mounted) showSuccessSnackBar(context, 'Timezone updated');
    } catch (e) {
      if (context.mounted) {
        showFailedSnackBar(context, 'Failed to update timezone');
      }
    }
  }

  Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
    final result = await showChangePasswordDialog(
      context,
      onSave: (newPassword) async {
        await ref.read(uspAdminProvider.notifier).setAdminPassword(newPassword);
      },
    );
    if (result == true && context.mounted) {
      showSuccessSnackBar(context, 'Password updated');
    }
  }

  Future<void> _reboot(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmActionDialog(
      context,
      title: 'Reboot Router',
      message:
          'The router will restart. All connected devices will be temporarily disconnected.',
      confirmLabel: 'Reboot',
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(uspAdminProvider.notifier).reboot();
      if (context.mounted) showSuccessSnackBar(context, 'Reboot command sent');
    } catch (e) {
      if (context.mounted) showFailedSnackBar(context, 'Reboot failed');
    }
  }

  Future<void> _factoryReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmActionDialog(
      context,
      title: 'Factory Reset',
      message:
          'This will erase all settings and restore the router to factory defaults. This action cannot be undone.',
      confirmLabel: 'Reset',
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(uspAdminProvider.notifier).factoryReset();
      if (context.mounted) {
        showSuccessSnackBar(context, 'Factory reset command sent');
      }
    } catch (e) {
      if (context.mounted) showFailedSnackBar(context, 'Factory reset failed');
    }
  }
}
