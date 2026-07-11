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
import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:dr/app_state.dart';
import 'package:dr/data.dart';
import 'package:dr/middleware/middleware.dart' show wrapper;
import 'package:dr/providers/no_internet_provider.dart';
import 'package:dr/providers/subject_appearance_provider.dart';
import 'package:dr/utc_date_time.dart';
import 'package:dr/util.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mutex/mutex.dart';

const String _subjects = "api/student/all_subjects";
const String _subjectsDetail = "api/student/subject_detail";
const String _grade = "api/student/entry/getGrade";

class GradesNotifier extends Notifier<GradesState> {
  late final _lock = _SemesterLock((s) async {
    await wrapper.send("?semesterWechsel=${s.n}");
  });
  final Set<int> _detailsLoadingSubjectIds = {};

  @override
  GradesState build() => GradesState();

  void reset() => state = GradesState();

  void restore(GradesState saved) {
    state = saved.rebuild((b) => b
      ..loading = false
      ..serverSemester = null);
  }

  void setSemester(Semester semester) {
    state = state.rebuild((b) => b..semester.replace(semester));
    load(semester);
  }

  void setConfig(Config config) {
    if (config.currentSemesterMaybe == 1) {
      state = state.rebuild((b) => b..semester.replace(Semester.first));
    } else if (config.currentSemesterMaybe == 2) {
      state = state.rebuild((b) => b..semester.replace(Semester.second));
    }
  }

  void resetForRelogin() {
    state = state.rebuild((b) => b..serverSemester = null);
  }

  void clearPendingSubject() =>
      state = state.rebuild((b) => b..pendingSubjectId = null);

  void clearPendingGrade() =>
      ref.read(pendingGradeIdProvider.notifier).state = null;

  Future<void> requestSubjectDetail(int objectId) async {
    ref.read(pendingGradeIdProvider.notifier).state = null;
    var subject = await _findSubjectById(objectId);
    if (subject == null) {
      subject = await _findSubjectForGradeId(objectId);
      if (subject != null) {
        ref.read(pendingGradeIdProvider.notifier).state = objectId;
      }
    }
    if (subject != null) {
      state = state.rebuild((b) => b..pendingSubjectId = subject!.id);
      await loadDetails(subject, state.semester);
    }
  }

  Future<Subject?> _findSubjectById(int subjectId) async {
    var subject = state.subjects.firstWhereOrNull((s) => s.id == subjectId);
    if (subject == null && !ref.read(noInternetProvider)) {
      await load(state.semester);
      subject = state.subjects.firstWhereOrNull((s) => s.id == subjectId);
    }
    return subject;
  }

  Future<Subject?> _findSubjectForGradeId(int gradeId) async {
    final loadedSubject = state.subjects.firstWhereOrNull(
      (subject) =>
          subject
              .detailEntries(state.semester)
              ?.whereType<GradeDetail>()
              .any((grade) => grade.id == gradeId) ==
          true,
    );
    if (loadedSubject != null) {
      return loadedSubject;
    }
    if (ref.read(noInternetProvider)) {
      return null;
    }
    dynamic data = await wrapper.send(
      _grade,
      args: {"gradeId": gradeId},
    );
    if (data == null) return null;
    if (data is String) data = json.decode(data);
    final subjectId = getInt(getMap(data)?["subjectId"]);
    if (subjectId == null) return null;
    return _findSubjectById(subjectId);
  }

  Future<void> load(Semester semester) async {
    if (ref.read(noInternetProvider)) return;
    state = state.rebuild((b) => b..loading = true);
    _doForSemester(
      semester == Semester.all ? [Semester.first, Semester.second] : [semester],
      (s) async {
        final dynamic data = await wrapper.send(
          _subjects,
          args: {"studentId": wrapper.config.userId},
        );
        if (data == null) {
          state = state.rebuild((b) => b..loading = false);
          return;
        }
        _applyLoaded(data, s);
      },
    );
  }

  Future<void> loadDetails(Subject subject, Semester semester) async {
    if (ref.read(noInternetProvider)) return;
    _doForSemester(
      semester == Semester.all ? [Semester.first, Semester.second] : [semester],
      (s) async {
        dynamic data = await wrapper.send(
          _subjectsDetail,
          args: {
            "studentId": wrapper.config.userId,
            "subjectId": subject.id,
          },
        );
        if (data == null) return;
        if (data is String) data = json.decode(data);
        _applyDetailsLoaded(data, s, subject);
        for (final grade in state.subjects
            .firstWhere((subj) => subj.id == subject.id)
            .grades[s]!
            .where((g) => g.cancelled)) {
          await loadCancelledDescription(grade, s);
        }
      },
    );
  }

  Future<void> ensureDetailDataForSubjects(
    Iterable<Subject> subjects,
    Semester semester,
  ) async {
    if (ref.read(noInternetProvider)) return;
    for (final subject in subjects) {
      final subjectId = subject.id;
      if (subjectId == null ||
          subject.hasDetailData(semester) ||
          _detailsLoadingSubjectIds.contains(subjectId)) {
        continue;
      }
      _detailsLoadingSubjectIds.add(subjectId);
      try {
        await loadDetails(subject, semester);
      } finally {
        _detailsLoadingSubjectIds.remove(subjectId);
      }
    }
  }

  Future<void> loadCancelledDescription(
      GradeDetail grade, Semester semester) async {
    if (ref.read(noInternetProvider)) return;
    _doForSemester([semester], (s) async {
      final dynamic data = await wrapper.send(
        _grade,
        args: {"gradeId": grade.id},
      );
      if (data == null) return;
      _applyCancelledDescription(data, grade, s);
    });
  }

  void _applyLoaded(dynamic data, Semester semester) {
    state = state.rebuild((b) {
      _updateSubjects(b.subjects.build(), b.subjects, getMap(data)!, semester);
      b
        ..serverSemester = semester.toBuilder()
        ..loading = false;
    });
    unawaited(
      ref.read(subjectAppearanceProvider.notifier).ensureThemesFor(
            state.subjects.map((s) => s.name).toList(),
          ),
    );
    // Pre-fetch all subject details in the background so averages are visible
    // immediately without expanding a subject first. Detail data is included in
    // the persisted app state, so averages are also instant on the next cold start.
    unawaited(ensureDetailDataForSubjects(state.subjects, semester));
  }

  void _applyDetailsLoaded(dynamic data, Semester semester, Subject subject) {
    final mapData = getMap(data)!;
    state = state.rebuild((b) => b.subjects.map(
          (s) => s.id == subject.id
              ? s.rebuild(
                  (sb) => sb
                    ..grades[semester] = BuiltList(
                      getList(mapData["grades"])!.map<GradeDetail>(
                        (dynamic g) =>
                            tryParse(getMap(g)!, _parseGrade).rebuild(
                          (d) => d
                            ..cancelledDescription = sb.grades[semester]
                                ?.firstWhereOrNull(
                                  (gd) => gd.id == d.id,
                                )
                                ?.cancelledDescription,
                        ),
                      ),
                    )
                    ..observations[semester] = BuiltList(
                      getList(mapData["observations"])!.map<Observation>(
                        (dynamic o) => tryParse(getMap(o)!, _parseObservation),
                      ),
                    )
                    ..lastFetchedDetailed[semester] = UtcDateTime.now(),
                )
              : s,
        ));
  }

  void _applyCancelledDescription(
      dynamic data, GradeDetail grade, Semester semester) {
    state = state.rebuild((b) => b.subjects.map(
          (s) => s.grades[semester]?.contains(grade) == true
              ? s.rebuild(
                  (sb) => sb
                    ..grades[semester] = sb.grades[semester]!.rebuild(
                      (gb) => gb.map(
                        (g) =>
                            g == grade ? _addCancelledDescription(g, data) : g,
                      ),
                    ),
                )
              : s,
        ));
  }

  void _doForSemester(
    List<Semester> semester,
    Future<void> Function(Semester s) f,
  ) {
    final currentSemester = _lock.current;
    if (semester.contains(currentSemester)) {
      semester.remove(currentSemester);
      _lock.synchronized(currentSemester!, () => f(currentSemester));
    }
    for (final s in semester) {
      _lock.synchronized(s, () => f(s));
    }
  }
}

void _updateSubjects(BuiltList<Subject> oldSubjects,
    ListBuilder<Subject> subjectsBuilder, Map data, Semester semester) {
  final newSubjects = List<Map<String, dynamic>>.from(
    getList(data["subjects"])!,
  );
  final removedIds = oldSubjects.map((s) => s.id).toSet();
  for (final subject in newSubjects) {
    final nestedSubject = getMap(subject["subject"])!;
    final id = getInt(nestedSubject["id"]);
    removedIds.remove(id);
    final subjectIdx = oldSubjects.indexWhere((s) => s.id == id);
    if (subjectIdx != -1) {
      subjectsBuilder[subjectIdx] = subjectsBuilder[subjectIdx].rebuild(
        (b) => b
          ..gradesAll[semester] = BuiltList(
            getList(subject["grades"])!.map<GradeAll>(
              (dynamic g) => tryParse(getMap(g)!, _parseGradeAll),
            ),
          )
          ..lastFetchedBasic[semester] = UtcDateTime.now(),
      );
    } else {
      subjectsBuilder.add(
        Subject(
          (b) => b
            ..id = getInt(nestedSubject["id"])
            ..name = getString(nestedSubject["name"])
            ..gradesAll = MapBuilder(
              {
                semester: BuiltList<GradeAll>(
                  getList(subject["grades"])!.map<GradeAll>(
                    (dynamic g) => tryParse(getMap(g)!, _parseGradeAll),
                  ),
                ),
              },
            ),
        ),
      );
    }
  }
  for (final subject in removedIds) {
    subjectsBuilder.removeWhere((s) => s.id == subject);
  }
}

Observation _parseObservation(Map data) {
  return Observation(
    (b) => b
      ..typeName = getString(data["typeName"])
      ..cancelled = data["cancelled"] != 0
      ..created = getString(data["created"])
      ..note = getString(data["note"])
      ..date = UtcDateTime.parse(getString(data["date"])!),
  );
}

int? _parseGradeValue(String? grade) {
  if (grade == null || grade == "" || grade == "0") return null;
  final gradeSplitted = grade
      .split(".")
      .map(
        (s) => int.parse(s),
      )
      .toList();
  final gradeValue = gradeSplitted[0] * 100 + gradeSplitted[1];
  return gradeValue;
}

GradeAll _parseGradeAll(Map data) {
  return GradeAll(
    (b) => b
      ..grade = tryParse(getString(data["grade"]), _parseGradeValue)
      ..weightPercentage = getInt(data["weight"])
      ..date = UtcDateTime.parse(getString(data["date"])!)
      ..cancelled = data["cancelled"] != 0
      ..type = getString(data["type"]),
  );
}

GradeDetail _parseGrade(Map data) {
  return GradeDetail(
    (b) => b
      ..grade = tryParse(getString(data["grade"]), _parseGradeValue)
      ..date = UtcDateTime.parse(getString(data["date"])!)
      ..weightPercentage = getInt(data["weight"])
      ..cancelled = getBool(data["cancelled"])
      ..type = getString(data["typeName"])
      ..created = getString(data["created"])
      ..name = getString(data["name"])
      ..description = getString(data["description"])
      ..id = getInt(data["id"])
      ..competences = ListBuilder(
        getList(data["competences"])!.map<Competence>(
          (dynamic c) => tryParse(getMap(c)!, _parseCompetence),
        ),
      ),
  );
}

GradeDetail _addCancelledDescription(GradeDetail grade, dynamic data) {
  return grade.rebuild(
    (b) => b..cancelledDescription = getString(data["cancelledDescription"]),
  );
}

Competence _parseCompetence(Map data) {
  return Competence((b) => b
    ..typeName = getString(data["typeName"])
    ..grade = (double.tryParse(getString(data["grade"]) ?? "") ?? 0).toInt());
}

class _SemesterLock {
  Semester? current;
  int usersOfCurrent = 0;
  final Future<void> Function(Semester) semesterChangeCallback;
  _SemesterLock(this.semesterChangeCallback);
  final _mutex = Mutex();
  Map<Semester, List<Future<void> Function()>> waitlist = {};

  Future<void> synchronized(
      Semester semester, Future<void> Function() f) async {
    await _mutex.acquire();
    bool mutexAcquired = true;
    if (usersOfCurrent == 0 || semester == current) {
      usersOfCurrent++;
      if (semester != current) {
        await semesterChangeCallback(semester);
        current = semester;
      }
      _mutex.release();
      mutexAcquired = false;
      await f();
      if (usersOfCurrent == 1 && waitlist.isNotEmpty) {
        final last = waitlist.entries.first;
        waitlist.remove(last.key);
        for (final f in last.value) {
          unawaited(synchronized(last.key, f));
        }
      }
      usersOfCurrent--;
    } else {
      if (waitlist.containsKey(semester)) {
        waitlist[semester]!.add(f);
      } else {
        waitlist[semester] = [f];
      }
    }
    if (mutexAcquired) {
      _mutex.release();
    }
  }
}

final gradesProvider =
    NotifierProvider<GradesNotifier, GradesState>(GradesNotifier.new);

final pendingGradeIdProvider = StateProvider<int?>((ref) => null);
