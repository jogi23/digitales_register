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

import 'package:collection/collection.dart';
import 'package:dr/actions/app_actions.dart';
import 'package:dr/app_state.dart';
import 'package:dr/providers/calendar_provider.dart';
import 'package:dr/providers/no_internet_provider.dart';
import 'package:dr/ui/calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_built_redux/flutter_built_redux.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CalendarContainer extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarState = ref.watch(calendarProvider);
    final noInternet = ref.watch(noInternetProvider);
    return StoreConnection<AppState, AppActions, _SettingsVM>(
      builder: (context, settingsVm, actions) {
        final currentDays = calendarState.currentDays;
        final vm = CalendarViewModel(
          first: currentDays.isEmpty ? null : currentDays.first.date,
          last: currentDays.isEmpty ? null : currentDays.last.date,
          currentMonday: calendarState.currentMonday!,
          showEditNicksBar: currentDays.any(
                (day) => day.hours.any(
                  (hour) => settingsVm.subjectNicks.entries.none(
                    (entry) => equalsIgnoreAsciiCase(entry.key, hour.subject),
                  ),
                ),
              ) &&
              settingsVm.showCalendarNicksBar,
          noInternet: noInternet,
          selection: calendarState.selection,
        );
        return Calendar(
          vm: vm,
          showEditSubjectNicks:
              actions.routingActions.showEditCalendarSubjectNicks.call,
          closeEditNicksBar: () =>
              actions.settingsActions.showCalendarSubjectNicksBar(false),
          dayCallback: (monday) =>
              ref.read(calendarProvider.notifier).load(monday),
          currentMondayCallback: (monday) =>
              ref.read(calendarProvider.notifier).setCurrentMonday(monday),
        );
      },
      connect: (state) => _SettingsVM(
        subjectNicks: state.settingsState.subjectNicks.toMap(),
        showCalendarNicksBar: state.settingsState.showCalendarNicksBar,
      ),
    );
  }
}

class _SettingsVM {
  final Map<String, String> subjectNicks;
  final bool showCalendarNicksBar;
  _SettingsVM({
    required this.subjectNicks,
    required this.showCalendarNicksBar,
  });
}
