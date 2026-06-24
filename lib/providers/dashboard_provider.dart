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

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:dr/app_state.dart';
import 'package:dr/data.dart';
import 'package:dr/middleware/middleware.dart'
    show canOpenFile, downloadFile, openFile, wrapper;
import 'package:dr/providers/dashboard_error_provider.dart';
import 'package:dr/providers/dashboard_parser.dart';
import 'package:dr/providers/grades_provider.dart';
import 'package:dr/providers/no_internet_provider.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/utc_date_time.dart';
import 'package:dr/util.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class DashboardGradeTarget {
  final Homework homework;
  final UtcDateTime dayDate;

  const DashboardGradeTarget({
    required this.homework,
    required this.dayDate,
  });
}

class DashboardNotifier extends Notifier<DashboardState> {
  @override
  DashboardState build() => DashboardState();

  /// Clears all dashboard data. Call this before loading data for a different
  /// account so that stale entries are not shown as deleted.
  void reset() {
    state = DashboardState();
  }

  void restore(DashboardState saved) =>
      state = saved.rebuild((b) => b..loading = false);

  Future<void> load(bool future) async {
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
    final settings = ref.read(settingsProvider);
    _applyLoaded(data, future, settings.dashboardMarkNewOrChangedEntries,
        settings.dashboardDeduplicateEntries);
  }

  Future<void> refresh() async {
    await load(state.future);
  }

  Future<void> switchFuture() async {
    await load(!state.future);
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
    final loadedDays =
        parseDays(data, deduplicate: deduplicate).whereType<Day>().toList();

    state = state.rebuild((b) {
      _mergeExistingDays(b, loadedDays, loadTime, future, markNew);
      _addNewDays(b, loadedDays, loadTime, markNew);
      b.allDays.sort((a, b) => a.date.compareTo(b.date));
      b.loading = false;
      b.future = future;
    });
  }

  /// Updates and merges days already present in state with newly loaded data.
  /// Days that no longer exist on the server and are old enough are removed.
  /// Removes exact duplicates (server-side bug workaround).
  void _mergeExistingDays(
    DashboardStateBuilder b,
    List<Day> loadedDays,
    UtcDateTime loadTime,
    bool future,
    bool markNew,
  ) {
    final Set<UtcDateTime> seenDates = {};
    final List<Day> daysToDelete = [];

    b.allDays.map(
      (day) => day.rebuild(
        (b) {
          if (seenDates.contains(day.date.stripTime())) {
            daysToDelete.add(day);
            return;
          }
          seenDates.add(day.date.stripTime());

          final newDay = loadedDays.firstWhereOrNull(
            (d) => d.date.stripTime() == day.date.stripTime(),
          );
          if (newDay == null) {
            if (!future &&
                day.date.isBefore(
                  loadTime.subtract(const Duration(days: 1)),
                )) {
              daysToDelete.add(day);
            }
            return;
          }
          loadedDays.remove(newDay);
          _mergeHomework(b, day, newDay, loadTime, markNew);
          b.lastRequested = loadTime;
        },
      ),
    );
    b.allDays.removeWhere((day) => daysToDelete.contains(day));
  }

  /// Merges homework from [newDay] into the existing day builder [b],
  /// tracking changes, deletions, and restorations.
  void _mergeHomework(
    DayBuilder b,
    Day oldDay,
    Day newDay,
    UtcDateTime loadTime,
    bool markNew,
  ) {
    final List<Homework> newHomework = newDay.homework.toList();
    for (final oldHw in oldDay.homework.toList()) {
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
              ..lastNotSeen = oldDay.lastRequested
              ..firstSeen = loadTime),
          );
        }
      } else if (!newHw.serverEquals(oldHw)) {
        b.homework.remove(oldHw);
        b.homework.add(newHw.rebuild((b) => b
          ..previousVersion = oldHw.toBuilder()
          ..lastNotSeen = oldDay.lastRequested
          ..firstSeen = loadTime
          ..isChanged = markNew &&
              !(oldHw.type == HomeworkType.gradeGroup &&
                  newHw.type == HomeworkType.grade)));
      } else {
        final mergedHw = newHw.toBuilder()
          ..firstSeen = oldHw.firstSeen
          ..lastNotSeen = oldHw.lastNotSeen
          ..previousVersion = oldHw.previousVersion?.toBuilder();
        mergedHw.gradeGroupSubmissions.map(
          (ggs) => ggs.rebuild(
            (ggs) => ggs.fileAvailable = oldHw.gradeGroupSubmissions?.any(
                  (oldGgs) => oldGgs.file == ggs.file,
                ) ??
                false,
          ),
        );
        b.homework[b.homework.build().indexOf(oldHw)] = mergedHw.build();
      }
      newHomework.remove(newHw);
    }
    _restoreOrAddNewHomework(b, oldDay, newHomework, loadTime, markNew);
  }

  /// Handles homework entries in [newHomework] that had no match in the old day:
  /// restores previously deleted homework or marks brand-new entries.
  void _restoreOrAddNewHomework(
    DayBuilder b,
    Day oldDay,
    List<Homework> newHomework,
    UtcDateTime loadTime,
    bool markNew,
  ) {
    for (final newHw in newHomework) {
      final deletedHw = oldDay.deletedHomework.firstWhereOrNull(
            (d) => d.id == newHw.id,
          ) ??
          oldDay.deletedHomework.firstWhereOrNull(
            (d) => d.isSuccessorOf(newHw),
          );
      if (deletedHw != null) {
        b.deletedHomework.remove(deletedHw);
        b.homework.add(newHw.rebuild((b) => b
          ..previousVersion = deletedHw.toBuilder()
          ..lastNotSeen = oldDay.lastRequested
          ..firstSeen = loadTime
          ..isChanged = markNew));
      } else {
        b.homework.add(newHw.rebuild((b) => b
          ..lastNotSeen = oldDay.lastRequested
          ..firstSeen = loadTime
          ..isNew = newHw.type != HomeworkType.grade &&
              newHw.type != HomeworkType.homework &&
              markNew));
      }
    }
  }

  /// Appends days from [loadedDays] that had no match in state (brand new days).
  void _addNewDays(
    DashboardStateBuilder b,
    List<Day> loadedDays,
    UtcDateTime loadTime,
    bool markNew,
  ) {
    for (final newDay in loadedDays) {
      b.allDays.add(newDay.rebuild((b) => b
        ..lastRequested = loadTime
        ..homework.map((h) => h.rebuild((b) => b..firstSeen = loadTime))));
    }
  }

  void _applyHomeworkAdded(Object data, UtcDateTime date) {
    state = state.rebuild(
      (b) => b.allDays.map(
        (day) => day.date == date
            ? day.rebuild(
                (b) => b
                  ..homework.add(
                    parseHomework(getMap(data)!).rebuild(
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

  void _mapSubmissions(
    GradeGroupSubmission Function(GradeGroupSubmission) fn,
  ) {
    state = state.rebuild(
      (b) => b.allDays.map(
        (day) => day.rebuild(
          (b) => b.homework.map(
            (hw) => hw.rebuild((b) => b.gradeGroupSubmissions.map(fn)),
          ),
        ),
      ),
    );
  }

  void _applyDownloadAttachment(GradeGroupSubmission ggs) {
    _mapSubmissions(
      (s) => s == ggs ? s.rebuild((b) => b..downloading = true) : s,
    );
  }

  void _applyAttachmentReady(GradeGroupSubmission ggs) {
    _mapSubmissions(
      (s) => s.file == ggs.file
          ? s.rebuild(
              (b) => b
                ..fileAvailable = ggs.fileAvailable
                ..downloading = false,
            )
          : s,
    );
  }

  void _showErrorIfOnline(String message) {
    if (!ref.read(noInternetProvider)) {
      ref.read(dashboardErrorProvider.notifier).state = message;
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

class DashboardGradeCompetencesNotifier
    extends Notifier<Map<int, BuiltList<Competence>>> {
  final Set<int> _loading = {};

  @override
  Map<int, BuiltList<Competence>> build() => {};

  Future<void> ensureLoaded(Iterable<DashboardGradeTarget> targets) async {
    if (ref.read(noInternetProvider)) return;
    final missingTargets = targets
        .where(
          (target) =>
              target.homework.type == HomeworkType.grade &&
              target.homework.grade == null &&
              !state.containsKey(target.homework.id) &&
              !_loading.contains(target.homework.id),
        )
        .toList(growable: false);

    for (final target in missingTargets) {
      final gradeId = target.homework.id;
      _loading.add(gradeId);
      try {
        final loadedCompetences = await _findFromGradesState(target) ??
            await _loadFromGradeIdFallback(target.homework.id);
        state = {
          ...state,
          gradeId: loadedCompetences,
        };
      } catch (_) {
        state = {
          ...state,
          gradeId: BuiltList<Competence>(),
        };
      } finally {
        _loading.remove(gradeId);
      }
    }
  }

  Future<BuiltList<Competence>?> _findFromGradesState(
      DashboardGradeTarget target) async {
    final homework = target.homework;
    var gradesState = ref.read(gradesProvider);
    final gradesNotifier = ref.read(gradesProvider.notifier);

    if (gradesState.subjects.isEmpty) {
      await gradesNotifier.load(gradesState.semester);
      gradesState = ref.read(gradesProvider);
    }

    var subject = gradesState.subjects.firstWhereOrNull(
      (s) => s.name.toLowerCase() == (homework.label ?? '').toLowerCase(),
    );
    if (subject == null) return null;

    if (subject.detailEntries(gradesState.semester) == null) {
      await gradesNotifier.loadDetails(subject, gradesState.semester);
      gradesState = ref.read(gradesProvider);
      subject = gradesState.subjects.firstWhereOrNull(
        (s) => s.id == subject!.id,
      );
      if (subject == null) return null;
    }

    final matchingGrade = subject
        .detailEntries(gradesState.semester)
        ?.whereType<GradeDetail>()
        .firstWhereOrNull(
          (grade) =>
              _toDate(grade.date) == _toDate(target.dayDate) &&
              _stringsMatch(grade.name, homework.subtitle),
        );

    final competences = matchingGrade?.competences;
    if (competences == null || competences.isEmpty) {
      return null;
    }
    return competences;
  }

  Future<BuiltList<Competence>> _loadFromGradeIdFallback(int gradeId) async {
    dynamic data = await wrapper.send(
      'api/student/entry/getGrade',
      args: {'gradeId': gradeId},
    );
    if (data is String) data = json.decode(data);
    return _parseDashboardGradeCompetences(data);
  }

  bool _stringsMatch(String a, String b) =>
      a.toLowerCase().contains(b.toLowerCase()) ||
      b.toLowerCase().contains(a.toLowerCase());

  UtcDateTime _toDate(UtcDateTime dateTime) =>
      UtcDateTime(dateTime.year, dateTime.month, dateTime.day);
}

BuiltList<Competence> _parseDashboardGradeCompetences(dynamic data) {
  final competences = getList(getMap(data)?['competences']);
  if (competences == null) {
    return BuiltList<Competence>();
  }
  return BuiltList<Competence>(
    competences.map<Competence>(
      (dynamic c) => tryParse(getMap(c)!, _parseDashboardCompetence),
    ),
  );
}

Competence _parseDashboardCompetence(Map data) {
  return Competence(
    (b) => b
      ..typeName = getString(data['typeName'])
      ..grade = (double.tryParse(getString(data['grade']) ?? '') ?? 0).toInt(),
  );
}

final dashboardGradeCompetencesProvider = NotifierProvider<
    DashboardGradeCompetencesNotifier, Map<int, BuiltList<Competence>>>(
  DashboardGradeCompetencesNotifier.new,
);
