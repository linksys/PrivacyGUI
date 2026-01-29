import 'package:flutter_riverpod/flutter_riverpod.dart';

/// UI state for the Demo App (non-persistent).
class DemoUIState {
  final bool isThemePanelOpen;

  const DemoUIState({this.isThemePanelOpen = false});

  DemoUIState copyWith({bool? isThemePanelOpen}) {
    return DemoUIState(
      isThemePanelOpen: isThemePanelOpen ?? this.isThemePanelOpen,
    );
  }
}

class DemoUIStateNotifier extends StateNotifier<DemoUIState> {
  DemoUIStateNotifier() : super(const DemoUIState());

  void toggleThemePanel() {
    state = state.copyWith(isThemePanelOpen: !state.isThemePanelOpen);
  }

  void setThemePanelOpen(bool isOpen) {
    state = state.copyWith(isThemePanelOpen: isOpen);
  }
}

final demoUIProvider =
    StateNotifierProvider<DemoUIStateNotifier, DemoUIState>((ref) {
  return DemoUIStateNotifier();
});
