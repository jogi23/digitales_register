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
import 'package:dr/data.dart';
import 'package:dr/ui/calendar_grid.dart';
import 'package:dr/utc_date_time.dart';
import 'package:flutter_test/flutter_test.dart';

final _date = UtcDateTime.parse("2025-10-20 00:00:00");

UtcDateTime _at(String hhmm, {int dayOffset = 0}) {
  final parts = hhmm.split(":");
  return UtcDateTime(_date.year, _date.month, _date.day + dayOffset,
      int.parse(parts[0]), int.parse(parts[1]));
}

/// A lesson covering [fromHour]..[toHour] with one time span per hour.
CalendarHour _lesson(int fromHour, int toHour, List<String> times,
    {int dayOffset = 0}) {
  return CalendarHour(
    (b) => b
      ..fromHour = fromHour
      ..toHour = toHour
      ..subject = "Deutsch"
      ..rooms = ListBuilder<String>()
      ..homeworkExams = ListBuilder<HomeworkExam>()
      ..lessonContents = ListBuilder<LessonContent>()
      ..timeSpans = ListBuilder<TimeSpan>([
        for (var i = 0; i < times.length; i += 2)
          TimeSpan((b) => b
            ..from = _at(times[i], dayOffset: dayOffset)
            ..to = _at(times[i + 1], dayOffset: dayOffset)),
      ]),
  );
}

CalendarDay _day(List<CalendarHour> hours, {int dayOffset = 0}) => CalendarDay(
      (b) => b
        ..date = _at("00:00", dayOffset: dayOffset)
        ..hours = ListBuilder<CalendarHour>(hours),
    );

void main() {
  group('slots', () {
    test('one slot per hour number when there are no gaps', () {
      final grid = CalendarGrid.fromDays([
        _day([
          _lesson(1, 1, ["07:50", "08:45"]),
          _lesson(2, 2, ["08:45", "09:35"]),
        ])
      ], 2);
      expect(grid.slots.whereType<LessonSlot>().length, 2);
      expect(grid.slots.whereType<BreakSlot>(), isEmpty);
    });

    test('a gap between consecutive hours becomes a break', () {
      // 6th ends 12:30, 7th starts 13:30 -> lunch break.
      final grid = CalendarGrid.fromDays([
        _day([
          _lesson(6, 6, ["11:40", "12:30"]),
          _lesson(7, 7, ["13:30", "14:20"]),
        ])
      ], 7);
      final breaks = grid.slots.whereType<BreakSlot>().toList();
      expect(breaks, hasLength(1));
      expect(breaks.single.duration, const Duration(minutes: 60));
      expect(grid.breakAfter(6), isTrue);
      expect(grid.breakAfter(7), isFalse);
    });

    test('a skipped hour number is not a break', () {
      // A cancelled 2nd lesson: the grid already shows empty space for it.
      final grid = CalendarGrid.fromDays([
        _day([
          _lesson(1, 1, ["07:50", "08:45"]),
          _lesson(3, 3, ["09:35", "10:25"]),
        ])
      ], 3);
      expect(grid.slots.whereType<BreakSlot>(), isEmpty);
      expect(grid.breakAfter(1), isFalse);
    });

    test('gaps shorter than the minimum are ignored', () {
      final grid = CalendarGrid.fromDays([
        _day([
          _lesson(1, 1, ["07:50", "08:45"]),
          _lesson(2, 2, ["08:50", "09:35"]),
        ])
      ], 2);
      expect(grid.slots.whereType<BreakSlot>(), isEmpty);
    });

    test('a double lesson gets one time per hour number', () {
      final grid = CalendarGrid.fromDays([
        _day([
          _lesson(1, 2, ["07:50", "08:45", "08:45", "09:35"]),
        ])
      ], 2);
      final lessons = grid.slots.whereType<LessonSlot>().toList();
      expect(lessons[0].time!.from, _at("07:50"));
      expect(lessons[1].time!.from, _at("08:45"));
    });

    test('times are collected across all days of the week', () {
      // Monday ends after the 6th, only Tuesday reveals the lunch break.
      final monday = _day([_lesson(6, 6, ["11:40", "12:30"])]);
      final tuesday = _day([
        _lesson(6, 6, ["11:40", "12:30"]),
        _lesson(7, 7, ["13:30", "14:20"]),
      ]);
      final grid = CalendarGrid.fromDays([monday, tuesday], 7);
      expect(grid.breakAfter(6), isTrue);
    });

    test('a break across two days measures the time of day, not the date', () {
      // Monday has no 7th hour, so it comes from Tuesday. Subtracting the
      // timestamps naively would yield 25 hours instead of one.
      final grid = CalendarGrid.fromDays([
        _day([_lesson(6, 6, ["11:40", "12:30"])]),
        _day([_lesson(7, 7, ["13:30", "14:20"], dayOffset: 1)], dayOffset: 1),
      ], 7);
      expect(
        grid.slots.whereType<BreakSlot>().single.duration,
        const Duration(minutes: 60),
      );
    });

    test('hasTimes is false when the server sent none', () {
      final grid = CalendarGrid.fromDays([
        _day([_lesson(1, 1, const [])])
      ], 1);
      expect(grid.hasTimes, isFalse);
    });
  });

  group('flex', () {
    // 1st, 2nd, break, 3rd
    final grid = CalendarGrid.fromDays([
      _day([
        _lesson(1, 1, ["07:50", "08:45"]),
        _lesson(2, 2, ["08:45", "09:35"]),
        _lesson(3, 3, ["10:45", "11:40"]),
      ])
    ], 3);

    test('total counts lessons and breaks', () {
      expect(grid.totalFlex, 2 + 2 + 1 + 2);
    });

    test('nothing lies before the first hour', () {
      expect(grid.flexBefore(1), 0);
    });

    test('a break counts towards the hour that follows it', () {
      expect(grid.flexThrough(2), 4);
      expect(grid.flexBefore(3), 5); // includes the break
      expect(grid.flexThrough(3), 7);
    });

    test('the space between two chunks includes the break', () {
      // Chunk 1..2, then chunk 3: the gap between them is the break alone.
      expect(grid.flexBefore(3) - grid.flexThrough(2), 1);
    });
  });
}
