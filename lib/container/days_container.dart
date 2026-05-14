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

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:dr/actions/app_actions.dart';
import 'package:dr/app_state.dart';
import 'package:dr/data.dart';
import 'package:dr/main.dart' show showSnackBar;
import 'package:dr/providers/dashboard_error_provider.dart';
import 'package:dr/providers/dashboard_provider.dart';
import 'package:dr/providers/login_provider.dart';
import 'package:dr/providers/no_internet_provider.dart';
import 'package:dr/providers/notifications_provider.dart';
import 'package:dr/providers/settings_provider.dart';
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
    final settings = ref.watch(settingsProvider);
    final loginLoading = ref.watch(loginProvider.select((s) => s.loading));
    final showNotifications = ref.watch(notificationsProvider.select((s) => s.notifications.isNotEmpty));
    ref.listen<String?>(dashboardErrorProvider, (_, error) {
      if (error != null) {
        showSnackBar(error);
        ref.read(dashboardErrorProvider.notifier).state = null;
      }
    });
    final notifier = ref.read(dashboardProvider.notifier);
    return StoreConnection<AppState, AppActions, Object>(
      connect: (_) => const Object(),
      builder: (context, _, actions) {
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

        final vm = DaysViewModel.from(
          dashboard,
          noInternet,
          loginLoading,
          showNotifications,
          settings,
          unorderedDays,
          blacklist,
        );

        return DaysWidget(
          vm: vm,
          onSwitchFuture: notifier.switchFuture,
          refresh: notifier.refresh,
          addReminderCallback: (day, msg) =>
              notifier.addReminder(day.date, msg),
          removeReminderCallback: (hw, day) => notifier.deleteHomework(hw),
          toggleDoneCallback: (hw, done) =>
              notifier.toggleDone(hw.id, hw.type.name, done),
            setDoNotAskWhenDeleteCallback: () =>
              ref.read(settingsProvider.notifier).setAskWhenDelete(false),
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

  static DaysViewModel from(
    DashboardState dashboard,
    bool noInternet,
    bool loginLoading,
    bool showNotifications,
    SettingsState settings,
    List<Day> unorderedDays,
    BuiltList<HomeworkType> blacklist,
  ) =>
      DaysViewModel(
        (b) => b
          ..days = ListBuilder(
            !dashboard.future ? unorderedDays.reversed : unorderedDays,
          )
          ..noInternet = noInternet
          ..future = dashboard.future
          ..loading = dashboard.loading || loginLoading
          ..askWhenDelete = settings.askWhenDelete
          ..showAddReminder = !blacklist.contains(HomeworkType.homework)
          ..showNotifications = showNotifications
          ..colorBorders = settings.dashboardColorBorders
          ..colorTestsInRed = settings.dashboardColorTestsInRed
          ..subjectThemes = settings.subjectThemes.toBuilder(),
      );
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
