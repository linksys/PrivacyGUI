import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';

const _sliverDashboardModesKey = 'sliver_dashboard_modes';

final sliverDashboardModeProvider = StateNotifierProvider<
    SliverDashboardModeNotifier, Map<String, DisplayMode>>(
  (ref) => SliverDashboardModeNotifier(),
);

class SliverDashboardModeNotifier
    extends StateNotifier<Map<String, DisplayMode>> {
  SliverDashboardModeNotifier() : super({}) {
    _loadModes();
  }

  Future<void> _loadModes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_sliverDashboardModesKey);
    if (jsonString != null) {
      try {
        final Map<String, dynamic> rawMap = jsonDecode(jsonString);
        final Map<String, DisplayMode> loadedModes = {};

        rawMap.forEach((key, value) {
          final mode = DisplayMode.values.firstWhere(
            (e) => e.name == value,
            orElse: () => DisplayMode.normal,
          );
          loadedModes[key] = mode;
        });

        state = loadedModes;
      } catch (e) {
        // Handle error or ignore
      }
    }
  }

  Future<void> saveModes() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, String> rawMap = state.map(
      (key, value) => MapEntry(key, value.name),
    );
    await prefs.setString(_sliverDashboardModesKey, jsonEncode(rawMap));
  }

  void setMode(String id, DisplayMode mode) {
    state = {...state, id: mode};
    saveModes();
  }

  void resetModes() async {
    state = {};
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sliverDashboardModesKey);
  }

  DisplayMode getMode(String id) {
    return state[id] ?? DisplayMode.normal;
  }
}
