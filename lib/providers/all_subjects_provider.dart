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

import 'package:dr/providers/calendar_provider.dart';
import 'package:dr/providers/dashboard_provider.dart';
import 'package:dr/providers/grades_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Computed list of all known subject names across grades, calendar and dashboard.
/// Used by settings to show subject-specific options (themes, nicks, averages).
final allSubjectsProvider = Provider<List<String>>((ref) {
  final grades = ref.watch(gradesProvider);
  final calendar = ref.watch(calendarProvider);
  final dashboard = ref.watch(dashboardProvider);
  final subjects = <String>{};
  for (final subject in grades.subjects) {
    subjects.add(subject.name);
  }
  for (final day in calendar.days.values) {
    for (final hour in day.hours) {
      subjects.add(hour.subject);
    }
  }
  final allDays = dashboard.allDays;
  if (allDays != null) {
    for (final day in allDays) {
      for (final homework in day.homework) {
        if (homework.label != null) subjects.add(homework.label!);
      }
    }
  }
  return subjects.toList();
});
