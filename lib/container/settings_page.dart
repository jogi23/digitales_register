// Copyright (C) 2021 Michael Debertol
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
import 'package:dr/actions/app_actions.dart';
import 'package:dr/app_state.dart';
import 'package:dr/providers/all_subjects_provider.dart';
import 'package:dr/providers/login_provider.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/ui/settings_page_widget.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_built_redux/flutter_built_redux.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsPageContainer extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final allSubjects = ref.watch(allSubjectsProvider);
    final isDemo = ref.watch(isDemoProvider);
    final vm = SettingsViewModel.from(settings, allSubjects, isDemo);
    return StoreConnection<AppState, AppActions, Object>(
      connect: (_) => const Object(),
      builder: (context, _, actions) {
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
          onSetPlatformOverride: (o) {
            DynamicTheme.of(context)!.setPlatformOverride(o);
          },
          onSetNoPassSaving: notifier.setSaveNoPass,
          onSetNoDataSaving: notifier.setSaveNoData,
          onSetAskWhenDelete: notifier.setAskWhenDelete,
          onSetDeleteDataOnLogout: notifier.setDeleteDataOnLogout,
          onSetSubjectNicks: (map) => notifier.setSubjectNicks(BuiltMap(map)),
          onSetShowCalendarEditNicksBar: notifier.setShowCalendarNicksBar,
          onSetShowGradesDiagram: notifier.setShowGradesDiagram,
          onSetShowAllSubjectsAverage: notifier.setShowAllSubjectsAverage,
          onSetDashboardMarkNewOrChangedEntries: notifier.setMarkNewOrChanged,
          onSetDashboardDeduplicateEntries: notifier.setDeduplicate,
          onShowProfile: actions.routingActions.showProfile.call,
          onSetIgnoreForGradesAverage: (list) =>
              notifier.setIgnoreForGradesAverage(BuiltList(list)),
          onSetDashboardColorBorders: notifier.setDashboardColorBorders,
          onSetCalenderColorBackground: notifier.setCalendarColorBackground,
          onSetDashboardColorTestsInRed: notifier.setDashboardColorTestsInRed,
          onSetSubjectTheme: notifier.setSubjectTheme,
        );
      },
    );
  }
}

typedef OnSettingChanged<T> = void Function(T newValue);

class SettingsViewModel {
  final Map<String, String> subjectNicks;
  final bool noPassSaving;
  final bool noDataSaving;
  final bool askWhenDelete;
  final bool deleteDataOnLogout;
  final bool showCalendarEditNicksBar;
  final bool showGradesDiagram;
  final bool showAllSubjectsAverage;
  final bool dashboardMarkNewOrChangedEntries;
  final bool dashboardDeduplicateEntries;
  final bool showSubjectNicks;
  final bool showGradesSettings;
  final bool dashboardColorBorders;
  final bool calendarColorBackground;
  final bool dashboardColorTestsInRed;
  final bool demoMode;
  final List<String> allSubjects;
  final List<String> ignoreForGradesAverage;
  final BuiltMap<String, SubjectTheme> subjectThemes;

  const SettingsViewModel({
    required this.noPassSaving,
    required this.noDataSaving,
    required this.askWhenDelete,
    required this.deleteDataOnLogout,
    required this.subjectNicks,
    required this.showSubjectNicks,
    required this.showGradesSettings,
    required this.showCalendarEditNicksBar,
    required this.showGradesDiagram,
    required this.showAllSubjectsAverage,
    required this.dashboardMarkNewOrChangedEntries,
    required this.dashboardDeduplicateEntries,
    required this.dashboardColorBorders,
    required this.calendarColorBackground,
    required this.dashboardColorTestsInRed,
    required this.allSubjects,
    required this.ignoreForGradesAverage,
    required this.subjectThemes,
    required this.demoMode,
  });

  factory SettingsViewModel.from(
          SettingsState s, List<String> allSubjects, bool isDemo) =>
      SettingsViewModel(
        noPassSaving: s.noPasswordSaving,
        noDataSaving: s.noDataSaving,
        askWhenDelete: s.askWhenDelete,
        deleteDataOnLogout: s.deleteDataOnLogout,
        subjectNicks: s.subjectNicks.toMap(),
        showSubjectNicks: s.scrollToSubjectNicks,
        showGradesSettings: s.scrollToGrades,
        showCalendarEditNicksBar: s.showCalendarNicksBar,
        showGradesDiagram: s.showGradesDiagram,
        showAllSubjectsAverage: s.showAllSubjectsAverage,
        dashboardMarkNewOrChangedEntries: s.dashboardMarkNewOrChangedEntries,
        dashboardDeduplicateEntries: s.dashboardDeduplicateEntries,
        dashboardColorBorders: s.dashboardColorBorders,
        calendarColorBackground: s.calendarColorBackground,
        dashboardColorTestsInRed: s.dashboardColorTestsInRed,
        allSubjects: allSubjects,
        ignoreForGradesAverage: s.ignoreForGradesAverage.toList(),
        subjectThemes: s.subjectThemes,
        demoMode: isDemo,
      );
}
