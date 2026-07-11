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
import 'package:dr/data.dart';
import 'package:dr/providers/calendar_provider.dart';
import 'package:dr/providers/no_internet_provider.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/providers/subject_appearance_provider.dart';
import 'package:dr/ui/calendar_week.dart';
import 'package:dr/utc_date_time.dart';
import 'package:flutter/material.dart';
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
    final settings = ref.watch(settingsProvider);
    final subjectAppearance = ref.watch(subjectAppearanceProvider);
    final vm = CalendarWeekViewModel(
      days: calendarState.daysForWeek(monday).toList(),
      subjectNicks: subjectAppearance.nicks,
      noInternet: noInternet,
      selection: calendarState.selection,
      colorBackground: settings.calendarColorBackground,
      subjectThemes: subjectAppearance.themes,
    );
    return CalendarWeek(vm: vm, key: key);
  }
}

class CalendarWeekViewModel {
  final List<CalendarDay> days;
  final Map<String, String> subjectNicks;
  final bool noInternet;
  final CalendarSelection? selection;
  final bool colorBackground;
  final Map<String, SubjectTheme> subjectThemes;

  CalendarWeekViewModel({
    required this.days,
    required this.subjectNicks,
    required this.noInternet,
    required this.selection,
    required this.colorBackground,
    required this.subjectThemes,
  });
}
