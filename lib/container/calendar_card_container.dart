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

import 'package:dr/app_state.dart';
import 'package:dr/providers/calendar_provider.dart';
import 'package:dr/providers/no_internet_provider.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/ui/calendar_card.dart';
import 'package:dr/utc_date_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CalendarCardContainer extends ConsumerWidget {
  final int hourIndex;
  final UtcDateTime day;

  const CalendarCardContainer({
    super.key,
    required this.hourIndex,
    required this.day,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarState = ref.watch(calendarProvider);
    final noInternet = ref.watch(noInternetProvider);
    final hour = calendarState.days[day]!.hours[hourIndex];
    final theme =
      ref.watch(settingsProvider).subjectThemes[hour.subject] ?? SubjectTheme();
    return CalendarCard(
      hour: hour,
      theme: theme,
      selected: calendarState.selection?.date == day &&
          calendarState.selection?.hour == hour.fromHour,
      onOpenFile: (submission) =>
          ref.read(calendarProvider.notifier).openLessonFile(submission),
      noInternet: noInternet,
    );
  }
}
