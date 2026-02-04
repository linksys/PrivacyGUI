import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:ui_kit_library/ui_kit.dart';

class IosInstallInstructionSheet extends StatelessWidget {
  const IosInstallInstructionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: AppText.titleLarge(
                  loc(context).pwaIosInstallTitle,
                ),
              ),
              AppIconButton(
                icon: const Icon(Icons.close),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          AppGap.md(),
          AppText.bodyMedium(
            loc(context).pwaIosInstallDescription,
          ),
          AppGap.lg(),
          _buildStep(
            context,
            '1',
            loc(context).pwaIosStep1,
            Icons.ios_share,
          ),
          AppGap.md(),
          _buildStep(
            context,
            '2',
            loc(context).pwaIosStep2,
            Icons.add_box_outlined,
          ),
          AppGap.xl(),
        ],
      ),
    );
  }

  Widget _buildStep(
      BuildContext context, String number, String text, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: AppText.titleMedium(
            number,
            color: Theme.of(context).primaryColor,
          ),
        ),
        AppGap.md(),
        Expanded(child: AppText.bodyMedium(text)),
        AppGap.sm(),
        Icon(icon, color: Colors.blue),
      ],
    );
  }
}
