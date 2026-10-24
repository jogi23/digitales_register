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
import 'package:intl/intl.dart';

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
    test('a double lesson with a single span is no time of its own', () {
      final times = portalLessonTimes([
        _day([
          _hour(3, 4, [_span(9, 55, 11, 45)]),
          _hour(5, 5, [_span(12, 0, 12, 50)]),
        ]),
      ]);
      expect(times.keys, [5]);
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

    test(
        'keeps the portal span where an override would end it before it begins',
        () {
      final day = _day([
        _hour(1, 2, [_span(8, 0, 9, 45)]),
      ]);
      // Only the begin of hour 1 is set, past the portal's end.
      final result = applyLessonTimes(day, {1: const LessonTime(600, 650)});
      expect(result.hours.single.timeSpans.single, _span(8, 0, 9, 45));
    });

    test('an entry for another hour leaves the day as it is', () {
      final day = _day([
        _hour(1, 1, [_span(8, 0, 8, 50)]),
      ]);
      expect(
        identical(applyLessonTimes(day, {7: const LessonTime(1, 2)}), day),
        isTrue,
      );
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

  group('absenceRangeText', () {
    final format = DateFormat('d.M.');
    const times = {
      3: LessonTime(595, 645),
      5: LessonTime(705, 755),
    };
    String text(
      DateTime startDate,
      int startHour,
      DateTime endDate,
      int endHour, [
      LessonTimes t = times,
    ]) =>
        absenceRangeText(
          dateFormat: format,
          startDate: startDate,
          startHour: startHour,
          endDate: endDate,
          endHour: endHour,
          times: t,
        );

    final monday = DateTime(2026, 2, 2);
    final tuesday = DateTime(2026, 2, 3);

    test('one lesson', () {
      expect(text(monday, 3, monday, 3), '2.2., 3. h (09:55)');
    });

    test('several lessons of one day', () {
      expect(text(monday, 3, monday, 5), '2.2., 3. - 5. h (09:55–12:35)');
    });

    test('several days name the begin of both lessons', () {
      expect(
        text(monday, 3, tuesday, 5),
        '2.2. 3. h (09:55) - 3.2. 5. h (11:45)',
      );
    });

    test('without times the text is as it was', () {
      expect(text(monday, 3, monday, 5, const {}), '2.2., 3. - 5. h');
    });
  });

  group('editLessonTime', () {
    const times = {
      1: LessonTime(480, 530),
      2: LessonTime(535, 585),
      3: LessonTime(600, 650),
    };

    test('a new start moves the end along, the lesson keeps its length', () {
      expect(
          editLessonTime(times, 3, start: 610)![3], const LessonTime(610, 660));
    });

    test('a new end leaves the start alone', () {
      expect(
          editLessonTime(times, 3, end: 655)![3], const LessonTime(600, 655));
    });

    test('a new end sets the start of the next lesson, which keeps its length',
        () {
      final changes = editLessonTime(times, 1, end: 540)!;
      expect(changes[1], const LessonTime(480, 540));
      expect(changes[2], const LessonTime(540, 590));
    });

    test('the next start never changes the end before it', () {
      final changes = editLessonTime(times, 3, start: 620)!;
      expect(changes.keys, [3]);
      expect(editLessonTime(times, 2, start: 535, end: null), const {});
    });

    test('the following lessons are pulled along one after the other', () {
      final changes = editLessonTime(times, 1, start: 490)!;
      expect(changes, {
        1: const LessonTime(490, 540),
        2: const LessonTime(540, 590),
        3: const LessonTime(590, 640),
      });
    });

    test('stops where the next lesson already begins at the new end', () {
      expect(editLessonTime(times, 1, start: 485)!.keys, [1]);
    });

    test('nothing changes where nothing is different', () {
      expect(editLessonTime(times, 2, end: 585), const {});
    });

    test('rejects an end that is not after the start', () {
      expect(editLessonTime(times, 2, end: 535), isNull);
      expect(editLessonTime(times, 2, end: 500), isNull);
    });

    test('rejects a start before the end of an earlier lesson', () {
      expect(editLessonTime(times, 2, start: 520), isNull);
      expect(
          editLessonTime(times, 2, start: 530)![2], const LessonTime(530, 580));
    });

    test('rejects what would run past midnight', () {
      expect(editLessonTime(times, 3, start: 24 * 60 - 10), isNull);
      expect(editLessonTime(times, 1, end: 24 * 60 + 1), isNull);
    });

    test('an hour nobody knows cannot be edited', () {
      expect(editLessonTime(times, 9, start: 600), isNull);
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

    test('a bad entry is skipped, the good ones stay', () {
      final state = SettingsState.fromJson({
        'lessonTimes': {
          'https://a.example.it': {
            '1': [480, 530],
            'x': [1, 2],
            '2': 'kaputt',
            '3': [1],
          },
          'https://b.example.it': 'kaputt',
          'https://c.example.it': {
            '1': ['a', 'b']
          },
        },
      });
      expect(state.lessonTimes, {
        'https://a.example.it': {1: const LessonTime(480, 530)},
      });
    });

    test('equal settings hash equal whatever the order of the schools', () {
      final a = SettingsState(lessonTimes: {
        'a': {1: const LessonTime(1, 2)},
        'b': {1: const LessonTime(3, 4)},
      });
      final b = SettingsState(lessonTimes: {
        'b': {1: const LessonTime(3, 4)},
        'a': {1: const LessonTime(1, 2)},
      });
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
