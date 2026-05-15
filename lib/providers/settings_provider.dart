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

import 'package:built_collection/built_collection.dart';
import 'package:dr/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsNotifier extends Notifier<SettingsState> {
  /// Called after [setSaveNoData] to trigger an immediate storage write.
  /// Wired by middleware._load once the Redux store is available.
  void Function()? onSaveState;

  @override
  SettingsState build() => SettingsState();

  /// Restores settings from persisted storage (called by middleware on login).
  void load(SettingsState settings) {
    state = settings.rebuild(
      (b) => b
        ..scrollToSubjectNicks = false
        ..scrollToGrades = false,
    );
  }

  // ─── Persistence / auth settings ─────────────────────────────────────────

  void setSaveNoPass(bool value) =>
      state = state.rebuild((b) => b..noPasswordSaving = value);

  void setSaveNoData(bool value) {
    state = state.rebuild((b) => b..noDataSaving = value);
    onSaveState?.call();
  }

  void setAskWhenDelete(bool value) =>
      state = state.rebuild((b) => b..askWhenDelete = value);

  void setDeleteDataOnLogout(bool value) =>
      state = state.rebuild((b) => b..deleteDataOnLogout = value);

  // ─── Grades settings ──────────────────────────────────────────────────────

  void setShowCancelledGrades(bool value) =>
      state = state.rebuild((b) => b..showCancelled = value);

  void setGradesTypeSorted(bool value) =>
      state = state.rebuild((b) => b..typeSorted = value);

  void setShowGradesDiagram(bool value) =>
      state = state.rebuild((b) => b..showGradesDiagram = value);

  void setShowAllSubjectsAverage(bool value) =>
      state = state.rebuild((b) => b..showAllSubjectsAverage = value);

  void setIgnoreForGradesAverage(BuiltList<String> subjects) =>
      state = state.rebuild((b) => b.ignoreForGradesAverage.replace(subjects));

  // ─── Dashboard settings ───────────────────────────────────────────────────

  void setMarkNewOrChanged(bool value) =>
      state = state.rebuild((b) => b..dashboardMarkNewOrChangedEntries = value);

  void setDeduplicate(bool value) =>
      state = state.rebuild((b) => b..dashboardDeduplicateEntries = value);

  void setDashboardColorBorders(bool value) =>
      state = state.rebuild((b) => b..dashboardColorBorders = value);

  void setDashboardColorTestsInRed(bool value) =>
      state = state.rebuild((b) => b..dashboardColorTestsInRed = value);

  // ─── Calendar settings ────────────────────────────────────────────────────

  void setShowCalendarNicksBar(bool value) =>
      state = state.rebuild((b) => b..showCalendarNicksBar = value);

  void setCalendarColorBackground(bool value) =>
      state = state.rebuild((b) => b..calendarColorBackground = value);

  // ─── Appearance / UI settings ─────────────────────────────────────────────

  void setDrawerFullyExpanded(bool value) =>
      state = state.rebuild((b) => b..drawerFullyExpanded = value);

  void setSubjectNicks(BuiltMap<String, String> nicks) =>
      state = state.rebuild((b) => b.subjectNicks.replace(nicks));

  void setSubjectTheme(MapEntry<String, SubjectTheme> entry) =>
      state = state.rebuild((b) => b.subjectThemes[entry.key] = entry.value);

  /// Ensures every subject in [subjects] has a [SubjectTheme]. New subjects are
  /// assigned an unused color automatically.
  void updateSubjectThemes(List<String> subjects) {
    final existing = state.subjectThemes;
    final newSubjects =
        subjects.where((s) => !existing.containsKey(s)).toList();
    if (newSubjects.isEmpty) return;

    state = state.rebuild((b) {
      for (final subject in newSubjects) {
        final usedColors =
            b.subjectThemes.build().values.map((t) => t.color).toSet();
        final color = _colors.firstWhere(
          (c) => !usedColors.contains(c.value),
          orElse: () => _similarColors.firstWhere(
            (c) => !usedColors.contains(c.value),
            orElse: () => (List.of(Colors.primaries)..shuffle()).first,
          ),
        );
        b.subjectThemes[subject] = SubjectTheme(
          (t) => t
            ..thick = _defaultThick
            ..color = color.value,
        );
      }
    });
  }

  // ─── Routing-triggered ephemeral scroll state ─────────────────────────────

  void scrollToSubjectNicksSection() => state = state.rebuild(
        (b) => b
          ..scrollToSubjectNicks = true
          ..scrollToGrades = false,
      );

  void scrollToGradesSection() => state = state.rebuild(
        (b) => b
          ..scrollToGrades = true
          ..scrollToSubjectNicks = false,
      );

  void resetScroll() => state = state.rebuild(
        (b) => b
          ..scrollToSubjectNicks = false
          ..scrollToGrades = false,
      );
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);


// ─── Color palette helpers (same logic as former settings reducer) ───────────

final _colors = List.of(Colors.primaries)
  ..removeWhere((c) => _similarColors.contains(c));

final _similarColors = [
  Colors.lime,
  Colors.lightBlue,
  Colors.cyan,
  Colors.amber,
];

const _defaultThick = 2;
