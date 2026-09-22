// Copyright (C) 2021 Michael Debertol
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
import 'package:dr/providers/all_subjects_provider.dart';
import 'package:dr/providers/login_provider.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/services/app_router.dart';
import 'package:dr/ui/settings_page_widget.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsPageContainer extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final allSubjects = ref.watch(allSubjectsProvider);
    final isDemo = ref.watch(isDemoProvider);
    final vm = SettingsViewModel.from(settings, allSubjects, isDemo);
    return SettingsPageWidget(
      vm: vm,
      onSetDarkMode: (dm) {
        DynamicTheme.of(context)!.setBrightness(
          dm ? Brightness.dark : Brightness.light,
        );
      },
      onSetFollowDeviceDarkMode: (dm) {
        DynamicTheme.of(context)!.setFollowDevice(dm);
      },
      onSetNoPassSaving: notifier.setSaveNoPass,
      onSetKeepPageOnAccountSwitch: notifier.setKeepPageOnAccountSwitch,
      onSetAccentBackground: notifier.setAccentBackground,
      onSetAskWhenDelete: notifier.setAskWhenDelete,
      onSetShowGradesDiagram: notifier.setShowGradesDiagram,
      onSetShowAllSubjectsAverage: notifier.setShowAllSubjectsAverage,
      onSetShowSubjectAverage: notifier.setShowSubjectAverage,
      onSetDashboardMarkNewOrChangedEntries: notifier.setMarkNewOrChanged,
      onSetDashboardDeduplicateEntries: notifier.setDeduplicate,
      onShowProfile: ref.read(appRouterProvider).showProfile,
      onSetIgnoreForGradesAverage: notifier.setIgnoreForGradesAverage,
      onSetDashboardColorBorders: notifier.setDashboardColorBorders,
      onSetCalenderColorBackground: notifier.setCalendarColorBackground,
      onSetCalendarShowTimes: notifier.setCalendarShowTimes,
      onSetCalendarShowAllDetails: notifier.setCalendarShowAllDetails,
      onSetDashboardViewMode: notifier.setDashboardViewMode,
      onSetClassbookViewMode: notifier.setClassbookViewMode,
      onSetClassbookDisplayMode: notifier.setClassbookDisplayMode,
      onSetHomeworkViewMode: notifier.setHomeworkViewMode,
      onSetHomeworkDisplayMode: notifier.setHomeworkDisplayMode,
      onSetAbsencesDisplayMode: notifier.setAbsencesDisplayMode,
      onSetGradesDisplayMode: notifier.setGradesDisplayMode,
      onSetDashboardColorTestsInRed: notifier.setDashboardColorTestsInRed,
      onSetStarColor: notifier.setStarColor,
      onSetLanguage: notifier.setLanguage,
      onSetNotificationsEnabled: notifier.setNotificationsEnabled,
      onSetNotificationPollMinutes: notifier.setNotificationPollMinutes,
      onSetNotifyClassbook: notifier.setNotifyClassbook,
      onSetNotifyMessages: notifier.setNotifyMessages,
      onSetNotifyGrades: notifier.setNotifyGrades,
      onSetNotifyObservations: notifier.setNotifyObservations,
      onSetNotifyHomework: notifier.setNotifyHomework,
    );
  }
}

typedef OnSettingChanged<T> = void Function(T newValue);

class SettingsViewModel {
  final bool noPassSaving;

  /// Whether switching accounts stays on the page instead of the Merkheft.
  final bool keepPageOnAccountSwitch;

  /// Whether the pages are tinted with the accent colour.
  final bool accentBackground;
  final bool askWhenDelete;
  final bool showGradesDiagram;
  final bool showAllSubjectsAverage;
  final bool showSubjectAverage;
  final bool dashboardMarkNewOrChangedEntries;
  final bool dashboardDeduplicateEntries;
  final bool showGradesSettings;
  final bool dashboardColorBorders;
  final bool calendarColorBackground;
  final bool calendarShowTimes;
  final bool calendarShowAllDetails;
  final DashboardViewMode dashboardViewMode;
  final ClassbookViewMode classbookViewMode;
  final EntryDisplayMode classbookDisplayMode;
  final ClassbookViewMode homeworkViewMode;
  final EntryDisplayMode homeworkDisplayMode;
  final EntryDisplayMode absencesDisplayMode;
  final EntryDisplayMode gradesDisplayMode;
  final bool dashboardColorTestsInRed;
  final String starColor;
  final bool notificationsEnabled;
  final int notificationPollMinutes;
  final bool notifyClassbook;
  final bool notifyMessages;
  final bool notifyGrades;
  final bool notifyObservations;
  final bool notifyHomework;

  /// Null follows the device language.
  final String? language;
  final bool demoMode;
  final List<String> allSubjects;
  final List<String> ignoreForGradesAverage;

  const SettingsViewModel({
    required this.noPassSaving,
    this.keepPageOnAccountSwitch = false,
    this.accentBackground = true,
    required this.askWhenDelete,
    required this.showGradesSettings,
    required this.showGradesDiagram,
    required this.showAllSubjectsAverage,
    required this.showSubjectAverage,
    required this.dashboardMarkNewOrChangedEntries,
    required this.dashboardDeduplicateEntries,
    required this.dashboardColorBorders,
    required this.calendarColorBackground,
    required this.calendarShowTimes,
    this.calendarShowAllDetails = false,
    required this.dashboardViewMode,
    required this.classbookViewMode,
    this.classbookDisplayMode = EntryDisplayMode.list,
    this.homeworkViewMode = ClassbookViewMode.chronological,
    this.homeworkDisplayMode = EntryDisplayMode.list,
    this.absencesDisplayMode = EntryDisplayMode.list,
    this.gradesDisplayMode = EntryDisplayMode.list,
    required this.dashboardColorTestsInRed,
    required this.starColor,
    this.notificationsEnabled = true,
    this.notificationPollMinutes = 30,
    this.notifyClassbook = true,
    this.notifyMessages = true,
    this.notifyGrades = true,
    this.notifyObservations = true,
    this.notifyHomework = true,
    this.language,
    required this.allSubjects,
    required this.ignoreForGradesAverage,
    required this.demoMode,
  });

  factory SettingsViewModel.from(
          SettingsState s, List<String> allSubjects, bool isDemo) =>
      SettingsViewModel(
        noPassSaving: s.noPasswordSaving,
        keepPageOnAccountSwitch: s.keepPageOnAccountSwitch,
        accentBackground: s.accentBackground,
        askWhenDelete: s.askWhenDelete,
        showGradesSettings: s.scrollToGrades,
        showGradesDiagram: s.showGradesDiagram,
        showAllSubjectsAverage: s.showAllSubjectsAverage,
        showSubjectAverage: s.showSubjectAverage,
        dashboardMarkNewOrChangedEntries: s.dashboardMarkNewOrChangedEntries,
        dashboardDeduplicateEntries: s.dashboardDeduplicateEntries,
        dashboardColorBorders: s.dashboardColorBorders,
        calendarColorBackground: s.calendarColorBackground,
        calendarShowTimes: s.calendarShowTimes,
        calendarShowAllDetails: s.calendarShowAllDetails,
        dashboardViewMode: s.dashboardViewMode,
        classbookViewMode: s.classbookViewMode,
        classbookDisplayMode: s.classbookDisplayMode,
        homeworkViewMode: s.homeworkViewMode,
        homeworkDisplayMode: s.homeworkDisplayMode,
        absencesDisplayMode: s.absencesDisplayMode,
        gradesDisplayMode: s.gradesDisplayMode,
        dashboardColorTestsInRed: s.dashboardColorTestsInRed,
        starColor: s.starColor,
        notificationsEnabled: s.notificationsEnabled,
        notificationPollMinutes: s.notificationPollMinutes,
        notifyClassbook: s.notifyClassbook,
        notifyMessages: s.notifyMessages,
        notifyGrades: s.notifyGrades,
        notifyObservations: s.notifyObservations,
        notifyHomework: s.notifyHomework,
        language: s.language,
        allSubjects: allSubjects,
        ignoreForGradesAverage: s.ignoreForGradesAverage,
        demoMode: isDemo,
      );
}
