import 'package:flutter/material.dart';
import 'package:privacy_gui/usp_page/admin/models/admin_ui_models.dart';
import 'package:ui_kit_library/ui_kit.dart';

class UspPasswordCard extends StatelessWidget {
  final AdminUserUIModel adminUser;
  final VoidCallback onChangePassword;

  const UspPasswordCard({
    super.key,
    required this.adminUser,
    required this.onChangePassword,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.titleMedium('Router Password'),
            AppGap.md(),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.bodyMedium('Admin: ${adminUser.username}'),
                      AppGap.xs(),
                      AppText.labelLarge(
                          '\u2022' * 12), // bullet dots for masked password
                    ],
                  ),
                ),
                AppButton.text(
                  label: 'Change',
                  onTap: onChangePassword,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
