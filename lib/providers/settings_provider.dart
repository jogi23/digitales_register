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
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the app lock was on, read straight from storage — for `main()`,
/// before the settings are loaded and before the first frame.
Future<bool> storedAppLockEnabled() => _storedFlag('appLockEnabled');

/// Whether the diagnostic log was on, read straight from storage — for the
/// start of the app and of the background isolate, before the settings load.
/// Reads the preferences fresh: the other isolate may have changed them.
Future<bool> storedDiagnosticsEnabled() => _storedFlag('diagnosticsEnabled');

Future<bool> _storedFlag(String key) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  final raw = prefs.getString(SettingsNotifier._globalPrefsKey);
  if (raw == null) return false;
  try {
    return (json.decode(raw) as Map<String, dynamic>)[key] == true;
  } on Object {
    return false;
  }
}

/// Whether this is a debug build; those record whatever the switch says.
final debugBuildProvider = Provider<bool>((ref) => kDebugMode);

/// Whether the network protocol and the debug log are recording.
final diagnosticsActiveProvider = Provider<bool>(
  (ref) =>
      ref.watch(debugBuildProvider) ||
      ref.watch(settingsProvider.select((s) => s.diagnosticsEnabled)),
);

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

  void setKeepPageOnAccountSwitch(bool value) =>
      _update(state.copyWith(keepPageOnAccountSwitch: value));

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

  /// Null follows the device language.
  void setLanguage(String? code) => _update(state.copyWith(language: code));

  /// Remembers the name a message was signed with, so the next confirmation
  /// starts with it already filled in.
  void setMessageSignature(String? name) =>
      _update(state.copyWith(messageSignature: name));

  void setDiagnosticsEnabled(bool value) =>
      _update(state.copyWith(diagnosticsEnabled: value));

  // ─── App lock ─────────────────────────────────────────────────────────────

  void setAppLockEnabled(bool value) =>
      _update(state.copyWith(appLockEnabled: value));

  void setAppLockGraceMinutes(int minutes) {
    final safe = allowedAppLockGraceMinutes.contains(minutes) ? minutes : 1;
    _update(state.copyWith(appLockGraceMinutes: safe));
  }

  // ─── Notification settings ────────────────────────────────────────────────

  void setNotificationsEnabled(bool value) =>
      _update(state.copyWith(notificationsEnabled: value));

  void setNotificationPollMinutes(int minutes) {
    final safe =
        allowedNotificationPollMinutes.contains(minutes) ? minutes : 30;
    _update(state.copyWith(notificationPollMinutes: safe));
  }

  void setNotifyClassbook(bool value) =>
      _update(state.copyWith(notifyClassbook: value));

  void setNotifyMessages(bool value) =>
      _update(state.copyWith(notifyMessages: value));

  void setNotifyGrades(bool value) =>
      _update(state.copyWith(notifyGrades: value));

  void setNotifyObservations(bool value) =>
      _update(state.copyWith(notifyObservations: value));

  void setNotifyHomework(bool value) =>
      _update(state.copyWith(notifyHomework: value));

  void setNotifyAbsences(bool value) =>
      _update(state.copyWith(notifyAbsences: value));

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

  void setSixDayWeek(bool value) => _update(state.copyWith(sixDayWeek: value));

  void setCalendarShowTimes(bool value) =>
      _update(state.copyWith(calendarShowTimes: value));

  void setCalendarShowAllDetails(bool value) =>
      _update(state.copyWith(calendarShowAllDetails: value));

  void setDashboardViewMode(DashboardViewMode value) =>
      _update(state.copyWith(dashboardViewMode: value));

  void setClassbookViewMode(ClassbookViewMode value) =>
      _update(state.copyWith(classbookViewMode: value));

  void setClassbookDisplayMode(EntryDisplayMode value) =>
      _update(state.copyWith(classbookDisplayMode: value));

  void setHomeworkViewMode(ClassbookViewMode value) =>
      _update(state.copyWith(homeworkViewMode: value));

  void setHomeworkDisplayMode(EntryDisplayMode value) =>
      _update(state.copyWith(homeworkDisplayMode: value));

  void setAbsencesDisplayMode(EntryDisplayMode value) =>
      _update(state.copyWith(absencesDisplayMode: value));

  void setGradesDisplayMode(EntryDisplayMode value) =>
      _update(state.copyWith(gradesDisplayMode: value));

  void setClassbookSubjects(List<String> value) =>
      _update(state.copyWith(classbookSubjects: value));

  // ─── Appearance / UI settings ─────────────────────────────────────────────

  void setDrawerFullyExpanded(bool value) =>
      _update(state.copyWith(drawerFullyExpanded: value));

  void setAccentBackground(bool value) =>
      _update(state.copyWith(accentBackground: value));

  // ─── Routing-triggered ephemeral scroll state ─────────────────────────────

  void scrollToGradesSection() => state = state.copyWith(scrollToGrades: true);

  void resetScroll() => state = state.copyWith(scrollToGrades: false);
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
