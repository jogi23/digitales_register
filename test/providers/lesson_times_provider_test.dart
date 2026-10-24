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
import 'package:dr/app_state.dart';
import 'package:dr/data.dart';
import 'package:dr/lesson_times.dart';
import 'package:dr/providers/calendar_provider.dart';
import 'package:dr/providers/lesson_times_provider.dart';
import 'package:dr/providers/login_provider.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/utc_date_time.dart';
import 'package:dr/util.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _school = 'https://a.example.it';

ProviderContainer _container() {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  c.read(loginProvider.notifier).setUrl('$_school/');
  c.read(calendarProvider.notifier).restore(
        CalendarState(
          (b) => b.days.addAll({
            UtcDateTime(2026, 10, 5): CalendarDay(
              (d) => d
                ..date = UtcDateTime(2026, 10, 5)
                ..hours = ListBuilder([
                  CalendarHour(
                    (h) => h
                      ..fromHour = 1
                      ..toHour = 1
                      ..subject = 'Mathe'
                      ..timeSpans = ListBuilder([
                        TimeSpan(
                          (t) => t
                            ..from = UtcDateTime(2026, 10, 5, 8)
                            ..to = UtcDateTime(2026, 10, 5, 8, 50),
                        ),
                      ])
                      ..rooms = ListBuilder()
                      ..homeworkExams = ListBuilder()
                      ..lessonContents = ListBuilder()
                      ..teachers = ListBuilder(),
                  ),
                ]),
            ),
          }),
        ),
      );
  return c;
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  test('without entries the times are the portal\'s', () {
    expect(
      _container().read(lessonTimesProvider),
      {1: const LessonTime(480, 530)},
    );
  });

  test('an entry of the signed-in school wins over the portal', () {
    final c = _container();
    c
        .read(settingsProvider.notifier)
        .setLessonTimes(serverKey(_school), {1: const LessonTime(490, 540)});
    expect(c.read(lessonTimesProvider)[1], const LessonTime(490, 540));
  });

  test('an entry of another school does not count', () {
    final c = _container();
    c.read(settingsProvider.notifier).setLessonTimes(
        serverKey('https://b.example.it'), {1: const LessonTime(490, 540)});
    expect(c.read(lessonTimesProvider)[1], const LessonTime(480, 530));
  });

  test('the displayed calendar carries the entry, the stored one does not', () {
    final c = _container();
    c
        .read(settingsProvider.notifier)
        .setLessonTimes(serverKey(_school), {1: const LessonTime(490, 540)});
    final shown = c.read(displayCalendarProvider);
    expect(
      shown.days.values.single.hours.single.timeSpans.single.from,
      UtcDateTime(2026, 10, 5, 8, 10),
    );
    expect(
      c
          .read(calendarProvider)
          .days
          .values
          .single
          .hours
          .single
          .timeSpans
          .single
          .from,
      UtcDateTime(2026, 10, 5, 8),
    );
  });

  test('resetting brings the portal times back', () {
    final c = _container();
    final settings = c.read(settingsProvider.notifier);
    final key = serverKey(_school);
    settings.setLessonTimes(key, {1: const LessonTime(490, 540)});
    settings.resetLessonTime(key, 1);
    expect(c.read(lessonTimesProvider)[1], const LessonTime(480, 530));
    expect(c.read(settingsProvider).lessonTimes, isEmpty);
  });
}
