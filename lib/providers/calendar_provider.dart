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

import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:dr/app_state.dart';
import 'package:dr/background_check.dart' show homeworkOf, rememberSeenHomework;
import 'package:dr/calendar_parser.dart';
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
    state = state.rebuild((b) => b.loadingWeeks.add(monday));
    try {
      final dynamic data = await wrapper.send(
        "api/calendar/student",
        args: {"startDate": DateFormat("yyyy-MM-dd").format(monday)},
      );
      if (data != null) {
        final days = _parseLoaded(data as Map<String, dynamic>);
        state = state.rebuild((b) => b.days.addAll(days));
        _rememberHomework(days.values);
      }
    } finally {
      // Also on failure: a week stuck in "loading" would spin forever.
      state = state.rebuild((b) => b.loadingWeeks.remove(monday));
    }
  }

  /// Homework the app has loaded is no news: the background check need not
  /// bring it up again as a system notification (#288).
  void _rememberHomework(Iterable<CalendarDay> days) {
    final user = wrapper.user;
    final url = wrapper.url;
    if (user == null || url == null) return;
    unawaited(rememberSeenHomework(
      user: user,
      url: url,
      ids: homeworkOf(days).map((h) => h.id),
    ));
  }

  /// Loads the week every page built on the calendar opens with.
  Future<void> loadCurrentWeek() => load(state.shownMonday);

  /// Loads this week and the next — what the homework overview is about.
  ///
  /// It lists whatever weeks are loaded; with this one alone, homework due
  /// next week stayed hidden until another page happened to load it (#289).
  Future<void> loadUpcomingWeeks() {
    final monday = toMonday(now);
    return Future.wait([
      load(monday),
      load(monday.add(const Duration(days: 7))),
    ]);
  }

  void setCurrentMonday(UtcDateTime monday) {
    final selectedDate = state.selection?.date;
    if (selectedDate != null && toMonday(selectedDate) != monday) {
      state = state.rebuild(
        (b) => b
          ..currentMonday = monday
          ..selection = CalendarSelection(
            (b) => b..date = UtcDateTime(monday.year, monday.month, monday.day),
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

  Map<UtcDateTime, CalendarDay> _parseLoaded(Map<String, dynamic> data) =>
      parseCalendarWeek(data, previous: state.days.toMap());
}

final calendarProvider =
    NotifierProvider<CalendarNotifier, CalendarState>(CalendarNotifier.new);
