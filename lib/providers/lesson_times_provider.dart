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
import 'package:dr/lesson_times.dart';
import 'package:dr/providers/calendar_provider.dart';
import 'package:dr/providers/login_provider.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/util.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The key of the school the signed-in account belongs to; null before login.
final schoolKeyProvider = Provider<String?>((ref) {
  final url = ref.watch(loginProvider.select((s) => s.url));
  return url == null ? null : serverKey(url);
});

/// What the school set itself, nothing where it kept the portal's times.
final lessonTimeOverridesProvider = Provider<LessonTimes>((ref) {
  final school = ref.watch(schoolKeyProvider);
  final all = ref.watch(settingsProvider.select((s) => s.lessonTimes));
  return all[school] ?? const {};
});

/// The times of each hour as the portal sends them, from the loaded weeks.
final portalLessonTimesProvider = Provider<LessonTimes>(
  (ref) => portalLessonTimes(
    ref.watch(calendarProvider.select((s) => s.days)).values,
  ),
);

/// The times to show: the portal's, with the school's own on top.
final lessonTimesProvider = Provider<LessonTimes>(
  (ref) => {
    ...ref.watch(portalLessonTimesProvider),
    ...ref.watch(lessonTimeOverridesProvider),
  },
);

/// The calendar as the screens show it: the loaded days with the school's own
/// lesson times. The stored state keeps the portal's, so taking an entry back
/// needs no reload.
final displayCalendarProvider = Provider<CalendarState>((ref) {
  final calendar = ref.watch(calendarProvider);
  final overrides = ref.watch(lessonTimeOverridesProvider);
  if (overrides.isEmpty) return calendar;
  return calendar.rebuild(
    (b) => b.days.updateAllValues((_, day) => applyLessonTimes(day, overrides)),
  );
});
