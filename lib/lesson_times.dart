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

/// Beginn und Ende einer Schulstunde, in Minuten ab Mitternacht.
class LessonTime {
  const LessonTime(this.start, this.end);

  factory LessonTime.fromJson(List<dynamic> json) =>
      LessonTime(json[0] as int, json[1] as int);

  final int start;
  final int end;

  List<int> toJson() => [start, end];

  @override
  bool operator ==(Object other) =>
      other is LessonTime && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

/// Die Zeiten einer Schule je Stundennummer.
typedef LessonTimes = Map<int, LessonTime>;

/// "08:05" für 485 Minuten ab Mitternacht.
String formatMinutes(int minutes) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(minutes ~/ 60)}:${two(minutes % 60)}';
}

int _minutesOfDay(UtcDateTime time) => time.hour * 60 + time.minute;

LessonTime _timeOf(TimeSpan span) =>
    LessonTime(_minutesOfDay(span.from), _minutesOfDay(span.to));

/// Die Zeiten, wie das Portal sie schickt: je Stundennummer die erste, die in
/// den Tagen vorkommt. Eine Doppelstunde bringt eine Zeitspanne je Stunde mit.
LessonTimes portalLessonTimes(Iterable<CalendarDay> days) {
  final times = <int, LessonTime>{};
  for (final day in days) {
    for (final lesson in day.hours) {
      for (var i = 0; i < lesson.timeSpans.length; i++) {
        times.putIfAbsent(
            lesson.fromHour + i, () => _timeOf(lesson.timeSpans[i]));
      }
    }
  }
  return times;
}

/// [day] mit den Zeiten aus [overrides] statt denen des Portals.
///
/// Stunden ohne Eintrag behalten ihre Zeit. Hat eine Doppelstunde nur eine
/// Zeitspanne, läuft sie vom Beginn der ersten bis zum Ende der letzten Stunde.
CalendarDay applyLessonTimes(CalendarDay day, LessonTimes overrides) {
  if (overrides.isEmpty) return day;
  return day.rebuild(
    (b) =>
        b.hours = ListBuilder(day.hours.map((h) => _applyToHour(h, overrides))),
  );
}

CalendarHour _applyToHour(CalendarHour hour, LessonTimes overrides) {
  final spans = hour.timeSpans;
  final wholeLesson = spans.length == 1 && hour.toHour > hour.fromHour;
  return hour.rebuild(
    (b) => b.timeSpans = ListBuilder(
      [
        for (var i = 0; i < spans.length; i++)
          _applyToSpan(
            spans[i],
            overrides[hour.fromHour + i],
            wholeLesson ? overrides[hour.toHour] : overrides[hour.fromHour + i],
          ),
      ],
    ),
  );
}

TimeSpan _applyToSpan(TimeSpan span, LessonTime? first, LessonTime? last) {
  if (first == null && last == null) return span;
  UtcDateTime at(UtcDateTime date, int minutes) =>
      UtcDateTime(date.year, date.month, date.day, minutes ~/ 60, minutes % 60);
  return TimeSpan(
    (b) => b
      ..from = first == null ? span.from : at(span.from, first.start)
      ..to = last == null ? span.to : at(span.to, last.end),
  );
}

/// Ob [time] für [hour] passt: Ende nach Beginn, und weder die vorherige
/// Stunde überlappt noch die nächste.
bool lessonTimeFits(LessonTimes all, int hour, LessonTime time) {
  if (time.end <= time.start) return false;
  for (final entry in all.entries) {
    if (entry.key < hour && entry.value.end > time.start) return false;
    if (entry.key > hour && entry.value.start < time.end) return false;
  }
  return true;
}

/// " (09:55)" für eine Stunde, " (09:55–11:45)" für mehrere, wo die Zeiten
/// bekannt sind; sonst nichts. Hängt direkt an "3. h".
String lessonTimeNote(LessonTimes times, int fromHour, int toHour) {
  final first = times[fromHour];
  if (first == null) return '';
  final last = times[toHour];
  if (fromHour == toHour || last == null) {
    return ' (${formatMinutes(first.start)})';
  }
  return ' (${formatMinutes(first.start)}–${formatMinutes(last.end)})';
}
