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
import 'package:built_value/built_value.dart';
import 'package:dr/actions/app_actions.dart';
import 'package:dr/app_state.dart';
import 'package:dr/data.dart';
import 'package:dr/providers/dashboard_provider.dart';
import 'package:dr/providers/no_internet_provider.dart';
import 'package:dr/ui/days.dart';
import 'package:flutter/material.dart' hide Builder;
import 'package:flutter_built_redux/flutter_built_redux.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'days_container.g.dart';

class DaysContainer extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardProvider);
    final noInternet = ref.watch(noInternetProvider);
    final notifier = ref.read(dashboardProvider.notifier);
    return StoreConnection<AppState, AppActions, _ReduxDaysData>(
      connect: _ReduxDaysData.from,
      builder: (context, reduxData, actions) {
        final blacklist = dashboard.blacklist!;
        final unorderedDays = dashboard.allDays
                ?.where((day) => day.future == dashboard.future)
                .map(
                  (day) => day.rebuild(
                    (b) => b
                      ..deletedHomework
                          .where((hw) => !isBlacklisted(hw, blacklist))
                      ..homework.where((hw) => !isBlacklisted(hw, blacklist)),
                  ),
                )
                .toList() ??
            [];

        final vm = DaysViewModel(
          (b) => b
            ..days = ListBuilder(
              !dashboard.future ? unorderedDays.reversed : unorderedDays,
            )
            ..noInternet = noInternet
            ..future = dashboard.future
            ..loading = dashboard.loading || reduxData.loginLoading
            ..askWhenDelete = reduxData.askWhenDelete
            ..showAddReminder = !blacklist.contains(HomeworkType.homework)
            ..showNotifications = reduxData.showNotifications
            ..colorBorders = reduxData.colorBorders
            ..colorTestsInRed = reduxData.colorTestsInRed
            ..subjectThemes = reduxData.subjectThemes.toBuilder(),
        );

        return DaysWidget(
          vm: vm,
          onSwitchFuture: () => notifier.switchFuture(
            markNew: reduxData.markNewOrChanged,
            deduplicate: reduxData.deduplicate,
          ),
          refresh: () => notifier.refresh(
            markNew: reduxData.markNewOrChanged,
            deduplicate: reduxData.deduplicate,
          ),
          addReminderCallback: (day, msg) =>
              notifier.addReminder(day.date, msg),
          removeReminderCallback: (hw, day) => notifier.deleteHomework(hw),
          toggleDoneCallback: (hw, done) =>
              notifier.toggleDone(hw.id, hw.type.name, done),
          setDoNotAskWhenDeleteCallback: () =>
              actions.settingsActions.askWhenDeleteReminder(false),
          markAsSeenCallback: notifier.markAsSeen,
          markDeletedHomeworkAsSeenCallback: notifier.markDeletedHomeworkAsSeen,
          markAllAsSeenCallback: notifier.markAllAsSeen,
          refreshNoInternet: actions.refreshNoInternet.call,
          onOpenAttachment: notifier.openAttachment,
        );
      },
    );
  }
}

class _ReduxDaysData {
  final bool askWhenDelete;
  final bool loginLoading;
  final bool showNotifications;
  final bool colorBorders;
  final bool colorTestsInRed;
  final BuiltMap<String, SubjectTheme> subjectThemes;
  final bool markNewOrChanged;
  final bool deduplicate;

  const _ReduxDaysData({
    required this.askWhenDelete,
    required this.loginLoading,
    required this.showNotifications,
    required this.colorBorders,
    required this.colorTestsInRed,
    required this.subjectThemes,
    required this.markNewOrChanged,
    required this.deduplicate,
  });

  factory _ReduxDaysData.from(AppState state) => _ReduxDaysData(
        askWhenDelete: state.settingsState.askWhenDelete,
        loginLoading: state.loginState.loading,
        showNotifications:
            (state.notificationState.notifications?.length ?? 0) > 0,
        colorBorders: state.settingsState.dashboardColorBorders,
        colorTestsInRed: state.settingsState.dashboardColorTestsInRed,
        subjectThemes: state.settingsState.subjectThemes,
        markNewOrChanged: state.settingsState.dashboardMarkNewOrChangedEntries,
        deduplicate: state.settingsState.dashboardDeduplicateEntries,
      );
}

typedef AddReminderCallback = void Function(Day day, String reminder);
typedef RemoveReminderCallback = void Function(Homework hw, Day day);
typedef ToggleDoneCallback = void Function(Homework hw, bool done);
typedef MarkAsNotNewOrChangedCallback = void Function(Homework hw);
typedef MarkDeletedHomeworkAsSeenCallback = void Function(Day day);
typedef AttachmentCallback = void Function(GradeGroupSubmission ggs);

abstract class DaysViewModel
    implements Built<DaysViewModel, DaysViewModelBuilder> {
  bool get future;
  bool get askWhenDelete;
  bool get noInternet;
  bool get loading;
  bool get showAddReminder;
  bool get colorBorders;
  bool get colorTestsInRed;
  BuiltMap<String, SubjectTheme> get subjectThemes;

  bool get showNotifications;
  BuiltList<Day> get days;

  factory DaysViewModel([void Function(DaysViewModelBuilder)? updates]) =
      _$DaysViewModel;
  DaysViewModel._();
}

// Map all (previously by the server used) homework types to the titles they
// would have been used with. Probably incomplete.
const typesToTitles = {
  HomeworkType.grade: ["Bewertung"],
  HomeworkType.gradeGroup: ["Testarbeit", "Schularbeit", "Prüfung"],
  HomeworkType.homework: ["Erinnerung"],
  HomeworkType.lessonHomework: ["Hausaufgabe"],
  HomeworkType.observation: ["Beobachtung"],
};

bool isBlacklisted(Homework homework, BuiltList<HomeworkType> blacklist) {
  return blacklist.any((blacklisted) {
    return typesToTitles[blacklisted]!
        .any((blacklistedTitle) => homework.title.contains(blacklistedTitle));
  });
}
