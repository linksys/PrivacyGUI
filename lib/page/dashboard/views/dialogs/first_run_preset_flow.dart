import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/page/dashboard/models/usp_dashboard_preset.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_preferences_provider.dart';
import 'package:privacy_gui/page/dashboard/views/dialogs/preset_selection_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Asks a first-time user which dashboard preset they want, once, and applies
/// the answer.
///
/// Lifted out of `UspSliverDashboardView` by #1497 so that
/// `LocalSurface.firstRunPresetFlow()` can hand the whole flow over as one value
/// and the remote surface can hand over `null`. The three steps are one decision
/// — the "already asked" preference, the picker, and applying the result — and
/// while they lived in the view the mode gate had to sit in front of all three as
/// a `GlobalConfig.remote.showPresetDialog` read.
///
/// The preference is written **before** `selectPreset`, deliberately: even if
/// applying the preset throws, the user is not asked again on the next
/// navigation.
Future<void> runFirstRunPresetFlow(BuildContext context, WidgetRef ref) async {
  final sharedPrefs = await SharedPreferences.getInstance();
  if (sharedPrefs.getBool(pUspPresetDialogSeen) == true) return;

  if (!context.mounted) return;

  final result = await showPresetSelectionDialog(context);
  if (!context.mounted) return;

  await sharedPrefs.setBool(pUspPresetDialogSeen, true);

  // Cancelling is an answer: apply the standard preset and do not ask again.
  await ref
      .read(uspLayoutPreferencesProvider.notifier)
      .selectPreset(result ?? UspDashboardPreset.standard);
}
