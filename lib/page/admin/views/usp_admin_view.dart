import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/components/views/service_error_view.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/helpers/recovery_dialog_helper.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/page/admin/providers/usp_admin_notifier.dart';
import 'package:privacy_gui/page/admin/providers/usp_admin_state.dart';
import 'package:privacy_gui/page/admin/views/components/usp_password_card.dart';
import 'package:privacy_gui/page/admin/views/components/usp_system_actions_card.dart';
import 'package:privacy_gui/page/admin/views/components/usp_timezone_card.dart';
import 'package:privacy_gui/page/admin/views/dialogs/change_password_dialog.dart';
import 'package:privacy_gui/page/admin/views/dialogs/confirm_action_dialog.dart';
import 'package:privacy_gui/page/admin/views/dialogs/timezone_edit_dialog.dart';
import 'package:privacy_gui/page/firmware_update/views/firmware_update_card.dart';
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
      title: loc(context).administration,
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      backFallback: RouteNamed.uspMenu,
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
          error: (error, stack) => ServiceErrorView(
            error: error is ServiceError ? error : null,
            title: loc(context).failedToLoadSettings,
            onRetry: () => ref.invalidate(uspAdminProvider),
          ),
          data: (state) => _buildContent(childContext, ref, state),
        );
      },
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
          fetchedAt: state.timeFetchedAt,
          onEdit: () => _editTimezone(context, ref, state),
        ),
        AppGap.xl(),
        UspPasswordCard(
          adminUser: state.adminUser,
          onChangePassword: () => _changePassword(context, ref),
        ),
        AppGap.xl(),
        const FirmwareUpdateCard(),
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
              AppGap.xl(),
              const FirmwareUpdateCard(),
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
      await doSomethingWithSpinner(
        context,
        ref.read(uspAdminProvider.notifier).updateTimezone(
              localTimeZone: result.localTimeZone,
              ntpServer1: result.ntpServer1,
            ),
      );
      if (context.mounted)
        showSuccessSnackBar(context, loc(context).timezoneUpdated);
    } catch (e) {
      if (context.mounted) {
        showFailedSnackBar(context, localizeServiceError(context, e));
      }
    }
  }

  Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
    try {
      final result = await showChangePasswordDialog(
        context,
        onSave: (newPassword) async {
          await ref
              .read(uspAdminProvider.notifier)
              .setAdminPassword(newPassword);
        },
      );
      if (result == true && context.mounted) {
        showSuccessSnackBar(context, loc(context).passwwordUpdated);
      }
    } catch (e) {
      if (context.mounted) {
        showFailedSnackBar(context, localizeServiceError(context, e));
      }
    }
  }

  Future<void> _reboot(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmActionDialog(
      context,
      title: loc(context).rebootRouter,
      message: loc(context).rebootRouterMessage,
      confirmLabel: loc(context).restart,
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await doSomethingWithSpinner(
        context,
        ref.read(uspAdminProvider.notifier).reboot(),
      );
      if (!context.mounted) return;

      await showRecoveryDialog(
        context,
        ref,
        trigger: RecoveryTrigger.operationalReboot,
        cooldown: const Duration(seconds: 60),
        title: loc(context).routerIsRebooting,
        message: loc(context).rebootWaitMessage,
        successMessage: loc(context).routerRebootComplete,
      );
    } catch (e) {
      if (context.mounted) {
        showFailedSnackBar(context, localizeServiceError(context, e));
      }
    }
  }

  Future<void> _factoryReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmActionDialog(
      context,
      title: loc(context).resetToFactoryDefault,
      message: loc(context).factoryResetDesc,
      confirmLabel: loc(context).reset,
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await doSomethingWithSpinner(
        context,
        ref.read(uspAdminProvider.notifier).factoryReset(),
      );
      if (!context.mounted) return;

      await showRecoveryDialog(
        context,
        ref,
        trigger: RecoveryTrigger.operationalFactoryReset,
        cooldown: const Duration(seconds: 90),
        healthOnly: true,
        title: loc(context).factoryResetInProgress,
        message: loc(context).factoryResetWaitMessage,
      );
    } catch (e) {
      if (context.mounted) {
        showFailedSnackBar(context, localizeServiceError(context, e));
      }
    }
  }
}
