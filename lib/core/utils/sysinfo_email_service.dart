import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/send_sysinfo_email.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/util/get_log_selector/get_log_base.dart'
    if (dart.library.io) 'package:privacy_gui/util/get_log_selector/get_log_mobile.dart'
    if (dart.library.html) 'package:privacy_gui/util/get_log_selector/get_log_web.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

class SysinfoEmailService {
  static Future<void> sendSystemInfo({
    required WidgetRef ref,
    required String userEmailList,
    required BuildContext context,
  }) async {
    List<String> emailList = [kDebugMode ? '' : 'routerinfo@linksys.com'];

    userEmailList = userEmailList.replaceAll(RegExp(r' '), '');
    if (userEmailList.contains(',')) {
      emailList.addAll(userEmailList.split(','));
    } else if (userEmailList.isNotEmpty) {
      emailList.add(userEmailList);
    }
    emailList.removeWhere((value) => value.isEmpty);

    // Step 1: Collect UI logs
    try {
      final logContent = await getLog(context);

      // Step 2: Send UI logs to FW (ignore result)
      try {
        await ref.read(routerRepositoryProvider).send(
          JNAPAction.getUILog,
          auth: true,
          data: {'log': logContent},
          cacheLevel: CacheLevel.noCache,
          timeoutMs: 30000,
        );
      } catch (error) {
        // Ignore GetUILog errors - continue with SendSysinfoEmail
        if (kDebugMode) {
          print('GetUILog failed: $error');
        }
      }
    } catch (error) {
      // Ignore log collection errors - continue with SendSysinfoEmail
      if (kDebugMode) {
        print('Log collection failed: $error');
      }
    }

    // Step 3: Send system info email (always execute)
    await ref.read(routerRepositoryProvider).send(
          JNAPAction.sendSysinfoEmail,
          auth: true,
          data: SendSysinfoEmail(addressList: emailList).toJson(),
          cacheLevel: CacheLevel.noCache,
          timeoutMs: 120000,
        );
  }

  static void showSendSystemInfoDialog(BuildContext context, WidgetRef ref) {
    final pageContext = context;
    showAdaptiveDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        insetPadding: const EdgeInsets.all(20),
        scrollable: true,
        title: AppText.titleMedium(loc(dialogContext).sendLogs),
        content: AppText.bodyMedium(loc(dialogContext).sendLogsDescription),
        actions: [
          AppTextButton(
            loc(dialogContext).cancel,
            onTap: () {
              dialogContext.pop();
            },
          ),
          AppTextButton(
            loc(dialogContext).shareLogs,
            onTap: () {
              dialogContext.pop();
              showVerifyEmailDialog(pageContext, ref);
            },
          ),
        ],
      ),
    );
  }

  static void showVerifyEmailDialog(BuildContext context, WidgetRef ref) {
    final pageContext = context;
    final emailController = TextEditingController();

    showAdaptiveDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        insetPadding: const EdgeInsets.all(20),
        title: AppText.titleMedium(loc(dialogContext).verifyEmail),
        content: Column(
          children: [
            AppTextField.outline(
              controller: emailController,
              hintText: loc(dialogContext).optional,
              onFocusChanged: (hasFocus) {},
            ),
            const AppGap.small3(),
            AppText.bodyMedium(loc(dialogContext).multipleEmailsHint),
          ],
        ),
        actions: [
          AppTextButton(
            loc(dialogContext).cancel,
            onTap: () {
              dialogContext.pop();
            },
          ),
          AppTextButton(
            loc(dialogContext).shareLogs,
            onTap: () {
              dialogContext.pop();
              doSomethingWithSpinner(
                pageContext,
                sendSystemInfo(
                  ref: ref,
                  userEmailList: emailController.text,
                  context: pageContext,
                ),
              ).then((_) {
                if (pageContext.mounted) {
                  showSuccessSnackBar(
                      pageContext, loc(pageContext).systemInfoSentSuccessfully);
                }
              }).onError((error, stackTrace) {
                if (pageContext.mounted) {
                  showFailedSnackBar(
                      pageContext, loc(pageContext).systemInfoSendFailed);
                }
              });
            },
          ),
        ],
      ),
    );
  }
}
