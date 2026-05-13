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
import 'package:dr/data.dart';
import 'package:dr/providers/calendar_provider.dart';
import 'package:dr/providers/no_internet_provider.dart';
import 'package:dr/ui/calendar_week.dart';
import 'package:dr/utc_date_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_built_redux/flutter_built_redux.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CalendarWeekContainer extends ConsumerWidget {
  final UtcDateTime monday;

  const CalendarWeekContainer({
    super.key,
    required this.monday,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarState = ref.watch(calendarProvider);
    final noInternet = ref.watch(noInternetProvider);
    return StoreConnection<AppState, AppActions, _SettingsVM>(
      builder: (context, settingsVm, actions) {
        final vm = CalendarWeekViewModel(
          days: BuiltList(calendarState.daysForWeek(monday)),
          subjectNicks: BuiltMap(
            settingsVm.subjectNicks.map(
              (key, value) => MapEntry(key.toLowerCase(), value),
            ),
          ),
          noInternet: noInternet,
          selection: calendarState.selection,
          colorBackground: settingsVm.colorBackground,
          subjectThemes: BuiltMap(settingsVm.subjectThemes),
        );
        return CalendarWeek(
          vm: vm,
          key: key,
        );
      },
      connect: (state) => _SettingsVM(
        subjectNicks: state.settingsState.subjectNicks.toMap(),
        colorBackground: state.settingsState.calendarColorBackground,
        subjectThemes: state.settingsState.subjectThemes.toMap(),
      ),
    );
  }
}

class _SettingsVM {
  final Map<String, String> subjectNicks;
  final bool colorBackground;
  final Map<String, SubjectTheme> subjectThemes;
  _SettingsVM({
    required this.subjectNicks,
    required this.colorBackground,
    required this.subjectThemes,
  });
}

class CalendarWeekViewModel {
  final BuiltList<CalendarDay> days;
  final BuiltMap<String, String> subjectNicks;
  final bool noInternet;
  final CalendarSelection? selection;
  final bool colorBackground;
  final BuiltMap<String, SubjectTheme> subjectThemes;

  CalendarWeekViewModel({
    required this.days,
    required this.subjectNicks,
    required this.noInternet,
    required this.selection,
    required this.colorBackground,
    required this.subjectThemes,
  });
}
