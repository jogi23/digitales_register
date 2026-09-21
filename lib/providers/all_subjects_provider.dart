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

import 'package:dr/providers/calendar_provider.dart';
import 'package:dr/providers/dashboard_provider.dart';
import 'package:dr/providers/grades_provider.dart';
import 'package:dr/providers/subject_appearance_provider.dart';
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

/// Containers that already assign colours on their own.
final _listening = Expando<bool>('subject themes');

/// Gives every subject the app learns about a colour, as it learns about it.
///
/// Colours used to be assigned at a few fixed moments — after logging in,
/// when the grades arrived, when the week view opened. The timetable arrives
/// later than any of them, so a subject that shows up nowhere but there
/// stayed colourless: a new account saw a calendar in which some lessons were
/// coloured and some were not (#259).
///
/// Called once per container at startup; assigning a colour that is already
/// there costs nothing.
void keepSubjectThemesUpToDate(ProviderContainer container) {
  if (_listening[container] ?? false) return;
  _listening[container] = true;
  container.listen<List<String>>(
    allSubjectsProvider,
    (previous, next) => unawaited(
      container.read(subjectAppearanceProvider.notifier).ensureThemesFor(next),
    ),
    fireImmediately: true,
  );
}
