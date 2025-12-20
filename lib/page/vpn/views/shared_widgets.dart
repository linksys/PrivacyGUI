import 'package:flutter/material.dart';
import 'package:privacy_gui/page/vpn/models/vpn_models.dart';
import 'package:ui_kit_library/ui_kit.dart';

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
      AppGap.sm(),
      AppText.titleMedium(status.toDisplayName(context)),
    ],
  );
}

Widget buildStatRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText.bodyMedium(label),
        Flexible(
          child: AppText.bodyMedium(
            value,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}
