import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/pwa/pwa_install_service.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/pwa/ios_install_instruction_sheet.dart';
import 'package:privacy_gui/page/components/pwa/mac_safari_install_instruction_sheet.dart';
import 'package:ui_kit_library/ui_kit.dart';

class InstallPromptBanner extends ConsumerWidget {
  const InstallPromptBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only show on Web - logic handled by provider state (PwaMode.none if not web)
    // Only show on 'DU' model (Logic moved to provider)
    final mode = ref.watch(pwaInstallServiceProvider);
    final pwaNotifier = ref.read(pwaInstallServiceProvider.notifier);

    if (mode == PwaMode.none) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Theme.of(context).colorScheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            const Icon(Icons.install_mobile, color: Colors.white),
            AppGap.sm(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText.titleMedium(
                    loc(context).pwaGetTheApp,
                    color: Colors.white,
                  ),
                  AppText.bodySmall(
                    loc(context).pwaInstallDescription,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
            AppButton.primary(
              key: const Key('pwa_install_button'),
              label: loc(context).pwaInstallButton,
              onTap: () {
                switch (mode) {
                  case PwaMode.ios:
                    showModalBottomSheet(
                      context: context,
                      useRootNavigator: false,
                      builder: (c) => const IosInstallInstructionSheet(),
                    );
                    break;
                  case PwaMode.mac:
                    showModalBottomSheet(
                      context: context,
                      useRootNavigator: false,
                      builder: (c) => const MacSafariInstallInstructionSheet(),
                    );
                    break;
                  case PwaMode.native:
                    pwaNotifier.promptInstall();
                    break;
                  case PwaMode.none:
                    break;
                }
              },
            ),
            AppGap.xs(),
            AppIconButton(
              icon: const Icon(Icons.close, color: Colors.white70),
              onTap: () {
                pwaNotifier.dismiss();
              },
            ),
          ],
        ),
      ),
    );
  }
}
