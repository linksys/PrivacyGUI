import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/page/administration/mac_filtering/providers/mac_filtering_state.dart';

final macFilteringProvider =
    NotifierProvider<MacFilteringNotifier, MacFilteringState>(
        () => MacFilteringNotifier());

class MacFilteringNotifier extends Notifier<MacFilteringState> {
  @override
  MacFilteringState build() => MacFilteringState.init();

  fetch() async {}

  setEnable(bool isEnabled) {
    state = state.copyWith(
        status: isEnabled ? MacFilterStatus.allow : MacFilterStatus.off);
  }

  setAccess(String value) {
    final status =
        MacFilterStatus.values.firstWhereOrNull((e) => e.name == value);
    if (status != null) {
      state = state.copyWith(status: status);
    }
  }
}
