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
import 'package:collection/collection.dart';
import 'package:dr/app_state.dart';
import 'package:dr/data.dart';
import 'package:dr/middleware/middleware.dart'
    show canOpenFile, downloadFile, openFile, wrapper;
import 'package:dr/providers/no_internet_provider.dart';
import 'package:dr/utc_date_time.dart';
import 'package:dr/util.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CalendarNotifier extends Notifier<CalendarState> {
  @override
  CalendarState build() => CalendarState();

  void reset() {
    state = CalendarState();
  }

  void restore(CalendarState saved) => state = saved;

  Future<void> load(UtcDateTime monday) async {
    if (ref.read(noInternetProvider)) return;
    final dynamic data = await wrapper.send(
      "api/calendar/student",
      args: {"startDate": DateFormat("yyyy-MM-dd").format(monday)},
    );
    if (data != null) {
      state = state.rebuild(
        (b) => b.days.addAll(_parseLoaded(data as Map<String, dynamic>)),
      );
    }
  }

  void setCurrentMonday(UtcDateTime monday) {
    final selectedDate = state.selection?.date;
    if (selectedDate != null && toMonday(selectedDate) != monday) {
      state = state.rebuild(
        (b) => b
          ..currentMonday = monday
          ..selection = CalendarSelection(
            (b) => b
              ..date = UtcDateTime(monday.year, monday.month, monday.day),
          ).toBuilder(),
      );
    } else {
      state = state.rebuild((b) => b..currentMonday = monday);
    }
  }

  void select(CalendarSelection? selection) {
    state = state.rebuild((b) => b..selection = selection?.toBuilder());
    if (selection == null) return;
    final newWeek = toMonday(selection.date);
    if (state.currentMonday != newWeek) {
      setCurrentMonday(newWeek);
    }
  }

  void clearSelection() {
    state = state.rebuild((b) => b..selection = null);
  }

  Future<void> openLessonFile(LessonContentSubmission submission) async {
    if (!submission.fileAvailable ||
        !await canOpenFile(submission.uniqueName)) {
      _markDownloading(submission);
      final success = await downloadFile(
        "${wrapper.baseAddress}api/lessonContent/lessonContentSubmissionDownloadEntry",
        submission.uniqueName,
        <String, dynamic>{
          "parentId": submission.lessonContentId,
          "submissionId": submission.id,
        },
      );
      _markFileAvailable(submission.rebuild((b) => b..fileAvailable = success));
      if (!success) return;
    }
    await openFile(submission.uniqueName);
  }

  void _markDownloading(LessonContentSubmission submission) {
    state = state.rebuild(
      (b) => b
        ..days[submission.date] = b.days[submission.date]!.rebuild(
          (b) => b
            ..hours = ListBuilder(
              <CalendarHour>[
                for (final hour in b.hours.build())
                  hour.rebuild(
                    (b) => b
                      ..lessonContents = ListBuilder(
                        <LessonContent>[
                          for (final lessonContent in b.lessonContents.build())
                            lessonContent.rebuild(
                              (b) => b
                                ..submissions = ListBuilder(
                                  <LessonContentSubmission>[
                                    for (final s in b.submissions.build())
                                      if (s.originalName ==
                                          submission.originalName)
                                        s.rebuild((b) => b..downloading = true)
                                      else
                                        s
                                  ],
                                ),
                            )
                        ],
                      ),
                  )
              ],
            ),
        ),
    );
  }

  void _markFileAvailable(LessonContentSubmission submission) {
    state = state.rebuild(
      (b) => b
        ..days[submission.date] = b.days[submission.date]!.rebuild(
          (b) => b
            ..hours = ListBuilder(
              <CalendarHour>[
                for (final hour in b.hours.build())
                  hour.rebuild(
                    (b) => b
                      ..lessonContents = ListBuilder(
                        <LessonContent>[
                          for (final lessonContent in b.lessonContents.build())
                            lessonContent.rebuild(
                              (b) => b
                                ..submissions = ListBuilder(
                                  <LessonContentSubmission>[
                                    for (final s in b.submissions.build())
                                      if (s.originalName ==
                                          submission.originalName)
                                        s.rebuild(
                                          (b) => b
                                            ..downloading = false
                                            ..fileAvailable =
                                                submission.fileAvailable,
                                        )
                                      else
                                        s
                                  ],
                                ),
                            )
                        ],
                      ),
                  )
              ],
            ),
        ),
    );
  }

  @visibleForTesting
  Map<UtcDateTime, CalendarDay> parseLoaded(Map<String, dynamic> data) =>
      _parseLoaded(data);

  Map<UtcDateTime, CalendarDay> _parseLoaded(Map<String, dynamic> data) {
    return data.map(
      (k, dynamic e) {
        final date = UtcDateTime.parse(k);
        return MapEntry(
          date,
          tryParse<CalendarDayBuilder, dynamic>(
            e,
            (dynamic e) => _parseCalendarDay(
              getMap(getMap(e)!.values.first.values.first)!,
              date,
              state.days[date],
            ),
          ).build(),
        );
      },
    );
  }

  CalendarDayBuilder _parseCalendarDay(
    Map day,
    UtcDateTime date,
    CalendarDay? oldDay,
  ) {
    return CalendarDayBuilder()
      ..lastFetched = UtcDateTime.now()
      ..date = date
      ..hours = ListBuilder(
        (day.values.toList()
              ..removeWhere((dynamic e) => e == null || e["isLesson"] == 0)
              ..sort(
                (dynamic a, dynamic b) => getInt(a["hour"])!.compareTo(
                  getInt(b["hour"])!,
                ),
              ))
            .map<CalendarHour>(
          (dynamic h) => tryParse(
            getMap(h)!,
            (Map map) => _parseHour(map, date, oldDay),
          ).build(),
        ),
      );
  }

  CalendarHourBuilder _parseHour(
    Map hour,
    UtcDateTime date,
    CalendarDay? oldDay,
  ) {
    final lesson = getMap(hour["lesson"])!;
    final timeSpans = ListBuilder<TimeSpan>();
    for (final linkedLesson in <dynamic>[
      lesson,
      ...getList(lesson["linkedHours"]) ?? <dynamic>[],
    ]) {
      final date = tryParse(
        getString(linkedLesson["date"])!,
        (String s) => UtcDateTime.parse(s),
      );
      UtcDateTime parseTime(UtcDateTime date, Map timeObject) {
        final h = getInt(timeObject["h"])!;
        final m = getInt(timeObject["m"])!;
        return UtcDateTime(date.year, date.month, date.day, h, m);
      }

      final from = parseTime(date, getMap(linkedLesson["timeStartObject"])!);
      final to = parseTime(date, getMap(linkedLesson["timeEndObject"])!);
      timeSpans.add(
        TimeSpan((b) => b
          ..from = from
          ..to = to),
      );
    }

    final fromHour = getInt(lesson["hour"])!;
    final toHour = getInt(lesson["toHour"])!;

    final oldHour = oldDay?.hours.firstWhereOrNull(
      (hour) =>
          (hour.fromHour <= fromHour && hour.toHour >= toHour) ||
          (hour.fromHour >= fromHour && hour.toHour <= toHour),
    );

    return CalendarHourBuilder()
      ..fromHour = fromHour
      ..toHour = toHour
      ..timeSpans = timeSpans
      ..rooms = ListBuilder(
        getList(lesson["rooms"])!
            .map<String>((dynamic r) => r["name"] as String),
      )
      ..subject = getString(lesson["subject"]["name"])
      ..teachers = ListBuilder(
        getList(lesson["teachers"])!.map<Teacher>(
          (dynamic r) => Teacher(
            (b) => b
              ..firstName = getString(r["firstName"])
              ..lastName = getString(r["lastName"]),
          ),
        ),
      )
      ..homeworkExams = ListBuilder(
        (lesson["homeworkExams"] as List).map<HomeworkExam>(
          (dynamic e) => tryParse(getMap(e)!, _parseHomeworkExam),
        ),
      )
      ..lessonContents = ListBuilder(
        (lesson["lessonContents"] as List).map<LessonContent>(
          (dynamic e) => tryParse(
            getMap(e)!,
            (Map map) => _parseLessonContent(map, date, oldHour),
          ),
        ),
      );
  }

  HomeworkExam _parseHomeworkExam(Map homeworkExam) {
    return HomeworkExam(
      (b) => b
        ..deadline =
            UtcDateTime.parse(getString(homeworkExam["deadline"])!)
        ..hasGradeGroupSubmissions =
            getBool(homeworkExam["hasGradeGroupSubmissions"])
        ..hasGrades = getBool(homeworkExam["hasGrades"])
        ..warning = homeworkExam["homework"] == 0
        ..homework = homeworkExam["homework"] != 0
        ..id = getInt(homeworkExam["id"])
        ..name = getString(homeworkExam["name"])
        ..online = homeworkExam["online"] != 0
        ..typeId = getInt(homeworkExam["typeId"])
        ..typeName = getString(homeworkExam["typeName"]),
    );
  }

  LessonContent _parseLessonContent(
    Map lessonContent,
    UtcDateTime date,
    CalendarHour? oldHour,
  ) {
    return LessonContent(
      (b) => b
        ..name = getString(lessonContent["name"])
        ..typeName = getString(lessonContent["typeName"])
        ..submissions = tryParse(
          getList(lessonContent["lessonContentSubmissions"]),
          (List? input) {
            return input
                ?.map(
                  (dynamic submission) => _parseLessonContentSubmission(
                    getMap(submission)!,
                    date,
                    oldHour,
                  ),
                )
                .whereType<LessonContentSubmission>()
                .toBuiltList()
                .toBuilder();
          },
        ),
    );
  }

  LessonContentSubmission? _parseLessonContentSubmission(
    Map submission,
    UtcDateTime date,
    CalendarHour? oldHour,
  ) {
    final type = getString(submission["type"]);
    if (type != "file") return null;
    final originalName = getString(submission["originalName"]);
    final id = getString(submission["id"]);
    final fileAvailable = oldHour?.lessonContents.any(
          (content) => content.submissions.any(
            (s) =>
                s.originalName == originalName &&
                s.id == id &&
                s.fileAvailable,
          ),
        ) ??
        false;
    return LessonContentSubmission(
      (b) => b
        ..type = type
        ..originalName = originalName
        ..id = id
        ..lessonContentId = getString(submission["lessonContentId"])
        ..date = date
        ..fileAvailable = fileAvailable,
    );
  }
}

final calendarProvider =
    NotifierProvider<CalendarNotifier, CalendarState>(CalendarNotifier.new);
