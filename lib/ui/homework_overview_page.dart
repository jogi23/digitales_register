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

import 'package:dr/data.dart';
import 'package:dr/ui/lesson_entry_list.dart';

/// Die Art, die fast jede Aufgabe trägt; Prüfungen weichen davon ab und
/// werden deshalb genannt.
const ordinaryHomeworkType = 'Hausaufgabe';

/// Jede Aufgabe und Prüfung aus [days], neueste zuerst.
///
/// Anders als es "Fälligkeit" vermuten lässt, liegt das deadline der
/// Schnittstelle auf dem Tag der Stunde selbst - in der Aufzeichnung bei
/// allen 74 Einträgen. Aufgegeben und fällig fallen hier also zusammen, und
/// die Gruppierung nach Tagen bildet beides ab.
List<LessonEntry> homeworkEntries(Iterable<CalendarDay> days) {
  final entries = <LessonEntry>[
    for (final day in days)
      for (final hour in day.hours)
        for (final homework in hour.homeworkExams)
          LessonEntry(
            date: day.date,
            fromHour: hour.fromHour,
            subject: hour.subject,
            teachers: [
              for (final teacher in hour.teachers) teacher.fullName,
            ],
            title: homework.name,
            typeName: homework.typeName,
          ),
  ];
  entries.sort((a, b) {
    final byDate = b.date.compareTo(a.date);
    return byDate != 0 ? byDate : a.fromHour.compareTo(b.fromHour);
  });
  return entries;
}
