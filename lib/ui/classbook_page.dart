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

/// Die Art, die fast jeder Unterrichtseintrag trägt; nur Abweichungen davon
/// sind erwähnenswert.
const ordinaryLessonType = 'Fachunterricht';

/// Every lesson content in [days], newest lesson first.
///
/// Hours without an entry are left out: an empty lesson says nothing, and
/// carrying it would bury the ones that do.
List<LessonEntry> classbookEntries(Iterable<CalendarDay> days) {
  final entries = <LessonEntry>[
    for (final day in days)
      for (final hour in day.hours)
        for (final content in hour.lessonContents)
          LessonEntry(
            date: day.date,
            fromHour: hour.fromHour,
            subject: hour.subject,
            teachers: [
              for (final teacher in hour.teachers) teacher.fullName,
            ],
            title: content.name,
            typeName: content.typeName,
          ),
  ];
  entries.sort((a, b) {
    final byDate = b.date.compareTo(a.date);
    return byDate != 0 ? byDate : a.fromHour.compareTo(b.fromHour);
  });
  return entries;
}

