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
import 'package:dr/utc_date_time.dart';
import 'package:dr/util.dart';
import 'package:flutter_test/flutter_test.dart';

TimeSpan _span(int fromH, int fromM, int toH, int toM) => TimeSpan(
      (b) => b
        ..from = UtcDateTime(2026, 10, 5, fromH, fromM)
        ..to = UtcDateTime(2026, 10, 5, toH, toM),
    );

CalendarHour _hour(int from, int to, List<TimeSpan> spans) => CalendarHour(
      (b) => b
        ..fromHour = from
        ..toHour = to
        ..subject = 'Mathe'
        ..timeSpans = ListBuilder(spans)
        ..rooms = ListBuilder()
        ..homeworkExams = ListBuilder()
        ..lessonContents = ListBuilder()
        ..teachers = ListBuilder(),
    );

CalendarDay _day(List<CalendarHour> hours) => CalendarDay(
      (b) => b
        ..date = UtcDateTime(2026, 10, 5)
        ..hours = ListBuilder(hours),
    );

void main() {
  group('LessonTime', () {
    test('formats minutes of the day as HH:mm', () {
      expect(formatMinutes(8 * 60 + 5), '08:05');
      expect(formatMinutes(13 * 60), '13:00');
    });

    test('survives a trip through json', () {
      const time = LessonTime(480, 530);
      expect(LessonTime.fromJson(time.toJson()), time);
    });
  });

  group('serverKey', () {
    test('ignores spelling, path and case of the same server', () {
      expect(
        serverKey('https://School.example.it/'),
        serverKey('https://school.example.it/v2/login'),
      );
    });

    test('keeps different servers apart', () {
      expect(
        serverKey('https://a.example.it'),
        isNot(serverKey('https://b.example.it')),
      );
    });
  });

  group('portalLessonTimes', () {
    test('takes the times of each hour number, double lessons per hour', () {
      final times = portalLessonTimes([
        _day([
          _hour(1, 2, [_span(8, 0, 8, 50), _span(8, 55, 9, 45)]),
          _hour(3, 3, [_span(10, 0, 10, 50)]),
        ]),
      ]);
      expect(times[1], const LessonTime(480, 530));
      expect(times[2], const LessonTime(535, 585));
      expect(times[3], const LessonTime(600, 650));
    });
  });

  group('applyLessonTimes', () {
    test('replaces the times of the hours that have an entry', () {
      final day = _day([
        _hour(1, 2, [_span(8, 0, 8, 50), _span(8, 55, 9, 45)]),
      ]);
      final result = applyLessonTimes(day, {
        2: const LessonTime(9 * 60, 9 * 60 + 50),
      });
      final spans = result.hours.single.timeSpans;
      expect(spans[0], _span(8, 0, 8, 50));
      expect(spans[1], _span(9, 0, 9, 50));
    });

    test('keeps the date of the span', () {
      final day = _day([
        _hour(1, 1, [_span(8, 0, 8, 50)]),
      ]);
      final span = applyLessonTimes(day, {1: const LessonTime(500, 550)})
          .hours
          .single
          .timeSpans
          .single;
      expect(span.from, UtcDateTime(2026, 10, 5, 8, 20));
      expect(span.to, UtcDateTime(2026, 10, 5, 9, 10));
    });

    test('a single span over a double lesson runs from first to last hour', () {
      final day = _day([
        _hour(1, 2, [_span(8, 0, 9, 45)]),
      ]);
      final span = applyLessonTimes(day, {
        1: const LessonTime(480, 530),
        2: const LessonTime(540, 590),
      }).hours.single.timeSpans.single;
      expect(span, _span(8, 0, 9, 50));
    });

    test('without entries the day is returned as it is', () {
      final day = _day([
        _hour(1, 1, [_span(8, 0, 8, 50)]),
      ]);
      expect(identical(applyLessonTimes(day, const {}), day), isTrue);
    });
  });

  group('lessonTimeNote', () {
    const times = {
      3: LessonTime(595, 645),
      5: LessonTime(705, 755),
    };

    test('one hour names its begin', () {
      expect(lessonTimeNote(times, 3, 3), ' (09:55)');
    });

    test('several hours run from the first begin to the last end', () {
      expect(lessonTimeNote(times, 3, 5), ' (09:55–12:35)');
    });

    test('a last hour without time falls back to the begin', () {
      expect(lessonTimeNote(times, 3, 4), ' (09:55)');
    });

    test('an unknown first hour leaves the note out', () {
      expect(lessonTimeNote(times, 4, 5), '');
    });
  });

  group('lessonTimeFits', () {
    const times = {
      1: LessonTime(480, 530),
      2: LessonTime(540, 590),
      3: LessonTime(600, 650),
    };

    test('accepts a time between its neighbours', () {
      expect(lessonTimeFits(times, 2, const LessonTime(535, 595)), isTrue);
    });

    test('rejects an end before the start', () {
      expect(lessonTimeFits(times, 2, const LessonTime(590, 540)), isFalse);
      expect(lessonTimeFits(times, 2, const LessonTime(540, 540)), isFalse);
    });

    test('rejects an overlap with the previous or next hour', () {
      expect(lessonTimeFits(times, 2, const LessonTime(520, 590)), isFalse);
      expect(lessonTimeFits(times, 2, const LessonTime(540, 610)), isFalse);
    });

    test('has no neighbours for the first and last hour', () {
      expect(lessonTimeFits(times, 1, const LessonTime(0, 100)), isTrue);
      expect(lessonTimeFits(times, 3, const LessonTime(600, 1000)), isTrue);
    });
  });

  group('lessonTimes setting', () {
    test('is kept per school and survives json', () {
      final state = SettingsState(lessonTimes: {
        'https://a.example.it': {1: const LessonTime(480, 530)},
      });
      final back = SettingsState.fromJson(state.toJson());
      expect(back.lessonTimes, state.lessonTimes);
      expect(back, state);
    });

    test('is app-wide', () {
      final state = SettingsState(lessonTimes: {
        'https://a.example.it': {1: const LessonTime(480, 530)},
      });
      expect(
        SettingsState().withGlobalsFrom(state).lessonTimes,
        state.lessonTimes,
      );
    });

    test('older json without it gives none', () {
      expect(SettingsState.fromJson(const {}).lessonTimes, isEmpty);
    });
  });
}
