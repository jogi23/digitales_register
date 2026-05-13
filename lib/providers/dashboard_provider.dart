// Copyright (C) 2021 Michael Debertol
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
import 'package:collection/collection.dart' show IterableExtension;
import 'package:dr/app_state.dart';
import 'package:dr/data.dart';
import 'package:dr/main.dart' show showSnackBar;
import 'package:dr/middleware/middleware.dart'
    show canOpenFile, downloadFile, openFile, wrapper;
import 'package:dr/providers/no_internet_provider.dart';
import 'package:dr/utc_date_time.dart';
import 'package:dr/util.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class DashboardNotifier extends Notifier<DashboardState> {
  @override
  DashboardState build() => DashboardState();

  Future<void> load(
    bool future, {
    required bool markNew,
    required bool deduplicate,
  }) async {
    if (ref.read(noInternetProvider)) return;
    state = state.rebuild((b) => b
      ..loading = true
      ..future = future);
    final dynamic data = await wrapper.send(
      'api/student/dashboard/dashboard',
      args: {'viewFuture': future},
    );
    if (data is! List) {
      state = state.rebuild((b) => b..loading = false);
      return;
    }
    _applyLoaded(data, future, markNew, deduplicate);
  }

  Future<void> refresh({
    required bool markNew,
    required bool deduplicate,
  }) async {
    await load(state.future, markNew: markNew, deduplicate: deduplicate);
  }

  Future<void> switchFuture({
    required bool markNew,
    required bool deduplicate,
  }) async {
    final newFuture = !state.future;
    await load(newFuture, markNew: markNew, deduplicate: deduplicate);
  }

  Future<void> addReminder(UtcDateTime date, String msg) async {
    final dynamic result = await wrapper.send(
      'api/student/dashboard/save_reminder',
      args: {
        'date': DateFormat('yyyy-MM-dd').format(date),
        'text': msg,
      },
    );
    if (result == null) {
      _showErrorIfOnline('Beim Speichern ist ein Fehler aufgetreten');
      return;
    }
    _applyHomeworkAdded(result as Object, date);
  }

  Future<void> deleteHomework(Homework hw) async {
    final dynamic result = await wrapper.send(
      'api/student/dashboard/delete_reminder',
      args: {'id': hw.id},
    );
    if (result != null && result['success'] == true) {
      _applyHomeworkRemoved(hw);
    } else {
      _showErrorIfOnline('Beim Speichern ist ein Fehler aufgetreten');
    }
  }

  Future<void> toggleDone(int hwId, String type, bool done) async {
    _applyToggleDone(hwId, done);
    final dynamic result = await wrapper.send(
      'api/student/dashboard/toggle_reminder',
      args: {'id': hwId, 'type': type, 'value': done},
    );
    if (result == null || result['success'] != true) {
      _applyToggleDone(hwId, !done);
      _showErrorIfOnline('Beim Speichern ist ein Fehler aufgetreten');
    }
  }

  void markAsSeen(Homework hw) {
    state = state.rebuild(
      (b) => b.allDays.map(
        (day) => day.homework.contains(hw)
            ? day.rebuild(
                (b) => b
                  ..homework[day.homework.indexOf(hw)] = hw.rebuild(
                    (hb) => hb
                      ..isChanged = false
                      ..isNew = false,
                  ),
              )
            : day,
      ),
    );
  }

  void markDeletedHomeworkAsSeen(Day day) {
    state = state.rebuild(
      (b) => b.allDays.map(
        (d) => d == day
            ? day.rebuild(
                (b) => b
                  ..deletedHomework.map(
                    (h) => h.rebuild((b) => b..isChanged = false),
                  ),
              )
            : d,
      ),
    );
  }

  void markAllAsSeen() {
    state = state.rebuild(
      (b) => b.allDays.map(
        (day) => day.rebuild(
          (b) => b
            ..homework.map(
              (homework) => homework.rebuild(
                (b) => b
                  ..isChanged = false
                  ..isNew = false,
              ),
            )
            ..deletedHomework.map(
              (homework) => homework.rebuild((b) => b..isChanged = false),
            ),
        ),
      ),
    );
  }

  void updateBlacklist(BuiltList<HomeworkType> blacklist) {
    state = state.rebuild((b) => b.blacklist.replace(blacklist));
  }

  Future<void> openAttachment(GradeGroupSubmission ggs) async {
    if (!ggs.fileAvailable || !await canOpenFile(ggs.uniqueName)) {
      _applyDownloadAttachment(ggs);
      final success = await downloadFile(
        '${wrapper.baseAddress}api/gradeGroup/gradeGroupSubmissionDownloadEntry',
        ggs.uniqueName,
        <String, dynamic>{
          'submissionId': ggs.id,
          'parentId': ggs.gradeGroupId,
        },
      );
      _applyAttachmentReady(ggs.rebuild((b) => b..fileAvailable = success));
      if (!success) return;
    }
    await openFile(ggs.uniqueName);
  }

  // ─── Private state mutation helpers ─────────────────────────────────────────

  void _applyLoaded(Object data, bool future, bool markNew, bool deduplicate) {
    final loadTime = now;
    final loadedDays = [
      for (final day in data as Iterable)
        tryParse<Day, dynamic>(
          day,
          (dynamic day) => _parseDay(getMap(day)!, deduplicate),
        )
    ];

    final List<Day> daysToDelete = [];
    // Due to a bug some days might have been duplicated.
    // TODO: Remove this once we are confident no users migrate from an affected version anymore.
    final Set<UtcDateTime> seenDates = {};

    state = state.rebuild((b) {
      b.allDays.map(
        (day) => day.rebuild(
          (b) {
            final newDay = loadedDays.firstWhereOrNull(
              (d) => d.date.stripTime() == day.date.stripTime(),
            );
            if (seenDates.contains(day.date.stripTime())) {
              daysToDelete.add(day);
            } else {
              seenDates.add(day.date.stripTime());
            }
            if (newDay == null) {
              if (!future &&
                  day.date.isBefore(
                    loadTime.subtract(
                      const Duration(days: 1),
                    ),
                  )) {
                daysToDelete.add(day);
              }
              return;
            }
            loadedDays.remove(newDay);
            final List<Homework> newHomework = newDay.homework.toList();
            for (final oldHw in day.homework.toList()) {
              final newHw = newHomework.firstWhereOrNull(
                    (d) => d.id == oldHw.id,
                  ) ??
                  newHomework.firstWhereOrNull(
                    (d) => d.isSuccessorOf(oldHw),
                  );
              if (newHw == null) {
                b.homework.remove(oldHw);
                if (oldHw.type != HomeworkType.homework) {
                  b.deletedHomework.add(
                    oldHw.rebuild((b) => b
                      ..deleted = true
                      ..isChanged = markNew
                      ..previousVersion = oldHw.toBuilder()
                      ..lastNotSeen = day.lastRequested
                      ..firstSeen = loadTime),
                  );
                }
              } else if (!newHw.serverEquals(oldHw)) {
                b.homework.remove(oldHw);
                b.homework.add(newHw.rebuild((b) => b
                  ..previousVersion = oldHw.toBuilder()
                  ..lastNotSeen = day.lastRequested
                  ..firstSeen = loadTime
                  ..isChanged = markNew &&
                      // there was already a notification in this case (new grade)
                      !(oldHw.type == HomeworkType.gradeGroup &&
                          newHw.type == HomeworkType.grade)));
              } else {
                // preserve client-custom data, but update everything else
                final mergedHw = newHw.toBuilder()
                  ..firstSeen = oldHw.firstSeen
                  ..lastNotSeen = oldHw.lastNotSeen
                  ..previousVersion = oldHw.previousVersion?.toBuilder();
                mergedHw.gradeGroupSubmissions.map(
                  (ggs) => ggs.rebuild(
                    (ggs) =>
                        ggs.fileAvailable = oldHw.gradeGroupSubmissions?.any(
                              (oldGgs) => oldGgs.file == ggs.file,
                            ) ??
                            false,
                  ),
                );
                b.homework[b.homework.build().indexOf(oldHw)] =
                    mergedHw.build();
              }
              newHomework.remove(newHw);
            }
            for (final newHw in newHomework) {
              final deletedHw = day.deletedHomework.firstWhereOrNull(
                    (d) => d.id == newHw.id,
                  ) ??
                  day.deletedHomework.firstWhereOrNull(
                    (d) => d.isSuccessorOf(newHw),
                  );
              if (deletedHw != null) {
                b.deletedHomework.remove(deletedHw);
                b.homework.add(newHw.rebuild((b) => b
                  ..previousVersion = deletedHw.toBuilder()
                  ..lastNotSeen = day.lastRequested
                  ..firstSeen = loadTime
                  ..isChanged = markNew));
              } else {
                b.homework.add(newHw.rebuild((b) => b
                  ..lastNotSeen = day.lastRequested
                  ..firstSeen = loadTime
                  ..isNew = newHw.type != HomeworkType.grade &&
                      newHw.type != HomeworkType.homework &&
                      markNew));
              }
            }
            b.lastRequested = loadTime;
          },
        ),
      );
      b.allDays.removeWhere((day) => daysToDelete.contains(day));
      for (final newDay in loadedDays) {
        b.allDays.add(newDay.rebuild((b) => b
          ..lastRequested = loadTime
          ..homework.map((h) => h.rebuild((b) => b..firstSeen = loadTime))));
      }
      b.allDays.sort((a, b) => a.date.compareTo(b.date));
      b.loading = false;
      b.future = future;
    });
  }

  void _applyHomeworkAdded(Object data, UtcDateTime date) {
    state = state.rebuild(
      (b) => b.allDays.map(
        (day) => day.date == date
            ? day.rebuild(
                (b) => b
                  ..homework.add(
                    _parseHomework(getMap(data)!).rebuild(
                      (b) => b
                        ..firstSeen = now
                        ..lastNotSeen = now,
                    ),
                  ),
              )
            : day,
      ),
    );
  }

  void _applyHomeworkRemoved(Homework hw) {
    state = state.rebuild(
      (b) => b.allDays.map(
        (day) => day.rebuild((b) => b..homework.remove(hw)),
      ),
    );
  }

  void _applyToggleDone(int hwId, bool done) {
    state = state.rebuild(
      (b) => b.allDays.map(
        (day) {
          final index = day.homework.indexWhere((hw) => hw.id == hwId);
          if (index == -1) return day;
          return day.rebuild(
            (b) => b
              ..homework[index] =
                  b.homework[index].rebuild((hb) => hb..checked = done),
          );
        },
      ),
    );
  }

  void _applyDownloadAttachment(GradeGroupSubmission ggs) {
    state = state.rebuild(
      (b) => b.allDays.map(
        (day) => day.rebuild(
          (b) => b.homework.map(
            (hw) => hw.rebuild(
              (b) => b.gradeGroupSubmissions.map(
                (s) => s == ggs ? s.rebuild((b) => b..downloading = true) : s,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _applyAttachmentReady(GradeGroupSubmission ggs) {
    state = state.rebuild(
      (b) => b.allDays.map(
        (day) => day.rebuild(
          (b) => b.homework.map(
            (hw) => hw.rebuild(
              (b) => b.gradeGroupSubmissions.map(
                (s) => s.file == ggs.file
                    ? s.rebuild(
                        (b) => b
                          ..fileAvailable = ggs.fileAvailable
                          ..downloading = false,
                      )
                    : s,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Private parse helpers ───────────────────────────────────────────────────

  Day _parseDay(Map<dynamic, dynamic> data, bool deduplicate) {
    final items = ListBuilder<Homework>(
      getList(data['items'])!.map<Homework>(
        (dynamic m) => tryParse(getMap(m)!, _parseHomework),
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

  Homework _parseHomework(Map<dynamic, dynamic> data) {
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
                        tryParse(getMap(s)!, _parseGradeGroupSubmission))
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

  GradeGroupSubmission? _parseGradeGroupSubmission(Map<dynamic, dynamic> data) {
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

  void _showErrorIfOnline(String message) {
    if (!wrapper.noInternet) {
      showSnackBar(message);
    }
  }

  @visibleForTesting
  void testApplyLoaded(
    Object data,
    bool future,
    bool markNew,
    bool deduplicate,
  ) {
    _applyLoaded(data, future, markNew, deduplicate);
  }
}

final dashboardProvider =
    NotifierProvider<DashboardNotifier, DashboardState>(DashboardNotifier.new);
