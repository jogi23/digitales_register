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

import 'dart:developer';

import 'package:built_collection/built_collection.dart';
import 'package:dr/data.dart';
import 'package:dr/utc_date_time.dart';
import 'package:dr/util.dart';

/// Parses a list of raw day maps into [Day] objects.
List<Day?> parseDays(Object data, {required bool deduplicate}) {
  return [
    for (final day in data as Iterable)
      tryParse<Day, dynamic>(
        day,
        (dynamic day) => parseDay(getMap(day)!, deduplicate: deduplicate),
      )
  ];
}

/// Parses a single day map into a [Day].
Day parseDay(Map<dynamic, dynamic> data, {required bool deduplicate}) {
  final items = ListBuilder<Homework>(
    getList(data['items'])!.map<Homework>(
      (dynamic m) => tryParse(getMap(m)!, parseHomework),
    ),
  );
  if (deduplicate) {
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      for (var ii = i + 1; ii < items.length;) {
        if (items[ii].serverEquals(item)) {
          items.removeAt(ii);
        } else {
          ii++;
        }
      }
    }
  }
  return Day(
    (b) => b
      ..date = UtcDateTime.parse(getString(data['date'])!)
      ..homework = items,
  );
}

/// Parses a single homework map into a [Homework].
Homework parseHomework(Map<dynamic, dynamic> data) {
  return Homework((b) {
    b
      ..id = getInt(data['id'])
      ..title = getString(data['title'])
      ..subtitle = getString(data['subtitle'])
      ..label = getString(data['label'])
      ..warning = data['homework'] == 0
      ..checkable = getBool(data['checkable']) ?? b.checkable
      ..checked = getBool(data['checked']) ?? false
      ..deleteable = getBool(data['deleteable']) ?? b.deleteable
      ..gradeGroupSubmissions = data['gradeGroupSubmissions'] == null
          ? null
          : ListBuilder(
              getList(data['gradeGroupSubmissions'])!
                  .map((dynamic s) =>
                      tryParse(getMap(s)!, parseGradeGroupSubmission))
                  .where((s) => s != null),
            );

    b.type = switch (getString(data['type'])) {
      'lessonHomework' => HomeworkType.lessonHomework,
      'gradeGroup' => HomeworkType.gradeGroup,
      'grade' => HomeworkType.grade,
      'observation' => HomeworkType.observation,
      'homework' => HomeworkType.homework,
      _ => HomeworkType.unknown,
    };

    if (b.type == HomeworkType.grade) {
      b
        ..gradeFormatted = formatGradeFromString(getString(data['grade']))
        ..grade = getString(data['grade']);
    }
  });
}

/// Parses a grade group submission map. Returns null if parsing fails.
GradeGroupSubmission? parseGradeGroupSubmission(
    Map<dynamic, dynamic> data) {
  try {
    return GradeGroupSubmission(
      (b) => b
        ..file = getString(data['file'])
        ..originalName = getString(data['originalName'])
        ..timestamp = UtcDateTime.parse(getString(data['timestamp'])!)
        ..typeName = getString(data['typeName'])
        ..id = getInt(data['id'])
        ..gradeGroupId = getInt(data['gradeGroupId'])
        ..userId = getInt(data['userId']),
    );
  } catch (e, s) {
    log('Failed to parse GradeGroupSubmission', error: e, stackTrace: s);
    return null;
  }
}
