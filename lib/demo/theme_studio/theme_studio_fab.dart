import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/demo/providers/demo_ui_provider.dart';

/// A simple FAB that toggles the Theme Studio panel.
class ThemeStudioFab extends ConsumerWidget {
  const ThemeStudioFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOpen = ref.watch(demoUIProvider).isThemePanelOpen;

    return AppIconButton.primary(
      icon: AppIcon.font(
        isOpen ? AppFontIcons.close : AppFontIcons.widgets,
      ),
      onTap: () {
        ref.read(demoUIProvider.notifier).toggleThemePanel();
      },
    );
  }
}
