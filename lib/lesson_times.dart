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
import 'package:intl/intl.dart';

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
///
/// shortcut: eine Zeit je Stundennummer für alle Wochentage, ein kürzerer
/// Freitag geht verloren; erst ändern, wenn eine Schule das braucht.
LessonTimes portalLessonTimes(Iterable<CalendarDay> days) {
  final times = <int, LessonTime>{};
  for (final day in days) {
    for (final lesson in day.hours) {
      // Eine Zeitspanne über mehrere Stunden gehört keiner einzelnen.
      if (_spansWholeLesson(lesson)) continue;
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
  final hours = day.hours.map((h) => _applyToHour(h, overrides)).toList();
  final changed = Iterable<int>.generate(hours.length)
      .any((i) => !identical(hours[i], day.hours[i]));
  return changed ? day.rebuild((b) => b.hours = ListBuilder(hours)) : day;
}

/// Eine einzige Zeitspanne über mehrere Stunden: eine Doppelstunde, die das
/// Portal nicht je Stunde aufteilt.
bool _spansWholeLesson(CalendarHour hour) =>
    hour.timeSpans.length == 1 && hour.toHour > hour.fromHour;

CalendarHour _applyToHour(CalendarHour hour, LessonTimes overrides) {
  final spans = hour.timeSpans;
  final wholeLesson = _spansWholeLesson(hour);
  final applied = [
    for (var i = 0; i < spans.length; i++)
      _applyToSpan(
        spans[i],
        overrides[hour.fromHour + i],
        wholeLesson ? overrides[hour.toHour] : overrides[hour.fromHour + i],
      ),
  ];
  final changed = Iterable<int>.generate(applied.length)
      .any((i) => !identical(applied[i], spans[i]));
  return changed
      ? hour.rebuild((b) => b.timeSpans = ListBuilder(applied))
      : hour;
}

TimeSpan _applyToSpan(TimeSpan span, LessonTime? first, LessonTime? last) {
  if (first == null && last == null) return span;
  UtcDateTime at(UtcDateTime date, int minutes) =>
      UtcDateTime(date.year, date.month, date.day, minutes ~/ 60, minutes % 60);
  final from = first == null ? span.from : at(span.from, first.start);
  final to = last == null ? span.to : at(span.to, last.end);
  // Nur der Beginn eingestellt und das Portal-Ende liegt davor: lieber die
  // Zeit des Portals als eine Stunde, die endet, bevor sie beginnt.
  if (!to.isAfter(from)) return span;
  return TimeSpan(
    (b) => b
      ..from = from
      ..to = to,
  );
}

const _minutesPerDay = 24 * 60;

/// Was sich ändert, wenn [hour] einen neuen [start] oder ein neues [end]
/// bekommt — nur die geänderten Stunden, oder null, wo es nicht geht.
///
/// - Ein neuer Beginn verschiebt das Ende mit: die Stunde dauert gleich lang.
/// - Ein neues Ende lässt den Beginn stehen.
/// - Hat sich das Ende geändert, beginnt die nächste Stunde zu dieser Zeit
///   und behält ihre Dauer; ihr neues Ende zieht die übernächste nach, und so
///   weiter, bis sich ein Ende nicht mehr ändert. Umgekehrt ändert der Beginn
///   einer Stunde nie das Ende der vorigen.
/// - Es geht nicht, wenn das Ende nicht nach dem Beginn liegt, die Stunde vor
///   dem Ende einer früheren beginnt oder eine Stunde über Mitternacht reicht.
LessonTimes? editLessonTime(
  LessonTimes all,
  int hour, {
  int? start,
  int? end,
}) {
  final old = all[hour];
  if (old == null) return null;
  final shift = start == null ? 0 : start - old.start;
  final edited = LessonTime(old.start + shift, end ?? old.end + shift);
  if (edited.start < 0 ||
      edited.end <= edited.start ||
      edited.end > _minutesPerDay) {
    return null;
  }
  if (all.entries.any((e) => e.key < hour && e.value.end > edited.start)) {
    return null;
  }
  if (edited == old) return const {};

  final changes = {hour: edited};
  var current = edited;
  var h = hour;
  while (current.end != all[h]!.end) {
    final following = all[h + 1];
    if (following == null) break;
    final delta = current.end - following.start;
    if (delta == 0) break;
    current = LessonTime(current.end, following.end + delta);
    if (current.end > _minutesPerDay) return null;
    changes[++h] = current;
  }
  return changes;
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

/// Die Tage und Stunden einer Absenz, z. B. "Mo 5.2.2026, 3. - 5. h
/// (09:55–11:45)": am selben Tag eine Stunde oder ein Bereich, über mehrere
/// Tage Datum und Beginn der ersten und der letzten Stunde.
String absenceRangeText({
  required DateFormat dateFormat,
  required DateTime startDate,
  required int startHour,
  required DateTime endDate,
  required int endHour,
  required LessonTimes times,
}) {
  String hour(int h) => '$h. h${lessonTimeNote(times, h, h)}';
  final start = dateFormat.format(startDate);
  if (startDate != endDate) {
    return '$start ${hour(startHour)} - '
        '${dateFormat.format(endDate)} ${hour(endHour)}';
  }
  if (startHour == endHour) return '$start, ${hour(startHour)}';
  return '$start, $startHour. - $endHour. h'
      '${lessonTimeNote(times, startHour, endHour)}';
}
