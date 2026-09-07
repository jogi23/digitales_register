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
import 'package:dr/utc_date_time.dart';

/// One row of the shared week grid.
sealed class CalendarSlot {
  const CalendarSlot();

  /// Relative height. Breaks are shown narrower than a lesson: they carry no
  /// content, but should stay proportional enough to read as a real gap.
  int get flex;
}

/// A numbered lesson slot. [time] is null when the server sent no times.
class LessonSlot extends CalendarSlot {
  final int hour;
  final TimeSpan? time;

  const LessonSlot(this.hour, this.time);

  @override
  int get flex => 2;
}

/// A gap between two consecutive lessons that the timetable does not number —
/// typically the lunch break.
class BreakSlot extends CalendarSlot {
  final Duration duration;

  const BreakSlot(this.duration);

  @override
  int get flex => 1;
}

/// The vertical layout shared by every day of a calendar week.
///
/// All days use the same slots so a lesson sits at the same height across the
/// week. Besides the numbered hours the grid carries breaks, which exist only
/// in the times: the school numbers its morning break as a regular lesson, but
/// the lunch break is a plain gap between two consecutive hour numbers.
class CalendarGrid {
  /// Anything shorter is treated as timetable noise rather than a break.
  static const minBreak = Duration(minutes: 10);

  final List<CalendarSlot> slots;

  const CalendarGrid(this.slots);

  /// Builds the grid from every day of the week, covering hours 1..[lastHour].
  factory CalendarGrid.fromDays(Iterable<CalendarDay> days, int lastHour) {
    final times = _timesByHour(days);
    final slots = <CalendarSlot>[];
    for (var hour = 1; hour <= lastHour; hour++) {
      slots.add(LessonSlot(hour, times[hour]));

      // A break only exists between *consecutive* numbers. A skipped number is
      // a cancelled lesson, which the grid already shows as empty space.
      final current = times[hour], next = times[hour + 1];
      if (current == null || next == null) continue;
      // Compare times of day: the two hours can come from different days,
      // because not every day covers every hour number.
      final gap = Duration(
        minutes: _minutesOfDay(next.from) - _minutesOfDay(current.to),
      );
      if (gap >= minBreak) slots.add(BreakSlot(gap));
    }
    return CalendarGrid(slots);
  }

  static int _minutesOfDay(UtcDateTime time) => time.hour * 60 + time.minute;

  /// First and last time seen for each hour number. Double lessons carry one
  /// span per hour they cover, so each number gets its own times.
  static Map<int, TimeSpan> _timesByHour(Iterable<CalendarDay> days) {
    final times = <int, TimeSpan>{};
    for (final day in days) {
      for (final lesson in day.hours) {
        for (var i = 0; i < lesson.timeSpans.length; i++) {
          times.putIfAbsent(lesson.fromHour + i, () => lesson.timeSpans[i]);
        }
      }
    }
    return times;
  }

  /// Whether a break directly follows [hour].
  bool breakAfter(int hour) {
    for (var i = 0; i < slots.length - 1; i++) {
      final slot = slots[i];
      if (slot is LessonSlot && slot.hour == hour) {
        return slots[i + 1] is BreakSlot;
      }
    }
    return false;
  }

  /// Cuts lessons that span a break into one lesson per side.
  ///
  /// The server merges neighbouring hours with the same subject into a single
  /// entry — across the lunch break too. Rendered as one card, that card would
  /// swallow the break, so the day would look like uninterrupted lessons.
  List<CalendarHour> splitAtBreaks(Iterable<CalendarHour> hours) {
    final result = <CalendarHour>[];
    for (final hour in hours) {
      var start = hour.fromHour;
      for (var at = hour.fromHour; at < hour.toHour; at++) {
        if (!breakAfter(at)) continue;
        result.add(_slice(hour, start, at));
        start = at + 1;
      }
      result.add(start == hour.fromHour ? hour : _slice(hour, start, hour.toHour));
    }
    return result;
  }

  /// [hour] limited to [from]..[to], keeping the time spans of those hours.
  static CalendarHour _slice(CalendarHour hour, int from, int to) {
    final spans = hour.timeSpans;
    final first = from - hour.fromHour, last = to - hour.fromHour;
    return hour.rebuild((b) => b
      ..fromHour = from
      ..toHour = to
      ..timeSpans = ListBuilder<TimeSpan>(
        last < spans.length ? spans.toList().sublist(first, last + 1) : spans,
      ));
  }

  int get totalFlex => slots.fold(0, (sum, slot) => sum + slot.flex);

  bool get hasTimes => slots.any((s) => s is LessonSlot && s.time != null);

  /// Height of everything above [hour], including a break right before it —
  /// that break is part of the space the hour is pushed down by.
  int flexBefore(int hour) {
    var sum = 0;
    for (final slot in slots) {
      if (slot is LessonSlot && slot.hour >= hour) break;
      sum += slot.flex;
    }
    return sum;
  }

  /// Height up to and including [hour], excluding a break that follows it —
  /// that break belongs to the next hour, not to this one.
  int flexThrough(int hour) {
    var sum = 0, pendingBreak = 0;
    for (final slot in slots) {
      if (slot is BreakSlot) {
        pendingBreak += slot.flex;
        continue;
      }
      if ((slot as LessonSlot).hour > hour) break;
      sum += pendingBreak + slot.flex;
      pendingBreak = 0;
    }
    return sum;
  }
}
