// Copyright (C) 2026 Johannes Feichter
//
// This file is part of digitales_register.
//
// digitales_register is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// digitales_register is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with digitales_register.  If not, see <http://www.gnu.org/licenses/>.

import 'dart:async';
import 'dart:convert';

import 'package:dr/app_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsNotifier extends Notifier<SettingsState> {
  static const _globalPrefsKey = 'settings_global';

  /// Whether the app-wide settings have a home of their own yet. False on the
  /// first start after they were split out of the per-account state.
  bool _globalStored = false;

  @override
  SettingsState build() => SettingsState();

  /// Reads the app-wide settings. Call once at startup, before any account
  /// state is restored.
  Future<void> loadGlobal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_globalPrefsKey);
    if (raw == null) return;
    _globalStored = true;
    state = state.withGlobalJson(json.decode(raw) as Map<String, dynamic>);
  }

  /// Restores the settings of the account that just logged in.
  ///
  /// The app-wide ones are not part of that — they stay as they are. The one
  /// exception is the first start after the split, when they have only ever
  /// been stored with an account: taking them from there beats resetting the
  /// user to defaults.
  void load(SettingsState settings) {
    final restored = settings.copyWith(scrollToGrades: false);
    if (_globalStored) {
      state = restored.withGlobalsFrom(state);
      return;
    }
    state = restored;
    unawaited(_persistGlobal());
  }

  /// Back to defaults for everything that belongs to the account.
  ///
  /// Called when switching accounts: an account with nothing stored yet used
  /// to inherit the settings of the one it was switched from.
  void resetForAccount() {
    state = SettingsState(noPasswordSaving: state.noPasswordSaving)
        .withGlobalsFrom(state);
  }

  /// Applies a change and keeps the app-wide settings on disk.
  void _update(SettingsState next) {
    state = next;
    unawaited(_persistGlobal());
  }

  Future<void> _persistGlobal() async {
    _globalStored = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_globalPrefsKey, json.encode(state.globalJson()));
  }

  // ─── Persistence / auth settings ─────────────────────────────────────────

  void setSaveNoPass(bool value) =>
      _update(state.copyWith(noPasswordSaving: value));

  void setAskWhenDelete(bool value) =>
      _update(state.copyWith(askWhenDelete: value));

  // ─── Grades settings ──────────────────────────────────────────────────────

  void setShowCancelledGrades(bool value) =>
      _update(state.copyWith(showCancelled: value));

  void setGradesTypeSorted(bool value) =>
      _update(state.copyWith(typeSorted: value));

  void setShowGradesDiagram(bool value) =>
      _update(state.copyWith(showGradesDiagram: value));

  void setShowAllSubjectsAverage(bool value) =>
      _update(state.copyWith(showAllSubjectsAverage: value));

  void setShowSubjectAverage(bool value) =>
      _update(state.copyWith(showSubjectAverage: value));

  void setIgnoreForGradesAverage(List<String> subjects) =>
      _update(state.copyWith(ignoreForGradesAverage: List.of(subjects)));

  void setStarColor(String id) => _update(state.copyWith(starColor: id));

  // ─── Dashboard settings ───────────────────────────────────────────────────

  void setMarkNewOrChanged(bool value) =>
      _update(state.copyWith(dashboardMarkNewOrChangedEntries: value));

  void setDeduplicate(bool value) =>
      _update(state.copyWith(dashboardDeduplicateEntries: value));

  void setDashboardColorBorders(bool value) =>
      _update(state.copyWith(dashboardColorBorders: value));

  void setDashboardColorTestsInRed(bool value) =>
      _update(state.copyWith(dashboardColorTestsInRed: value));

  // ─── Calendar settings ────────────────────────────────────────────────────

  void setShowCalendarNicksBar(bool value) =>
      _update(state.copyWith(showCalendarNicksBar: value));

  void setCalendarColorBackground(bool value) =>
      _update(state.copyWith(calendarColorBackground: value));

  void setCalendarShowTimes(bool value) =>
      _update(state.copyWith(calendarShowTimes: value));

  void setDashboardViewMode(DashboardViewMode value) =>
      _update(state.copyWith(dashboardViewMode: value));

  // ─── Appearance / UI settings ─────────────────────────────────────────────

  void setDrawerFullyExpanded(bool value) =>
      _update(state.copyWith(drawerFullyExpanded: value));

  // ─── Routing-triggered ephemeral scroll state ─────────────────────────────

  void scrollToGradesSection() => state = state.copyWith(scrollToGrades: true);

  void resetScroll() => state = state.copyWith(scrollToGrades: false);
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
