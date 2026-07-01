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

import 'package:dr/app_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() => SettingsState();

  /// Restores settings from persisted storage (called by middleware on login).
  void load(SettingsState settings) {
    state = settings.copyWith(scrollToGrades: false);
  }

  // ─── Persistence / auth settings ─────────────────────────────────────────

  void setSaveNoPass(bool value) =>
      state = state.copyWith(noPasswordSaving: value);

  void setAskWhenDelete(bool value) =>
      state = state.copyWith(askWhenDelete: value);

  // ─── Grades settings ──────────────────────────────────────────────────────

  void setShowCancelledGrades(bool value) =>
      state = state.copyWith(showCancelled: value);

  void setGradesTypeSorted(bool value) =>
      state = state.copyWith(typeSorted: value);

  void setShowGradesDiagram(bool value) =>
      state = state.copyWith(showGradesDiagram: value);

  void setShowAllSubjectsAverage(bool value) =>
      state = state.copyWith(showAllSubjectsAverage: value);

  void setIgnoreForGradesAverage(List<String> subjects) =>
      state = state.copyWith(ignoreForGradesAverage: List.of(subjects));

  // ─── Dashboard settings ───────────────────────────────────────────────────

  void setMarkNewOrChanged(bool value) =>
      state = state.copyWith(dashboardMarkNewOrChangedEntries: value);

  void setDeduplicate(bool value) =>
      state = state.copyWith(dashboardDeduplicateEntries: value);

  void setDashboardColorBorders(bool value) =>
      state = state.copyWith(dashboardColorBorders: value);

  void setDashboardColorTestsInRed(bool value) =>
      state = state.copyWith(dashboardColorTestsInRed: value);

  // ─── Calendar settings ────────────────────────────────────────────────────

  void setShowCalendarNicksBar(bool value) =>
      state = state.copyWith(showCalendarNicksBar: value);

  void setCalendarColorBackground(bool value) =>
      state = state.copyWith(calendarColorBackground: value);

  // ─── Appearance / UI settings ─────────────────────────────────────────────

  void setDrawerFullyExpanded(bool value) =>
      state = state.copyWith(drawerFullyExpanded: value);

  // ─── Routing-triggered ephemeral scroll state ─────────────────────────────

  void scrollToGradesSection() => state = state.copyWith(scrollToGrades: true);

  void resetScroll() => state = state.copyWith(scrollToGrades: false);
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
