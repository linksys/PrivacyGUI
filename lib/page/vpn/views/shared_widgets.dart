import 'package:flutter/material.dart';
import 'package:privacy_gui/page/vpn/models/vpn_models.dart';
import 'package:privacygui_widgets/widgets/gap/gap.dart';
import 'package:privacygui_widgets/widgets/text/app_text.dart';

Widget vpnStatus(BuildContext context, IPsecStatus status) {
  return Row(
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: status.color,
          shape: BoxShape.circle,
        ),
      ),
      const AppGap.small2(),
      AppText.titleMedium(status.toDisplayName(context)),
    ],
  );
}

Widget buildStatRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    // The label is Expanded, so a long one wraps before it reaches the
    // value instead of running past a narrow page (#1802).
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: AppText.bodyMedium(label)),
        const AppGap.small2(),
        AppText.bodyMedium(value),
      ],
    ),
  );
}
